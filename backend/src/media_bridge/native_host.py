# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from __future__ import annotations

import json
import struct
import sys
from typing import BinaryIO

from fastapi import HTTPException
from pydantic import ValidationError

from .app import (
    DownloadRequest,
    ProbeRequest,
    create_native_download,
    get_job,
    health,
    open_downloads,
    probe,
    run_download_worker,
)


MAX_MESSAGE_BYTES = 1024 * 1024


def read_message(stream: BinaryIO) -> dict | None:
    length_bytes = stream.read(4)
    if not length_bytes:
        return None
    if len(length_bytes) != 4:
        raise ValueError("Incomplete native message header.")
    (length,) = struct.unpack("<I", length_bytes)
    if length > MAX_MESSAGE_BYTES:
        raise ValueError("Native message is too large.")
    payload = stream.read(length)
    if len(payload) != length:
        raise ValueError("Incomplete native message payload.")
    message = json.loads(payload.decode("utf-8"))
    if not isinstance(message, dict):
        raise ValueError("Native message must be a JSON object.")
    return message


def write_message(stream: BinaryIO, message: dict) -> None:
    payload = json.dumps(message, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    stream.write(struct.pack("<I", len(payload)))
    stream.write(payload)
    stream.flush()


def handle_message(message: dict) -> dict:
    request_id = message.get("requestId")
    action = message.get("action")
    payload = message.get("payload") or {}
    if not isinstance(payload, dict):
        raise ValueError("Message payload must be an object.")

    if action == "health":
        data = health()
    elif action == "probe":
        data = probe(ProbeRequest.model_validate(payload))
    elif action == "download":
        data = create_native_download(DownloadRequest.model_validate(payload))
    elif action == "job":
        job_id = payload.get("id")
        if not isinstance(job_id, str) or not job_id:
            raise ValueError("A job id is required.")
        data = get_job(job_id)
    elif action == "open_downloads":
        open_downloads()
        data = {"opened": True}
    else:
        raise ValueError(f"Unknown helper action: {action!r}")
    return {"requestId": request_id, "ok": True, "data": data}


def error_response(message: dict | None, error: Exception) -> dict:
    request_id = message.get("requestId") if isinstance(message, dict) else None
    if isinstance(error, HTTPException):
        detail = str(error.detail)
    elif isinstance(error, ValidationError):
        detail = "Invalid request options."
    else:
        detail = str(error)
    return {"requestId": request_id, "ok": False, "error": detail[:800]}


def main() -> None:
    if len(sys.argv) == 3 and sys.argv[1] == "--download-worker":
        run_download_worker(sys.argv[2])
        return
    stdin = sys.stdin.buffer
    stdout = sys.stdout.buffer
    while True:
        message = None
        try:
            message = read_message(stdin)
            if message is None:
                return
            response = handle_message(message)
        except Exception as error:
            response = error_response(message, error)
        write_message(stdout, response)


if __name__ == "__main__":
    main()
