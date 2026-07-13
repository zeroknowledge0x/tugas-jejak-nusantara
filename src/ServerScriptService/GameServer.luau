--! GameServer.luau (ServerScriptService)
--! Server bootstrap: per-player session via the Game orchestrator.
--! The orchestrator inits + wires ALL systems, so the core loop is consistent.

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = Replicated:WaitForChild("JN"):WaitForChild("Modules")
local Data = require(Modules:WaitForChild("Data"):WaitForChild("Data"))
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

	-- Persist on key milestones.
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

return true
