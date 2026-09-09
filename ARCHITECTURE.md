# Architecture

```text
filesystem / Git
  |  source, specs, acceptance contracts, scripts, evidence
  v
Rojo (default.project.json)
  |  build or live sync
  v
Roblox Studio
  |  runtime only
  v
Official Studio MCP
     playtest, TestState, console, screenshots, keyboard/mouse input
```

`src/shared/GameSpec.json` describes the generated world and test sampling. `src/server/MicroObbyBuilder.luau` builds that world. The acceptance contract is separate at `tests/acceptance/micro_obby_jump_v0.json`, mapped by Rojo into `ServerStorage.AcceptanceContracts`. Bootstrap loads both and gives the contract to `TestHooks`; the builder never receives it.

`TestHooks` exposes facts through `ReplicatedStorage.TestState` and console markers. Codex or another reviewer applies the acceptance contract to those facts and records the evidence under `artifacts/`. Studio state is disposable and must never be treated as the persistent source.
