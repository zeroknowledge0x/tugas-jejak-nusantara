--! GameServer.luau (ServerScriptService)
--! Server bootstrap: loads save, inits all systems, runs core loop.
--! Entry point on the server.

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = Replicated:WaitForChild("JN"):WaitForChild("Modules")
local Systems = Modules:WaitForChild("Systems")
local Data = require(Modules:WaitForChild("Data"):WaitForChild("Data"))

local SaveSystem = require(Systems:WaitForChild("SaveSystem"))
local SkillSystem = require(Systems:WaitForChild("SkillSystem"))
local DialogueSystem = require(Systems:WaitForChild("DialogueSystem"))
local QuestSystem = require(Systems:WaitForChild("QuestSystem"))
local NPCSystem = require(Systems:WaitForChild("NPCSystem"))
local MiniGameSystem = require(Systems:WaitForChild("MiniGameSystem"))
local JournalSystem = require(Systems:WaitForChild("JournalSystem"))
local InventorySystem = require(Systems:WaitForChild("InventorySystem"))
local InteractionSystem = require(Systems:WaitForChild("InteractionSystem"))
local AreaManager = require(Systems:WaitForChild("AreaManager"))
local GameManager = require(Systems:WaitForChild("GameManager"))
local AchievementSystem = require(Systems:WaitForChild("AchievementSystem"))
local EndingSystem = require(Systems:WaitForChild("EndingSystem"))
local NotificationSystem = require(Systems:WaitForChild("NotificationSystem"))

SaveSystem.Init()
NotificationSystem.Init()

local sessions: { [Player]: any } = {}

local function startSession(player: Player)
	local save = SaveSystem.Load(player)
	-- Init systems with this player's save
	SkillSystem.Init(save)
	DialogueSystem.Init(save, Data.Dialogue)
	QuestSystem.Init(save, Data.Quests)
	NPCSystem.Init(save, Data.NPCs)
	MiniGameSystem.Init(save)
	JournalSystem.Init(save)
	InventorySystem.Init(save)
	InteractionSystem.Init(save)
	AreaManager.Init(save, Data.Areas)
	AchievementSystem.Init(save, Data.Achievements)
	EndingSystem.Init(save, Data.Endings)
	GameManager.Init(save)

	sessions[player] = save
	AreaManager.Unlock("RumahBudaya")
	AreaManager.Load("RumahBudaya")
	GameManager.Start()

	-- Wire skill unlocks -> notifications
	SkillSystem.OnUnlock:Connect(function(kind, id)
		NotificationSystem.Toast("Unlocked: " .. kind .. " / " .. id, "unlock")
	end)
end

local function endSession(player: Player)
	local save = sessions[player]
	if save ~= nil then
		SaveSystem.Save(player, save)
		sessions[player] = nil
	end
end

Players.PlayerAdded:Connect(startSession)
Players.PlayerRemoving:Connect(endSession)

return true
