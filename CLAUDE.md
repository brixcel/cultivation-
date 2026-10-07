# Cultivation (Roblox) — Claude rules

Solo-playable xianxia cultivation game. V1 is the "first breakthrough" slice: one region, Mortal → Qi Condensation → Foundation Establishment, one tribulation, one hidden cave. V1 exists to answer one question: after the first major breakthrough, do players want to keep cultivating?

## Source of truth

Read these before starting any task:

- `docs/architecture.md`: services, state machine, remotes, data model, config, sequences
- `docs/v1-roadmap.md`: phases, gates, V1 scope table
- `docs/design.md`: game design summary (once added)

Build only what the current phase lists. Anything outside the V1 scope table goes into `docs/later.md`, not into code.

## Rules

1. The server owns all Qi, realm, breakthrough, and reward logic. Clients only send inputs and show results.
2. `CultivationService:AddQi` is the only way Qi changes.
3. Validate every remote: type-check arguments, check player state, rate-limit, reject impossible values. All remotes are defined in `src/shared/remotes/Remotes.luau`.
4. All player data goes through DataService using ProfileStore (`src/server/packages/ProfileStore.luau`). Never call DataStoreService directly anywhere else. Never rename or delete a data field without a schema migration.
5. Balance numbers live only in `src/shared/config`, never hard-coded in services or controllers.
6. `--!strict` in every module we write. Vendored code in `packages/` is left untouched.
7. Services and controllers expose `Init()` (wire dependencies, no yielding) and `Start()` (connect events, start loops). Register new ones in the `order` list of the bootstrap script.
8. Use CollectionService tags for world objects (`Clue`, `CaveFormation`, ...); never hard-code instance paths.
9. One feature per task. After each task: playtest through Studio MCP, check the Output for errors, and report what changed.
10. Never delete or restructure folders without asking first.
11. Commit after every working feature with a clear message. Commit before any big change so it can be rolled back.

## Where things live

| Path | Syncs to (Rojo) |
| --- | --- |
| `src/server/` (`init.server.luau` + `services/`, `packages/`) | `ServerScriptService.Server` |
| `src/client/` (`init.client.luau` + `controllers/`) | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared/` (`config/`, `remotes/`, `types/`, `util/`) | `ReplicatedStorage.Shared` |
| `assets/blender/`, `assets/exports/` | Not synced; Blender sources and FBX exports for the Studio 3D Importer |

Code lives in Git through Rojo. The map, terrain, and imported meshes live in the place file (`Place1.rbxl`, not in Git). Do not create scripts directly in Studio: they won't be in Git and Rojo won't know about them.

## Workflow

- Toolchain is pinned in `rokit.toml` (Rojo, StyLua, selene). Run `rokit install` after cloning.
- Start sync: `rojo serve` (run it in the background), then connect the Rojo plugin in Studio.
- Lint and format before committing: `selene src` and `stylua src`.
- Studio MCP: use it to inspect the DataModel, run playtests, and read the Output window. Edit code in `src/`, not through MCP script edits, so Rojo and Git stay the source of truth.
