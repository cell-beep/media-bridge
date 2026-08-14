# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import threading
import uuid
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Literal

import yt_dlp
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from yt_dlp.version import __version__ as yt_dlp_version

from .core import (
    UnsafeUrlError,
    build_ydl_options,
    percentage_from_hook,
    validate_media_url,
)


class ProbeRequest(BaseModel):
    url: str = Field(min_length=8, max_length=4096)


class DownloadRequest(ProbeRequest):
    mode: Literal["video", "audio"] = "video"
    max_height: Literal[480, 720, 1080, 1440, 2160] = 1080
    audio_format: Literal["mp3", "m4a", "opus"] = "mp3"


app = FastAPI(title="Media Bridge", version="0.2.2")
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=(
        r"^(chrome-extension|moz-extension)://[A-Za-z0-9_-]+$|"
        r"^http://(localhost|127\.0\.0\.1)(:\d+)?$"
    ),
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)

DOWNLOAD_DIR = Path(
    os.environ.get("MEDIA_BRIDGE_DOWNLOAD_DIR", Path.home() / "Downloads" / "MediaBridge")
).expanduser()
STATE_DIR = Path(
    os.environ.get(
        "MEDIA_BRIDGE_STATE_DIR",
        Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData" / "Local")) / "Media Bridge",
    )
).expanduser()
JOBS_DIR = STATE_DIR / "jobs"
EXECUTOR = ThreadPoolExecutor(max_workers=2, thread_name_prefix="media-bridge")
JOBS: dict[str, dict] = {}
JOBS_LOCK = threading.Lock()
TEST_MODE = os.environ.get("MEDIA_BRIDGE_TEST_MODE", "").lower() in {"1", "true", "yes"}
ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


def _ffmpeg_dir() -> Path | None:
    configured = os.environ.get("MEDIA_BRIDGE_FFMPEG_DIR")
    if configured:
        candidate = Path(configured).expanduser()
        if (candidate / "ffmpeg.exe").is_file() or (candidate / "ffmpeg").is_file():
            return candidate
    if getattr(sys, "frozen", False):
        bundle_root = Path(getattr(sys, "_MEIPASS", Path(sys.executable).parent))
        candidates = [bundle_root / "ffmpeg", Path(sys.executable).parent / "ffmpeg"]
    else:
        project_root = Path(__file__).resolve().parents[3]
        candidates = [project_root / ".tools" / "ffmpeg" / "bin"]
    for candidate in candidates:
        if (candidate / "ffmpeg.exe").is_file() or (candidate / "ffmpeg").is_file():
            return candidate
    executable = shutil.which("ffmpeg")
    return Path(executable).parent if executable else None


def _deno_path() -> Path | None:
    configured = os.environ.get("MEDIA_BRIDGE_DENO_PATH")
    if configured:
        candidate = Path(configured).expanduser()
        if candidate.is_file():
            return candidate
    if getattr(sys, "frozen", False):
        bundle_root = Path(getattr(sys, "_MEIPASS", Path(sys.executable).parent))
        candidates = [
            bundle_root / "runtime" / "deno.exe",
            Path(sys.executable).parent / "runtime" / "deno.exe",
            Path(sys.executable).parent / "deno.exe",
        ]
        for candidate in candidates:
            if candidate.is_file():
                return candidate
    executable = shutil.which("deno")
    return Path(executable) if executable else None


def _clean_error(error: Exception) -> str:
    return ANSI_ESCAPE_RE.sub("", str(error)).strip()[:800]


def open_download_directory() -> None:
    """Open the download directory with the operating system file manager."""
    DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
    if sys.platform == "win32":
        os.startfile(DOWNLOAD_DIR)  # type: ignore[attr-defined]
    elif sys.platform == "darwin":
        subprocess.Popen(["open", str(DOWNLOAD_DIR)])
    else:
        subprocess.Popen(["xdg-open", str(DOWNLOAD_DIR)])


def _public_job(job: dict) -> dict:
    return {key: value for key, value in job.items() if not key.startswith("_")}


def _job_path(job_id: str) -> Path:
    return JOBS_DIR / f"{job_id}.json"


def _request_path(job_id: str) -> Path:
    return JOBS_DIR / f"{job_id}.request.json"


