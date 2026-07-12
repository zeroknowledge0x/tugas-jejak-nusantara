--! InteractionSystem.luau
--! Proximity prompts & activation of cultural/environmental objects.
--! Public API:
--!   InteractionSystem.Init(save: SaveData)
--!   InteractionSystem.Register(object: {id:string, prompt:string, onInteract:()->()})
--!   InteractionSystem.Prompt(player: Player, objectId: string)
--!   InteractionSystem.Unregister(objectId: string)
--!   InteractionSystem.OnInteract: Signal(objectId, player)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type Interactable = {
	id: string,
	prompt: string,
	onInteract: ((player: Player) -> ())?,
	hiddenUntilSkill: Types.SkillId?,
	hiddenThreshold: number?,
}

export type InteractionSystemApi = {
	Init: (save: Types.SaveData) -> (),
	Register: (object: Interactable) -> (),
	Prompt: (player: Player, objectId: string) -> (),
	Unregister: (objectId: string) -> (),
	OnInteract: Signal.Signal<string, Player>,
}

local InteractionSystem = {} :: InteractionSystemApi
InteractionSystem.OnInteract = Signal.new()

local save: Types.SaveData? = nil
local registry: { [string]: Interactable } = {}

function InteractionSystem.Init(s: Types.SaveData)
	save = s
end

function InteractionSystem.Register(object: Interactable)
	registry[object.id] = object
end

function InteractionSystem.Prompt(player: Player, objectId: string)
	local obj = registry[objectId]
	if obj == nil then
		return
	end
	if obj.hiddenUntilSkill ~= nil then
		assert(save, "InteractionSystem not initialized")
		local v = save.skills[obj.hiddenUntilSkill] or 0
		if v < (obj.hiddenThreshold or Types.Constants.SKILL_T2) then
			return -- hidden until skill threshold met (Observation reveals secrets)
		end
	end
	if obj.onInteract ~= nil then
		(obj.onInteract)(player)
	end
	InteractionSystem.OnInteract:Fire(objectId, player)
end

function InteractionSystem.Unregister(objectId: string)
	registry[objectId] = nil
end

return InteractionSystem
