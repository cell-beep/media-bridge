# Media Bridge

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](LICENSE)
[![CI](https://github.com/cell-beep/media-bridge/actions/workflows/ci.yml/badge.svg)](https://github.com/cell-beep/media-bridge/actions/workflows/ci.yml)

Media Bridge is a browser extension for downloading media that you are allowed
to save. A local Helper performs extraction and conversion on the user's own
computer. The browser starts it through Native Messaging, so no terminal,
localhost server, or manual background process is needed in the packaged app.

Media Bridge does not impose its own daily download quotas, paid waiting
timers, or intrusive ads on basic downloads. Website, authorization, format,
network, and hardware limitations still apply.

Public source: [github.com/cell-beep/media-bridge](https://github.com/cell-beep/media-bridge)

## Current MVP (0.2.2)

- Supports Microsoft Edge/Chromium and Firefox 142 or later with separate,
  store-ready manifests built from the same interface code.
- Detects the URL in the active browser tab.
- Reads media metadata before downloading.
- Downloads a video up to a selected resolution, or extracts audio as MP3,
  M4A, or Opus.
- Shows job progress in the popup.
- Opens the download folder directly from the extension.
- Saves files to `Downloads/MediaBridge` by default.
- Communicates with the packaged Helper through the browser's Native Messaging
  protocol.
- Runs downloads in a detached local worker and persists job state, so browser
  service-worker restarts do not cancel progress tracking.
- Includes a quiet, dismissible sponsor-card slot that never executes remote
  code or uses the current page for ad targeting.
- Rejects local/private-network URLs to avoid turning the service into an SSRF
  proxy.

Only download media when you own it or have permission from the rights holder
and the site permits downloading it.

## Development requirements

- Windows with Microsoft Edge or Firefox 142 or later for the packaged Helper
  integration tests.
- Python managed by `uv` for development and automated tests.
- FFmpeg for merging separate video/audio streams and converting audio. It can
  be installed locally for this project with the setup command below. Some
  simple downloads work without it.
- Deno and `yt-dlp-ejs` for current YouTube JavaScript challenges. They are
  installed as locked Python project dependencies and bundled into the Helper.

## Development engine

From this repository:

```powershell
./scripts/setup-ffmpeg.ps1
cd backend
uv sync
uv run media-bridge
```

The FFmpeg setup downloads the current Windows essentials build linked by the
official FFmpeg download page, verifies its published SHA-256 checksum, and
stores only the required executables under the ignored `.tools` folder. You can
instead put FFmpeg on `PATH` or set `MEDIA_BRIDGE_FFMPEG_DIR` to its `bin`
directory.

Optional environment variables:

```powershell
$env:MEDIA_BRIDGE_DOWNLOAD_DIR = "D:\Media"
$env:MEDIA_BRIDGE_PORT = "8765"
uv run media-bridge
```

For integration tests only, `MEDIA_BRIDGE_TEST_MODE=1` asks `yt-dlp` to fetch
only a small portion of each stream instead of the complete media file.

## Build and install the Helper

The end user does not need Python, `uv`, FFmpeg, or PowerShell. Create the
packaged native host and standard Windows installer with:

```powershell
cd backend
uv sync
cd ..
./scripts/build-helper.ps1 -Clean
./scripts/build-installer.ps1
```

The installer is created at
`dist/installer/MediaBridgeHelper-Setup-0.2.2.exe`. It installs per-user,
registers the native host for Chrome, Edge, and Firefox, and appears in Windows
Installed Apps for normal removal. Public releases must be code-signed.

## Build the browser store packages

Generate the extension icons and store artwork, then create a ZIP with
`manifest.json` at its root:

```powershell
cd backend
uv sync
cd ..
./scripts/build-assets.ps1
./scripts/build-extension.ps1 -Target All -Clean
```

The Edge and Firefox packages are created under `dist/extension`. Store
artwork is under `store-assets`. Use `-Target Edge` or `-Target Firefox` to
build only one package.

For an unpacked development extension, the installer and native-host manifest
must use that extension's 32-character ID. Pass it to `build-installer.ps1`, or
register a development build directly:

```powershell
./scripts/register-helper-dev.ps1 -ExtensionId <chromium-extension-id>
```

The command also registers the fixed Firefox development ID declared in
`packaging/firefox/manifest.json`.

## Load the Chromium development extension

1. Open `chrome://extensions` (or `edge://extensions`).
2. Enable **Developer mode**.
3. Choose **Load unpacked**.
4. Select the `extension` folder from this repository.
5. Pin Media Bridge, open a supported media page, and click the extension.

After changing `manifest.json`, click **Reload** on the extension card. The
browser then starts the registered Helper automatically when the popup opens.

## Load the Firefox development extension

The recommended automated path uses Mozilla's `web-ext` against the staged
Firefox package:

```powershell
./scripts/build-extension.ps1 -Target Firefox -Clean
web-ext lint --source-dir .build/extension-package-firefox --warnings-as-errors
web-ext run --source-dir .build/extension-package-firefox
```

For a manual temporary install, open `about:debugging#/runtime/this-firefox`,
select **Load Temporary Add-on**, and choose
`.build/extension-package-firefox/manifest.json`. Temporary add-ons disappear
when Firefox restarts.

The future lightweight online service is limited to sponsor-card content,
license restoration, and update metadata. Video files remain on the user's
computer and are never uploaded for monetization.

## Run tests

```powershell
cd backend
uv run python -m unittest discover -s tests -v
```

## Open-source project

Media Bridge first-party source code is licensed under the
[Mozilla Public License 2.0](LICENSE). Changes to MPL-covered files stay open,
while the file-level license still permits Media Bridge to be combined with
separately licensed software. Third-party components retain their own
licenses; see [third-party notices](docs/THIRD_PARTY_NOTICES.md).

Contributions are welcome under the same license. Before opening a pull
request, read [CONTRIBUTING.md](CONTRIBUTING.md). Security reports should follow
[SECURITY.md](SECURITY.md), and release signing is documented in
[CODE_SIGNING_POLICY.md](CODE_SIGNING_POLICY.md).

## Planned next steps

1. Test downloads on user-owned/public-domain media across several services.
2. Add a download history page and cancel/retry controls.
3. Add the remote sponsor/license contract and privacy-preserving frequency
   caps.
4. Add a transcription endpoint and Whisper worker, then subtitles, summaries,
   chapters, and searchable transcripts.

## Release documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Product principles](docs/PRODUCT_PRINCIPLES.md)
- [Microsoft Edge publishing guide](docs/PUBLISHING_EDGE.md)
- [Firefox Add-ons publishing guide](docs/PUBLISHING_FIREFOX.md)
- [Firefox Add-ons listing copy](docs/STORE_LISTING_FIREFOX.md)
- [Store listing copy](docs/STORE_LISTING_EDGE.md)
- [Privacy policy draft](docs/PRIVACY_POLICY.md)
- [Support guide](docs/SUPPORT.md)
- [Release checklist](docs/RELEASE_CHECKLIST.md)
- [Release notes 0.2.2](docs/RELEASE_NOTES_0.2.2.md)
- [Third-party notices](docs/THIRD_PARTY_NOTICES.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Code-signing policy](CODE_SIGNING_POLICY.md)
- [Trademark policy](TRADEMARKS.md)
- [GitHub publishing guide](docs/PUBLISHING_GITHUB.md)
