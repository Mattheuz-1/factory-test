[CmdletBinding()]
param(
    [switch]$AllowProtectedChanges,
    [string]$AuthorizationReason
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

& (Join-Path $PSScriptRoot "Test-Json.ps1")
if (-not $?) { exit 1 }

& (Join-Path $PSScriptRoot "Test-AcceptanceContract.ps1")
if (-not $?) { exit 1 }

$protectedArgs = @{ BaseRef = "HEAD" }
if ($AllowProtectedChanges) {
    $protectedArgs.AllowProtectedChanges = $true
    $protectedArgs.AuthorizationReason = $AuthorizationReason
}

& (Join-Path $PSScriptRoot "Test-ProtectedChanges.ps1") @protectedArgs
if (-not $?) { exit 1 }

$buildPath = Join-Path ([System.IO.Path]::GetTempPath()) ("factory-test-{0}.rbxlx" -f [guid]::NewGuid())

try {
    & rojo build (Join-Path $repoRoot "default.project.json") -o $buildPath
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $build = Get-Item -LiteralPath $buildPath
    if ($build.Length -le 0) {
        Write-Error "Rojo produced an empty build artifact"
        exit 1
    }

    Write-Output "Rojo build PASS ($($build.Length) bytes, temporary artifact)"
}
finally {
    if (Test-Path -LiteralPath $buildPath) {
        Remove-Item -LiteralPath $buildPath -Force
    }
}
