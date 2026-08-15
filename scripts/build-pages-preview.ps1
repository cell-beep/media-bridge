# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$templateRoot = Join-Path $projectRoot "site-template"
$manifest = Get-Content -LiteralPath (Join-Path $projectRoot "extension\manifest.json") -Raw -Encoding utf8 | ConvertFrom-Json
$version = [string]$manifest.version
$supportEmail = "chatandworkv@gmail.com"
$releaseConfigPath = Join-Path $projectRoot "release\public-release.json"
$releaseConfig = if (Test-Path -LiteralPath $releaseConfigPath -PathType Leaf) {
    Get-Content -LiteralPath $releaseConfigPath -Raw -Encoding utf8 | ConvertFrom-Json
}
else {
    [pscustomobject]@{ status = 'preparing' }
}

if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $projectRoot ".build\pages-preview"
}
$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
if (-not $outputRoot.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar)) {
    throw "Pages output must stay inside the project directory."
}

if (Test-Path -LiteralPath $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
Copy-Item -Path (Join-Path $templateRoot "*") -Destination $outputRoot -Recurse -Force
$templateReadme = Join-Path $outputRoot "README.md"
if (Test-Path -LiteralPath $templateReadme) {
    Remove-Item -LiteralPath $templateReadme -Force
}

$assetRoot = Join-Path $outputRoot "assets"
$legalRoot = Join-Path $outputRoot "legal"
New-Item -ItemType Directory -Force -Path $assetRoot, $legalRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot "store-assets\media-bridge-logo-300.png") -Destination (Join-Path $assetRoot "logo.png") -Force
Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE") -Destination (Join-Path $legalRoot "LICENSE") -Force
Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE.txt") -Destination (Join-Path $legalRoot "LICENSE.txt") -Force
Copy-Item -LiteralPath (Join-Path $projectRoot "docs\THIRD_PARTY_NOTICES.md") -Destination (Join-Path $legalRoot "THIRD-PARTY-NOTICES.md") -Force

$productActions = @"
<a class="button" href="https://github.com/cell-beep/media-bridge">View the open-source project</a><a class="button secondary" href="download.html">Helper release status</a>
"@

if ($releaseConfig.status -eq 'unsigned-beta') {
    $required = 'tag', 'version', 'installerUrl', 'installerSha256', 'sourceUrl', 'sourceSha256'
    $missing = $required | Where-Object { -not $releaseConfig.$_ }
    if ($missing) { throw "Unsigned beta release config is incomplete: $($missing -join ', ')." }
    if ([string]$releaseConfig.version -ne $version) { throw 'Release config version does not match the extension manifest.' }
    if ([string]$releaseConfig.installerSha256 -notmatch '^[0-9a-fA-F]{64}$') { throw 'Installer SHA-256 is invalid.' }
    if ([string]$releaseConfig.sourceSha256 -notmatch '^[0-9a-fA-F]{64}$') { throw 'Source SHA-256 is invalid.' }
    if ([string]$releaseConfig.installerUrl -notmatch '^https://github\.com/cell-beep/media-bridge/releases/download/') { throw 'Installer URL must point to the official GitHub release.' }
    if ([string]$releaseConfig.sourceUrl -notmatch '^https://github\.com/cell-beep/media-bridge/releases/download/') { throw 'Source URL must point to the official GitHub release.' }

    $helperDownloadBlock = @"
<div class="notice"><p><strong>Unsigned beta for early testing.</strong></p><p>Media Bridge Helper $version is a public open-source beta, but it does not yet have an Authenticode signature. Windows may identify the publisher as unknown or show a SmartScreen warning. Do not weaken Windows security settings or bypass an organization policy to install it. The future production release will be signed and timestamped after project approval.</p></div>
<p><a class="button" href="$($releaseConfig.installerUrl)">Download unsigned beta Helper</a><a class="button secondary" href="https://github.com/cell-beep/media-bridge/releases/tag/$($releaseConfig.tag)">View release details</a></p>
<section><h2>Verify the beta download</h2><p>Installer SHA-256:</p><p><code>$($releaseConfig.installerSha256.ToLowerInvariant())</code></p><p>Only install a file whose checksum matches this value. This beta is intended to establish and test the first public release before code-signing enrollment; it is not the final store-ready Helper.</p></section>
"@
    $ffmpegSourceBlock = @"
<section><h2>FFmpeg corresponding source</h2><p>The exact corresponding-source package for the FFmpeg binaries bundled with Helper $version is published alongside the beta:</p><p><a href="$($releaseConfig.sourceUrl)">Download FFmpeg corresponding source</a></p><p>Source archive SHA-256:</p><p><code>$($releaseConfig.sourceSha256.ToLowerInvariant())</code></p><p>Questions may be sent to <a href="mailto:$supportEmail">$supportEmail</a>.</p></section>
"@
    $licenseArchiveBlock = '<p>Packaged license texts and third-party notices are included inside the Helper installation and in the GitHub release metadata.</p>'
}
else {
    $helperDownloadBlock = @"
<div class="notice"><p><strong>The signed public Helper is being prepared.</strong></p><p>Media Bridge $version is in release preparation. We will publish the Windows installer here only after release packaging and verification are complete.</p></div>
<p><a class="button secondary" href="https://github.com/cell-beep/media-bridge/releases">View GitHub releases</a></p>
<section><h2>Why there is no download yet</h2><p>The public beta and its matching source package are still being assembled. We do not publish an incomplete installer without its checksums, notices, and corresponding source.</p></section>
"@
    $ffmpegSourceBlock = @"
<section><h2>FFmpeg corresponding source</h2><p>No Helper binary is currently distributed from this site. The exact corresponding-source package and build identification for the FFmpeg binaries bundled with each Helper release will be published alongside that release.</p><p>Questions may be sent to <a href="mailto:$supportEmail">$supportEmail</a>.</p></section>
"@
    $licenseArchiveBlock = '<p>The complete packaged license archive will be published with the Helper release.</p>'
}

$replacements = @{
    '{{VERSION}}' = $version
    '{{SUPPORT_EMAIL}}' = $supportEmail
    '{{PRODUCT_ACTIONS}}' = $productActions
    '{{HELPER_DOWNLOAD_BLOCK}}' = $helperDownloadBlock
    '{{FFMPEG_SOURCE_BLOCK}}' = $ffmpegSourceBlock
    '{{LICENSE_ARCHIVE_BLOCK}}' = $licenseArchiveBlock
}

$textFiles = Get-ChildItem -LiteralPath $outputRoot -Recurse -File | Where-Object { $_.Extension -in '.html', '.txt', '.md' }
foreach ($file in $textFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding utf8
    foreach ($token in $replacements.Keys) {
        $content = $content.Replace($token, $replacements[$token])
    }
    [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($false))
}

$remaining = $textFiles | Select-String -SimpleMatch '{{'
if ($remaining) {
    throw "The Pages preview still contains unreplaced placeholders."
}

[System.IO.File]::WriteAllText((Join-Path $outputRoot '.nojekyll'), '', [System.Text.UTF8Encoding]::new($false))
Write-Output "GitHub Pages preview prepared at: $outputRoot"
