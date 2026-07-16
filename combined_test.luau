
local function inst(kind)
  local t={ClassName=kind or "Instance",Children={},Parent=nil}
  setmetatable(t,{__index=function(s,k)
    if k=="GetChildren" then return function() return s.Children end end
    if k=="WaitForChild" then return function(_,n) return inst(n) end end
    if k=="FindFirstChild" then return function(_,n) return inst(n) end end
    return rawget(s,k) end})
  return t
end
local services={}
local function svc(name)
  if services[name]==nil then services[name]=inst(name) end
  return services[name]
end
game={GetService=svc,PlaceId=0}
local Players=inst("Players")
Players.LocalPlayer=inst("Player")
Players.LocalPlayer.PlayerGui=inst("PlayerGui")
svc("Players").LocalPlayer=Players.LocalPlayer
Instance={new=function(k) return inst(k) end}
Enum={Font={GothamBold="GothamBold"}}
Color3={fromRGB=function() return {} end}
UDim2={new=function() return {} end}
Vector3={new=function() return {} end}
BrickColor={new=function() return {} end}
task={delay=function() end,wait=function() end}
require=function() error("mock require") end

--! GameClient.client.luau (StarterPlayerScripts)
--! Client bootstrap. BANNER is shown FIRST (before any require) so even if a
--! module fails to load, you still see the game booted. Each require is wrapped
--! in pcall and warns which one failed. Single-player client session.

print("JN GameClient STARTED")

-- ===== BANNER FIRST (no requires above this) =====
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function showBanner(text)
	local sg = Instance.new("ScreenGui")
	sg.Name = "LoadBanner"
	sg.ResetOnSpawn = false
	sg.Parent = playerGui
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0.14, 0)
	f.Position = UDim2.new(0, 0, 0.43, 0)
	f.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	f.BorderSizePixel = 0
	f.Parent = sg
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.fromRGB(240, 180, 60)
	t.TextScaled = true
	t.Parent = f
	t.ZIndex = 10
	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0.12, 0, 0.4, 0)
	close.Position = UDim2.new(0.86, 0, 0.3, 0)
	close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextScaled = true
	close.Parent = f
	close.ZIndex = 11
	close.Activated:Connect(function()
		if sg.Parent ~= nil then sg:Destroy() end
	end)
end

showBanner("JEGAK NUSANTARA - GAME JALAN. Dekat kotak BIRU (Budi) lalu klik Bicara.")

-- Disable legacy chat noise (best-effort).
pcall(function()
	game:GetService("TextChatService").ChatVersion = Enum.ChatVersion.TextChatService
end)

-- ===== REQUIRES (each wrapped so a failure is visible, not silent) =====
local function tryRequire(name, inst)
	local ok, mod = pcall(function() return require(inst) end)
	if not ok then
		warn("REQUIRE FAILED [" .. name .. "]: " .. tostring(mod))
		showBanner("LOAD ERROR: " .. name)
	end
	return ok and mod or nil
end

local Replicated = game:GetService("ReplicatedStorage")
local Modules = Replicated:WaitForChild("JN"):WaitForChild("Modules")
local Systems = Modules:WaitForChild("Systems")

local Game = tryRequire("Game", Modules:WaitForChild("Game"))
local SaveSystem = tryRequire("SaveSystem", Systems:WaitForChild("SaveSystem"))
local UIController = tryRequire("UIController", Systems:WaitForChild("UIController"))
local AudioManager = tryRequire("AudioManager", Systems:WaitForChild("AudioManager"))
local NotificationSystem = tryRequire("NotificationSystem", Systems:WaitForChild("NotificationSystem"))
local AchievementSystem = tryRequire("AchievementSystem", Systems:WaitForChild("AchievementSystem"))
local DialogueSystem = tryRequire("DialogueSystem", Systems:WaitForChild("DialogueSystem"))

if Game == nil or SaveSystem == nil or UIController == nil then
	showBanner("CORE MODULES MISSING - check output")
	return
end

-- ===== BUILD SESSION =====
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

	DialogueSystem.OnNode:Connect(function(_node)
		UIController.Open("DialogueUI")
	end)

	local Workspace = game:GetService("Workspace")
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
			gameSession:StartDialogue("intro_" .. id:lower(), id)
		end)
	end

	spawnNPC("Budi", Vector3.new(8, 4, 0))

	game:GetService("Players").PlayerRemoving:Connect(function(p)
		if p == player then gameSession:Save() end
	end)

	showBanner("JEGAK NUSANTARA - SIAP MAIN!")
end)

if not ok then
	warn("GameClient session failed: " .. tostring(err))
	showBanner("SESSION ERROR - lihat output")
end

print("MOCK_OK_BANNER_REACHED")
