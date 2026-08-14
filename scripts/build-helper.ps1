# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

param(
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $projectRoot "backend"
$ffmpegDir = Join-Path $projectRoot ".tools\ffmpeg\bin"
$ffmpeg = Join-Path $ffmpegDir "ffmpeg.exe"
$ffprobe = Join-Path $ffmpegDir "ffprobe.exe"
$distDir = Join-Path $projectRoot "dist\helper"
$workDir = Join-Path $projectRoot ".build\helper"
$specDir = Join-Path $projectRoot ".build"
$buildEnvironment = Join-Path $backendDir ".venv"
$pyinstaller = Join-Path $buildEnvironment "Scripts\pyinstaller.exe"

if (-not (Test-Path -LiteralPath $ffmpeg) -or -not (Test-Path -LiteralPath $ffprobe)) {
    throw "FFmpeg is missing. Run scripts\setup-ffmpeg.ps1 first."
}

if ($Clean) {
    if (Test-Path -LiteralPath $distDir) {
        Remove-Item -LiteralPath $distDir -Recurse -Force
    }
    if (Test-Path -LiteralPath $workDir) {
        Remove-Item -LiteralPath $workDir -Recurse -Force
    }
}

New-Item -ItemType Directory -Force -Path $distDir, $workDir, $specDir | Out-Null

Push-Location $backendDir
try {
    $deno = Join-Path $buildEnvironment "Scripts\deno.exe"
    if (-not (Test-Path -LiteralPath $pyinstaller)) {
        throw "PyInstaller is missing. Run 'uv sync' in the backend directory first."
    }
    if (-not (Test-Path -LiteralPath $deno)) {
        throw "Deno is missing. Run 'uv sync' in the backend directory first."
    }
    & $pyinstaller `
        --noconfirm `
        --clean `
        --onedir `
        --name MediaBridgeHelper `
        --distpath $distDir `
        --workpath $workDir `
        --specpath $specDir `
        --collect-all yt_dlp `
        --collect-all yt_dlp_ejs `
        --add-binary "$ffmpeg;ffmpeg" `
        --add-binary "$ffprobe;ffmpeg" `
        --add-binary "$deno;runtime" `
        native_entry.py

    $helperRoot = Join-Path $distDir "MediaBridgeHelper"
    $licenseRoot = Join-Path $helperRoot "licenses"
    $pythonLicenseRoot = Join-Path $licenseRoot "python-packages"
    New-Item -ItemType Directory -Force -Path $licenseRoot, $pythonLicenseRoot | Out-Null

    Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE") -Destination (Join-Path $helperRoot "LICENSE") -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE.txt") -Destination (Join-Path $helperRoot "LICENSE.txt") -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot "docs\THIRD_PARTY_NOTICES.md") -Destination (Join-Path $helperRoot "THIRD-PARTY-NOTICES.md") -Force

    $sitePackages = Join-Path $buildEnvironment "Lib\site-packages"
    Get-ChildItem -LiteralPath $sitePackages -Directory -Filter "*.dist-info" | ForEach-Object {
        $packageLicenseDir = Join-Path $_.FullName "licenses"
        if (Test-Path -LiteralPath $packageLicenseDir) {
            $packageName = $_.Name -replace '\.dist-info$', ''
            $target = Join-Path $pythonLicenseRoot $packageName
            New-Item -ItemType Directory -Force -Path $target | Out-Null
            Copy-Item -Path (Join-Path $packageLicenseDir "*") -Destination $target -Recurse -Force
        }
    }
}
finally {
    Pop-Location
}

Write-Host "Helper build created at: $distDir\MediaBridgeHelper\MediaBridgeHelper.exe"
