# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [string]$ArchivePath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$toolsRoot = Join-Path $projectRoot '.tools'
$targetBin = Join-Path $toolsRoot 'ffmpeg\bin'
$ffmpegExe = Join-Path $targetBin 'ffmpeg.exe'
$ffprobeExe = Join-Path $targetBin 'ffprobe.exe'
$targetRoot = Split-Path -Parent $targetBin
$installedMetadata = Join-Path $targetRoot 'build.json'
$releaseMetadataPath = Join-Path $projectRoot 'packaging\ffmpeg\build.json'
$releaseMetadata = Get-Content -LiteralPath $releaseMetadataPath -Raw -Encoding utf8 | ConvertFrom-Json

if (-not $Force -and (Test-Path -LiteralPath $ffmpegExe) -and (Test-Path -LiteralPath $ffprobeExe) -and (Test-Path -LiteralPath $installedMetadata)) {
    $installed = Get-Content -LiteralPath $installedMetadata -Raw -Encoding utf8 | ConvertFrom-Json
    if ($installed.assetSha256 -eq $releaseMetadata.assetSha256) {
        Write-Output "Pinned FFmpeg $($releaseMetadata.ffmpegVersion) is already ready at $targetBin"
        exit 0
    }
}

$downloadUri = [string]$releaseMetadata.assetUrl
$publishedHash = ([string]$releaseMetadata.assetSha256).ToUpperInvariant()
$archive = if ($ArchivePath) { [System.IO.Path]::GetFullPath($ArchivePath) } else { Join-Path $toolsRoot ([string]$releaseMetadata.assetName) }
$extractRoot = Join-Path $toolsRoot 'ffmpeg-extract'

New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
if (-not $ArchivePath) {
    Invoke-WebRequest -Uri $downloadUri -OutFile $archive
}
elseif (-not (Test-Path -LiteralPath $archive -PathType Leaf)) {
    throw "FFmpeg archive not found: $archive"
}

$actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToUpperInvariant()
if ($publishedHash -ne $actualHash) {
    throw "FFmpeg checksum mismatch. Expected $publishedHash but received $actualHash."
}

if (Test-Path -LiteralPath $extractRoot) {
    $resolvedExtract = [System.IO.Path]::GetFullPath($extractRoot)
    if (-not $resolvedExtract.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar)) {
        throw 'Unsafe extraction cleanup path.'
    }
    Remove-Item -LiteralPath $resolvedExtract -Recurse -Force
}
Expand-Archive -LiteralPath $archive -DestinationPath $extractRoot -Force

$sourceFfmpeg = Get-ChildItem -LiteralPath $extractRoot -Filter 'ffmpeg.exe' -File -Recurse | Select-Object -First 1
$sourceFfprobe = Get-ChildItem -LiteralPath $extractRoot -Filter 'ffprobe.exe' -File -Recurse | Select-Object -First 1
if ($null -eq $sourceFfmpeg -or $null -eq $sourceFfprobe) {
    throw 'The verified FFmpeg archive did not contain ffmpeg.exe and ffprobe.exe.'
}

New-Item -ItemType Directory -Force -Path $targetBin | Out-Null
Copy-Item -LiteralPath $sourceFfmpeg.FullName -Destination $ffmpegExe -Force
Copy-Item -LiteralPath $sourceFfprobe.FullName -Destination $ffprobeExe -Force

$archiveRoot = $sourceFfmpeg.Directory.Parent.FullName
$licenseFiles = Get-ChildItem -LiteralPath $archiveRoot -File -Recurse | Where-Object {
    $_.Name -match '^(COPYING|LICENSE)(\..+)?$'
}
if (-not $licenseFiles) {
    throw 'The verified FFmpeg archive did not contain a license file.'
}
$targetLicenseRoot = Join-Path $targetRoot 'licenses'
if (Test-Path -LiteralPath $targetLicenseRoot) {
    Remove-Item -LiteralPath $targetLicenseRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $targetLicenseRoot | Out-Null
$licenseFiles | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $targetLicenseRoot $_.Name) -Force
}
Copy-Item -LiteralPath $releaseMetadataPath -Destination $installedMetadata -Force

$versionLine = (& $ffmpegExe -version | Select-Object -First 1)
$configurationLine = (& $ffmpegExe -version | Select-String -Pattern '^configuration:' | Select-Object -First 1).Line
if ($versionLine -notmatch [regex]::Escape([string]$releaseMetadata.ffmpegVersion)) {
    throw "Unexpected FFmpeg version: $versionLine"
}
if ($configurationLine -notmatch '--enable-gpl') {
    throw 'The selected FFmpeg build does not report --enable-gpl.'
}

Remove-Item -LiteralPath $extractRoot -Recurse -Force
if (-not $ArchivePath) { Remove-Item -LiteralPath $archive -Force }

Write-Output "Verified FFmpeg is ready at $targetBin"
Write-Output "SHA-256: $actualHash"
Write-Output $versionLine
