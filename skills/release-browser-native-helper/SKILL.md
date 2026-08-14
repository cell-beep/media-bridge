---
name: release-browser-native-helper
description: Prepare, audit, package, sign, document, and publish a browser extension that depends on a local native-messaging Helper. Use for Firefox/Chromium WebExtensions with companion Windows executables, Native Messaging host manifests, installer creation, Authenticode or SignPath setup, bundled FFmpeg or other third-party tools, store review, privacy disclosures, release artifacts, and cross-browser release readiness.
---

# Release Browser Native Helper

Ship a browser extension and its local companion as one understandable, reviewable product. Treat the browser package, native host, third-party binaries, installer, website, source archive, and store listing as one release system.

## Start with the product boundary

1. Confirm why native code is required. Browsers cannot normally run downloaders, transcoders, or arbitrary local executables from a store extension.
2. Prefer Native Messaging for production. Use a localhost HTTP service only as a development bridge or when its security model is explicitly justified.
3. Keep remote servers optional for analytics, sponsorship, or configuration. Do not make user media pass through a cloud service unless that is an explicit product feature and disclosure.
4. Make the user flow: install extension, install signed Helper once, then use the extension. Never require a terminal for ordinary use.
5. State what the product will not do: bypass DRM, paywalls, authentication, or site restrictions; import browser cookies without a separately reviewed need; or download media the user lacks permission to save.

Before changing code, read [release gates](references/release-gates.md), [pitfalls](references/pitfalls.md), and [store review](references/store-review.md).

## Audit the architecture

Map these parts and their trust boundaries:

- Firefox and Chromium manifests, permissions, stable store IDs, and background execution differences.
- Popup/content UI and all data sent to the Helper.
- Native host manifests and browser-specific allowlists.
- Helper entry point, job lifecycle, output folder, logging, and update behavior.
- Bundled executables and libraries, their versions, licenses, source offers, and hashes.
- Installer registration, uninstall behavior, and per-user versus machine-wide scope.
- Public website, privacy policy, support channel, source repository, release downloads, and store listings.

Reject credential-bearing URLs and local/private-network destinations unless the product explicitly requires and secures them. Bind any development HTTP service to loopback only.

## Separate browser variants deliberately

Do not assume a single manifest is store-ready everywhere.

- Give Firefox a stable Gecko ID and supported minimum version.
- Use Firefox background scripts where service-worker behavior differs.
- Give Chromium a stable extension ID before generating `allowed_origins`.
- Generate separate ZIP archives with portable forward-slash entry names.
- Keep permissions minimal and explain each sensitive permission to reviewers.
- Test the exact packaged ZIP, not only an unpacked directory. Unpacked IDs and host allowlists can hide production failures.

## Make jobs resilient

Native Messaging connections and MV3 workers may disappear between requests. Persist enough job state for the popup to reconnect and poll after reopening. A newly awakened worker must not answer "job not found" merely because its in-memory map was reset.

Treat media-specific HTTP failures as normal operational errors. A successful download from one URL does not prove universal compatibility, and a 403 on one media item does not prove the entire product is broken. Surface the original cause without promising to defeat the site.

## Package third-party tools responsibly

For every bundled tool:

1. Pin the provider repository, provider commit, exact asset URL, version, variant, and SHA-256.
2. Verify the hash before extracting.
3. Copy license and notice files into the installed product.
4. Record whether the Helper links to the tool or merely invokes it as a separate process. Do not infer license contagion from bundling alone.
5. Preserve or publish the corresponding source needed by the selected license.
6. Generate a dependency lockfile and machine-readable SBOM when practical.
7. Put checksums and a release manifest beside public downloads.

Use broader codec builds only when their licensing and source obligations are accepted. This workflow is engineering guidance, not legal advice.

## Build and sign in the correct order

On Windows, sign nested executable content before building the containing installer:

1. Reproduce dependencies from pinned metadata.
2. Build the browser archives and unsigned Helper.
3. Submit the Helper executable for Authenticode signing.
4. Verify a valid signature and trusted timestamp.
5. Replace the unsigned Helper with the signed file.
6. Build the installer around the signed Helper.
7. Submit the installer for signing.
8. Verify both signatures and timestamps again.
9. Generate checksums, SBOM, release manifest, and source bundles from the final candidate.

Never rebuild after signing. A rebuild changes bytes and invalidates the signature or makes published hashes describe another file.

For free open-source signing programs, keep the repository public, document reproducible build steps, enable MFA, publish an unsigned source release first if required, and make the signing workflow auditable. Never commit API tokens or certificates.

## Prepare the public release surface

The product page must answer these questions before the user installs anything:

- What does the extension do?
- Why is a separate Helper necessary?
- Which operating systems and browsers are supported?
- Is media processed locally or uploaded?
- Where is the signed installer, source, privacy policy, support, license, and checksum?
- What happens if the Helper is not installed?
- Are there quotas, forced redirects, paid wait timers, or intrusive ads?

Before signatures exist, publish only a preview page. Do not place an unsigned installer behind a button that looks final. After signing, replace the preview with immutable release URLs and exact hashes.

## Prepare store review

Use [store review](references/store-review.md) to prepare descriptions, privacy text, categories, reviewer notes, and test instructions. Be direct about the separately installed Helper. Give reviewers a public, rights-cleared test URL and explain the expected install flow.

Do not claim the extension downloads from every site or always defeats HTTP failures. Do not describe optional sponsorship as invisible if code can display it. Screenshots should show the real product without desktop notifications, unrelated overlays, personal data, or development browser chrome.

## Validate before publishing

Run the full gate list in [release gates](references/release-gates.md). In addition:

- Test clean installation and uninstall on a clean Windows user or VM.
- Test Firefox without Chromium installed and vice versa.
- Test Helper missing, Helper offline, invalid URL, rejected private URL, inspect, audio-only, video+audio, progress reconnect, cancel, and downloads-folder opening.
- Verify installed host manifests point to the real installed executable.
- Inspect the built ZIP and installer contents.
- Confirm public pages contain no placeholders or unsigned download URLs.
- Confirm source repository, release artifacts, listing text, and version numbers agree.

Publish only when all required gates pass or every exception is explicitly documented.
