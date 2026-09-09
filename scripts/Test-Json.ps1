[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$jsonFiles = Get-ChildItem -Path $repoRoot -Recurse -File -Filter "*.json" |
    Where-Object { $_.FullName -notlike (Join-Path $repoRoot ".git\*") }

$failures = @()

foreach ($file in $jsonFiles) {
    try {
        $null = Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json
    }
    catch {
        $relativePath = $file.FullName.Substring($repoRoot.Length + 1)
        $failures += "${relativePath}: $($_.Exception.Message)"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "JSON validation PASS ($($jsonFiles.Count) files)"
