# Third-Party Components and Release Notices

This file is an inventory for release preparation. It is not yet a substitute for the complete license bundle required before public distribution.

## Runtime components

| Component | Current version/build | License summary | Project/source |
|---|---:|---|---|
| FFmpeg | 9.0.1 Gyan essentials build | GNU GPL v3 or later; current binary reports `--enable-gpl --enable-version3` | https://ffmpeg.org/ and https://www.gyan.dev/ffmpeg/builds/ |
| yt-dlp | 2026.07.04 | Unlicense | https://github.com/yt-dlp/yt-dlp |
| yt-dlp-ejs | 0.8.0 | Unlicense AND MIT AND ISC | https://github.com/yt-dlp/ejs |
| Deno | 2.9.5 Python-packaged binary | MIT | https://github.com/denoland/deno |
| Python | 3.13 | Python Software Foundation License | https://www.python.org/ |
| PyInstaller bootloader/runtime | 6.22.0 | GPL with the PyInstaller bootloader exception | https://pyinstaller.org/ |

The Helper also contains transitive Python packages. Generate a complete inventory from `backend/uv.lock` and the packaged output before release, including FastAPI, Uvicorn, Pydantic, Starlette, Requests, urllib3, certifi, websockets, Brotli, Mutagen, PyCryptodome, and their transitive dependencies.

## FFmpeg release obligation

The current bundled FFmpeg executables identify themselves as GPLv3-or-later builds. Before public distribution, include the complete GPL text and provide equivalent network access to the complete corresponding source for the exact distributed binary, including the source and build material required for the linked libraries. Record the exact archive URL and checksum used by `scripts/setup-ffmpeg.ps1`. A link to the upstream FFmpeg repository alone is not treated by this project as sufficient release evidence. If a different FFmpeg license profile is desired, select and verify that build deliberately rather than assuming an "essentials" build is LGPL-only.

## Required release work

1. Collect full license and notice texts for each shipped component.
2. Add them to the installed Helper directory and installer. `build-helper.ps1` now collects license files exposed by installed Python packages, but the generated set still requires review.
3. Publish corresponding-source information where required.
4. Preserve copyright notices.
5. Review the final bundle with qualified legal counsel before commercial distribution.
