# Jejak Nusantara — Technical Design Document (TDD)

> **Source of Truth:** The three GDD PDFs in `/docs` (`2023150018_20260420211840.pdf` = Narrative, `...20260504115155.pdf` = Mechanics & Loop, `...20260518221816.pdf` = Level Design) are the product specification. The expanded system requirements from the lead brief (progression, NPC system, journal, quests, mini-games, endings, UI, audio, code quality) are binding and *extend* the PDFs. **On any conflict between code and PDFs: the PDFs win.** This TDD is derived entirely from those documents and must remain faithful to every mechanic.

---

## 1. Purpose & Scope

Transform the repository into a complete, production-quality Roblox game: *Jejak Nusantara* — a narrative-adventure cultural-education game where the player is a university student on a cultural expedition through Indonesia (Central Java → West Java), learning culture through **gameplay** (mini-games + exploration), not quizzes.

Faithful to PDFs; improved in polish, immersion, replayability, and code quality. Not a prototype. Not a demo. Not a student assignment.

**Non-goals:** quizzes as primary mechanic (forbidden), empty maps, "talk → quiz → XP → next area" loop (forbidden).

---

## 2. Tech Stack & Build Pipeline

| Concern | Choice |
|---|---|
| Language | Luau (strict typing where feasible) |
| Module system | Reusable `ModuleScript`s, no giant scripts |
| Build tool | **Rojo** (`default.project.json` → `.rbxlx` place file) |
| Lint / format | `selene`, `stylua` |
| Type check | `luau analyze` with Roblox global type stubs (`tooling/roblox-types.d.luau`) |
| Data layer | Single content `Data` module (data-driven design) |
| Runtime target | Roblox client/server; single-player experience simulated via `Player` |

All game logic lives under `src/` and is mapped by `default.project.json` into the place's `ReplicatedStorage`, `ServerScriptService`, and `StarterPlayer`. `rojo build` yields a place file openable in Studio; `rojo serve` enables live sync during development.

---

## 3. Repository Layout (target — see Roadmap Phase 3)

```
tugas-jejak-nusantara/
  default.project.json
  selene.toml
  stylua.toml
  docs/                         # GDD PDFs (source of truth) + this TDD + Roadmap
  src/
    ReplicatedStorage/
      Modules/
        Types.luau              # canonical enums & records (single source of types)
        Data/                   # content (NPCs, dialogue, quests, areas, minigames, endings)
        Systems/                # 16 system modules (see §7)
        Util/                   # small shared helpers (Tween, Table, Signal, RNG)
    ServerScriptService/
      GameServer.luau           # bootstraps systems server-side
    StarterPlayer/StarterPlayerScripts/
      GameClient.luau           # bootstraps systems client-side + UI
  tooling/
    roblox-types.d.luau         # global type stubs for `luau analyze`
```

---

## 4. Canonical Type System (`Types.luau`)

Single source of truth for all shared types. Key enums/records (abridged):

```luau
export type SkillId = "Observation" | "Communication"
  | "ProblemSolving" | "DecisionMaking" | "CulturalUnderstanding"

export type AreaId = "RumahBudaya" | "DesaBudaya" | "SanggarSeni"
  | "PasarTradisional" | "TempatBersejarah" | "KebangkitanTradisi"

export type QuestKind = "Main" | "Side" | "Hidden" | "Npc" | "Journal" | "Exploration"

export type SaveData = {
  version: number,
  skills: { [SkillId]: number },            -- 0..100 progression
  unlocked: {
    dialogue: { [string]: boolean },
    secrets: { [string]: boolean },
    quests: { [string]: boolean },
    npcs: { [string]: boolean },
  },
  journal: JournalData,
  inventory: { [string]: number },
  quests: { active: {[string]: QuestState}, completed: {[string]: boolean} },
  areaProgress: { [AreaId]: AreaState },
  completedAreas: { [AreaId]: boolean },
  endingFlags: { [string]: boolean },
  achievements: { [string]: boolean },
  discovered: { locations: {[string]:boolean}, npcs:{[string]:boolean},
                food:{[string]:boolean}, music:{[string]:boolean}, dance:{[string]:boolean},
                artifacts:{[string]:boolean}, history:{[string]:boolean},
                secrets:{[string]:boolean} },
}

export type DialogueNode = {
  id: string, npc: string, text: string,
  speaker: "NPC" | "Player" | "Narration",
  choices: { text: string, next: string?, effect?: DialogueEffect }?,
  requires?: UnlockCond,            -- gated dialogue (Rule 3)
  onEnter?: string,                 -- hook id
}
```

