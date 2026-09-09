# Codex repository map

## Permanent invariants

- Filesystem and Git are the only persistent source of truth.
- Rojo builds and syncs filesystem state into Roblox Studio; Studio is runtime only.
- Acceptance contracts live in `tests/acceptance/`, separate from `GameSpec` and builders.
- Builders may create the world but may not award PASS. PASS requires contract assertions, `TestState` telemetry, and an independent console review.
- Gameplay verification is black-box: keyboard/mouse input only; never teleport, `character_navigation`, CFrame/Position writes, or Luau-assisted movement.
- Persistent changes start in the filesystem. Record each experiment and update `docs/STATE.md` after it finishes.

## Primary commands

```powershell
pwsh -NoProfile -File scripts/Build-Check.ps1
pwsh -NoProfile -File scripts/Test-Json.ps1
pwsh -NoProfile -File scripts/Test-AcceptanceContract.ps1
pwsh -NoProfile -File scripts/Test-ProtectedChanges.ps1
rojo serve default.project.json
```

Protected changes require `-AllowProtectedChanges -AuthorizationReason "..."` and explicit task authorization.

## Safety limits

- Do not publish, upload assets, install large dependencies, or add remote/always-on infrastructure without explicit authorization.
- Do not weaken acceptance criteria, test hooks, protected checks, or this invariant map during an ordinary repair.
- Preserve unrelated and pre-existing worktree changes.

## Verification protocol

1. Run `scripts/Build-Check.ps1`, then build/sync with Rojo.
2. Start a clean Studio playtest through the official MCP.
3. Confirm bootstrap markers, inspect `TestState`, and exercise gameplay with normal input.
4. Evaluate the protected contract and console independently; capture structured evidence under `artifacts/`.
5. Update `docs/STATE.md`; commit only a verified state.
