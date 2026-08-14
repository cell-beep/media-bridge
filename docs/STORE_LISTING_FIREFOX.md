# Firefox Add-ons Listing Copy

## Name

Media Bridge

## Summary

Save media you own or are permitted to download—without cloud uploads,
intrusive ads, or artificial quotas.

## Categories

- Download Management
- Photos, Music & Videos

## Listing choices

- Experimental: No
- Requires payment, non-free services/software, or additional hardware: No
  (the required Windows Helper is free)
- Support email: `chatandworkv@gmail.com`
- License: Mozilla Public License 2.0
- Privacy policy: Yes

## Description

Media Bridge is a straightforward local tool for saving video or audio that
you own or have permission to download. It does not impose daily download
quotas, paid waiting timers, forced redirects, or disruptive advertising on
basic downloads.

Open a supported media page, inspect the detected URL, choose video or audio,
select the preferred quality, and save the result directly to your computer.

Features:

- save video at a selected maximum resolution;
- extract audio as MP3, M4A, or Opus;
- inspect a media title and duration before downloading;
- monitor local download progress;
- open the Media Bridge downloads folder directly;
- process files locally without routing media through publisher servers.

The free Media Bridge Helper for Windows performs local extraction, downloading,
merging, and audio conversion. Users do not need Python, PowerShell, FFmpeg, or
other developer tools. The Helper must be installed separately from the
official Media Bridge website.
The official Helper page is
https://cell-beep.github.io/media-bridge/download.html. The Helper and
extension are open source, and the release page publishes the installer
checksum, third-party licenses, and FFmpeg source bundle.

Media Bridge is designed as a calmer alternative to downloaders built around
artificial limits and aggressive advertising.

Websites can impose their own technical, regional, account, and rights-related
restrictions. Media Bridge does not bypass DRM, authentication, paywalls, or
site restrictions and does not guarantee that every stream is available.

Media Bridge does not grant rights to media. Download only content that you
own, that you have permission from the rights holder to save, and that the
website permits you to download.

## Privacy summary

Version 0.2.2 has no publisher analytics, advertising network, account system,
or cloud media processing. Firefox sends the active-tab or user-entered URL,
media metadata, format choices, download action, progress, and errors to the
locally installed Windows Helper for the requested operation. These data are
not transmitted to servers operated by the publisher. The local Helper
contacts the website submitted by the user to retrieve metadata and authorized
media.

## Reviewer notes

Media Bridge requires the separately installed Windows Helper because media
extraction and conversion cannot be performed reliably inside the browser
extension sandbox.

Testing procedure:

1. Install the signed Helper from
   `https://cell-beep.github.io/media-bridge/download.html`.
2. Restart Firefox.
3. Open
   `https://cell-beep.github.io/media-bridge/media/media-bridge-review-sample.mp4`.
4. Open Media Bridge and select **Inspect**.
5. Confirm the rights-and-site-permission checkbox and select **Download**.
6. The completed file appears in `%USERPROFILE%\Downloads\MediaBridge`.

All executable extension code is included in the submitted package. The
extension does not download or execute remote JavaScript or WebAssembly. It
does not import browser cookies, bypass authentication, defeat DRM or paywalls,
or download playlists in this release.

## Required links

- Product page: `https://cell-beep.github.io/media-bridge/`
- Source code: `https://github.com/cell-beep/media-bridge`
- Helper: `https://cell-beep.github.io/media-bridge/download.html`
- Privacy policy: `https://cell-beep.github.io/media-bridge/privacy.html`
- Support: `https://cell-beep.github.io/media-bridge/support.html`
- Third-party notices: `https://cell-beep.github.io/media-bridge/third-party.html`