(See file for full record definitions.)

---

## 5. Content Data Model (`Data` module)

All narrative content is **data**, not code:
- `Data.NPCs` — personality, daily schedule, relationship curve, quest links, teaching moments.
- `Data.Dialogue` — dialogue trees keyed by node id, with `requires` gating.
- `Data.Quests` — quest definitions per `QuestKind`.
- `Data.Areas` — 5 levels + Rumah Budaya hub, with spawn, interactables, secrets.
- `Data.MiniGames` — configs for each mini-game (rhythm tracks, dance sequences, negotiation profiles, history puzzles, hidden-object layouts).
- `Data.Endings` — scoring rules mapping player journey → ending.
- `Data.Achievements` — achievement defs.

Generic system modules read this data; designers edit `Data` without touching logic.

---

## 6. Player Skill & Progression System (binding requirement)

The 5 skills **must affect gameplay** and gate unlocks. Model: each skill is a 0–100 value in `SaveData.skills`. Gains come from the matching Player Action (PDF 2 §B/§E):

| Skill | Raised by | Gameplay effect (must be real) |
|---|---|---|
| **Observation** | Observe Environment, find symbols/objects | Reveals hidden interactables & secret symbols (L2/L4); wider detection radius; more journal detail; easier Hidden-Object mini-game |
| **Communication** | Dialogue Choice, NPC interaction | Better negotiation prices (L3); more dialogue options; faster relationship gain; NPCs reveal secrets sooner |
| **Problem Solving** | History puzzle, mini-games | Extra hints / lower penalty in puzzles; alternative solutions; looser timing tolerance |
| **Decision Making** | Story choices | Unlocks branching quests, **Hidden NPCs**, secret paths, **alternative endings** availability |
| **Cultural Understanding** | Learn Culture, mini-game success | Unlocks **secret dialogue**, **alternative quests**, journal depth, ending quality; gates certain NPCs |

**Unlock mapping (binding):** skill thresholds flip `SaveData.unlocked.*`:
- *Dialogue* → Communication ≥ T1 OR CulturalUnderstanding ≥ T1
- *Secrets* → Observation ≥ T2 OR DecisionMaking ≥ T2
- *Alternative quests* → DecisionMaking ≥ T2 OR CulturalUnderstanding ≥ T2
- *Hidden NPC* → DecisionMaking ≥ T3 (appears after prior objectives, PDF NPC rule)
- *Alternative endings* → DecisionMaking ≥ T3 + Journal completion ≥ X%

Thresholds (`SkillSystem`): T1=20, T2=45, T3=70. Tunable in `Data`.

---

## 7. Module Architecture & Public APIs

16 system modules (per brief). Each documents its public API. Responsibilities:

| Module | Responsibility | Key public API (abridged) |
|---|---|---|
| `GameManager` | Orchestrates game loop, phase state machine, area transitions | `Start()`, `AdvanceArea(area)`, `GetState()` |
| `SkillSystem` | Progression, thresholds, unlock flips | `AddXP(skill, n)`, `GetLevel(skill)`, `IsUnlocked(kind, id)` |
| `DialogueSystem` | Drives dialogue trees, gating, choices | `Start(nodeId, npc)`, `Choose(option)` |
| `QuestSystem` | 6 quest kinds, tracking, rewards | `Accept(id)`, `Update(id, ...)`, `Complete(id)` |
| `NPCSystem` | NPC lifecycle: personality, memory, daily behavior, relationships, teaching | `Spawn(id)`, `GetMemory(npc)`, `SetRelationship(npc, delta)`, `DailyTick()` |
| `MiniGameSystem` | Mini-game framework + catalog | `Launch(kind, cfg)`, `Submit(result)`, `OnComplete(cb)` |
| `JournalSystem` | Auto-records all categories; computes completion % | `Record(category, key)`, `GetCompletion()` |
| `InventorySystem` | Cultural items, foods, artifacts | `Add(item, n)`, `Has(item)` |
| `InteractionSystem` | Proximity prompts, cultural/env object activation | `Register(obj)`, `Prompt(player, obj)` |
| `SaveSystem` | DataStore-backed save + local fallback; versioned migrate | `Load(player)`, `Save(player)`, `Reset(player)` |
| `AreaManager` | Loads/unloads area content, world living-state | `Load(area)`, `Unload(area)`, `IsUnlocked(area)` |
| `UIController` | All screens, transitions, HUD; client | `Open(screen)`, `Close(screen)`, `BindHud(...)` |
| `AudioManager` | Ambient/music/SFX/runtime feedback | `PlayBgm(area)`, `Sfx(name)`, `SetAmbient(area)` |
| `NotificationSystem` | Toasts, achievement popups | `Toast(msg)`, `Achievement(id)` |
| `AchievementSystem` | Evaluates achievement defs | `Check(id)`, `Unlock(id)` |
| `EndingSystem` | Multi-factor scoring → ending | `Evaluate(save)`, `Play(endingId)` |

