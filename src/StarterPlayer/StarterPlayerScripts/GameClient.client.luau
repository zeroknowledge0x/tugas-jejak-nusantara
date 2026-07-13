--! GameClient.client.luau (StarterPlayerScripts)
--! Client bootstrap: requires systems, inits UI/audio, binds HUD.
--! Rojo maps *.client.luau -> LocalScript (auto-runs on the client).

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = Replicated:WaitForChild("JN"):WaitForChild("Modules")
local Systems = Modules:WaitForChild("Systems")

local UIController = require(Systems:WaitForChild("UIController"))
local AudioManager = require(Systems:WaitForChild("AudioManager"))
local NotificationSystem = require(Systems:WaitForChild("NotificationSystem"))
local AchievementSystem = require(Systems:WaitForChild("AchievementSystem"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

UIController.Init(playerGui)
NotificationSystem.Init()
AudioManager.Init(game:GetService("SoundService"))

AchievementSystem.OnUnlock:Connect(function(id)
	NotificationSystem.Achievement(id, id)
end)

UIController.Open("QuestTracker")
UIController.Open("SkillProgressUI")
UIController.Open("AreaProgressUI")
