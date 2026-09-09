# Operational checkpoint

Updated: 2026-09-09

- Baseline commit: `54e17fb` (`micro-obby black-box PASS with TestHooks v0.1`).
- Last verified gameplay: checkpoint and goal reached, completed, zero pre-goal deaths, `elapsedTime=1.017`, zero runtime errors.
- Toolchain: Windows 11, PowerShell, Rokit 1.2.0, Rojo 7.7.0, official Roblox Studio MCP.
- Acceptance source: `tests/acceptance/micro_obby_jump_v0.json`; ordinary repairs must pass protected-change checks.
- Baseline geometry restored: Landing `Z=-16`, Checkpoint `Z=-13`, Goal `Z=-19`; `GameSpec` contains no acceptance criteria.
- Repository-preparation verification: JSON PASS; acceptance invariants PASS; unauthorized protected changes correctly blocked; authorized build/check PASS.
- Rojo build: PASS, 13,598-byte temporary `.rbxlx`; expected contract and runtime modules present; temporary binary removed.
- Runtime regression: BLOCKED. `rojo serve` started from this repository, but after Studio restart `list_roblox_studios` returned no registered instances. A Rojo-built temporary place also failed to register with the official MCP, so no valid `studio_id` existed for preflight or gameplay.
- Commit: not created because the new runtime wiring has not been regression-tested from the current filesystem revision.

Next: connect the reopened `build.rbxlx` Studio window to both the official MCP and this repository's Rojo server, then rerun preflight and black-box regression. Do not create the experiment branch before the GREEN baseline commit.
