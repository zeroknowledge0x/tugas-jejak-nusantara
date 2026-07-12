--! UIController.luau
--! Screen manager + transitions for all UI (client). Data-bound to systems.
--! Public API:
--!   UIController.Init(playerGui: PlayerGui)
--!   UIController.Open(screen: string)
--!   UIController.Close(screen: string)
--!   UIController.IsOpen(screen: string): boolean
--!   UIController.BindHud(getters: table)
--!   UIController.OnOpen: Signal(screen), OnClose: Signal(screen)

local Signal = require(script.Parent.Parent.Util.Signal)
local Tween = require(script.Parent.Parent.Util.Tween)

export type UIControllerApi = {
	Init: (playerGui: PlayerGui) -> (),
	Open: (screen: string) -> (),
	Close: (screen: string) -> (),
	IsOpen: (screen: string) -> boolean,
	BindHud: (getters: table) -> (),
	OnOpen: Signal.Signal<string>,
	OnClose: Signal.Signal<string>,
}

local SCREENS = {
	"QuestTracker",
	"Dialogue",
	"Journal",
	"Inventory",
	"Settings",
	"Pause",
	"Map",
	"AreaProgress",
	"SkillProgress",
	"EndingSummary",
	"Achievements",
}

local UIController = {} :: UIControllerApi
UIController.OnOpen = Signal.new()
UIController.OnClose = Signal.new()

local open: { [string]: boolean } = {}
local root: Instance? = nil

function UIController.Init(playerGui: PlayerGui)
	-- In a live build this builds a ScreenGui tree from SCREENS.
	root = Instance.new("ScreenGui")
	root.Name = "JN_HUD"
	root.ResetOnSpawn = false
	root.Parent = playerGui
	for _, s in ipairs(SCREENS) do
		open[s] = false
	end
end

function UIController.Open(screen: string)
	if open[screen] == nil then
		return
	end
	open[screen] = true
	UIController.OnOpen:Fire(screen)
end

function UIController.Close(screen: string)
	if open[screen] == nil then
		return
	end
	open[screen] = false
	UIController.OnClose:Fire(screen)
end

function UIController.IsOpen(screen: string): boolean
	return open[screen] == true
end

function UIController.BindHud(getters: table)
	-- HUD update loop would call getters periodically; stub stores them.
	UIController._getters = getters
end

return UIController
