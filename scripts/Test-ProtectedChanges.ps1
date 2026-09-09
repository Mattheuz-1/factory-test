[CmdletBinding()]
param(
    [string]$BaseRef = "HEAD",
    [switch]$AllowProtectedChanges,
    [string]$AuthorizationReason
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$changedPaths = @(
    & git -C $repoRoot diff --name-only $BaseRef --
    & git -C $repoRoot diff --cached --name-only $BaseRef --
    & git -C $repoRoot ls-files --others --exclude-standard
) | ForEach-Object { $_ -replace "\\", "/" } | Sort-Object -Unique

$protectedPatterns = @(
    "AGENTS.md",
    "ARCHITECTURE.md",
    "default.project.json",
    "src/server/TestHooks.luau",
    "src/server/bootstrap.server.luau",
    "tests/acceptance/*",
    "scripts/*.ps1"
)

$protectedChanges = @(
    foreach ($path in $changedPaths) {
        foreach ($pattern in $protectedPatterns) {
            if ($path -like $pattern) {
                $path
                break
            }
        }
    }
) | Sort-Object -Unique

if ($protectedChanges.Count -eq 0) {
    Write-Output "Protected changes PASS (none detected)"
    return
}

if (-not $AllowProtectedChanges -or [string]::IsNullOrWhiteSpace($AuthorizationReason)) {
    Write-Error "Protected paths changed without explicit authorization: $($protectedChanges -join ', ')"
    exit 1
}

Write-Output "Protected changes AUTHORIZED: $AuthorizationReason"
$protectedChanges | ForEach-Object { Write-Output "  $_" }
