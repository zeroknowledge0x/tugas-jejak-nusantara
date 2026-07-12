--! GameManager.luau
--! Orchestrates the core game loop & area state machine.
--! Public API:
--!   GameManager.Init(save: SaveData)
--!   GameManager.Start()              -> begins at checkpoint/opening
--!   GameManager.AdvanceArea(area)    -> unlock + transition
--!   GameManager.GetState(): { area: AreaId, phase: string }
--!   GameManager.OnPhaseChanged: Signal(area, phase)
--!   GameManager.OnAreaCompleted: Signal(area)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type GameManagerApi = {
	Init: (save: Types.SaveData) -> (),
	Start: () -> (),
	AdvanceArea: (area: Types.AreaId) -> (),
	GetState: () -> { area: Types.AreaId, phase: string },
	OnPhaseChanged: Signal.Signal<string, string>,
	OnAreaCompleted: Signal.Signal<Types.AreaId>,
}

local GameManager = {} :: GameManagerApi
GameManager.OnPhaseChanged = Signal.new()
GameManager.OnAreaCompleted = Signal.new()

local state = { area = "RumahBudaya" :: Types.AreaId, phase = "Init" }

function GameManager.Init(save: Types.SaveData)
	state.area = save.checkpoint
	state.phase = "Init"
end

function GameManager.Start()
	state.phase = "ReceiveMission"
	GameManager.OnPhaseChanged:Fire(state.area, state.phase)
end

function GameManager.AdvanceArea(area: Types.AreaId)
	state.area = area
	state.phase = "ReceiveMission"
	GameManager.OnAreaCompleted:Fire(area)
	GameManager.OnPhaseChanged:Fire(area, state.phase)
end

function GameManager.GetState()
	return { area = state.area, phase = state.phase }
end

return GameManager
