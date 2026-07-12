--! NPCSystem.luau
--! NPC lifecycle: personality, memory, daily behavior, relationships, teaching,
--! appearance gating. NPCs never behave like quiz terminals.
--! Public API:
--!   NPCSystem.Init(save: SaveData, data: {[string]:Types.NPCData})
--!   NPCSystem.Spawn(id: string): boolean
--!   NPCSystem.GetMemory(npc: string): {[string]:any}
--!   SetRelationship(npc: string, delta: number)
--!   GetRelationship(npc: string): number
--!   DailyTick(hour: number)
--!   IsAvailable(npc: NPCData): boolean
--!   OnSpawn: Signal(id), OnRelationship: Signal(id, value)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type NPCSystemApi = {
	Init: (save: Types.SaveData, data: { [string]: Types.NPCData }) -> (),
	Spawn: (id: string) -> boolean,
	GetMemory: (npc: string) -> { [string]: any },
	SetRelationship: (npc: string, delta: number) -> (),
	GetRelationship: (npc: string) -> number,
	DailyTick: (hour: number) -> (),
	IsAvailable: (npc: Types.NPCData) -> boolean,
	OnSpawn: Signal.Signal<string>,
	OnRelationship: Signal.Signal<string, number>,
}

local NPCSystem = {} :: NPCSystemApi
NPCSystem.OnSpawn = Signal.new()
NPCSystem.OnRelationship = Signal.new()

local save: Types.SaveData? = nil
local data: { [string]: Types.NPCData }? = nil
local memory: { [string]: { [string]: any } } = {}

function NPCSystem.Init(s: Types.SaveData, d: { [string]: Types.NPCData })
	save = s
	data = d
end

function NPCSystem.IsAvailable(npc: Types.NPCData): boolean
	if npc.appearanceGate == nil then
		return true
	end
	assert(save, "NPCSystem not initialized")
	return save.completedAreas[npc.appearanceGate.completedArea] == true
end

function NPCSystem.Spawn(id: string): boolean
	assert(data, "NPCSystem not initialized")
	local npc = data[id]
	if npc == nil or not NPCSystem.IsAvailable(npc) then
		return false
	end
	assert(save, "NPCSystem not initialized")
	if save.relationships[id] == nil then
		save.relationships[id] = npc.relationshipStart
	end
	if memory[id] == nil then
		memory[id] = {}
	end
	NPCSystem.OnSpawn:Fire(id)
	return true
end

function NPCSystem.GetMemory(npc: string): { [string]: any }
	return memory[npc] or {}
end

function NPCSystem.SetRelationship(npc: string, delta: number)
	assert(save, "NPCSystem not initialized")
	local cur = save.relationships[npc] or 0
	save.relationships[npc] = math.clamp(cur + delta, 0, Types.Constants.RELATIONSHIP_MAX)
	NPCSystem.OnRelationship:Fire(npc, save.relationships[npc])
end

function NPCSystem.GetRelationship(npc: string): number
	assert(save, "NPCSystem not initialized")
	return save.relationships[npc] or 0
end

function NPCSystem.DailyTick(hour: number)
	assert(data, "NPCSystem not initialized")
	for id, npc in pairs(data) do
		if npc.schedule == nil then
			continue
		end
		for _, slot in ipairs(npc.schedule) do
			if hour >= slot.from and hour < slot.to then
				-- In a live build this moves the NPC model to slot.position.
				break
			end
		end
	end
end

return NPCSystem
