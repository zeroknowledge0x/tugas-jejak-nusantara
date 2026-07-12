--! GameClient.luau (StarterPlayerScripts)
--! Client bootstrap: requires systems, inits UI/audio, binds HUD.
--! This is the entry point on the client. Systems live in ReplicatedStorage.

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = Replicated:WaitForChild("JN"):WaitForChild("Modules")
local Systems = Modules:WaitForChild("Systems")
local Data = require(Modules:WaitForChild("Data"):WaitForChild("Data"))

local UIController = require(Systems:WaitForChild("UIController"))
local AudioManager = require(Systems:WaitForChild("AudioManager"))
local NotificationSystem = require(Systems:WaitForChild("NotificationSystem"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

UIController.Init(playerGui)
NotificationSystem.Init()
AudioManager.Init(game:GetService("SoundService"))

-- Bind achievement popup -> notification
local AchievementSystem = require(Systems:WaitForChild("AchievementSystem"))
AchievementSystem.OnUnlock:Connect(function(id)
	NotificationSystem.Achievement(id, id)
end)

UIController.Open("QuestTracker")

return true
