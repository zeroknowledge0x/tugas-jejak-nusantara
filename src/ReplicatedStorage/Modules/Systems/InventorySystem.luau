--! InventorySystem.luau
--! Cultural items, foods, artifacts the player collects (rewards/exploration).
--! Public API:
--!   InventorySystem.Init(save: SaveData)
--!   InventorySystem.Add(item: string, count: number?)
--!   InventorySystem.Remove(item: string, count: number?): boolean
--!   InventorySystem.Has(item: string, count: number?): boolean
--!   InventorySystem.Count(item: string): number
--!   InventorySystem.OnAdd: Signal(item, count)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type InventorySystemApi = {
	Init: (save: Types.SaveData) -> (),
	Add: (item: string, count: number?) -> (),
	Remove: (item: string, count: number?) -> boolean,
	Has: (item: string, count: number?) -> boolean,
	Count: (item: string) -> number,
	OnAdd: Signal.Signal<string, number>,
}

local InventorySystem = {} :: InventorySystemApi
InventorySystem.OnAdd = Signal.new()

local save: Types.SaveData? = nil

function InventorySystem.Init(s: Types.SaveData)
	save = s
end

function InventorySystem.Add(item: string, count: number?)
	assert(save, "InventorySystem not initialized")
	local n = count or 1
	save.inventory[item] = (save.inventory[item] or 0) + n
	InventorySystem.OnAdd:Fire(item, n)
end

function InventorySystem.Remove(item: string, count: number?): boolean
	assert(save, "InventorySystem not initialized")
	local n = count or 1
	local cur = save.inventory[item] or 0
	if cur < n then
		return false
	end
	save.inventory[item] = cur - n
	return true
end

function InventorySystem.Has(item: string, count: number?): boolean
	return InventorySystem.Count(item) >= (count or 1)
end

function InventorySystem.Count(item: string): number
	assert(save, "InventorySystem not initialized")
	return save.inventory[item] or 0
end

return InventorySystem