def _read_job_file(job_id: str) -> dict | None:
    try:
        value = json.loads(_job_path(job_id).read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def _write_job_file(job: dict) -> None:
    JOBS_DIR.mkdir(parents=True, exist_ok=True)
    public_job = _public_job(job)
    target = _job_path(str(public_job["id"]))
    temporary = target.with_suffix(f".{os.getpid()}.tmp")
    temporary.write_text(
        json.dumps(public_job, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    os.replace(temporary, target)


def _update_job(job_id: str, **updates: object) -> None:
    with JOBS_LOCK:
        job = JOBS.get(job_id) or _read_job_file(job_id)
        if job is None:
            return
        job.update(updates)
        JOBS[job_id] = job
        _write_job_file(job)


def _progress_hook(job_id: str):
    def hook(event: dict) -> None:
        status = event.get("status")
        if status == "downloading":
            percentage = percentage_from_hook(event)
            updates: dict[str, object] = {"status": "downloading", "message": "Downloading media…"}
            if percentage is not None:
                updates["progress"] = percentage
            _update_job(job_id, **updates)
        elif status == "finished":
            _update_job(job_id, progress=100.0, message="Finalizing file…")

    return hook


def _download(job_id: str, request: DownloadRequest) -> None:
    try:
        _update_job(job_id, status="starting", message="Starting download…")
        output_dir = DOWNLOAD_DIR
        output_dir.mkdir(parents=True, exist_ok=True)
        ffmpeg_dir = _ffmpeg_dir()
        deno_path = _deno_path()
        options = build_ydl_options(
            mode=request.mode,
            max_height=request.max_height,
            audio_format=request.audio_format,
            output_dir=output_dir,
            progress_hook=_progress_hook(job_id),
            ffmpeg_available=ffmpeg_dir is not None,
            ffmpeg_location=str(ffmpeg_dir) if ffmpeg_dir else None,
            js_runtime_path=str(deno_path) if deno_path else None,
        )
        if TEST_MODE:
            options["test"] = True
        with yt_dlp.YoutubeDL(options) as downloader:
            info = downloader.extract_info(request.url, download=True)
        title = info.get("title") if isinstance(info, dict) else None
        _update_job(
            job_id,
            status="finished",
            progress=100.0,
            message=f"Finished: {title or 'media'}",
        )
    except Exception as exc:  # yt-dlp exposes extractor-specific exception types.
        _update_job(
            job_id,
            status="failed",
            message="Download failed.",
            error=_clean_error(exc),
        )


@app.get("/api/health")
def health() -> dict:
    ffmpeg_dir = _ffmpeg_dir()
    deno_path = _deno_path()
    return {
        "status": "ok",
        "ffmpeg": ffmpeg_dir is not None,
        "ffmpeg_dir": str(ffmpeg_dir) if ffmpeg_dir else None,
        "javascript_runtime": "deno" if deno_path else None,
        "javascript_runtime_path": str(deno_path) if deno_path else None,
        "yt_dlp_version": yt_dlp_version,
        "output_dir": str(DOWNLOAD_DIR),
        "state_dir": str(STATE_DIR),
        "test_mode": TEST_MODE,
    }


@app.post("/api/open-downloads", status_code=204)
def open_downloads() -> None:
    try:
        open_download_directory()
    except OSError as exc:
        raise HTTPException(status_code=500, detail="Could not open the downloads folder.") from exc


@app.post("/api/probe")
def probe(request: ProbeRequest) -> dict:
    try:
        safe_url = validate_media_url(request.url)
        deno_path = _deno_path()
        with yt_dlp.YoutubeDL(
            {
                "quiet": True,
                "no_warnings": True,
                "noplaylist": True,
                "skip_download": True,
                "socket_timeout": 20,
                **(
                    {"js_runtimes": {"deno": {"path": str(deno_path)}}}
                    if deno_path
                    else {}
                ),
            }
        ) as downloader:
            info = downloader.extract_info(safe_url, download=False)
    except UnsafeUrlError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=422, detail=_clean_error(exc)) from exc

    return {
        "title": info.get("title"),
        "duration": info.get("duration"),
        "extractor": info.get("extractor_key") or info.get("extractor"),
        "thumbnail": info.get("thumbnail"),
        "webpage_url": info.get("webpage_url") or safe_url,
    }


def _prepare_download(request: DownloadRequest) -> tuple[str, dict]:
    try:
        request.url = validate_media_url(request.url)
    except UnsafeUrlError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    if request.mode == "audio" and _ffmpeg_dir() is None:
        raise HTTPException(status_code=503, detail="FFmpeg is required for audio conversion.")

    job_id = uuid.uuid4().hex
    job = {
        "id": job_id,
        "status": "queued",
        "progress": 0.0,
        "message": "Waiting to start…",
        "error": None,
        "output_dir": str(DOWNLOAD_DIR),
    }
    with JOBS_LOCK:
        JOBS[job_id] = job
        _write_job_file(job)
    return job_id, job


@app.post("/api/downloads", status_code=202)
def create_download(request: DownloadRequest) -> dict:
    job_id, job = _prepare_download(request)
    EXECUTOR.submit(_download, job_id, request)
    return _public_job(job)


def create_native_download(request: DownloadRequest) -> dict:
    """Start a detached worker so browser service-worker restarts do not cancel a download."""
    job_id, job = _prepare_download(request)
    request_path = _request_path(job_id)
    request_path.write_text(request.model_dump_json(), encoding="utf-8")
    if getattr(sys, "frozen", False):
        command = [sys.executable, "--download-worker", job_id]
    else:
        command = [sys.executable, "-m", "media_bridge.native_host", "--download-worker", job_id]
    creationflags = 0
    if sys.platform == "win32":
        creationflags = subprocess.CREATE_NO_WINDOW | subprocess.DETACHED_PROCESS
    try:
        subprocess.Popen(
            command,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            close_fds=True,
            creationflags=creationflags,
        )
    except OSError as exc:
        request_path.unlink(missing_ok=True)
        _update_job(job_id, status="failed", message="Download failed.", error="Could not start download worker.")
        raise HTTPException(status_code=500, detail="Could not start download worker.") from exc
    return _public_job(job)


def run_download_worker(job_id: str) -> None:
    request_path = _request_path(job_id)
    try:
        request = DownloadRequest.model_validate_json(request_path.read_text(encoding="utf-8"))
    except (OSError, ValidationError) as exc:
        _update_job(job_id, status="failed", message="Download failed.", error="Invalid worker request.")
        raise RuntimeError("Invalid worker request.") from exc
    finally:
        request_path.unlink(missing_ok=True)
    existing = _read_job_file(job_id)
    if existing is not None:
        with JOBS_LOCK:
            JOBS[job_id] = existing
    _download(job_id, request)


@app.get("/api/jobs/{job_id}")
def get_job(job_id: str) -> dict:
    persisted = _read_job_file(job_id)
    with JOBS_LOCK:
        if persisted is not None:
            JOBS[job_id] = persisted
        job = persisted or JOBS.get(job_id)
        if job is None:
            raise HTTPException(status_code=404, detail="Download job not found.")
        return _public_job(job)
