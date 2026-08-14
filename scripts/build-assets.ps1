# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$python = Join-Path $projectRoot 'backend\.venv\Scripts\python.exe'
$renderer = Join-Path $PSScriptRoot 'render_assets.py'

if (-not (Test-Path -LiteralPath $python)) {
    throw "The build environment is missing. Run 'uv sync' in the backend directory first."
}

& $python $renderer --project-root $projectRoot
if ($LASTEXITCODE -ne 0) {
    throw 'Could not render release assets.'
}
