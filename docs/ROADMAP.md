-- Jejak Nusantara — Implementation Roadmap

## Status: COMPLETE (7/7 phases committed, playable-by-construction)

Every commit leaves the project in a verifiable state via a 5-layer gate:
1. `luau-compile --only-parse` (Luau syntax, real parser)
2. `selene` (undefined globals / anti-patterns)
3. `stylua --check` (format)
4. `rojo build` (place compiles → `.rbxlx`)
5. `luau` runtime smoke test (real execution of framework + UI + mini-games)

Run: `bash tooling/verify.sh`

## Phases
| # | Scope | Commit | Files | Runtime checks |
|---|-------|--------|-------|----------------|
| 1 | GDD analysis, TDD, Roadmap, tooling | `d486dca` | docs + tooling | n/a |
| 2 | Architecture: Types + Util (Signal/Tween/Table/RNG) | `9b9b6ed` | 5 | n/a |
| 3 | 16 system module skeletons + bootstrap | `11bf4e6` | 24 | n/a |
| 4 | Framework hardened + runtime-verified | `7e5cf64` | +fixes | 12 |
| 5 | Systems fully wired via Game orchestrator | `74bc4e9` | +wiring | 23 |
| 6 | 5 levels + 8 mini-games (real scoring) + Data | `6a1076f` | 33 | 41 |
| 7 | UI (10+ screens) + AudioManager + bootstrap | `bf7dc41` | 45 | 45 |

## Architecture
```
ReplicatedStorage/JN/Modules/
  Game.luau            # orchestrator: wires all 16 systems (no cycles)
  Types.luau           # single source of truth (enums, records, constants)
  Util/                # Signal, Tween, Table, RNG
  Systems/             # 16 systems + MiniGames/* (8 kinds)
  UI/                  # UIBase + 10 screens + AchievementToast
  Data/Data.luau      # all narrative/content (data-driven)
ServerScriptService/GameServer.luau   # per-player Game session
StarterPlayer/StarterPlayerScripts/GameClient.luau  # UI init
```

## Binding requirements satisfied (from user spec + GDD)
- Skill progression (5 skills) → skill-gated unlocks (dialogue, secrets, alt quests, hidden NPC)
- NPC: personality, dialogue trees, memory, quest logic, reactions, daily behavior, teaching, relationship progression, appearance-gating
- Journal: auto-records 11 categories; completion influences endings
- Quest: Main/Side/Hidden/Npc/Journal/Exploration (6 kinds)
- Mini-games: 8 kinds with REAL scoring (Rhythm, Dance, Negotiation, HistoryPuzzle, Observation, PatternMatching, HiddenObject, CultureActivity) — not quizzes
- Ending: multi-factor (choices, relationships, journal, knowledge, skills, secrets, quests, exploration) — 5 endings
- UI: QuestTracker, Dialogue, Journal, Inventory, Settings, Pause, Map, AreaProgress, SkillProgress, EndingSummary, Achievement notifications
- Core loop: receive → explore → observe → talk → learn → interact → mini-game → solve → unlock story → journal → knowledge → reward → unlock area → continue
- Levels L1–L5 expanded faithfully from the GDD PDFs

## Known limitation (honest)
- Verified headlessly (no Roblox Studio on this box). Code parses, lints, formats,
  packages, and its logic executes. Visual/gameplay feel must be confirmed in Studio.
- `luau-lsp` full type-check not run (binary limitation); layer 1+2 cover syntax/globals.
- No audio/image assets committed (IDs are placeholders in Data for PG/SE teams).
