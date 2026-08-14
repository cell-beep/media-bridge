# Media Bridge Release Checklist

## Blocking decisions

- [x] Public publisher name: Soft Harbor Studio.
- [x] First-party code licensed under MPL-2.0; third-party licenses remain in force.
- [x] Product site and support email selected for the first release.
- [ ] Decide which countries and languages are included in the first release.

## Extension

- [x] Manifest V3 package.
- [x] Minimal permissions: `activeTab`, `nativeMessaging`, `storage`.
- [x] No host permissions and no remote executable code.
- [x] Extension icons at 16, 32, 48, and 128 pixels.
- [x] Store logo and promotional tiles.
- [x] Test sponsor card disabled for the first review package.
- [ ] Capture clean store screenshots at 1280×800.
- [ ] Validate the final ZIP in Partner Center.

## Helper

- [x] Per-user installer and standard uninstaller.
- [x] Bundled FFmpeg, Deno, yt-dlp, and EJS components.
- [x] Detached downloads with persisted progress state.
- [x] First public release scoped to Firefox; Edge follows after its production ID is known.
- [x] Firefox-only installer mode avoids registering a temporary Chromium extension ID.
- [ ] Digitally sign and timestamp binaries and installer.
- [ ] Publish a stable HTTPS download page and SHA-256 hash.
- [ ] Test install, upgrade, and uninstall on a clean Windows user.

## Privacy and support

- [x] Draft privacy policy.
- [x] Draft support and uninstall instructions.
- [x] Draft Partner Center permission justifications and remote-code declaration.
- [x] Publish privacy and support pages at stable HTTPS URLs.
- [x] Add the real support contact to every document and listing.
- [ ] Re-review disclosures immediately before submission.

## Licensing and supply chain

- [x] Include the full MPL-2.0 text and first-party license notice.
- [x] Publish the public source repository and replace code-signing policy placeholders.
- [ ] Obtain free open-source signing approval or another trusted signing certificate.
- [ ] Complete third-party license inventory for every bundled binary and Python package.
- [ ] Include full required license texts in the installer and installed folder.
- [x] Pin a reproducible BtbN GPL FFmpeg build and automate its corresponding-source bundle.
- [x] Automate version and SHA-256 recording for release artifacts and FFmpeg.
- [x] Generate a CycloneDX SBOM for the locked Python environment.
- [ ] Decide whether automatic component updates are allowed; never download executable code into the extension.

## Product QA

- [x] Unit tests for URL validation, format selection, native protocol, and persisted jobs.
- [ ] Test at least ten authorized/public-domain URLs across supported services.
- [ ] Verify video and audio at each advertised format and quality.
- [ ] Test slow, interrupted, rejected, and unsupported downloads.
- [ ] Verify 403 fallback behavior before advertising it.
- [ ] Accessibility pass: keyboard, focus, contrast, zoom, and screen-reader labels.
- [ ] Confirm all user-facing English strings are correctly encoded.
- [ ] Add localization only after the English flow is frozen.

## Release artifacts

- [x] `MediaBridge-Firefox-<version>.zip`
- [ ] signed `MediaBridgeHelper-Setup-<version>.exe`
- [ ] store images and screenshots
- [ ] public privacy, support, and Helper download URLs
- [ ] release notes and known issues
- [ ] SHA-256 checksums and third-party notices
