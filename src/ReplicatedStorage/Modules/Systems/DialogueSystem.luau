--! DialogueSystem.luau
--! Drives branching dialogue trees with Rule-3 gating & choice effects.
--! NPCs never behave like quiz terminals: choices have real consequences.
--! Public API:
--!   DialogueSystem.Init(save: SaveData, data: table, effects: DialogueEffects?)
--!   DialogueSystem.Start(nodeId: string, npc: string)
--!   DialogueSystem.Choose(optionIndex: number)
--!   DialogueSystem.IsNodeAvailable(node): boolean
--!   DialogueSystem.OnNode: Signal(node, npc)
--!   DialogueSystem.OnEnd: Signal(npc)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type DialogueEffects = {
	ApplySkillGain: (skill: Types.SkillId, amount: number) -> (),
	ApplyUnlock: (kind: Types.UnlockKind, id: string) -> (),
	ApplyRelationship: (npc: string, delta: number) -> (),
	ApplyFlag: (key: string, value: boolean) -> (),
	ApplyJournal: (category: Types.JournalCategory, key: string) -> (),
	ApplyInventory: (item: string, count: number) -> (),
}

export type DialogueSystemApi = {
	Init: (save: Types.SaveData, data: { [string]: Types.DialogueNode }, effects: DialogueEffects?) -> (),
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
local fx: DialogueEffects? = nil
local current: Types.DialogueNode? = nil

function DialogueSystem.Init(s: Types.SaveData, d: { [string]: Types.DialogueNode }, effects: DialogueEffects?)
	save = s
	tree = d
	fx = effects
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
	-- apply effect (skill/unlock/relationship/flag/journal/inventory)
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

-- Effects are delegated to the injected handler so DialogueSystem stays decoupled
-- from other systems (no require cycles). Falls back to recording flags locally.
function DialogueSystem._apply(effect: Types.DialogueEffect)
	assert(save, "system not initialized")
	if effect.skill ~= nil then
		if fx ~= nil then
			fx.ApplySkillGain(effect.skill, effect.skillXp or 10)
		end
	end
	if effect.unlock ~= nil then
		if fx ~= nil then
			fx.ApplyUnlock(effect.unlock.kind, effect.unlock.id)
		else
			save.unlocked[effect.unlock.kind][effect.unlock.id] = true
		end
	end
	if effect.relationship ~= nil then
		if fx ~= nil then
			fx.ApplyRelationship(effect.relationship.npc, effect.relationship.delta)
		end
	end
	if effect.flag ~= nil then
		save.endingFlags[effect.flag.key] = effect.flag.value
		if fx ~= nil then
			fx.ApplyFlag(effect.flag.key, effect.flag.value)
		end
	end
	if effect.journal ~= nil then
		if fx ~= nil then
			fx.ApplyJournal(effect.journal.category, effect.journal.key)
		end
	end
	if effect.item ~= nil then
		if fx ~= nil then
			fx.ApplyInventory(effect.item, effect.itemCount or 1)
		end
	end
end

return DialogueSystem
