# Microsoft Edge Add-ons Listing Copy

## Product name

Media Bridge

## Manifest short description

Save media you own or are permitted to download—without cloud uploads, intrusive ads, or artificial quotas.

## Category

Productivity

## Full description

Media Bridge is a straightforward local tool for saving video or audio that you own or have permission to download. It does not impose daily download quotas, paid waiting timers, or disruptive advertising on basic downloads. Open a supported media page, inspect the detected URL, choose video or audio, select the preferred quality, and save the result directly to your computer.

Downloads and conversions are handled by the free Media Bridge Helper installed on Windows. Media files are not uploaded to a Media Bridge cloud service. The Helper includes the tools needed to merge separate video and audio streams and convert audio to MP3, M4A, or Opus, so users do not need Python, PowerShell, FFmpeg, or other developer software.

Features:

- save video at a selected maximum resolution;
- extract audio as MP3, M4A, or Opus;
- inspect a media title and duration before downloading;
- monitor local download progress;
- open the Media Bridge downloads folder directly;
- continue tracking a download when the Microsoft Edge extension worker restarts;
- process files locally without routing media through the publisher's servers.

## A calmer downloader

Media Bridge is designed as an alternative to downloaders built around artificial limits and aggressive advertising. Basic downloads are not restricted by a Media Bridge daily quota and are not unlocked through countdowns, pop-ups, forced redirects, or interstitial ads. A future optional sponsor or donation card may appear quietly inside the extension interface, but it must remain dismissible and must never block or slow a download.

Websites can still impose their own technical, regional, account, or rights-related restrictions. Media Bridge does not claim to bypass those restrictions and does not guarantee that every URL or stream is available.

The separate Media Bridge Helper is required and must be downloaded from the official Media Bridge website after installing the extension.

Media Bridge does not grant rights to media. Only download content that you own, that you have permission from the rights holder to save, and that the website permits you to download.

## Single-purpose description for Partner Center

Media Bridge allows a user to submit the current page's media URL and save permitted video or audio locally through the installed Media Bridge Helper.

## Permission justifications

### `activeTab`

Used only after the user opens Media Bridge, to read the current tab URL and place it in the editable Media URL field. The extension does not monitor other tabs or browsing history.

### `nativeMessaging`

Required to communicate with the separately installed Media Bridge Helper, which performs local metadata inspection, downloading, merging, and audio conversion.

### `storage`

Stores format preferences and local interface state, such as a dismissed informational card. It is not used to store browsing history or downloaded media.

## Remote-code declaration

No. All executable extension code is included in the submitted package. The extension does not download or execute remote JavaScript or WebAssembly.

## Current data-use declaration

Version 0.2.2 has no publisher analytics, advertising network, account system, or cloud media processing. The active-tab URL and media metadata are processed locally and are not transmitted to servers operated by the publisher. The local Helper contacts the website submitted by the user to retrieve metadata and permitted media.

When completing Partner Center, disclose the active-tab URL under browsing activity or website content if the current form treats locally accessed data as a disclosure category, and explain that it is processed locally and not collected by the publisher.

## Search terms

media downloader, video, audio, local download, MP3, media tool

## Certification notes

Media Bridge requires the separately installed Windows Helper because media extraction and conversion cannot be performed reliably inside the browser extension sandbox.

Testing procedure:

1. Install the signed Helper from `[REQUIRED: PUBLIC HTTPS HELPER URL]`.
2. Restart Microsoft Edge.
3. Open a public-domain or reviewer-owned supported media URL.
4. Open Media Bridge and select **Inspect**.
5. Confirm that the publisher-owned sample is authorized and that the test website permits downloading, then select **Download**.
6. The completed file appears in `%USERPROFILE%\Downloads\MediaBridge`.

The extension contains no remote code. Media is processed locally. The required rights-and-site-permission confirmation is intentionally visible before the Download button is enabled. Media Bridge does not import browser cookies, bypass authentication, defeat DRM or paywalls, or download playlists in this release.

## Required URLs before submission

- Website: `[REQUIRED: HTTPS PRODUCT PAGE]`
- Helper download: `[REQUIRED: HTTPS SIGNED INSTALLER PAGE]`
- Privacy policy: `[REQUIRED: PUBLIC URL FOR PRIVACY_POLICY.md]`
- Support: `[REQUIRED: HTTPS SUPPORT PAGE OR EMAIL]`
