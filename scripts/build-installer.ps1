# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

param(
    [string]$ExtensionId = "kjeliceonffdcojomilebhoipjbkbohh",
    [string]$FirefoxExtensionId = "{d6c3a4cc-8b7b-4f97-a669-7f41c39a6ac8}"
)

$ErrorActionPreference = "Stop"
if ($ExtensionId -notmatch "^[a-p]{32}$") {
    throw "ExtensionId must be a 32-character Chromium extension id."
}
if ($FirefoxExtensionId -notmatch '^\{[0-9a-fA-F-]{36}\}$|^[A-Za-z0-9._@-]+$') {
    throw "FirefoxExtensionId is not a valid Firefox extension id."
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$compilerCandidates = @(
    (Join-Path $projectRoot ".tools\nsis\nsis-3.12\makensis.exe"),
    "C:\Program Files (x86)\NSIS\makensis.exe",
    "C:\Program Files\NSIS\makensis.exe"
)
$compiler = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $compiler) {
    throw "NSIS 3 is not available."
}

$helper = Join-Path $projectRoot "dist\helper\MediaBridgeHelper\MediaBridgeHelper.exe"
if (-not (Test-Path -LiteralPath $helper)) {
    throw "Helper build is missing. Run scripts\build-helper.ps1 first."
}

$buildDir = Join-Path $projectRoot ".build\installer"
$outputDir = Join-Path $projectRoot "dist\installer"
New-Item -ItemType Directory -Force -Path $buildDir, $outputDir | Out-Null

$chromiumTemplatePath = Join-Path $projectRoot "installer\native-host\chromium-host.template.json"
$chromiumManifestPath = Join-Path $buildDir "com.media_bridge.helper.chromium.json"
$chromiumManifest = Get-Content -LiteralPath $chromiumTemplatePath -Raw
$chromiumManifest = $chromiumManifest.Replace("__HELPER_PATH__", "MediaBridgeHelper.exe")
$chromiumManifest = $chromiumManifest.Replace("__EXTENSION_ID__", $ExtensionId)
[System.IO.File]::WriteAllText($chromiumManifestPath, $chromiumManifest, [System.Text.UTF8Encoding]::new($false))

$firefoxTemplatePath = Join-Path $projectRoot "installer\native-host\firefox-host.template.json"
$firefoxManifestPath = Join-Path $buildDir "com.media_bridge.helper.firefox.json"
$firefoxManifest = Get-Content -LiteralPath $firefoxTemplatePath -Raw
$firefoxManifest = $firefoxManifest.Replace("__HELPER_PATH__", "MediaBridgeHelper.exe")
$firefoxManifest = $firefoxManifest.Replace("__EXTENSION_ID__", $FirefoxExtensionId)
[System.IO.File]::WriteAllText($firefoxManifestPath, $firefoxManifest, [System.Text.UTF8Encoding]::new($false))

$script = Join-Path $projectRoot "installer\MediaBridgeHelper.nsi"
Push-Location (Split-Path -Parent $script)
try {
    & $compiler $script
    if ($LASTEXITCODE -ne 0) {
        throw "NSIS failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
