# SignPath Foundation application notes

This file collects the public facts and remaining release work for a future
SignPath Foundation open-source code-signing application. It is not an approval
claim and it must be reviewed immediately before submission.

## Project

- Project name: Media Bridge
- Publisher: Soft Harbor Studio
- Repository: https://github.com/cell-beep/media-bridge
- License: Mozilla Public License 2.0 for first-party source code
- Maintainer account: https://github.com/cell-beep
- Support email: chatandworkv@gmail.com
- Product site: https://cell-beep.github.io/media-bridge/
- Privacy policy: https://cell-beep.github.io/media-bridge/privacy.html
- Support page: https://cell-beep.github.io/media-bridge/support.html
- Code-signing policy: https://github.com/cell-beep/media-bridge/blob/main/CODE_SIGNING_POLICY.md

## What is signed

The requested Windows artifact is `MediaBridgeHelper-Setup-<version>.exe`.
The installer contains the local Media Bridge Helper and its runtime
dependencies. The browser extension itself is separately reviewed and signed by
the relevant browser store.

The Helper accepts native-messaging requests only from the explicitly allowed
browser extension IDs enabled for that release. The first public release is
Firefox-only; Microsoft Edge support will be added after the production Edge ID
is assigned. It downloads authorized media to the user's computer and does not
upload media to a Media Bridge cloud service.

## Reproducible build entry points

From a clean Windows checkout, the release build is created with:

```powershell
./scripts/build-helper.ps1
./scripts/build-installer.ps1 -FirefoxOnly
```

The final signing workflow must use a pinned source revision and record the
versions and SHA-256 hashes of all downloaded build inputs. A release is not
published until the resulting installer has a valid Authenticode signature and
timestamp and has passed the release-readiness checks.

## Public-interest and governance summary

Media Bridge is a free, open-source browser media downloader with local
processing. It has no publisher-imposed daily quota, paid waiting timer, forced
redirect, or intrusive advertising. Users are instructed to download only media
they own or have permission to save.

Project security reports are handled according to `SECURITY.md`. Signing and
release authority is documented in `CODE_SIGNING_POLICY.md`. First-party changes
are accepted under MPL-2.0 as described in `CONTRIBUTING.md`.

## Prerequisites before applying

- [ ] GitHub Pages deployment is live at the URLs above.
- [ ] At least one tagged source release and release notes are public.
- [x] The permanent Firefox extension ID is fixed in the submitted manifest.
- [ ] The exact corresponding source for the bundled GPL FFmpeg build is public.
- [ ] Complete third-party notices, license texts, versions, and hashes are in the release.
- [ ] A release SBOM is generated and published.
- [ ] The clean-machine install, upgrade, uninstall, and download test matrix passes.
- [ ] Two-factor authentication is enabled for every account with release authority.
- [ ] The current SignPath Foundation eligibility and application requirements have been rechecked.

## Proposed application summary

> Media Bridge is a free and open-source browser extension and local Windows
> Helper for saving media that the user owns or is permitted to download. Media
> processing takes place on the user's computer; the project does not upload
> media to a Media Bridge cloud service. The browser extension contains no remote
> executable code, and the Helper is restricted to the published extension ID.
> We request open-source code signing for the Windows Helper installer so users
> can verify the publisher and avoid ambiguous warnings caused by an unsigned
> executable. Source, build scripts, licensing information, security policy, and
> release artifacts are publicly maintained in the project repository.
