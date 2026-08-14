# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [string]$ProductionExtensionId,
    [string]$SupportEmail,
    [string]$PublicSiteUrl
)

$ErrorActionPreference = "Stop"
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$manifest = Get-Content -LiteralPath (Join-Path $projectRoot "extension\manifest.json") -Raw | ConvertFrom-Json
$firefoxManifest = Get-Content -LiteralPath (Join-Path $projectRoot "packaging\firefox\manifest.json") -Raw | ConvertFrom-Json
$version = [string]$manifest.version
$failures = [System.Collections.Generic.List[string]]::new()
$passes = [System.Collections.Generic.List[string]]::new()

function Check([bool]$Condition, [string]$Pass, [string]$Fail) {
    if ($Condition) { $passes.Add($Pass) } else { $failures.Add($Fail) }
}

Check ($manifest.manifest_version -eq 3) "Manifest V3" "Extension must use Manifest V3."
Check (($manifest.permissions -join ',') -eq 'activeTab,nativeMessaging,storage') "Minimal permissions" "Unexpected extension permissions."
Check (-not $manifest.host_permissions) "No persistent host access" "Remove host_permissions for this release."
Check ($firefoxManifest.background.scripts[0] -eq 'service-worker.js') "Firefox background script configured" "Firefox must use a background script instead of a Chromium service worker."
Check (($firefoxManifest.browser_specific_settings.gecko.data_collection_permissions.required -join ',') -eq 'browsingActivity,websiteContent,websiteActivity') "Firefox declares local Helper data processing" "Declare Firefox data_collection_permissions for the active URL, media content, and download action sent to the native Helper."
Check ((Get-Content -LiteralPath (Join-Path $projectRoot 'extension\config.js') -Raw) -match 'enabled:\s*false') "Sponsor disabled" "Sponsor card must be disabled for first review."

$zipPath = Join-Path $projectRoot "dist\extension\MediaBridge-Edge-$version.zip"
Check (Test-Path -LiteralPath $zipPath -PathType Leaf) "Extension ZIP exists" "Build the Edge extension ZIP."
$firefoxZipPath = Join-Path $projectRoot "dist\extension\MediaBridge-Firefox-$version.zip"
Check (Test-Path -LiteralPath $firefoxZipPath -PathType Leaf) "Firefox ZIP exists" "Build the Firefox extension ZIP."

$installerPath = Join-Path $projectRoot "dist\installer\MediaBridgeHelper-Setup-$version.exe"
Check (Test-Path -LiteralPath $installerPath -PathType Leaf) "Helper installer exists" "Build the Helper installer."
if (Test-Path -LiteralPath $installerPath -PathType Leaf) {
    $signature = Get-AuthenticodeSignature -LiteralPath $installerPath
    Check ($signature.Status -eq 'Valid') "Installer signature valid" "Sign and timestamp the Helper installer (current status: $($signature.Status))."
}

$productionIdValid = $ProductionExtensionId -match '^[a-p]{32}$'
Check $productionIdValid "Production extension ID supplied" "Supply the 32-character Microsoft Catalog extension ID."
if ($productionIdValid) {
    Check ($ProductionExtensionId -ne 'kjeliceonffdcojomilebhoipjbkbohh') "Production ID is not the unpacked ID" "Do not release a Helper restricted only to the unpacked development extension ID."
}
Check ($SupportEmail -match '^[^@\s]+@[^@\s]+\.[^@\s]+$' -and $SupportEmail -notmatch '\.example$') "Dedicated support email supplied" "Supply the real dedicated support email."
Check ($PublicSiteUrl -match '^https://[^\s]+$' -and $PublicSiteUrl -notmatch 'example\.') "Public HTTPS site supplied" "Supply the real public HTTPS product URL."

$siteRoot = Join-Path $projectRoot 'dist\site'
Check (Test-Path -LiteralPath (Join-Path $siteRoot 'privacy.html')) "Privacy page built" "Build the public privacy page."
Check (Test-Path -LiteralPath (Join-Path $siteRoot 'support.html')) "Support page built" "Build the public support page."
Check (Test-Path -LiteralPath (Join-Path $siteRoot 'source\ffmpeg-corresponding-source.zip')) "FFmpeg source published with site" "Provide exact FFmpeg corresponding source or replace the FFmpeg distribution strategy."

$helperRoot = Join-Path $projectRoot 'dist\helper\MediaBridgeHelper'
Check (Test-Path -LiteralPath (Join-Path $helperRoot 'LICENSE')) "Full MPL-2.0 license included" "Rebuild Helper so the full LICENSE is installed."
Check (Test-Path -LiteralPath (Join-Path $helperRoot 'LICENSE.txt')) "First-party Helper license notice included" "Rebuild Helper so LICENSE.txt is installed."
Check (Test-Path -LiteralPath (Join-Path $helperRoot 'THIRD-PARTY-NOTICES.md')) "Third-party notices included" "Rebuild Helper so third-party notices are installed."
Check ((Get-ChildItem -LiteralPath (Join-Path $projectRoot 'store-assets') -Filter '*screenshot*.png' -File -ErrorAction SilentlyContinue).Count -ge 2) "Store screenshots present" "Capture at least two clean 1280x800 store screenshots."

Write-Output "PASS ($($passes.Count))"
$passes | ForEach-Object { Write-Output "  + $_" }
Write-Output "BLOCKERS ($($failures.Count))"
$failures | ForEach-Object { Write-Output "  - $_" }
if ($failures.Count -gt 0) { exit 1 }
