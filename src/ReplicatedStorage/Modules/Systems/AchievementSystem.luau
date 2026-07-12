--! AchievementSystem.luau
--! Evaluates achievement definitions against save state.
--! Public API:
--!   AchievementSystem.Init(save: SaveData, defs: {[string]:any})
--!   AchievementSystem.Check(id: string): boolean
--!   AchievementSystem.Unlock(id: string)
--!   AchievementSystem.IsUnlocked(id: string): boolean
--!   AchievementSystem.OnUnlock: Signal(id)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type AchievementSystemApi = {
	Init: (save: Types.SaveData, defs: { [string]: any }) -> (),
	Check: (id: string) -> boolean,
	Unlock: (id: string) -> (),
	IsUnlocked: (id: string) -> boolean,
	OnUnlock: Signal.Signal<string>,
}

local AchievementSystem = {} :: AchievementSystemApi
AchievementSystem.OnUnlock = Signal.new()

local save: Types.SaveData? = nil
local defs: { [string]: any }? = nil

function AchievementSystem.Init(s: Types.SaveData, d: { [string]: any })
	save = s
	defs = d
end

function AchievementSystem.IsUnlocked(id: string): boolean
	assert(save, "AchievementSystem not initialized")
	return save.achievements[id] == true
end

function AchievementSystem.Check(id: string): boolean
	assert(save, "AchievementSystem not initialized")
	assert(defs, "AchievementSystem not initialized")
	local def = defs[id]
	if def == nil or def.test == nil then
		return false
	end
	return def.test(save)
end

function AchievementSystem.Unlock(id: string)
	assert(save, "AchievementSystem not initialized")
	if save.achievements[id] then
		return
	end
	save.achievements[id] = true
	AchievementSystem.OnUnlock:Fire(id)
end

return AchievementSystem
