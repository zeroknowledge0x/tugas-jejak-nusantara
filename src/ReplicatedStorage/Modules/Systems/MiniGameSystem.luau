--! MiniGameSystem.luau
--! Mini-game framework + catalog (primary gameplay, not quizzes).
--! Public API:
--!   MiniGameSystem.Init(save: SaveData)
--!   MiniGameSystem.Launch(kind: MiniGameKind, cfg: table): string (instanceId)
--!   MiniGameSystem.Submit(instanceId: string, result: MiniGameResult)
--!   MiniGameSystem.Abort(instanceId: string)
--!   MiniGameSystem.OnComplete: Signal(instanceId, MiniGameResult)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type MiniGameApi = {
	Init: (save: Types.SaveData) -> (),
	Launch: (kind: Types.MiniGameKind, cfg: table) -> string,
	Submit: (instanceId: string, result: Types.MiniGameResult) -> (),
	Abort: (instanceId: string) -> (),
	OnComplete: Signal.Signal<string, Types.MiniGameResult>,
}

local MiniGameSystem = {} :: MiniGameApi
MiniGameSystem.OnComplete = Signal.new()

local save: Types.SaveData? = nil
local active: { [string]: { kind: Types.MiniGameKind, cfg: table } } = {}
local nextId = 0

function MiniGameSystem.Init(s: Types.SaveData)
	save = s
end

function MiniGameSystem.Launch(kind: Types.MiniGameKind, cfg: table): string
	nextId += 1
	local id = "mg_" .. tostring(nextId)
	active[id] = { kind = kind, cfg = cfg }
	return id
end

function MiniGameSystem.Submit(instanceId: string, result: Types.MiniGameResult)
	local inst = active[instanceId]
	if inst == nil then
		return
	end
	active[instanceId] = nil
	MiniGameSystem.OnComplete:Fire(instanceId, result)
end

function MiniGameSystem.Abort(instanceId: string)
	active[instanceId] = nil
end

return MiniGameSystem
