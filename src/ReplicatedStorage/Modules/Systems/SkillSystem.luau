--! SkillSystem.luau
--! Player skill progression + threshold-gated unlocks (binding requirement).
--! Public API:
--!   SkillSystem.Init(save: SaveData)
--!   SkillSystem.AddXP(skill: SkillId, amount: number)
--!   SkillSystem.GetValue(skill: SkillId): number
--!   SkillSystem.GetLevel(skill: SkillId): number   (0..3 tier)
--!   SkillSystem.IsUnlocked(kind: UnlockKind, id: string): boolean
--!   SkillSystem.OnLevelUp: Signal(skill, level)
--!   SkillSystem.OnUnlock: Signal(kind, id)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type SkillSystemApi = {
	Init: (save: Types.SaveData) -> (),
	AddXP: (skill: Types.SkillId, amount: number) -> (),
	GetValue: (skill: Types.SkillId) -> number,
	GetLevel: (skill: Types.SkillId) -> number,
	IsUnlocked: (kind: Types.UnlockKind, id: string) -> boolean,
	OnLevelUp: Signal.Signal<Types.SkillId, number>,
	OnUnlock: Signal.Signal<Types.UnlockKind, string>,
}

local SkillSystem = {} :: SkillSystemApi
SkillSystem.OnLevelUp = Signal.new()
SkillSystem.OnUnlock = Signal.new()

local save: Types.SaveData? = nil

local function tier(value: number): number
	local C = Types.Constants
	if value >= C.SKILL_T3 then
		return 3
	elseif value >= C.SKILL_T2 then
		return 2
	elseif value >= C.SKILL_T1 then
		return 1
	end
	return 0
end

function SkillSystem.Init(s: Types.SaveData)
	save = s
end

function SkillSystem.AddXP(skill: Types.SkillId, amount: number)
	assert(save, "SkillSystem not initialized")
	local before = save.skills[skill] or 0
	local after = math.clamp(before + amount, 0, Types.Constants.SKILL_MAX)
	save.skills[skill] = after
	local bT, aT = tier(before), tier(after)
	if aT > bT then
		SkillSystem.OnLevelUp:Fire(skill, aT)
		SkillSystem._applyUnlocks(skill, aT)
	end
end

function SkillSystem.GetValue(skill: Types.SkillId): number
	assert(save, "SkillSystem not initialized")
	return save.skills[skill] or 0
end

function SkillSystem.GetLevel(skill: Types.SkillId): number
	return tier(SkillSystem.GetValue(skill))
end

function SkillSystem.IsUnlocked(kind: Types.UnlockKind, id: string): boolean
	assert(save, "SkillSystem not initialized")
	return save.unlocked[kind][id] == true
end

-- Internal: flip unlocks based on thresholds (TDD §6 mapping).
-- Independent `if` blocks so a single level-up can satisfy multiple gates.
function SkillSystem._applyUnlocks(skill: Types.SkillId, lvl: number)
	assert(save, "SkillSystem not initialized")
	local u = save.unlocked
	if skill == "Communication" and lvl >= 1 then
		u.dialogue["intro"] = true
		SkillSystem.OnUnlock:Fire("dialogue", "intro")
	end
	if skill == "CulturalUnderstanding" and lvl >= 1 then
		u.dialogue["culture"] = true
		SkillSystem.OnUnlock:Fire("dialogue", "culture")
	end
	if (skill == "Observation" or skill == "DecisionMaking") and lvl >= 2 then
		u.secrets["tier2"] = true
		SkillSystem.OnUnlock:Fire("secrets", "tier2")
	end
	if (skill == "DecisionMaking" or skill == "CulturalUnderstanding") and lvl >= 2 then
		u.quests["alt"] = true
		SkillSystem.OnUnlock:Fire("quests", "alt")
	end
	if skill == "DecisionMaking" and lvl >= 3 then
		u.npcs["hidden"] = true
		SkillSystem.OnUnlock:Fire("npcs", "hidden")
	end
end

return SkillSystem
