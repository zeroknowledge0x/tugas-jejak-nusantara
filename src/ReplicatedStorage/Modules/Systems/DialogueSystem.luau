--! DialogueSystem.luau
--! Drives branching dialogue trees with Rule-3 gating & choice effects.
--! Public API:
--!   DialogueSystem.Init(save: SaveData, data: table)
--!   DialogueSystem.Start(nodeId: string, npc: string)
--!   DialogueSystem.Choose(optionIndex: number)
--!   DialogueSystem.IsNodeAvailable(node): boolean
--!   DialogueSystem.OnNode: Signal(node, npc)
--!   DialogueSystem.OnEnd: Signal(npc)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type DialogueSystemApi = {
	Init: (save: Types.SaveData, data: { [string]: Types.DialogueNode }) -> (),
	Start: (nodeId: string, npc: string) -> (),
	Choose: (optionIndex: number) -> (),
	IsNodeAvailable: (node: Types.DialogueNode) -> boolean,
	OnNode: Signal.Signal<Types.DialogueNode, string>,
	OnEnd: Signal.Signal<string>,
}

local DialogueSystem = {} :: DialogueSystemApi
DialogueSystem.OnNode = Signal.new()
DialogueSystem.OnEnd = Signal.new()

local save: Types.SaveData? = nil
local tree: { [string]: Types.DialogueNode }? = nil
local current: Types.DialogueNode? = nil

function DialogueSystem.Init(s: Types.SaveData, d: { [string]: Types.DialogueNode })
	save = s
	tree = d
end

function DialogueSystem.IsNodeAvailable(node: Types.DialogueNode): boolean
	if node.requires == nil then
		return true
	end
	local req = node.requires
	assert(save, "DialogueSystem not initialized")
	return (save.skills[req.skill] or 0) >= req.min
end

function DialogueSystem.Start(nodeId: string, npc: string)
	assert(tree, "DialogueSystem not initialized")
	local node = tree[nodeId]
	if node == nil then
		return
	end
	current = node
	DialogueSystem.OnNode:Fire(node, npc)
end

function DialogueSystem.Choose(optionIndex: number)
	assert(current, "No active dialogue")
	local node = current
	local choices = node.choices
	if choices == nil then
		DialogueSystem.OnEnd:Fire(node.npc)
		current = nil
		return
	end
	local choice = choices[optionIndex]
	if choice == nil then
		return
	end
	-- apply effect (skill/unlock/relationship/flag/journal)
	if choice.effect ~= nil then
		DialogueSystem._apply(choice.effect)
	end
	if choice.next ~= nil then
		DialogueSystem.Start(choice.next, node.npc)
	else
		DialogueSystem.OnEnd:Fire(node.npc)
		current = nil
	end
end

function DialogueSystem._apply(effect: Types.DialogueEffect)
	assert(save, "system not initialized")
	-- Effects wired to other systems in Phase 5; stub records flags here.
	if effect.flag ~= nil and save ~= nil then
		save.endingFlags[effect.flag.key] = effect.flag.value
	end
end

return DialogueSystem
