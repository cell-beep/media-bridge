# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$SupportEmail,
    [Parameter(Mandatory = $true)][string]$EdgeStoreUrl,
    [Parameter(Mandatory = $true)][string]$InstallerPath,
    [string]$FfmpegSourceArchive,
    [switch]$AllowUnsignedPreview
)

$ErrorActionPreference = "Stop"
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$templateRoot = Join-Path $projectRoot "site-template"
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot "dist\site"))
$manifest = Get-Content -LiteralPath (Join-Path $projectRoot "extension\manifest.json") -Raw | ConvertFrom-Json
$version = [string]$manifest.version

if ($BaseUrl -notmatch '^https://[^\s]+$') { throw "BaseUrl must be a public HTTPS URL." }
if ($EdgeStoreUrl -notmatch '^https://[^\s]+$') { throw "EdgeStoreUrl must be an HTTPS URL." }
if ($SupportEmail -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { throw "SupportEmail is not valid." }
if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) { throw "Installer not found: $InstallerPath" }

$signature = Get-AuthenticodeSignature -LiteralPath $InstallerPath
if (-not $AllowUnsignedPreview -and $signature.Status -ne 'Valid') {
    throw "The public Helper installer must have a valid Authenticode signature. Current status: $($signature.Status)."
}
if (-not $AllowUnsignedPreview -and (-not $FfmpegSourceArchive -or -not (Test-Path -LiteralPath $FfmpegSourceArchive -PathType Leaf))) {
    throw "The exact FFmpeg corresponding-source archive is required for a public build."
}
if (-not $outputRoot.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar)) { throw "Unsafe site output path." }

if (Test-Path -LiteralPath $outputRoot) { Remove-Item -LiteralPath $outputRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
Copy-Item -Path (Join-Path $templateRoot "*") -Destination $outputRoot -Recurse -Force
Remove-Item -LiteralPath (Join-Path $outputRoot "README.md") -Force

$assetRoot = Join-Path $outputRoot "assets"
$fileRoot = Join-Path $outputRoot "files"
$legalRoot = Join-Path $outputRoot "legal"
$sourceRoot = Join-Path $outputRoot "source"
New-Item -ItemType Directory -Force -Path $assetRoot, $fileRoot, $legalRoot, $sourceRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot "store-assets\media-bridge-logo-300.png") -Destination (Join-Path $assetRoot "logo.png") -Force

$installerName = "MediaBridgeHelper-Setup-$version.exe"
$publicInstaller = Join-Path $fileRoot $installerName
Copy-Item -LiteralPath $InstallerPath -Destination $publicInstaller -Force
$installerHash = (Get-FileHash -LiteralPath $publicInstaller -Algorithm SHA256).Hash

$productActions = @"
<a class="button" href="$EdgeStoreUrl">Get the Edge extension</a><a class="button secondary" href="download.html">Install the Windows Helper</a>
"@
$helperDownloadBlock = @"
<div class="notice"><p>Version $version · Windows 10 or later · $(if ($signature.Status -eq 'Valid') { 'Digitally signed by Soft Harbor Studio' } else { 'Unsigned preview—not for public distribution' })</p></div>
<p><a class="button" href="files/$installerName">Download Helper</a></p>
<section><h2>Verify the download</h2><p>SHA-256:</p><p><code>$installerHash</code></p></section>
"@
$ffmpegSourceBlock = @"
<section><h2>FFmpeg corresponding source</h2><p>The exact corresponding-source package for the FFmpeg binaries distributed with Helper $version is available here:</p><p><a href="source/ffmpeg-corresponding-source.zip">Download FFmpeg corresponding source</a></p><p>Build identification and checksums are included with the archive. Questions may be sent to <a href="mailto:$SupportEmail">$SupportEmail</a>.</p></section>
"@

Copy-Item -LiteralPath (Join-Path $projectRoot "docs\THIRD_PARTY_NOTICES.md") -Destination (Join-Path $legalRoot "THIRD-PARTY-NOTICES.md") -Force
$helperLicenseRoot = Join-Path $projectRoot "dist\helper\MediaBridgeHelper\licenses"
if (Test-Path -LiteralPath $helperLicenseRoot) {
    Copy-Item -LiteralPath $helperLicenseRoot -Destination $legalRoot -Recurse -Force
    Compress-Archive -Path (Join-Path $helperLicenseRoot '*') -DestinationPath (Join-Path $legalRoot 'media-bridge-licenses.zip') -CompressionLevel Optimal
    $licenseArchiveBlock = '<p><a href="legal/media-bridge-licenses.zip">Packaged license texts</a></p>'
}
elseif ($AllowUnsignedPreview) {
    $licenseArchiveBlock = '<p>The complete packaged license archive is not included in this preview.</p>'
}
else {
    throw "The packaged Helper license directory is required for a public build."
}
if ($FfmpegSourceArchive -and (Test-Path -LiteralPath $FfmpegSourceArchive -PathType Leaf)) {
    Copy-Item -LiteralPath $FfmpegSourceArchive -Destination (Join-Path $sourceRoot "ffmpeg-corresponding-source.zip") -Force
}

$replacements = @{
    '{{VERSION}}' = $version
    '{{SUPPORT_EMAIL}}' = $SupportEmail
    '{{PRODUCT_ACTIONS}}' = $productActions
    '{{HELPER_DOWNLOAD_BLOCK}}' = $helperDownloadBlock
    '{{FFMPEG_SOURCE_BLOCK}}' = $ffmpegSourceBlock
    '{{LICENSE_ARCHIVE_BLOCK}}' = $licenseArchiveBlock
}
$textFiles = Get-ChildItem -LiteralPath $outputRoot -Recurse -File | Where-Object { $_.Extension -in '.html', '.txt', '.md' }
$textFiles | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw
    foreach ($token in $replacements.Keys) { $content = $content.Replace($token, $replacements[$token]) }
    [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.UTF8Encoding]::new($false))
}

$remaining = $textFiles | Select-String -SimpleMatch '{{'
if ($remaining) { throw "The public site still contains unreplaced placeholders." }

if ($AllowUnsignedPreview) {
    Set-Content -LiteralPath (Join-Path $outputRoot 'PREVIEW-NOT-FOR-PUBLICATION.txt') -Encoding utf8 -Value 'This site build may contain an unsigned installer, example contact information, and an incomplete FFmpeg source link. Do not publish it.'
}

Write-Output "Public site prepared at: $outputRoot"
Write-Output "Base URL: $($BaseUrl.TrimEnd('/'))/"
Write-Output "Installer SHA-256: $installerHash"
Write-Output "Authenticode status: $($signature.Status)"
