# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$HelperPath,
    [Parameter(Mandatory = $true)][string]$InstallerPath
)

$ErrorActionPreference = 'Stop'
foreach ($path in @($HelperPath, $InstallerPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Signed artifact not found: $path" }
    $signature = Get-AuthenticodeSignature -LiteralPath $path
    if ($signature.Status -ne 'Valid') {
        throw "Authenticode validation failed for $path. Status: $($signature.Status)."
    }
    if (-not $signature.TimeStamperCertificate) {
        throw "A trusted timestamp is missing from $path."
    }
    Write-Output "Valid signed artifact: $path"
    Write-Output "  Signer: $($signature.SignerCertificate.Subject)"
    Write-Output "  Timestamp: $($signature.TimeStamperCertificate.Subject)"
    Write-Output "  SHA-256: $((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash)"
}