All modules expose a typed `table` returned from `require()`. No module exceeds ~400 lines; shared helpers live in `Util/`.

---

## 8. NPC System (NPCs must feel alive — never quiz terminals)

Every NPC record (PDF + brief) carries:
- `personality` (tone, vocabulary), `dialogueTrees` (branching, `requires` gating per Rule 3),
- `memory` (remembers player choices/actions across sessions via SaveData),
- `questLogic` (offers/updates/completes quests), `reactions` (responds to skill/relationship state),
- `dailyBehavior` (schedule table → position/activity by in-game time; `NPCSystem.DailyTick`),
- `teachingMoments` (scripted culture lessons tied to mini-games),
- `relationship` (0–100, raised by Communication/specific choices; gates secrets & hidden dialogue),
- `appearanceGate` (some NPCs only spawn after prior objectives completed — e.g., L3 old merchant, L5 revived villagers).

`NPCSystem` is data-driven from `Data.NPCs`. NPCs are never quiz terminals: dialogue is branching narrative + contextual reactions, and culture is *taught through* the mini-games they hand you.

---

## 9. Journal System

`JournalSystem.Record(category, key)` auto-logs (player never manually types):
`locations, npcs, food, music, dance, artifacts, history, discoveries, secrets, puzzleProgress, completedQuests`.
`GetCompletion()` returns 0–100% used by EndingSystem and the Skill *Dialogue/Secrets* gating. Journal UI is a full screen (§13).

---

## 10. Quest System

Six kinds (brief): `Main, Side, Hidden, Npc, Journal, Exploration`.
- **Main** = level objective (complete cultural activity to advance — Rule 1).
- **Side** = optional NPC favors. **Hidden** = secret-gated. **Npc** = relationship-driven.
- **Journal** = "document X categories" quests. **Exploration** = "find/interact with Y" quests.
Quest completion is the gating signal for area unlock (Rule 1) and feeds rewards/knowledge.

---

## 11. Mini-Game Framework & Catalog

`MiniGameSystem` provides a common lifecycle: `Launch(kind, cfg) → play → Submit(result) → OnComplete(cb)`. Results feed SkillSystem XP, QuestSystem, JournalSystem, and rewards.

Catalog (brief + PDFs):
1. **Rhythm (Angklung, L1)** — follow note sequence; wrong note → repeat (L1 obstacle).
2. **Dance (L2)** — follow movement pattern via rhythm; mismatched → lower performance score (L2 obstacle).
3. **Negotiation (L3)** — price haggling; wrong dialogue → price rises (L3 obstacle); Communication skill improves offers.
4. **History Puzzle (L4)** — arrange history fragments; wrong → fewer clues + time limit (L4 obstacle); Observation/ProblemSolving help.
5. **Observation** — spot symbols/objects in environment (cross-level, gates secrets).
6. **Pattern Matching** — sequence replication (supports dance/rhythm tuning).
7. **Hidden Object** — find items in scene (rewards exploration).
8. **Interactive Culture Activity** — e.g., play angklung ensemble, cook dish (combines learned skills in L5).

Mini-games are the **primary** gameplay; quizzes are optional knowledge checks only.

---

## 12. Ending System

Ending determined by **multi-factor** scoring (not XP alone — brief):
`player choices + relationships + journal completion + knowledge (CulturalUnderstanding) + skill progression + secrets found + quest completion + exploration`.
Maps to the PDF's three endings (Success / Adequate / Explorative) plus **alternative endings** unlocked by Decision Making ≥ T3 + Journal completion. `EndingSystem.Evaluate(save)` computes the ending; `Play()` shows the Ending Summary screen.

