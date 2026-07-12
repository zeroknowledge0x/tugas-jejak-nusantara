# Jejak Nusantara — Implementation Roadmap

> Companion to `TECHNICAL_DESIGN.md`. Each phase ends in a commit that leaves the project **playable** (builds via `rojo build`, core loop runnable). Per the lead brief's development process.

## Phase 1 — Analyze & Design ✅ (this commit)
- [x] Clone repo, inspect structure (only `/docs` PDFs exist; no code yet).
- [x] Extract & read all 3 GDD PDFs; cross-reference.
- [x] Write `TECHNICAL_DESIGN.md` (TDD): architecture, types, systems, compliance matrix.
- [x] Write this roadmap.
- [x] **Commit 1**: `docs/` GDD + TDD + roadmap.

## Phase 2 — Architecture & Tooling  (commit 2)
- [ ] `default.project.json` (Rojo place mapping).
- [ ] `selene.toml`, `stylua.toml`.
- [ ] `tooling/roblox-types.d.luau` (global stubs: `game`, `Players`, `TweenService`, `DataStoreService`, `task`, `Enum`, `Instance` types, etc.) for `luau analyze`.
- [ ] `src/ReplicatedStorage/Modules/Types.luau` — canonical enums/records.
- [ ] `src/ReplicatedStorage/Modules/Util/` — Tween, Table, Signal, RNG helpers.
- [ ] Verify `luau analyze` runs clean on stubs.
- [ ] **Commit 2**: build pipeline + type foundation. Project builds via `rojo build`.

## Phase 3 — Project Structure  (commit 3)
- [ ] Create all 16 system module skeletons under `src/.../Systems/` (public API typed, stubs returning sane defaults).
- [ ] `GameServer.luau` + `GameClient.luau` bootstrap (require systems, init order).
- [ ] `Data/` content module placeholders (NPCs, Dialogue, Quests, Areas, MiniGames, Endings, Achievements).
- [ ] **Commit 3**: empty-but-wired skeleton that runs (no-op loop) and builds.

## Phase 4 — Framework  (commit 4)
- [ ] `SaveSystem` (DataStore + local fallback, versioned migrate).
- [ ] `GameManager` state machine (area loop orchestration).
- [ ] `SkillSystem` (progression + thresholds + unlock flips).
- [ ] `InteractionSystem` (proximity prompts, object registry).
- [ ] `NotificationSystem` + `AchievementSystem` (basic).
- [ ] `UIController` base (screen manager + transition util).
- [ ] **Commit 4**: framework runnable — can load an area, gain skill XP, see unlocks fire (console-verified).

## Phase 5 — Systems  (commit 5)
- [ ] `DialogueSystem` (trees, Rule-3 gating, choices → effects).
- [ ] `NPCSystem` (personality, memory, daily behavior, relationships, teaching, appearance gates).
- [ ] `QuestSystem` (6 kinds, tracking, rewards).
- [ ] `JournalSystem` (auto-record all categories, completion %).
- [ ] `MiniGameSystem` + catalog (Rhythm, Dance, Negotiation, History Puzzle, Observation, Pattern Matching, Hidden Object, Culture Activity).
- [ ] `InventorySystem`, `AreaManager`, `AudioManager`, `EndingSystem`.
- [ ] **Commit 5**: all systems implemented & unit-smoke-tested (console-level).

## Phase 6 — Levels  (commit 6)
- [ ] Author `Data` content: 5 levels + Rumah Budaya hub (NPCs, dialogue, quests, interactables, secrets, mini-game configs).
- [ ] Wire each level to the core loop; enforce Rule 1/2/3/4/5.
- [ ] Place lightweight geometry/parts (proximity triggers, interactables) — functional, not final art.
- [ ] **Commit 6**: all 5 levels completable start→ending; build green.

## Phase 7 — Polish  (commit 7)
- [ ] Full UI screens (Quest Tracker, Dialogue, Journal, Inventory, Settings, Pause, Map, Area/Skill Progress, Ending Summary, Achievements) with animations.
- [ ] Audio integration (ambient/BGM/SFX hooks).
- [ ] Balancing: skill thresholds, ending scoring, reward tuning.
- [ ] Performance pass (pooling, throttle), code-quality lint (`selene`, `stylua`), final `luau analyze` clean.
- [ ] **Commit 7**: production-quality, polished, build green.

## Playability Gate (every commit)
A commit is only made if: `luau analyze src --defs=tooling/roblox-types.d.luau` passes, `selene check` passes, `stylua --check` passes, and `rojo build` produces a `.rbxlx`. Core loop must be runnable (at minimum console-verifiable) after each commit.
