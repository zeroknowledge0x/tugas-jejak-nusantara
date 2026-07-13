--! GameServer.server.luau (ServerScriptService)
--! Server bootstrap: per-player session via the Game orchestrator.
--! Rojo maps *.server.luau -> Script (auto-runs on the server).

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = Replicated:WaitForChild("JN"):WaitForChild("Modules")
local Game = require(Modules:WaitForChild("Game"))

local SaveSystem = require(Modules:WaitForChild("Systems"):WaitForChild("SaveSystem"))
local AreaManager = require(Modules:WaitForChild("Systems"):WaitForChild("AreaManager"))
local GameManager = require(Modules:WaitForChild("Systems"):WaitForChild("GameManager"))
local NotificationSystem = require(Modules:WaitForChild("Systems"):WaitForChild("NotificationSystem"))

SaveSystem.Init()
NotificationSystem.Init()

local sessions: { [Player]: any } = {}

local function startSession(player: Player)
	local save = SaveSystem.Load(player)
	local gameSession = Game.new(save, player)
	sessions[player] = gameSession

	-- Rule 1: first area is open from the start.
	AreaManager.Unlock("RumahBudaya")
	AreaManager.Load("RumahBudaya")
	GameManager.Start()

	gameSession:Save()
end

local function endSession(player: Player)
	local session = sessions[player]
	if session ~= nil then
		session:Save()
		sessions[player] = nil
	end
end

Players.PlayerAdded:Connect(startSession)
Players.PlayerRemoving:Connect(endSession)

-- Players already in-game when this script starts (Studio play solo).
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(startSession, player)
end
