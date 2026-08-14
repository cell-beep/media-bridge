# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $projectRoot 'dist\release' }
$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
if (-not $outputRoot.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar)) {
    throw 'Release metadata output must stay inside the project directory.'
}

$manifest = Get-Content -LiteralPath (Join-Path $projectRoot 'extension\manifest.json') -Raw -Encoding utf8 | ConvertFrom-Json
$ffmpegMetadata = Get-Content -LiteralPath (Join-Path $projectRoot 'packaging\ffmpeg\build.json') -Raw -Encoding utf8 | ConvertFrom-Json
$version = [string]$manifest.version
$expectedFiles = @(
    (Join-Path $projectRoot "dist\extension\MediaBridge-Firefox-$version.zip"),
    (Join-Path $projectRoot "dist\installer\MediaBridgeHelper-Setup-$version.exe"),
    (Join-Path $projectRoot 'dist\helper\MediaBridgeHelper\MediaBridgeHelper.exe'),
    (Join-Path $projectRoot '.tools\ffmpeg\bin\ffmpeg.exe'),
    (Join-Path $projectRoot '.tools\ffmpeg\bin\ffprobe.exe')
)
$missing = $expectedFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }
if ($missing) { throw "Release inputs are missing:`n$($missing -join "`n")" }

New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
$sbomPath = Join-Path $outputRoot "MediaBridge-$version.cdx.json"
Push-Location (Join-Path $projectRoot 'backend')
try {
    & uv export --format cyclonedx1.5 --locked --no-dev --output-file $sbomPath
    if ($LASTEXITCODE -ne 0) { throw "uv export failed with exit code $LASTEXITCODE." }
}
finally { Pop-Location }

$artifacts = foreach ($path in $expectedFiles) {
    $item = Get-Item -LiteralPath $path
    [ordered]@{
        name = $item.Name
        relativePath = [System.IO.Path]::GetRelativePath($projectRoot, $item.FullName).Replace('\', '/')
        bytes = $item.Length
        sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}
$sbomItem = Get-Item -LiteralPath $sbomPath
$artifacts += [ordered]@{
    name = $sbomItem.Name
    relativePath = [System.IO.Path]::GetRelativePath($projectRoot, $sbomItem.FullName).Replace('\', '/')
    bytes = $sbomItem.Length
    sha256 = (Get-FileHash -LiteralPath $sbomItem.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
}

$releaseManifest = [ordered]@{
    schemaVersion = 1
    product = 'Media Bridge'
    version = $version
    generatedAtUtc = [DateTime]::UtcNow.ToString('o')
    sourceCommit = (& git -C $projectRoot rev-parse HEAD).Trim()
    firefoxExtensionId = '{d6c3a4cc-8b7b-4f97-a669-7f41c39a6ac8}'
    ffmpeg = $ffmpegMetadata
    artifacts = $artifacts
}
$manifestPath = Join-Path $outputRoot "MediaBridge-$version-release-manifest.json"
$releaseManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8

$hashFiles = @($expectedFiles) + @($sbomPath, $manifestPath)
$hashLines = $hashFiles | ForEach-Object {
    $hash = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $([System.IO.Path]::GetFileName($_))"
}
$hashLines | Set-Content -LiteralPath (Join-Path $outputRoot 'SHA256SUMS.txt') -Encoding ascii

Write-Output "Release manifest: $manifestPath"
Write-Output "CycloneDX SBOM: $sbomPath"
