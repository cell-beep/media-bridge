# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$FfmpegSourceArchive,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manifest = Get-Content -LiteralPath (Join-Path $projectRoot 'extension\manifest.json') -Raw -Encoding utf8 | ConvertFrom-Json
$version = [string]$manifest.version
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $projectRoot 'dist\beta-release' }
$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
if (-not $outputRoot.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar)) {
    throw 'Beta output must stay inside the project directory.'
}
$sourceArchive = [System.IO.Path]::GetFullPath($FfmpegSourceArchive)
if (-not (Test-Path -LiteralPath $sourceArchive -PathType Leaf)) {
    throw "FFmpeg corresponding-source archive not found: $sourceArchive"
}
if ($sourceArchive -notmatch '\.tar\.zst$|\.zip$') {
    throw 'FFmpeg corresponding source must be a .tar.zst or .zip archive.'
}

$installer = Join-Path $projectRoot "dist\installer\MediaBridgeHelper-Setup-$version.exe"
$extension = Join-Path $projectRoot "dist\extension\MediaBridge-Firefox-$version.zip"
$sbom = Join-Path $projectRoot "dist\release\MediaBridge-$version.cdx.json"
$releaseManifest = Join-Path $projectRoot "dist\release\MediaBridge-$version-release-manifest.json"
$helperLicenseRoot = Join-Path $projectRoot 'dist\helper\MediaBridgeHelper\licenses'
$requiredInputs = @($installer, $extension, $sbom, $releaseManifest)
$missing = $requiredInputs | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }
if ($missing) { throw "Beta inputs are missing:`n$($missing -join "`n")" }
if (-not (Test-Path -LiteralPath $helperLicenseRoot -PathType Container)) {
    throw 'Packaged Helper license directory is missing.'
}

$installerSignature = Get-AuthenticodeSignature -LiteralPath $installer
if ($installerSignature.Status -eq 'Valid') {
    throw 'This command is only for the explicitly unsigned beta channel.'
}

if (Test-Path -LiteralPath $outputRoot) {
    $resolvedOutput = [System.IO.Path]::GetFullPath($outputRoot)
    if (-not $resolvedOutput.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar)) {
        throw 'Refusing to remove an unsafe beta output path.'
    }
    Remove-Item -LiteralPath $resolvedOutput -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$filesToCopy = @(
    $installer,
    $extension,
    $sbom,
    $releaseManifest,
    (Join-Path $projectRoot 'docs\BETA_RELEASE_NOTES_0.2.2.md'),
    (Join-Path $projectRoot 'LICENSE'),
    (Join-Path $projectRoot 'LICENSE.txt'),
    (Join-Path $projectRoot 'docs\THIRD_PARTY_NOTICES.md')
)
foreach ($path in $filesToCopy) {
    Copy-Item -LiteralPath $path -Destination (Join-Path $outputRoot ([System.IO.Path]::GetFileName($path))) -Force
}
Copy-Item -LiteralPath $sourceArchive -Destination (Join-Path $outputRoot ([System.IO.Path]::GetFileName($sourceArchive))) -Force
Compress-Archive -Path (Join-Path $helperLicenseRoot '*') -DestinationPath (Join-Path $outputRoot "MediaBridgeHelper-$version-licenses.zip") -CompressionLevel Optimal

$warning = @"
MEDIA BRIDGE $version UNSIGNED BETA

MediaBridgeHelper-Setup-$version.exe is not Authenticode signed. Windows may
identify the publisher as unknown or show a SmartScreen warning. Do not weaken
Windows security settings or bypass an organization policy to install it.

Download only from https://github.com/cell-beep/media-bridge/releases and
verify the SHA-256 checksum in SHA256SUMS.txt before running the installer.

This beta is not the final store-ready Helper. No SignPath Foundation approval
or signature is claimed.
"@
[System.IO.File]::WriteAllText((Join-Path $outputRoot 'UNSIGNED-BETA-WARNING.txt'), $warning, [System.Text.UTF8Encoding]::new($false))

$releaseFiles = Get-ChildItem -LiteralPath $outputRoot -File | Sort-Object Name
$hashLines = $releaseFiles | ForEach-Object {
    $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $($_.Name)"
}
$hashLines | Set-Content -LiteralPath (Join-Path $outputRoot 'SHA256SUMS.txt') -Encoding ascii

Write-Output "Unsigned beta assets prepared at: $outputRoot"
Write-Output "Installer SHA-256: $((Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash.ToLowerInvariant())"
Write-Output "FFmpeg source SHA-256: $((Get-FileHash -LiteralPath $sourceArchive -Algorithm SHA256).Hash.ToLowerInvariant())"
