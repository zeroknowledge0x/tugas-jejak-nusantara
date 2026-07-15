--! GameClient.client.luau (StarterPlayerScripts)
--! Client bootstrap: builds a local single-player session, spawns a minimal
--! interactable world (NPC Budi) so the game is actually playable in Studio,
--! and wires the HUD. For a class project single-player test this is fine;
--! in a real multi-player build the server would own the session instead.

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Modules = Replicated:WaitForChild("JN"):WaitForChild("Modules")
local Systems = Modules:WaitForChild("Systems")

local Game = require(Modules:WaitForChild("Game"))
local SaveSystem = require(Systems:WaitForChild("SaveSystem"))
local UIController = require(Systems:WaitForChild("UIController"))
local AudioManager = require(Systems:WaitForChild("AudioManager"))
local NotificationSystem = require(Systems:WaitForChild("NotificationSystem"))
local AchievementSystem = require(Systems:WaitForChild("AchievementSystem"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Build a client-side session (single-player test).
SaveSystem.Init()
local save = SaveSystem.Load(player)
local gameSession = Game.new(save, player)

UIController.Init(playerGui)
NotificationSystem.Init()
AudioManager.Init(game:GetService("SoundService"))

AchievementSystem.OnUnlock:Connect(function(id)
	NotificationSystem.Achievement(id, id)
end)

UIController.Open("QuestTracker")
UIController.Open("SkillProgressUI")
UIController.Open("AreaProgressUI")

-- Minimal interactable world so the player can actually trigger dialogue.
local function spawnNPC(id: string, position: Vector3)
	local part = Instance.new("Part")
	part.Name = id
	part.Size = Vector3.new(2, 4, 2)
	part.Position = position
	part.Anchored = true
	part.BrickColor = BrickColor.new("Bright blue")
	part.Parent = Workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = id
	prompt.ActionText = "Bicara"
	prompt.HoldDuration = 0.3
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	prompt.Triggered:Connect(function(who)
		-- Start this NPC's intro dialogue (Data.Dialogue has intro_budi etc.)
		local node = "intro_" .. id:lower()
		gameSession:StartDialogue(node, id)
	end)
end

-- Rumah Budaya hub: spawn Budi so the core loop is reachable.
spawnNPC("Budi", Vector3.new(8, 4, 0))

-- Persist on leave (local fallback only in Studio).
game:GetService("Players").PlayerRemoving:Connect(function(p)
	if p == player then
		gameSession:Save()
	end
end)
