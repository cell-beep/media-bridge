# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [string]$FfmpegArchivePath,
    [switch]$Clean,
    [switch]$SkipDependencySync
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$backendRoot = Join-Path $projectRoot 'backend'

$setupArguments = @{}
if ($FfmpegArchivePath) { $setupArguments.ArchivePath = $FfmpegArchivePath }
if ($Clean) { $setupArguments.Force = $true }
& (Join-Path $PSScriptRoot 'setup-ffmpeg.ps1') @setupArguments

if (-not $SkipDependencySync) {
    Push-Location $backendRoot
    try {
        & uv sync --locked
        if ($LASTEXITCODE -ne 0) { throw "uv sync failed with exit code $LASTEXITCODE." }
    }
    finally { Pop-Location }
}

& (Join-Path $PSScriptRoot 'build-extension.ps1') -Target Firefox -Clean:$Clean
& (Join-Path $PSScriptRoot 'build-helper.ps1') -Clean:$Clean
& (Join-Path $PSScriptRoot 'build-installer.ps1') -FirefoxOnly
& (Join-Path $PSScriptRoot 'generate-release-metadata.ps1')

Write-Output 'Unsigned release candidate prepared. Do not publish it before SignPath signing and verification.'
