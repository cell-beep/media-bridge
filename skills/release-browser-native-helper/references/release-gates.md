# Release gates

Use this as a blocking checklist. Record evidence, not only a yes/no assertion.

## Source and reproducibility

- Clean checkout builds the same extension ZIP and functionally equivalent Helper.
- Dependency lockfiles are committed.
- Third-party asset URLs, versions, variants, commits, and SHA-256 values are pinned.
- Corresponding-source archives are prepared where licenses require them.
- First-party license, third-party notices, SBOM, build instructions, and release notes exist.
- Generated or local-only files are excluded from source control.

## Browser packages

- Version matches across Firefox, Chromium, Helper, and installer metadata.
- Firefox package has a stable Gecko ID and supported minimum version.
- Chromium package uses the intended store ID in the native-host allowlist.
- Permissions are minimal and match the listing/privacy disclosures.
- ZIP entries use `/`, contain icons and licenses, and have no secrets or developer paths.
- Sponsor/advertising experiments are disabled for the first review unless fully disclosed.

## Helper and installer

- Native host accepts only the intended browser IDs/origins.
- User input is validated; credential-bearing and local/private destinations are rejected unless required.
- Helper uses a deterministic per-user downloads location.
- Helper, bundled tools, host manifests, licenses, and uninstall entries are present after install.
- Helper is signed before installer construction.
- Helper and installer Authenticode statuses are valid and timestamped.
- Clean install, repair/update, and uninstall succeed in a VM.

## Behavior

- Inspect returns title, duration, and thumbnail for rights-cleared test media.
- Video+audio and audio-only flows work.
- Popup can reconnect to a running job after it closes or the background worker restarts.
- Missing Helper and failed downloads produce understandable, non-secret error messages.
- One media-specific 403 does not break subsequent jobs.
- No DRM, authentication, paywall, or browser-cookie bypass is attempted.

## Public release

- Product, privacy, support, source, release, checksum, and third-party/source links work anonymously.
- Store listing and reviewer notes describe the Helper dependency.
- Public installer URL is immutable and points only to a signed file.
- SHA256SUMS and release manifest match uploaded bytes.
- No placeholder text, private address, token, local path, or unsigned candidate is public.
- Screenshots are clean and accurate.
