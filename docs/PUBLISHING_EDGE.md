# Publishing Media Bridge at Microsoft Edge Add-ons

This guide follows the current Microsoft Edge Add-ons workflow in Partner Center.

Official references:

- [Register as a Microsoft Edge extension developer](https://learn.microsoft.com/en-us/microsoft-edge/extensions/publish/create-dev-account)
- [Publish a Microsoft Edge extension](https://learn.microsoft.com/en-us/microsoft-edge/extensions/publish/publish-extension)
- [Developer policies for Microsoft Edge Add-ons](https://learn.microsoft.com/en-us/legal/microsoft-edge/extensions/developer-policies)

Microsoft currently states that registration for the Edge extension program has no fee.

## 1. Prepare the publisher account

Register in Partner Center with a Microsoft account. Choose the individual or company identity that should remain the public owner of Media Bridge. Enter a durable support contact because it can be shown to users.

For this release, the publisher display name is **Soft Harbor Studio**. Microsoft currently documents that email, phone, and business address can be updated later under **Settings → Developer settings → Contact info**. Updating contact information can trigger another account-verification pass. Treat publisher display name, account type, and country/region as fixed after registration.

## 2. Build the extension package

From the project root:

```powershell
cd backend
uv sync
cd ..
./scripts/build-assets.ps1
./scripts/build-extension.ps1 -Clean
```

Upload `dist/extension/MediaBridge-Edge-0.2.2.zip`. The ZIP has `manifest.json` at its root, as required by Partner Center.

Do not upload the Helper installer as the extension package. The Helper is distributed separately from the product website.

## 3. Obtain the production extension ID

The development ID `kjeliceonffdcojomilebhoipjbkbohh` belongs only to the current unpacked build. The production Edge listing receives its own Chromium extension ID.

Once the production ID is available, rebuild the Helper installer so its Native Messaging manifest permits the store extension:

```powershell
./scripts/build-installer.ps1 -ExtensionId <production-extension-id>
```

Test the rebuilt installer with the actual store-installed extension. A Helper built only for the development ID will appear Offline to the store version.

## 4. Sign and host the Helper

Before public distribution:

1. Obtain a trusted Windows code-signing certificate.
2. Sign the Helper binaries and final installer and timestamp the signatures.
3. Verify signatures on a clean Windows machine.
4. Host the installer on an HTTPS product page under the publisher's control.
5. Publish its version, SHA-256 hash, system requirements, and uninstall instructions.

An unsigned Helper creates avoidable SmartScreen warnings and is not a credible public release.

## 5. Complete Partner Center metadata

Use [PARTNER_CENTER_SUBMISSION.md](PARTNER_CENTER_SUBMISSION.md) for field-by-field copy and [STORE_LISTING_EDGE.md](STORE_LISTING_EDGE.md) for the complete source text.

Required or recommended assets are in `store-assets`:

- `media-bridge-logo-300.png` — listing logo, 300×300;
- `media-bridge-small-tile-440x280.png` — small promotional tile;
- `media-bridge-large-tile-1400x560.png` — large promotional tile.

Microsoft currently accepts up to six optional screenshots at 640×480 or 1280×800. Capture clean screenshots without copyrighted page content, personal tabs, developer tools, or unrelated overlays.

## 6. Complete privacy disclosures

Publish [PRIVACY_POLICY.md](PRIVACY_POLICY.md) at a stable public HTTPS URL. Ensure Partner Center answers, store text, extension behavior, and the policy all agree.

For version 0.2.2:

- purpose: locally save user-authorized media;
- remote code: no;
- publisher analytics: none;
- advertising network: none;
- URL access: active tab only after the user invokes the extension;
- cloud media processing: none;
- native application: required and clearly disclosed.

Revisit all disclosures before adding sponsor experiments, analytics, accounts, payments, or cloud features.

## 7. Test the exact production path

Use a clean Windows user or virtual machine:

1. Install the extension from its Microsoft Edge Add-ons listing or private test link.
2. Install the signed production Helper from the public website.
3. Restart Edge and confirm **Ready**.
4. Test metadata inspection, video, audio, progress recovery, folder opening, reinstall, update, and uninstall.
5. Test a failed URL and confirm that the error is understandable.
6. Confirm no PowerShell, Python, FFmpeg, Deno, or developer mode is required.

## 8. Submit and monitor certification

Add the Helper installation URL and clear testing steps to certification notes. Submit the listing and respond to reviewer questions without changing the production URLs during review. Any extension update begins a new review.
