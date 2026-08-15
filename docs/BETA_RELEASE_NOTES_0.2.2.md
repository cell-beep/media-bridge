# Media Bridge 0.2.2 beta 1

This is the first public Windows beta of Media Bridge. It exists so the
open-source build, installation, browser integration, licensing package, and
uninstallation path can be tested before the production code-signing process
is completed.

## Important unsigned-build notice

`MediaBridgeHelper-Setup-0.2.2.exe` is not Authenticode signed. Windows may
identify the publisher as unknown or display a SmartScreen warning. Do not
weaken Windows security settings or bypass an organization policy to install
this beta. Download it only from the official `cell-beep/media-bridge` GitHub
release and verify its SHA-256 checksum before running it.

The future production release is intended to be signed and timestamped through
the SignPath Foundation open-source program after project approval. No current
signature or approval is claimed.

## Included functionality

- Firefox desktop extension support through Native Messaging;
- local metadata inspection and authorized video or audio downloads;
- video stream merging and MP3, M4A, or Opus audio conversion;
- persisted local job state and download progress;
- per-user Windows installation and normal uninstallation;
- no publisher analytics, ad network, account system, or cloud media upload.

## Legal and source materials

The release includes checksums, a CycloneDX SBOM, first- and third-party
license notices, and the exact corresponding-source archive for the bundled
FFmpeg build. First-party source is licensed under MPL-2.0. Users must download
only media they own, are permitted by the rights holder to save, and that the
website permits downloading.

## Known limitations

- Windows is the only packaged platform in this beta.
- The Firefox extension must be installed separately.
- Some sites or individual streams can reject retrieval with HTTP 403.
- The installer is unsigned and is not yet the production store companion.
