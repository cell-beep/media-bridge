# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [string]$RepositoryUrl = 'https://github.com/cell-beep/media-bridge.git',
    [string]$CommitMessage = 'Update Media Bridge'
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$safeDirectory = $projectRoot.Replace('\\', '/')

function Invoke-RepositoryGit {
    param([Parameter(Mandatory = $true)][string[]]$GitArguments)
    & git -c "safe.directory=$safeDirectory" -C $projectRoot @GitArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git failed: git $($GitArguments -join ' ')"
    }
}

Remove-Item Env:GIT_DIR -ErrorAction SilentlyContinue
Remove-Item Env:GIT_WORK_TREE -ErrorAction SilentlyContinue

$gitHeadFile = Join-Path $projectRoot '.git\HEAD'
if (-not (Test-Path -LiteralPath $gitHeadFile -PathType Leaf)) {
    & git -C $projectRoot init -b main
    if ($LASTEXITCODE -ne 0) { throw 'Unable to initialize the Git repository.' }
}

Invoke-RepositoryGit @('config', 'user.name', 'Soft Harbor Studio')
Invoke-RepositoryGit @('config', 'user.email', 'chatandworkv@gmail.com')

$remotes = @(& git -c "safe.directory=$safeDirectory" -C $projectRoot remote)
if ($LASTEXITCODE -ne 0) { throw 'Unable to read Git remotes.' }
if ($remotes -contains 'origin') {
    Invoke-RepositoryGit @('remote', 'set-url', 'origin', $RepositoryUrl)
}
else {
    Invoke-RepositoryGit @('remote', 'add', 'origin', $RepositoryUrl)
}

Invoke-RepositoryGit @('add', '--all')
$pending = & git -c "safe.directory=$safeDirectory" -C $projectRoot status --porcelain
if ($LASTEXITCODE -ne 0) { throw 'Unable to read Git status.' }
if ($pending) {
    Invoke-RepositoryGit @('diff', '--cached', '--check')
    & git -c "safe.directory=$safeDirectory" -C $projectRoot show-ref --verify --quiet refs/heads/main
    $effectiveMessage = if ($LASTEXITCODE -eq 0) { $CommitMessage } else { 'Initial open-source release' }
    Invoke-RepositoryGit @('commit', '-m', $effectiveMessage)
}

Invoke-RepositoryGit @('branch', '-M', 'main')
Invoke-RepositoryGit @('push', '--set-upstream', 'origin', 'main')

Write-Host 'Media Bridge source was published successfully.' -ForegroundColor Green
