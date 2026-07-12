--! AreaManager.luau
--! Loads/unloads area content; tracks world living-state & unlocks.
--! Public API:
--!   AreaManager.Init(save: SaveData, data: {[any]:any})
--!   AreaManager.Load(area: AreaId)
--!   AreaManager.Unload(area: AreaId)
--!   AreaManager.IsUnlocked(area: AreaId): boolean
--!   AreaManager.Unlock(area: AreaId)
--!   AreaManager.GetState(area: AreaId): AreaState?
--!   AreaManager.OnLoaded: Signal(area), OnUnlocked: Signal(area)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type AreaManagerApi = {
	Init: (save: Types.SaveData, data: { [any]: any }) -> (),
	Load: (area: Types.AreaId) -> (),
	Unload: (area: Types.AreaId) -> (),
	IsUnlocked: (area: Types.AreaId) -> boolean,
	Unlock: (area: Types.AreaId) -> (),
	GetState: (area: Types.AreaId) -> Types.AreaState?,
	OnLoaded: Signal.Signal<Types.AreaId>,
	OnUnlocked: Signal.Signal<Types.AreaId>,
}

local AreaManager = {} :: AreaManagerApi
AreaManager.OnLoaded = Signal.new()
AreaManager.OnUnlocked = Signal.new()

local save: Types.SaveData? = nil
local defs: { [any]: any }? = nil
local loaded: { [Types.AreaId]: boolean } = {}

function AreaManager.Init(s: Types.SaveData, d: { [any]: any })
	save = s
	defs = d
end

function AreaManager.IsUnlocked(area: Types.AreaId): boolean
	assert(save, "AreaManager not initialized")
	if save.areaProgress[area] == nil then
		return area == "RumahBudaya"
	end
	return save.areaProgress[area].unlocked
end

function AreaManager.Unlock(area: Types.AreaId)
	assert(save, "AreaManager not initialized")
	if save.areaProgress[area] == nil then
		save.areaProgress[area] = {
			id = area,
			unlocked = false,
			entered = false,
			mainComplete = false,
			secretsFound = 0,
			secretsTotal = 0,
			optionalComplete = 0,
			optionalTotal = 0,
		}
	end
	save.areaProgress[area].unlocked = true
	AreaManager.OnUnlocked:Fire(area)
end

function AreaManager.Load(area: Types.AreaId)
	assert(save, "AreaManager not initialized")
	if not AreaManager.IsUnlocked(area) then
		return
	end
	loaded[area] = true
	if save.areaProgress[area] ~= nil then
		save.areaProgress[area].entered = true
	end
	AreaManager.OnLoaded:Fire(area)
end

function AreaManager.Unload(area: Types.AreaId)
	loaded[area] = false
end

function AreaManager.GetState(area: Types.AreaId): Types.AreaState?
	assert(save, "AreaManager not initialized")
	return save.areaProgress[area]
end

return AreaManager
