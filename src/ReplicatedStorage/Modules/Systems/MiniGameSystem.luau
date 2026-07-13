--! MiniGameSystem.luau
--! Mini-game framework + catalog (primary gameplay, not quizzes).
--! Routes each kind to a dedicated sub-module with real scoring logic.
--! Public API:
--!   MiniGameSystem.Init(save: SaveData)
--!   MiniGameSystem.Launch(kind: MiniGameKind, cfg: table): string
--!   MiniGameSystem.Submit(instanceId: string, result: MiniGameResult)
--!   MiniGameSystem.Get(instanceId): table?
--!   MiniGameSystem.OnComplete: Signal(instanceId, MiniGameResult)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

local Rhythm = require(script.Parent.MiniGames.Rhythm)
local Dance = require(script.Parent.MiniGames.Dance)
local Negotiation = require(script.Parent.MiniGames.Negotiation)
local HistoryPuzzle = require(script.Parent.MiniGames.HistoryPuzzle)
local Observation = require(script.Parent.MiniGames.Observation)
local PatternMatching = require(script.Parent.MiniGames.PatternMatching)
local HiddenObject = require(script.Parent.MiniGames.HiddenObject)
local CultureActivity = require(script.Parent.MiniGames.CultureActivity)

export type MiniGameSystemApi = {
	Init: (save: Types.SaveData) -> (),
	Launch: (kind: Types.MiniGameKind, cfg: table) -> string,
	Submit: (instanceId: string, result: Types.MiniGameResult) -> (),
	Get: (instanceId: string) -> table?,
	OnComplete: Signal.Signal<string, Types.MiniGameResult>,
}

local MiniGameSystem = {} :: MiniGameSystemApi
MiniGameSystem.OnComplete = Signal.new()

local FACTORY: { [Types.MiniGameKind]: (cfg: table) -> table } = {
	Rhythm = Rhythm.Create,
	Dance = Dance.Create,
	Negotiation = Negotiation.Create,
	HistoryPuzzle = HistoryPuzzle.Create,
	Observation = Observation.Create,
	PatternMatching = PatternMatching.Create,
	HiddenObject = HiddenObject.Create,
	CultureActivity = CultureActivity.Create,
}

local save: Types.SaveData? = nil
local instances: { [string]: table } = {}
local counter = 0

function MiniGameSystem.Init(s: Types.SaveData)
	save = s
end

function MiniGameSystem.Launch(kind: Types.MiniGameKind, cfg: table): string
	local factory = FACTORY[kind]
	if factory == nil then
		error("Unknown mini-game kind: " .. tostring(kind))
	end
	counter += 1
	local id = kind .. "_" .. tostring(counter)
	instances[id] = factory(cfg or {})
	return id
end

function MiniGameSystem.Get(instanceId: string): table?
	return instances[instanceId]
end

function MiniGameSystem.Submit(instanceId: string, result: Types.MiniGameResult)
	local inst = instances[instanceId]
	if inst == nil then
		return
	end
	result.kind = inst.kind
	instances[instanceId] = nil
	MiniGameSystem.OnComplete:Fire(instanceId, result)
end

return MiniGameSystem
