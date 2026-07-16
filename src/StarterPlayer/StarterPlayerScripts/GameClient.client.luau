--! GameClient.client.luau
--! Client bootstrap for Studio / ZIP download testing.
--! 1) Print + banner FIRST (before any require) so silent death is impossible.
--! 2) pcall every require; name the failed module.
--! 3) Build a local single-player session and auto-start intro dialogue.
--! 4) Bind to server-spawned Budi ProximityPrompt (WorldBuilder).

print("[JN] GameClient STARTED")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function showBanner(text: string)
	local old = playerGui:FindFirstChild("JNLoadBanner")
	if old then
		old:Destroy()
	end
	local sg = Instance.new("ScreenGui")
	sg.Name = "JNLoadBanner"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 200
	sg.Parent = playerGui

	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0.16, 0)
	f.Position = UDim2.new(0, 0, 0.42, 0)
	f.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	f.BackgroundTransparency = 0.1
	f.BorderSizePixel = 0
	f.Parent = sg

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(0.86, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.fromRGB(255, 210, 80)
	t.TextScaled = true
	t.Parent = f

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0.12, 0, 0.5, 0)
	close.Position = UDim2.new(0.87, 0, 0.25, 0)
	close.BackgroundColor3 = Color3.fromRGB(190, 50, 50)
	close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.TextScaled = true
	close.Parent = f
	close.Activated:Connect(function()
		sg:Destroy()
	end)
end

showBanner("[JN] BOOTING… tunggu sebentar")

local function tryRequire(name: string, inst: Instance)
	local ok, mod = pcall(require, inst)
	if not ok then
		warn("[JN] REQUIRE FAILED [" .. name .. "]: " .. tostring(mod))
		showBanner("[JN] LOAD ERROR: " .. name .. " — cek Output")
		return nil
	end
	return mod
end

local Replicated = game:GetService("ReplicatedStorage")
local jn = Replicated:WaitForChild("JN", 15)
if jn == nil then
	showBanner("[JN] FATAL: ReplicatedStorage.JN missing — place file rusak/stale")
	warn("[JN] ReplicatedStorage.JN not found after 15s")
	return
end
local Modules = jn:WaitForChild("Modules", 10)
if Modules == nil then
	showBanner("[JN] FATAL: JN.Modules missing")
	return
end
local Systems = Modules:WaitForChild("Systems", 10)
if Systems == nil then
	showBanner("[JN] FATAL: Modules.Systems missing")
	return
end

local Game = tryRequire("Game", Modules:WaitForChild("Game"))
local SaveSystem = tryRequire("SaveSystem", Systems:WaitForChild("SaveSystem"))
local UIController = tryRequire("UIController", Systems:WaitForChild("UIController"))
local AudioManager = tryRequire("AudioManager", Systems:WaitForChild("AudioManager"))
local NotificationSystem = tryRequire("NotificationSystem", Systems:WaitForChild("NotificationSystem"))
local AchievementSystem = tryRequire("AchievementSystem", Systems:WaitForChild("AchievementSystem"))
local DialogueSystem = tryRequire("DialogueSystem", Systems:WaitForChild("DialogueSystem"))

if Game == nil or SaveSystem == nil or UIController == nil or DialogueSystem == nil then
	showBanner("[JN] CORE MODULE GAGAL — lihat Output (REQUIRE FAILED)")
	return
end

local ok, err = pcall(function()
	SaveSystem.Init()
	local save = SaveSystem.Load(player)
	local session = Game.new(save, player)

	UIController.Init(playerGui)
	NotificationSystem.Init()
	AudioManager.Init(game:GetService("SoundService"))

	AchievementSystem.OnUnlock:Connect(function(id)
		NotificationSystem.Achievement(id, id)
	end)

	UIController.Open("QuestTracker")
	UIController.Open("SkillProgressUI")
	UIController.Open("AreaProgressUI")

	-- Wire dialogue UI (extra safety; UIController also wires OnNode).
	DialogueSystem.OnNode:Connect(function(_node)
		UIController.Open("DialogueUI")
	end)

	-- Bind to server-spawned Budi (WorldBuilder). Fallback: spawn local Budi.
	local Workspace = game:GetService("Workspace")
	local budi = Workspace:WaitForChild("Budi", 8)
	if budi == nil then
		warn("[JN] Budi not found from server — spawning client fallback")
		budi = Instance.new("Part")
		budi.Name = "Budi"
		budi.Size = Vector3.new(2, 5, 2)
		budi.Position = Vector3.new(0, 3, -12)
		budi.Anchored = true
		budi.Color = Color3.fromRGB(30, 120, 255)
		budi.Material = Enum.Material.Neon
		budi.Parent = Workspace
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt"
		prompt.ObjectText = "Budi"
		prompt.ActionText = "Bicara"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt.Parent = budi
	end

	local prompt = budi:FindFirstChild("TalkPrompt") or budi:FindFirstChildOfClass("ProximityPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function()
			session:StartDialogue("intro_budi", "Budi")
		end)
	end

	Players.PlayerRemoving:Connect(function(p)
		if p == player then
			session:Save()
		end
	end)

	showBanner("[JN] SIAP MAIN — dialog auto-start 1 detik, atau tekan E di Budi (biru)")
	print("[JN] session ready — auto-starting intro_budi")

	-- Auto-start first dialogue so the player always sees the game loop.
	task.delay(1, function()
		local started, startErr = pcall(function()
			session:StartDialogue("intro_budi", "Budi")
		end)
		if not started then
			warn("[JN] auto StartDialogue failed: " .. tostring(startErr))
			showBanner("[JN] Dialog gagal: " .. tostring(startErr))
		else
			showBanner("[JN] DIALOG AKTIF — pilih pilihan di layar")
		end
	end)
end)

if not ok then
	warn("[JN] session build failed: " .. tostring(err))
	showBanner("[JN] SESSION ERROR: " .. tostring(err))
end
