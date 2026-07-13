# Jejak Nusantara — Roblox Game (Luau)

A complete, modular Roblox game built from a Game Design Document. Player explores
Indonesian culture through mini-games and dialogue (not quizzes), learns 5 skills
that gate unlocks, keeps a journal, and reaches one of 5 endings based on the
whole journey.

## Structure
- `src/` — all Luau ModuleScripts (Rojo-mapped via `default.project.json`)
  - `ReplicatedStorage/JN/Modules/` — game code (Game orchestrator, Types, Util, Systems, UI, Data)
  - `ServerScriptService/GameServer.luau` — server entry
  - `StarterPlayer/StarterPlayerScripts/GameClient.luau` — client entry
- `docs/` — GDD PDFs, TECHNICAL_DESIGN.md, ROADMAP.md
- `tooling/` — build/verify pipeline (rojo, selene, stylua, luau binaries are gitignored)

## Build
```bash
# Produce the .rbxlx place file
tooling/bin/rojo build --output build/JejakNusantara.rbxlx
```
Open `build/JejakNusantara.rbxlx` in Roblox Studio, then Play.

## Verify (headless, no Studio needed)
```bash
bash tooling/verify.sh
```
Runs 5 layers: Luau syntax → selene lint → stylua format → rojo build →
`luau` runtime smoke test (45 checks covering skill gating, orchestrated
game loop, 8 mini-game scorings, and UI screen construction).

## Conventions
- Small reusable ModuleScripts; no giant scripts.
- All content is data-driven in `Modules/Data/Data.luau`.
- Shared types/constants in `Modules/Types.luau` (no magic numbers).
- Systems communicate via a hand-rolled `Signal` (testable headlessly).

## Audio / Art
Sound and image asset IDs are placeholders in `Data` — wire real PG/SE assets
in Studio (AudioManager already gates music/sfx toggles).
