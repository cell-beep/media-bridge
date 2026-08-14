# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$toolsRoot = Join-Path $projectRoot '.tools'
$targetBin = Join-Path $toolsRoot 'ffmpeg\bin'
$ffmpegExe = Join-Path $targetBin 'ffmpeg.exe'
$ffprobeExe = Join-Path $targetBin 'ffprobe.exe'

if ((Test-Path -LiteralPath $ffmpegExe) -and (Test-Path -LiteralPath $ffprobeExe)) {
    Write-Output "FFmpeg is already ready at $targetBin"
    exit 0
}

$downloadUri = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
$checksumUri = "$downloadUri.sha256"
$archive = Join-Path $toolsRoot 'ffmpeg-release-essentials.zip'
$checksumFile = "$archive.sha256"
$extractRoot = Join-Path $toolsRoot 'ffmpeg-extract'

New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
Invoke-WebRequest -Uri $downloadUri -OutFile $archive
Invoke-WebRequest -Uri $checksumUri -OutFile $checksumFile

$publishedLine = (Get-Content -LiteralPath $checksumFile -Raw).Trim()
$publishedHash = ($publishedLine -split '\s+')[0].ToUpperInvariant()
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

Remove-Item -LiteralPath $extractRoot -Recurse -Force
Remove-Item -LiteralPath $archive -Force
Remove-Item -LiteralPath $checksumFile -Force

Write-Output "FFmpeg is ready at $targetBin"
& $ffmpegExe -version | Select-Object -First 1
