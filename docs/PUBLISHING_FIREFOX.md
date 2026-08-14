# Publishing Media Bridge on Firefox Add-ons

This guide covers the first Windows desktop release on addons.mozilla.org
(AMO).

Official references:

- [Submit an add-on](https://extensionworkshop.com/documentation/publish/submitting-an-addon/)
- [Package an extension](https://extensionworkshop.com/documentation/publish/package-your-extension/)
- [Firefox add-on policies](https://extensionworkshop.com/documentation/publish/add-on-policies/)
- [Temporary installation for testing](https://extensionworkshop.com/documentation/develop/temporary-installation-in-firefox/)

## 1. Prepare the developer account

Sign in to AMO with the dedicated publisher Mozilla Account. Set the AMO
developer display name to **Soft Harbor Studio** and use a durable support
address. Keep two-factor authentication and recovery codes enabled for the
publisher account.

## 2. Build and validate the package

From the project root:

```powershell
./scripts/build-extension.ps1 -Target Firefox -Clean
web-ext lint --source-dir .build/extension-package-firefox --warnings-as-errors
```

Upload `dist/extension/MediaBridge-Firefox-0.2.2.zip`. Its root contains the
Firefox `manifest.json`. The extension source is plain, readable JavaScript and
CSS with no bundling, minification, remote code, or generated runtime code.

The permanent Firefox add-on ID is
`{d6c3a4cc-8b7b-4f97-a669-7f41c39a6ac8}`. Do not change it after the first AMO
submission because the Helper Native Messaging allowlist depends on it.

## 3. Choose distribution and platform

For the public release choose **On this site** so AMO hosts the listing and
updates. Select Firefox desktop on Windows. The current Helper is a Windows
application; do not claim Linux, macOS, or Android support until native Helpers
for those platforms have passed end-to-end tests.

## 4. Complete privacy and permissions

The manifest declares `browsingActivity`, `websiteContent`, and
`websiteActivity` as required data types because Firefox treats data sent to a
native application as transmission outside the extension. The active URL,
media metadata, and user-requested download operation are sent only to the
local Helper for the primary function. Version 0.2.2 does not transmit this
data to the publisher. The Helper contacts only the media URL submitted by the
user to inspect and retrieve authorized media.

Permission explanations:

- `activeTab`: place the current tab URL into the editable Media URL field when
  the user opens the extension;
- `nativeMessaging`: communicate with the separately installed local Helper;
- `storage`: remember format preferences and local interface state.

Publish the project privacy policy and support page at stable HTTPS URLs before
submission. Revisit the declaration before enabling analytics, remote sponsor
content, accounts, or payments.

## 5. Prepare the Helper

Build the first public installer with only the permanent Firefox ID registered:

```powershell
./scripts/build-helper.ps1
./scripts/build-installer.ps1 -FirefoxOnly
```

Before public release, code-sign and timestamp the Helper and installer, host
the installer over HTTPS, and publish its version, SHA-256 hash, licenses,
uninstall instructions, and Windows requirements.

## 6. Reviewer notes and test path

Use the certification notes in [STORE_LISTING_FIREFOX.md](STORE_LISTING_FIREFOX.md).
Give reviewers a direct HTTPS Helper link and a publisher-controlled or
public-domain media sample whose website permits downloading.

Test the exact submitted ZIP and hosted Helper in a clean Windows user or
virtual machine. Confirm metadata inspection, one video download, one audio
conversion, progress updates, folder opening, understandable failure messages,
and normal uninstall behavior.
