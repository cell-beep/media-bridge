# Media Bridge Support

## What Media Bridge does

Media Bridge saves permitted video or audio to the user's computer. The Microsoft Edge extension provides the interface, and the free Media Bridge Helper performs local extraction, downloading, merging, and audio conversion.

Only download media that you own, that you have permission to save, and that the website permits you to download.

## Installation

1. Install Media Bridge from Microsoft Edge Add-ons.
2. Download and install the signed Media Bridge Helper from the official Media Bridge website.
3. Restart Microsoft Edge.
4. Pin Media Bridge, open a supported media page, and select the extension.

The Helper does not require Python, PowerShell, FFmpeg, Deno, or any other developer tool from the user.

## Using the extension

1. Open a page containing the media.
2. Open Media Bridge and inspect the detected URL.
3. Select video or audio and the preferred quality or format.
4. Confirm that you own the media or have permission to download it.
5. Select **Download**.
6. Select **Open downloads folder** when the job finishes.

Files are saved to `%USERPROFILE%\Downloads\MediaBridge` by default.

## Troubleshooting

### Status shows Offline

- Confirm that Media Bridge Helper is installed in Windows Installed apps.
- Fully close and reopen Microsoft Edge.
- Reinstall the latest Helper from the official download page.

### Status shows Update Helper

The installed Helper is older than the extension. Install the current Helper and restart Microsoft Edge.

### HTTP 403 for one video

A website can reject a particular stream even when other videos work. Remove any partial file for that video, retry, or choose a lower quality. Do not repeatedly retry content that requires authorization you do not have.

### A download appears stuck

Close and reopen the extension to refresh its progress. Downloads run in a separate local worker and are not cancelled when the Microsoft Edge extension service worker sleeps.

### Where is local job state stored?

The Helper uses `%LOCALAPPDATA%\Media Bridge\jobs`. These small JSON records contain job status and local error details; submitted URL request files exist only briefly while a local worker starts.

## Removing Media Bridge

1. Remove Media Bridge from `edge://extensions`.
2. Uninstall Media Bridge Helper from Windows Installed apps.
3. Optionally delete `%LOCALAPPDATA%\Media Bridge` and downloaded files in `Downloads\MediaBridge`.

## Contact

Use the dedicated Soft Harbor Studio support address displayed on the Media Bridge listing and product support page. The release build must replace this sentence with the working address before submission.