---

## 13. UI / UX

Modern Roblox UI (brief): Quest Tracker, Dialogue UI, Journal, Inventory, Settings, Pause, Map, Area Progress, Skill Progress, Ending Summary, Achievement Notifications. Smooth transitions + professional animations (TweenService-based, no jank). HUD driven by `UIController`; all screens data-bound to systems.

---

## 14. Audio

`AudioManager`: per-area ambient loops, area-specific BGM, NPC voice/SFX cues, interaction SFX, mini-game feedback, reward jingles. Content referenced from `Data`/assets; graceful no-op if assets absent (so headless build still runs).

---

## 15. Save System

`SaveSystem` uses `DataStoreService` (keyed by `userId`) with a **local fallback** (`DataStore` simulator / `DataStore2`-style pcall wrap) so the game is playable in Studio without live DS. Versioned schema (`SaveData.version`) with migration. Checkpoint rule (Rule 2): failing main mission returns player to last area checkpoint — handled by `GameManager` + `SaveSystem`.

---

## 16. Area / Level Mapping (faithful to PDF 3)

| Area | PDF | Mechanics | Mystery / Secret |
|---|---|---|---|
| Rumah Budaya (hub) | Narrative opening | Find old book → Nusantara map | — |
| L1 Desa Budaya (W Java) | §A | Angklung rhythm + interview dialogue | Observation reveals extra lore |
| L2 Sanggar Seni | §B | Dance rhythm (basic→complex) | **Secret practice room** → bonus dance-history dialogue |
| L3 Pasar Tradisional | §C | Negotiation + cuisine | **Old merchant** → rare-food secret + bonus story |
| L4 Tempat Bersejarah | §D | History puzzle + env observation | **Ancient hidden symbol** → bonus origin dialogue |
| L5 Kebangkitan Tradisi | §E | Combine all skills; revive traditions | Ending determined by journey |

Each level enforces the core loop (Task→Explore→Learn→Challenge→Knowledge→Advance) and contains story, exploration, NPC, mini-game, secrets, optional objectives, hidden dialogue, environmental storytelling, journal entries, rewards.

---

## 17. Game Loop Orchestration (`GameManager`)

State machine per area:
`ReceiveMission → Explore → Observe → Talk → Learn → Interact → MiniGame → Solve → UnlockStory → UpdateJournal → GainKnowledge → Reward → UnlockArea → Continue`.
`GameManager` coordinates systems; each transition is a method call, not hardcoded spaghetti. The brief's loop (Receive Mission → … → Continue Adventure) is the canonical sequence used in every level.

---

## 18. Conflict Resolution & Compliance Matrix

- Any code vs PDF conflict → PDF wins. This TDD documents the binding interpretation.
- Compliance checkpoints (each phase): confirm every PDF mechanic is present:
  - 5 RULES ✓, 5 Player Actions ✓, 4 Game Objects ✓, 5 Skills ✓, Core Loop ✓, 5 Levels + Climax ✓, 3 Endings (+alternatives) ✓, Mystery gates (L2/L3/L4) ✓, Dialogue samples reused ✓.

---

## 19. Verification Strategy

- `luau analyze src --defs=tooling/roblox-types.d.luau` → 0 errors (syntax + types).
- `selene check src` → 0 errors.
- `stylua --check src` → formatted.
- `rojo build` → produces `.rbxlx` (openable in Studio; proves place compiles).
- Manual smoke checklist (run in Studio): each level completable, skill unlocks fire, journal auto-records, endings vary by run.
- **Every commit leaves the project in a playable state** (builds + core loop runnable).

---

## 20. Performance & Code Quality Standards

- No script > ~400 lines; split into ModuleScripts. Document every public API.
- No magic numbers (constants in `Data`/`Types`). No duplicated code (shared `Util`).
- Professional Luau: typed function signatures, `!` non-nil asserts, `task.spawn`/`Heartbeat` discipline, `Connections` cleaned on unload.
- Object pooling for UI toasts/particles; throttle `DailyTick`; avoid per-frame allocations.

---
*This TDD is the architecture contract for Phases 2–7. It is derived solely from the GDD PDFs and the lead brief; the PDFs remain the ultimate authority.*
