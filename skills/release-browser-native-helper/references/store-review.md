# Store listing and reviewer notes

## Listing structure

Lead with the local-processing benefit and the core action. Then explain:

1. The extension sends a user-selected media URL to the separately installed local Helper.
2. The Helper downloads/processes the file on the user's computer.
3. The media is not uploaded to the publisher's servers.
4. The product is for media the user owns or is permitted to save.
5. The product does not bypass DRM, paywalls, authentication, or site controls.
6. The product has no publisher-imposed daily quota, forced redirect, or paid waiting timer, if that is true.

Avoid “works everywhere,” “unlimited” without qualification, “anonymous,” or “bypasses restrictions.” Say “no publisher-imposed quota” rather than implying third-party sites have no limits.

## Privacy disclosure

List each data category the extension can observe because of permissions, even when it is processed only locally. Explain retention and transmission separately:

- Active-tab URL and page metadata: read only when the user invokes the extension.
- User-entered media URL: sent only to the local Helper.
- Job status/settings: stored locally for continuity.
- Media: written to the local downloads directory.
- Remote analytics/sponsorship: disabled or described with endpoint, fields, purpose, retention, and opt-out.

The privacy policy, manifest declarations, behavior, and listing must agree.

## Reviewer-only notes template

Provide:

- supported browser and desktop OS;
- extension version and stable ID;
- signed Helper installer URL and SHA-256;
- source repository, exact release tag, build instructions, and SBOM;
- why Native Messaging is needed;
- a rights-cleared test URL;
- steps to install Helper, install extension, inspect, download, and open output;
- expected filenames and visible progress;
- explanation of requested permissions;
- confirmation that no browser cookies, DRM bypass, paywall bypass, or cloud media upload occurs;
- contact email for review questions.

If the Helper is unsigned or not publicly downloadable, do not submit the store package as a production-ready release.

## Storefront update sequence

1. Reserve the store slug/ID.
2. Publish source and preview documentation.
3. Obtain signatures and publish immutable Helper release assets.
4. Replace preview links with signed release links and hashes.
5. Recheck privacy and third-party notices.
6. Upload the final browser ZIP.
7. Fill listing and reviewer notes from the same versioned source document.
8. Submit, then preserve a copy of exactly what reviewers saw.
