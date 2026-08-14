# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

param(
    [ValidatePattern("^[a-p]{32}$")]
    [string]$ExtensionId = "kjeliceonffdcojomilebhoipjbkbohh",
    [ValidatePattern('^\{[0-9a-fA-F-]{36}\}$|^[A-Za-z0-9._@-]+$')]
    [string]$FirefoxExtensionId = "{d6c3a4cc-8b7b-4f97-a669-7f41c39a6ac8}"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$helperPath = Join-Path $projectRoot "dist\helper\MediaBridgeHelper\MediaBridgeHelper.exe"
$chromiumTemplatePath = Join-Path $projectRoot "installer\native-host\chromium-host.template.json"
$chromiumManifestPath = Join-Path $projectRoot "dist\helper\com.media_bridge.helper.chromium.json"
$firefoxTemplatePath = Join-Path $projectRoot "installer\native-host\firefox-host.template.json"
$firefoxManifestPath = Join-Path $projectRoot "dist\helper\com.media_bridge.helper.firefox.json"

if (-not (Test-Path -LiteralPath $helperPath)) {
    throw "MediaBridgeHelper.exe is missing. Run scripts\build-helper.ps1 first."
}

$chromiumManifest = Get-Content -LiteralPath $chromiumTemplatePath -Raw
$chromiumManifest = $chromiumManifest.Replace("__HELPER_PATH__", $helperPath.Replace("\", "\\"))
$chromiumManifest = $chromiumManifest.Replace("__EXTENSION_ID__", $ExtensionId)
[System.IO.File]::WriteAllText(
    $chromiumManifestPath,
    $chromiumManifest,
    [System.Text.UTF8Encoding]::new($false)
)

$firefoxManifest = Get-Content -LiteralPath $firefoxTemplatePath -Raw
$firefoxManifest = $firefoxManifest.Replace("__HELPER_PATH__", $helperPath.Replace("\", "\\"))
$firefoxManifest = $firefoxManifest.Replace("__EXTENSION_ID__", $FirefoxExtensionId)
[System.IO.File]::WriteAllText(
    $firefoxManifestPath,
    $firefoxManifest,
    [System.Text.UTF8Encoding]::new($false)
)

$registryEntries = @(
    @{ Path = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.media_bridge.helper"; Manifest = $chromiumManifestPath },
    @{ Path = "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\com.media_bridge.helper"; Manifest = $chromiumManifestPath },
    @{ Path = "HKCU:\Software\Mozilla\NativeMessagingHosts\com.media_bridge.helper"; Manifest = $firefoxManifestPath }
)
foreach ($entry in $registryEntries) {
    New-Item -Path $entry.Path -Force | Out-Null
    Set-Item -Path $entry.Path -Value $entry.Manifest
}

Write-Host "Media Bridge Helper registered for Chrome/Edge $ExtensionId and Firefox $FirefoxExtensionId"
