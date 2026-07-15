--! GameClient.client.luau (StarterPlayerScripts)
--! Client bootstrap: builds a local single-player session, spawns a minimal
--! interactable world (NPC Budi) so the game is actually playable in Studio,
--! wires the HUD, shows a load banner, and disables legacy chat noise.
--! For a class project single-player test this is fine; in a real multi-player
--! build the server would own the session instead.

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local Modules = Replicated:WaitForChild("JN"):WaitForChild("Modules")
local Systems = Modules:WaitForChild("Systems")

local Game = require(Modules:WaitForChild("Game"))
local SaveSystem = require(Systems:WaitForChild("SaveSystem"))
local UIController = require(Systems:WaitForChild("UIController"))
local AudioManager = require(Systems:WaitForChild("AudioManager"))
local NotificationSystem = require(Systems:WaitForChild("NotificationSystem"))
local AchievementSystem = require(Systems:WaitForChild("AchievementSystem"))
local DialogueSystem = require(Systems:WaitForChild("DialogueSystem"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Kill legacy chat so the benign "PlayerBlockedEvent" CoreScript warning disappears.
pcall(function()
	local tcs = game:GetService("TextChatService")
	tcs.ChatVersion = Enum.ChatVersion.TextChatService
end)

-- Load banner so it's obvious the game booted (auto-dismiss 3s).
local function showBanner()
	local sg = Instance.new("ScreenGui")
	sg.Name = "LoadBanner"
	sg.ResetOnSpawn = false
	sg.Parent = playerGui
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0.12, 0)
	f.Position = UDim2.new(0, 0, 0.44, 0)
	f.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	f.BorderSizePixel = 0
	f.Parent = sg
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Text = "JEGAK NUSANTARA — GAME LOADED"
	t.TextColor3 = Color3.fromRGB(240, 180, 60)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = f
	task.delay(3, function()
		if sg.Parent ~= nil then sg:Destroy() end
	end)
end
showBanner()

-- Build a client-side session (single-player test).
local ok, err = pcall(function()
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

	-- Make sure dialogue UI shows when a node fires.
	DialogueSystem.OnNode:Connect(function(node)
		UIController.Open("DialogueUI")
	end)

	-- Minimal interactable world so the player can actually trigger dialogue.
	local function spawnNPC(id, position)
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

		prompt.Triggered:Connect(function(_who)
			local node = "intro_" .. id:lower()
			gameSession:StartDialogue(node, id)
		end)
	end

	spawnNPC("Budi", Vector3.new(8, 4, 0))

	game:GetService("Players").PlayerRemoving:Connect(function(p)
		if p == player then
			gameSession:Save()
		end
	end)
end)

if not ok then
	warn("GameClient init failed: " .. tostring(err))
end
