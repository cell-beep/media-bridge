# Contributing to Media Bridge

Thank you for helping improve Media Bridge.

## Before you start

- Use Media Bridge only with media that you own or are permitted to download.
- Do not propose DRM, authentication, paywall, or access-control bypasses.
- Do not add remote executable code to the browser extension.
- Do not commit credentials, signing keys, browser profiles, downloaded media,
  packaged installers, or generated build directories.

## Development

Install `uv`, then run:

```powershell
cd backend
uv sync
uv run python -m unittest discover -s tests -v
cd ..
./scripts/build-extension.ps1 -Target All -Clean
```

The packaged Helper also requires the verified FFmpeg setup described in the
README. Pull requests that alter bundled dependencies must update
`docs/THIRD_PARTY_NOTICES.md` and the release checklist.

## Pull requests

Keep changes focused, add tests for behavior changes, and explain user-visible
effects and privacy implications. By contributing, you agree that your
contribution is licensed under MPL-2.0.
