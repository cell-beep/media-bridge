# Partner Center submission sheet — Media Bridge 0.2.2

This is the copy/paste sheet for the first Microsoft Edge Add-ons submission.
Replace every `[REQUIRED: ...]` marker before selecting **Publish**.

## Identity

- Publisher display name: **Soft Harbor Studio**
- Product name: **Media Bridge**
- Category: **Productivity**
- Language: **English (en-US)**
- Visibility for pre-certification testing: **Hidden**
- Final visibility after a successful production-path test: **Public**
- Markets: `[REQUIRED: SELECT INITIAL MARKETS DELIBERATELY]`

## Package

- Upload: `dist/extension/MediaBridge-Edge-0.2.2.zip`
- Do not upload the Helper installer in the extension ZIP.
- After upload, record the Microsoft Catalog extension ID: `[REQUIRED: 32-CHARACTER PRODUCTION ID]`
- Rebuild and sign the Helper installer for that ID before submitting for certification.

## Single purpose

Media Bridge lets a user save an individual video or audio item that the user owns or is permitted to download, using the locally installed Media Bridge Helper.

## Permission justifications

### activeTab

Used only when the user opens Media Bridge to read the current tab URL into an editable field. Media Bridge does not monitor other tabs or collect browsing history.

### nativeMessaging

Used to communicate with the separately installed Media Bridge Helper. The Helper performs metadata inspection, an authorized single-item download, stream merging, and optional audio conversion on the user's Windows computer.

### storage

Used for local format preferences and interface state. It is not used to store browsing history, account credentials, or downloaded media.

## Remote code

**No.** All executable extension JavaScript is included in the submitted ZIP. The extension does not download or execute remote JavaScript or WebAssembly. The separately installed native Helper is disclosed as a required companion application and is distributed from the product website.

## Data usage answers

- Active-tab URL: accessed only after the user invokes the extension; editable before submission to the Helper.
- Website content/media metadata: processed locally for the user-facing inspect and download functions.
- Publisher collection: none in version 0.2.2.
- Publisher analytics: none.
- Advertising network or behavioral advertising: none.
- Account credentials and cookies: not accessed.
- Cloud media processing: none.
- Sale or data-broker sharing: none.

Where Partner Center asks whether browsing activity or website content is
handled, answer **Yes** and explain the local, user-initiated purpose. Do not
answer **No** merely because the publisher does not receive the data.

## URLs

- Product website: `[REQUIRED: PUBLIC HTTPS PRODUCT URL]`
- Helper download page: `[REQUIRED: PUBLIC HTTPS HELPER PAGE]`
- Privacy policy: `[REQUIRED: PUBLIC HTTPS PRIVACY URL]`
- Support: `[REQUIRED: PUBLIC HTTPS SUPPORT URL]`
- Support email: `[REQUIRED: DEDICATED SUPPORT EMAIL]`
- Publisher-owned reviewer sample: `[REQUIRED: PUBLIC HTTPS SAMPLE MP4 URL]`

## Short description

Save media you own or are permitted to download—without cloud uploads, intrusive ads, or artificial quotas.

## Search terms

Use no more than seven terms and 21 words total:

`media downloader; video saver; audio extractor; MP3; local media; permitted download`

## Certification notes

Media Bridge requires the separately installed Windows Helper. Microsoft Edge
does not install or manage native messaging hosts, so please install the signed
Helper before testing.

1. Download the signed Helper from `[REQUIRED: PUBLIC HTTPS HELPER PAGE]`.
2. Verify the displayed version is 0.2.2 and install it for the current Windows user.
3. Restart Microsoft Edge.
4. Open `[REQUIRED: PUBLISHER-OWNED SAMPLE MP4 URL]`. Soft Harbor Studio created this short sample and authorizes downloading it for certification testing.
5. Open Media Bridge. The status badge should read **Ready** and the current URL should be prefilled.
6. Select **Inspect**.
7. Confirm the rights-and-site-permission checkbox and select **Download**.
8. The completed file appears in `%USERPROFILE%\Downloads\MediaBridge`.
9. Repeat with **Audio only → MP3** if desired.

The extension does not use remote executable code, import browser cookies,
bypass authentication, defeat DRM or paywalls, or download playlists. Version
0.2.2 has no analytics, advertising network, account system, or cloud media
processing. The Helper contacts only the URL and associated delivery hosts
submitted by the user.

## Assets

- Logo: `store-assets/media-bridge-logo-300.png`
- Small tile: `store-assets/media-bridge-small-tile-440x280.png`
- Large tile: `store-assets/media-bridge-large-tile-1400x560.png`
- Screenshots: `[REQUIRED: 2–6 CLEAN 1280×800 PNG FILES]`

Screenshots must show the real interface with the publisher-owned sample and no
personal tabs, notifications, copyrighted recommendations, developer tools, or
desktop overlays.
