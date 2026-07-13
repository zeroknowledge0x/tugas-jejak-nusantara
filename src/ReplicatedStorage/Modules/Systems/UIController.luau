--! UIController.luau
--! Screen manager + transitions. Builds all 10+ UI screens into a PlayerGui and
--! wires them to system signals so HUD stays live.
--! Public API:
--!   UIController.Init(playerGui: PlayerGui)
--!   UIController.Open(screen: string)
--!   UIController.Close(screen: string)
--!   UIController.RefreshAll()
--!   UIController.ShowEnding(ending: Types.EndingId)

local Types = require(script.Parent.Types)
local UIBase = require(script.Parent.UI.UIBase)
local QuestTracker = require(script.Parent.UI.QuestTracker)
local DialogueUI = require(script.Parent.UI.DialogueUI)
local JournalUI = require(script.Parent.UI.JournalUI)
local InventoryUI = require(script.Parent.UI.InventoryUI)
local SettingsUI = require(script.Parent.UI.SettingsUI)
local PauseUI = require(script.Parent.UI.PauseUI)
local MapUI = require(script.Parent.UI.MapUI)
local AreaProgressUI = require(script.Parent.UI.AreaProgressUI)
local SkillProgressUI = require(script.Parent.UI.SkillProgressUI)
local EndingSummaryUI = require(script.Parent.UI.EndingSummaryUI)
local AchievementToast = require(script.Parent.UI.AchievementToast)

local QuestSystem = require(script.Parent.Systems.QuestSystem)
local DialogueSystem = require(script.Parent.Systems.DialogueSystem)
local JournalSystem = require(script.Parent.Systems.JournalSystem)
local InventorySystem = require(script.Parent.Systems.InventorySystem)
local AreaManager = require(script.Parent.Systems.AreaManager)
local SkillSystem = require(script.Parent.Systems.SkillSystem)
local AchievementSystem = require(script.Parent.Systems.AchievementSystem)

export type UIControllerApi = {
	Init: (pg: Instance) -> (),
	Open: (screen: string) -> (),
	Close: (screen: string) -> (),
	RefreshAll: () -> (),
	ShowEnding: (ending: Types.EndingId) -> (),
}

local UIController = {} :: UIControllerApi

local root: Instance? = nil
local screens: { [string]: Instance } = {}

local TOGGLABLE = {
	QuestTracker = true,
	DialogueUI = true,
	JournalUI = true,
	InventoryUI = true,
	SettingsUI = true,
	PauseUI = true,
	MapUI = true,
	AreaProgressUI = true,
	SkillProgressUI = true,
	EndingSummaryUI = true,
	AchievementToast = true,
}

function UIController.Init(pg: Instance)
	root = Instance.new("ScreenGui")
	root.Name = "JejakNusantaraUI"
	root.ResetOnSpawn = false
	root.Parent = pg

	screens.QuestTracker = QuestTracker.Build(root)
	screens.AreaProgressUI = AreaProgressUI.Build(root)
	screens.SkillProgressUI = SkillProgressUI.Build(root)
	screens.DialogueUI = DialogueUI.Build(root)
	screens.JournalUI = JournalUI.Build(root)
	screens.InventoryUI = InventoryUI.Build(root)
	screens.SettingsUI = SettingsUI.Build(root)
	screens.PauseUI = PauseUI.Build(root)
	screens.MapUI = MapUI.Build(root)
	screens.EndingSummaryUI = EndingSummaryUI.Build(root)
	screens.AchievementToast = AchievementToast.Build(root)

	-- Live refresh wiring
	local refresh = function()
		UIController.RefreshAll()
	end
	QuestSystem.OnComplete:Connect(refresh)
	JournalSystem.OnRecord:Connect(refresh)
	InventorySystem.OnAdd:Connect(refresh)
	AreaManager.OnUnlocked:Connect(refresh)
	SkillSystem.OnUnlock:Connect(refresh)
	DialogueSystem.OnNode:Connect(function(node)
		DialogueUI.Show(screens.DialogueUI, node)
	end)
	DialogueSystem.OnEnd:Connect(function()
		screens.DialogueUI.Visible = false
	end)
	AchievementSystem.OnUnlock:Connect(function(id)
		AchievementToast.Pop(screens.AchievementToast, id)
	end)
end

function UIController.Open(screen: string)
	if TOGGLABLE[screen] and screens[screen] ~= nil then
		screens[screen].Visible = true
		UIController.RefreshAll()
	end
end

function UIController.Close(screen: string)
	if screens[screen] ~= nil then
		screens[screen].Visible = false
	end
end

function UIController.RefreshAll()
	if screens.QuestTracker ~= nil then
		QuestTracker.Refresh(screens.QuestTracker)
	end
	if screens.JournalUI ~= nil then
		JournalUI.Refresh(screens.JournalUI)
	end
	if screens.InventoryUI ~= nil then
		InventoryUI.Refresh(screens.InventoryUI)
	end
	if screens.MapUI ~= nil then
		MapUI.Refresh(screens.MapUI)
	end
	if screens.AreaProgressUI ~= nil then
		AreaProgressUI.Refresh(screens.AreaProgressUI)
	end
	if screens.SkillProgressUI ~= nil then
		SkillProgressUI.Refresh(screens.SkillProgressUI)
	end
end

function UIController.ShowEnding(ending: Types.EndingId)
	EndingSummaryUI.Show(screens.EndingSummaryUI, ending)
end

return UIController
