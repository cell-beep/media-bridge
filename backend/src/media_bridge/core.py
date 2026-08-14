# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from __future__ import annotations

import ipaddress
import socket
from pathlib import Path
from typing import Callable
from urllib.parse import urlparse


class UnsafeUrlError(ValueError):
    """Raised when a URL could target the local or private network."""


def validate_media_url(
    url: str,
    *,
    resolver: Callable[..., list[tuple]] = socket.getaddrinfo,
) -> str:
    """Validate an external HTTP(S) URL and return its normalized input."""
    value = url.strip()
    parsed = urlparse(value)
    if parsed.scheme not in {"http", "https"}:
        raise UnsafeUrlError("Only http:// and https:// media URLs are supported.")
    if parsed.username or parsed.password:
        raise UnsafeUrlError("URLs containing credentials are not accepted.")
    hostname = parsed.hostname
    if not hostname:
        raise UnsafeUrlError("The media URL has no hostname.")
    lowered = hostname.rstrip(".").lower()
    if lowered == "localhost" or lowered.endswith(".localhost") or lowered.endswith(".local"):
        raise UnsafeUrlError("Local network URLs are not accepted.")

    try:
        default_port = 443 if parsed.scheme == "https" else 80
        addresses = {item[4][0] for item in resolver(hostname, parsed.port or default_port)}
    except socket.gaierror as exc:
        raise UnsafeUrlError("The media hostname could not be resolved.") from exc

    if not addresses:
        raise UnsafeUrlError("The media hostname could not be resolved.")
    for address in addresses:
        ip = ipaddress.ip_address(address)
        if not ip.is_global:
            raise UnsafeUrlError("Local or private-network media URLs are not accepted.")
    return value


def build_ydl_options(
    *,
    mode: str,
    max_height: int,
    audio_format: str,
    output_dir: Path,
    progress_hook: Callable[[dict], None],
    ffmpeg_available: bool = True,
    ffmpeg_location: str | None = None,
    js_runtime_path: str | None = None,
) -> dict:
    """Create yt-dlp options for one safe, single-item download."""
    common = {
        "noplaylist": True,
        "paths": {"home": str(output_dir)},
        "outtmpl": {"default": "%(title).180B [%(id)s].%(ext)s"},
        "progress_hooks": [progress_hook],
        "quiet": True,
        "retries": 3,
        "socket_timeout": 30,
    }
    if ffmpeg_location:
        common["ffmpeg_location"] = ffmpeg_location
    if js_runtime_path:
        common["js_runtimes"] = {"deno": {"path": js_runtime_path}}
    if mode == "audio":
        return {
            **common,
            "format": "bestaudio/best",
            "postprocessors": [
                {
                    "key": "FFmpegExtractAudio",
                    "preferredcodec": audio_format,
                    "preferredquality": "192",
                }
            ],
        }
    if not ffmpeg_available:
        return {
            **common,
            "format": f"best[height<={max_height}]/best",
        }
    return {
        **common,
        "format": (
            f"bestvideo*[height<={max_height}]+bestaudio/"
            f"best[height<={max_height}]/best"
        ),
        "merge_output_format": "mp4",
    }


def percentage_from_hook(event: dict) -> float | None:
    total = event.get("total_bytes") or event.get("total_bytes_estimate")
    downloaded = event.get("downloaded_bytes")
    if not total or downloaded is None:
        return None
    return round(min(100.0, max(0.0, downloaded * 100 / total)), 1)
