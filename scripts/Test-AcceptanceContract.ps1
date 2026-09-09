[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$specPath = Join-Path $repoRoot "src\shared\GameSpec.json"
$contractPath = Join-Path $repoRoot "tests\acceptance\micro_obby_jump_v0.json"
$builderPath = Join-Path $repoRoot "src\server\MicroObbyBuilder.luau"

$spec = Get-Content -Raw -LiteralPath $specPath | ConvertFrom-Json
$contract = Get-Content -Raw -LiteralPath $contractPath | ConvertFrom-Json
$failures = @()

function Assert-Equal($Name, $Actual, $Expected) {
    if ($Actual -ne $Expected) {
        $script:failures += "$Name expected '$Expected', got '$Actual'"
    }
}

if ($spec.PSObject.Properties.Name -contains "acceptance") {
    $failures += "GameSpec must not contain acceptance criteria"
}

Assert-Equal "contract.schemaVersion" $contract.schemaVersion 1
Assert-Equal "contract.testId" $contract.testId $spec.id
Assert-Equal "contract.harnessVersion" $contract.harnessVersion "0.1"
Assert-Equal "contract.requiresCheckpoint" $contract.requiresCheckpoint $true
Assert-Equal "contract.requiresGoal" $contract.requiresGoal $true
Assert-Equal "contract.maxDeaths" $contract.maxDeaths 0
Assert-Equal "contract.maxElapsedSeconds" $contract.maxElapsedSeconds 30
Assert-Equal "contract.maxActiveErrors" $contract.maxActiveErrors 0
Assert-Equal "contract.gameplayInputMode" $contract.gameplayInputMode "keyboard_mouse_only"

$requiredMarkers = @(
    "TEST_HOOKS_READY micro_obby_jump_v0",
    "FACTORY_MICRO_OBBY_READY micro_obby_jump_v0",
    "TEST_RUN_STARTED",
    "TEST_CHECKPOINT_REACHED",
    "TEST_GOAL_REACHED"
)

foreach ($marker in $requiredMarkers) {
    if ($contract.requiredConsoleMarkers -notcontains $marker) {
        $failures += "required console marker missing: $marker"
    }
}

$builderSource = Get-Content -Raw -LiteralPath $builderPath
$builderForbiddenTokens = @(
    "AcceptanceContract",
    "spec.acceptance",
    "TestState",
    "goalReached",
    "completed"
)

foreach ($token in $builderForbiddenTokens) {
    if ($builderSource.Contains($token)) {
        $failures += "builder must not evaluate acceptance or grant PASS: found '$token'"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "Acceptance contract PASS ($($contract.testId), harness $($contract.harnessVersion))"
