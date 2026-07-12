--! QuestSystem.luau
--! Tracks the 6 quest kinds, progress, rewards, area gating (Rule 1/5).
--! Public API:
--!   QuestSystem.Init(save: SaveData, data: table)
--!   QuestSystem.Accept(id: string)
--!   QuestSystem.Update(id: string, amount: number)
--!   QuestSystem.Complete(id: string)
--!   QuestSystem.IsComplete(id: string): boolean
--!   QuestSystem.GetActive(kind: QuestKind?): {Types.QuestState}
--!   QuestSystem.OnComplete: Signal(id, QuestKind)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type QuestSystemApi = {
	Init: (save: Types.SaveData, data: { [string]: any }) -> (),
	Accept: (id: string) -> (),
	Update: (id: string, amount: number) -> (),
	Complete: (id: string) -> (),
	IsComplete: (id: string) -> boolean,
	GetActive: (kind: Types.QuestKind?) -> { Types.QuestState },
	OnComplete: Signal.Signal<string, Types.QuestKind>,
}

local QuestSystem = {} :: QuestSystemApi
QuestSystem.OnComplete = Signal.new()

local save: Types.SaveData? = nil
local defs: { [string]: any }? = nil

function QuestSystem.Init(s: Types.SaveData, d: { [string]: any })
	save = s
	defs = d
end

function QuestSystem.Accept(id: string)
	assert(save, "QuestSystem not initialized")
	local def = defs[id]
	if def == nil then
		return
	end
	save.quests.active[id] = {
		id = id,
		kind = def.kind,
		active = true,
		completed = false,
		progress = 0,
		goal = def.goal or 1,
	}
end

function QuestSystem.Update(id: string, amount: number)
	assert(save, "QuestSystem not initialized")
	local q = save.quests.active[id]
	if q == nil or q.completed then
		return
	end
	q.progress = math.min(q.goal, q.progress + amount)
	if q.progress >= q.goal then
		QuestSystem.Complete(id)
	end
end

function QuestSystem.Complete(id: string)
	assert(save, "QuestSystem not initialized")
	local q = save.quests.active[id]
	if q == nil then
		return
	end
	q.completed = true
	q.active = false
	save.quests.completed[id] = true
	save.quests.active[id] = nil
	QuestSystem.OnComplete:Fire(id, q.kind)
end

function QuestSystem.IsComplete(id: string): boolean
	assert(save, "QuestSystem not initialized")
	return save.quests.completed[id] == true
end

function QuestSystem.GetActive(kind: Types.QuestKind?): { Types.QuestState }
	assert(save, "QuestSystem not initialized")
	local out = {}
	for _, q in pairs(save.quests.active) do
		if kind == nil or q.kind == kind then
			table.insert(out, q)
		end
	end
	return out
end

return QuestSystem
