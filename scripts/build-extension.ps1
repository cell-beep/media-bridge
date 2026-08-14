# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [ValidateSet('Edge', 'Firefox', 'All')]
    [string]$Target = 'All',
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$extensionDir = Join-Path $projectRoot 'extension'
$outputDir = Join-Path $projectRoot 'dist\extension'
$edgeManifestPath = Join-Path $extensionDir 'manifest.json'
$firefoxManifestPath = Join-Path $projectRoot 'packaging\firefox\manifest.json'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

foreach ($required in 'assets\icon-16.png', 'assets\icon-32.png', 'assets\icon-48.png', 'assets\icon-128.png') {
    if (-not (Test-Path -LiteralPath (Join-Path $extensionDir $required))) {
        throw "Missing $required. Run scripts\build-assets.ps1 first."
    }
}

function New-PortableZipArchive {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDirectory,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    $sourceRoot = [System.IO.Path]::GetFullPath($SourceDirectory).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $stream = [System.IO.File]::Open(
        $DestinationPath,
        [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None
    )
    try {
        $archive = [System.IO.Compression.ZipArchive]::new(
            $stream,
            [System.IO.Compression.ZipArchiveMode]::Create,
            $false
        )
        try {
            Get-ChildItem -LiteralPath $sourceRoot -File -Recurse |
                Sort-Object FullName |
                ForEach-Object {
                    $entryName = $_.FullName.Substring($sourceRoot.Length + 1).Replace('\', '/')
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                        $archive,
                        $_.FullName,
                        $entryName,
                        [System.IO.Compression.CompressionLevel]::Optimal
                    ) | Out-Null
                }
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

function New-ExtensionPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Browser,
        [Parameter(Mandatory = $true)][string]$ManifestPath
    )

    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $version = [string]$manifest.version
    $buildDir = Join-Path $projectRoot ".build\extension-package-$($Browser.ToLowerInvariant())"
    $resolvedBuildDir = [System.IO.Path]::GetFullPath($buildDir)
    if (-not $resolvedBuildDir.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar)) {
        throw 'Unsafe extension staging path.'
    }

    if (Test-Path -LiteralPath $resolvedBuildDir) {
        Remove-Item -LiteralPath $resolvedBuildDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $resolvedBuildDir, $outputDir | Out-Null
    Copy-Item -Path (Join-Path $extensionDir '*') -Destination $resolvedBuildDir -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination (Join-Path $resolvedBuildDir 'LICENSE') -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE.txt') -Destination (Join-Path $resolvedBuildDir 'LICENSE.txt') -Force
    if ($Browser -eq 'Firefox') {
        Copy-Item -LiteralPath $ManifestPath -Destination (Join-Path $resolvedBuildDir 'manifest.json') -Force
    }

    $outputPath = Join-Path $outputDir "MediaBridge-$Browser-$version.zip"
    if (Test-Path -LiteralPath $outputPath) {
        Remove-Item -LiteralPath $outputPath -Force
    }
    New-PortableZipArchive -SourceDirectory $resolvedBuildDir -DestinationPath $outputPath
    Write-Output "$Browser extension package created at: $outputPath"
}

if ($Target -in @('Edge', 'All')) {
    New-ExtensionPackage -Browser 'Edge' -ManifestPath $edgeManifestPath
}
if ($Target -in @('Firefox', 'All')) {
    New-ExtensionPackage -Browser 'Firefox' -ManifestPath $firefoxManifestPath
}
