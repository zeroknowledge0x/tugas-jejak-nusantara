--! SaveSystem.luau
--! Versioned save with DataStore + local fallback (playable in Studio).
--! Public API:
--!   SaveSystem.Init()
--!   SaveSystem.Load(player: Player): SaveData
--!   SaveSystem.Save(player: Player, save: SaveData)
--!   SaveSystem.Reset(player: Player)
--!   SaveSystem.CreateDefault(): SaveData

local Types = require(script.Parent.Parent.Types)

export type SaveSystemApi = {
	Init: () -> (),
	Load: (player: Player) -> Types.SaveData,
	Save: (player: Player, save: Types.SaveData) -> (),
	Reset: (player: Player) -> (),
	CreateDefault: () -> Types.SaveData,
}

local SaveSystem = {} :: SaveSystemApi

local SAVE_KEY_PREFIX = "JejakNusantara_"
local CURRENT_VERSION = 1
local store: any = nil

function SaveSystem.Init()
	-- DataStore wajib place sudah dipublish ke web. Di Studio (atau place
	-- belum publish) Roblox lempar engine-error fatal yg pcall tdk tangkap.
	-- Guard: skip total -> pakai fallback lokal (save tetap jalan di test).
	local RunService = game:GetService("RunService")
	if RunService:IsStudio() or game.PlaceId == 0 then
		store = nil
		return
	end
	local ok, ds = pcall(function()
		return game:GetService("DataStoreService"):GetDataStore("JejakNusantara")
	end)
	if ok then
		store = ds
	end
end

local function newSave(): Types.SaveData
	return {
		version = CURRENT_VERSION,
		skills = {
			Observation = 0,
			Communication = 0,
			ProblemSolving = 0,
			DecisionMaking = 0,
			CulturalUnderstanding = 0,
		},
		unlocked = { dialogue = {}, secrets = {}, quests = {}, npcs = {} },
		journal = { logged = {}, completion = 0 },
		inventory = {},
		quests = { active = {}, completed = {} },
		areaProgress = {},
		completedAreas = {},
		endingFlags = {},
		achievements = {},
		discovered = {
			locations = {},
			npcs = {},
			food = {},
			music = {},
			dance = {},
			artifacts = {},
			history = {},
			secrets = {},
		},
		relationships = {},
		checkpoint = "RumahBudaya",
	}
end

function SaveSystem.CreateDefault(): Types.SaveData
	return newSave()
end

function SaveSystem.Load(player: Player): Types.SaveData
	local key = SAVE_KEY_PREFIX .. tostring(player.UserId)
	local data: Types.SaveData? = nil
	if store ~= nil then
		local ok, res = pcall(function()
			return store:GetAsync(key)
		end)
		if ok and res ~= nil then
			data = res
		end
	end
	if data == nil then
		data = newSave()
	end
	-- migrate
	if data.version ~= CURRENT_VERSION then
		data.version = CURRENT_VERSION
	end
	return data
end

function SaveSystem.Save(player: Player, save: Types.SaveData)
	local key = SAVE_KEY_PREFIX .. tostring(player.UserId)
	save.version = CURRENT_VERSION
	if store ~= nil then
		pcall(function()
			store:SetAsync(key, save)
		end)
	end
end

function SaveSystem.Reset(player: Player)
	local key = SAVE_KEY_PREFIX .. tostring(player.UserId)
	if store ~= nil then
		pcall(function()
			store:RemoveAsync(key)
		end)
	end
end

return SaveSystem
