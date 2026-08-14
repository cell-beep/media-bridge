# Media Bridge Architecture

## Product boundary

Media Bridge has a local data plane and an optional future cloud control plane.

```text
Microsoft Edge popup
        │ Native Messaging
        ▼
Media Bridge Helper
        │
        ├── yt-dlp + EJS + Deno ──► requested media website/CDN
        ├── FFmpeg ────────────────► local merge/conversion
        └── Downloads/MediaBridge ─► local output files

Future marketing service
        └── declarative JSON only: experiments, sponsor copy, frequency caps
```

Media files do not pass through the future marketing service.

## Browser extension

- Manifest V3.
- Plain HTML, CSS, and JavaScript; no Node runtime in the browser.
- `activeTab` reads the current URL only after the user opens the extension.
- `nativeMessaging` connects to `com.media_bridge.helper`.
- `storage` remembers local interface preferences.
- The service worker owns the native connection and correlates request IDs.

## Windows Helper

- Python application packaged as a self-contained PyInstaller onedir build.
- Native Messaging uses length-prefixed JSON over stdin/stdout.
- yt-dlp extracts metadata and media streams.
- yt-dlp-ejs and bundled Deno solve current JavaScript challenges.
- FFmpeg merges video/audio and performs audio conversion.
- A detached worker owns each download so an Edge service-worker restart cannot cancel it.
- Public job state is persisted under `%LOCALAPPDATA%\Media Bridge\jobs`.
- Output is saved under `%USERPROFILE%\Downloads\MediaBridge` by default.

## Future marketing control plane

The planned server should return integrity-protected declarative configuration. It may choose between quiet sponsor, donation, or no-card variants and accept minimal aggregate events. It must not return executable JavaScript, receive media URLs or files, or become required for core downloading.

Before enabling it, update the privacy policy, store disclosure, consent and opt-out controls, retention rules, and security review.
