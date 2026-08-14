# Media Bridge 0.2.2 — Release Notes

Release date: August 14, 2026

## Highlights

- Firefox desktop Manifest V3 extension with a compact local-download interface.
- Windows Helper installed per user; no Python, PowerShell, FFmpeg, or Deno setup required by the user.
- Video downloads with selectable maximum resolution.
- Audio extraction to MP3, M4A, or Opus.
- Metadata inspection, progress display, and direct access to the downloads folder.
- Native Messaging instead of a manually started localhost service.
- Detached local workers and persisted job state, so browser service-worker restarts do not lose downloads.
- Bundled yt-dlp EJS support and Deno runtime for current YouTube extraction requirements.
- Minimal browser permissions and no cloud media upload.
- Explicit extension-page Content Security Policy with self-hosted code only.
- Download confirmation now requires both rights-holder authorization and website permission.
- No publisher-imposed daily download quota, paid waiting timer, or intrusive advertising.

## Publication preparation

- MPL-2.0 open-source license and Soft Harbor Studio project/publisher display name for the individual maintainer.
- Collected Python-package license files included in new Helper builds.
- Firefox Add-ons listing and reviewer instructions.
- Static product, Helper download, privacy, support, and third-party notice pages.
- Publisher-owned six-second certification sample with video and audio.
- Reproducible FFmpeg input metadata, corresponding-source workflow, CycloneDX SBOM, and release hashes.
- Automated release-readiness checks for nested Helper/installer signatures, timestamps, public URLs, FFmpeg source, and screenshots.

## Privacy state

This release has no publisher analytics, ad network, account system, remote sponsor configuration, or cloud media processing. The experimental sponsor card is disabled in the first-review package.

## Known limitations

- Windows is the only packaged platform in this release.
- The separately installed Media Bridge Helper is required.
- Some websites or individual streams can return HTTP 403 or require authorization not available to the Helper.
- Automatic format fallback after HTTP 403 is not yet enabled.
- Download history, cancel controls, and retry controls are not yet included.
- The Windows installer is not public until both its nested Helper and the outer installer have valid timestamped Authenticode signatures.

## Distribution blockers

Before public binary release, complete Windows code signing, run the clean-machine install/uninstall matrix, publish the exact FFmpeg corresponding-source bundle, and attach final checksums described in [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md). The Firefox extension ID, HTTPS product/privacy/support pages, public repository, and release automation are already prepared.
