--! Types.luau
--! Canonical type system & shared constants for Jejak Nusantara.
--! Single source of truth for all enums/records. Every system module imports from here.
--! PDFs are the product spec; this file encodes the binding interpretation.

export type SkillId = "Observation" | "Communication" | "ProblemSolving" | "DecisionMaking" | "CulturalUnderstanding"

export type AreaId =
	"RumahBudaya"
	| "DesaBudaya"
	| "SanggarSeni"
	| "PasarTradisional"
	| "TempatBersejarah"
	| "KebangkitanTradisi"

export type QuestKind = "Main" | "Side" | "Hidden" | "Npc" | "Journal" | "Exploration"

export type MiniGameKind =
	"Rhythm"
	| "Dance"
	| "Negotiation"
	| "HistoryPuzzle"
	| "Observation"
	| "PatternMatching"
	| "HiddenObject"
	| "CultureActivity"

export type JournalCategory =
	"locations"
	| "npcs"
	| "food"
	| "music"
	| "dance"
	| "artifacts"
	| "history"
	| "discoveries"
	| "secrets"
	| "puzzleProgress"
	| "completedQuests"

export type UnlockKind = "dialogue" | "secrets" | "quests" | "npcs"

export type EndingId = "Success" | "Adequate" | "Explorative" | "Guardian" | "Lorekeeper"

export type SkillState = {
	value: number, -- 0..SKILL_MAX
	level: number, -- derived tier
}

export type UnlockState = {
	dialogue: { [string]: boolean },
	secrets: { [string]: boolean },
	quests: { [string]: boolean },
	npcs: { [string]: boolean },
}

export type DiscoveryState = {
	locations: { [string]: boolean },
	npcs: { [string]: boolean },
	food: { [string]: boolean },
	music: { [string]: boolean },
	dance: { [string]: boolean },
	artifacts: { [string]: boolean },
	history: { [string]: boolean },
	secrets: { [string]: boolean },
}

export type QuestState = {
	id: string,
	kind: QuestKind,
	active: boolean,
	completed: boolean,
	progress: number,
	goal: number,
}

export type AreaState = {
	id: AreaId,
	unlocked: boolean,
	entered: boolean,
	mainComplete: boolean,
	secretsFound: number,
	secretsTotal: number,
	optionalComplete: number,
	optionalTotal: number,
}

export type SaveData = {
	version: number,
	skills: { [SkillId]: number },
	unlocked: UnlockState,
	journal: {
		logged: { [JournalCategory]: { [string]: boolean } },
		completion: number, -- 0..100
	},
	inventory: { [string]: number },
	quests: { active: { [string]: QuestState }, completed: { [string]: boolean } },
	areaProgress: { [AreaId]: AreaState },
	completedAreas: { [AreaId]: boolean },
	endingFlags: { [string]: boolean },
	achievements: { [string]: boolean },
	discovered: DiscoveryState,
	relationships: { [string]: number }, -- npcId -> 0..100
	checkpoint: AreaId,
}

-- Dialogue
export type DialogueEffect = {
	skillGain: { skill: SkillId, amount: number }?,
	unlock: { kind: UnlockKind, id: string }?,
	relationship: { npc: string, delta: number }?,
	flag: { key: string, value: boolean }?,
	journal: { category: JournalCategory, key: string }?,
}

export type DialogueChoice = {
	text: string,
	next: string?,
	effect: DialogueEffect?,
}

export type DialogueNode = {
	id: string,
	npc: string,
	speaker: "NPC" | "Player" | "Narration",
	text: string,
	choices: { DialogueChoice }?,
	requires: { skill: SkillId, min: number }?,
	onEnter: string?,
}

-- NPC
export type NPCDailySlot = {
	from: number, -- hour 0..23
	to: number,
	position: Vector3,
	activity: string,
}

export type NPCData = {
	id: string,
	name: string,
	personality: string,
	homeArea: AreaId,
	relationshipStart: number,
	teaching: string?,
	quests: { string }?,
	reactions: { [string]: string }?, -- keyed by mood/state
	appearanceGate: { completedArea: AreaId }?, -- only appears after area done
	schedule: { NPCDailySlot }?,
}

-- Mini-game result
export type MiniGameResult = {
	kind: MiniGameKind,
	score: number, -- 0..100
	success: boolean,
	perfect: boolean,
	meta: { [string]: any }?,
}

-- Constants (no magic numbers elsewhere)
export type Constants = {
	SKILL_MAX: number,
	SKILL_T1: number,
	SKILL_T2: number,
	SKILL_T3: number,
	RELATIONSHIP_MAX: number,
}

local Constants: Constants = {
	SKILL_MAX = 100,
	SKILL_T1 = 20,
	SKILL_T2 = 45,
	SKILL_T3 = 70,
	RELATIONSHIP_MAX = 100,
}

local SkillOrder: { SkillId } = {
	"Observation",
	"Communication",
	"ProblemSolving",
	"DecisionMaking",
	"CulturalUnderstanding",
}

local AreaOrder: { AreaId } = {
	"RumahBudaya",
	"DesaBudaya",
	"SanggarSeni",
	"PasarTradisional",
	"TempatBersejarah",
	"KebangkitanTradisi",
}

return {
	Constants = Constants,
	SkillOrder = SkillOrder,
	AreaOrder = AreaOrder,
}
