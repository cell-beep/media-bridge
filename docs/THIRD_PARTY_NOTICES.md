# Third-Party Components and Release Notices

This file identifies the major runtime components. The generated Helper also
contains a machine-readable SBOM and the license texts collected from its
packaged Python distributions.

## Runtime components

| Component | Current version/build | License summary | Project/source |
|---|---:|---|---|
| FFmpeg and FFprobe | n8.1.2-40-g852b0552f0 BtbN win64-gpl-8.1 | GNU GPL v3 or later | https://github.com/BtbN/FFmpeg-Builds/tree/590a6612d7d961e9258429e501619e0b7d7cbedf |
| yt-dlp | 2026.07.04 | Unlicense | https://github.com/yt-dlp/yt-dlp |
| yt-dlp-ejs | 0.8.0 | Unlicense AND MIT AND ISC | https://github.com/yt-dlp/ejs |
| Deno | 2.9.5 Python-packaged binary | MIT | https://github.com/denoland/deno |
| Python | 3.13 | Python Software Foundation License | https://www.python.org/ |
| PyInstaller bootloader/runtime | 6.22.0 | GPL with the PyInstaller bootloader exception | https://pyinstaller.org/ |

The Helper also contains transitive Python packages, including FastAPI,
Uvicorn, Pydantic, Starlette, Requests, urllib3, certifi, websockets, Brotli,
Mutagen, and PyCryptodome. `scripts/generate-release-metadata.ps1` exports the
locked environment as a CycloneDX 1.5 SBOM for every release candidate.

## FFmpeg release obligation

Media Bridge invokes FFmpeg and FFprobe as separate programs; they are not
linked into the MPL-covered Helper. They identify themselves as GPL builds.
The selected binary is pinned in `packaging/ffmpeg/build.json` with SHA-256
`4dc80a665fd8a3481acae3f7836807334396a607581f7123b35a71f2ebaacb5d`.

Before public binary distribution, include the complete GPL text and provide
equivalent network access to the complete corresponding source for this exact
binary, including BtbN build scripts, patches, FFmpeg source, and downloaded
source archives for linked libraries. `.github/workflows/ffmpeg-source.yml`
creates that large source bundle from the pinned BtbN commit. A link to the
upstream FFmpeg repository alone is not sufficient release evidence.

## Required release work

1. Review the generated Python license collection against the final SBOM.
2. Run the FFmpeg source-bundle workflow for the pinned build and attach its
   archive and checksum to the same GitHub release as the Helper.
3. Preserve all copyright notices.
4. Review the final bundle with qualified legal counsel before commercial
   distribution.
