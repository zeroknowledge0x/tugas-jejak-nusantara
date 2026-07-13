--! Game.luau
--! Central orchestrator. Requires all systems (no cycles: systems only depend on
--! Types/Util). Wires cross-system effects so the core loop actually runs:
--!   dialogue choice -> skill/relationship/journal/flag/inventory
--!   mini-game complete -> skill XP + quest progress + reward + journal
--!   quest complete -> area unlock (Rule 1) + reward + notification
--!   skill level-up -> unlocks (binding requirement)
--! This is the real game logic, shared by GameServer and the runtime test.

local Types = require(script.Parent.Types)
local Data = require(script.Parent.Data.Data)

local SaveSystem = require(script.Parent.Systems.SaveSystem)
local SkillSystem = require(script.Parent.Systems.SkillSystem)
local DialogueSystem = require(script.Parent.Systems.DialogueSystem)
local QuestSystem = require(script.Parent.Systems.QuestSystem)
local NPCSystem = require(script.Parent.Systems.NPCSystem)
local MiniGameSystem = require(script.Parent.Systems.MiniGameSystem)
local JournalSystem = require(script.Parent.Systems.JournalSystem)
local InventorySystem = require(script.Parent.Systems.InventorySystem)
local InteractionSystem = require(script.Parent.Systems.InteractionSystem)
local AreaManager = require(script.Parent.Systems.AreaManager)
local GameManager = require(script.Parent.Systems.GameManager)
local AchievementSystem = require(script.Parent.Systems.AchievementSystem)
local EndingSystem = require(script.Parent.Systems.EndingSystem)
local NotificationSystem = require(script.Parent.Systems.NotificationSystem)
local AudioManager = require(script.Parent.Systems.AudioManager)

local Game = {}
Game.__index = Game

-- Skill XP granted per mini-game success (by kind). Tunable in Data.
local MiniGameSkill: { [Types.MiniGameKind]: Types.SkillId } = {
	Rhythm = "CulturalUnderstanding",
	Dance = "CulturalUnderstanding",
	Negotiation = "Communication",
	HistoryPuzzle = "ProblemSolving",
	Observation = "Observation",
	PatternMatching = "ProblemSolving",
	HiddenObject = "Observation",
	CultureActivity = "CulturalUnderstanding",
}

local function new(save: Types.SaveData, player: Player?)
	local self = setmetatable({}, Game)

	-- Init all systems with this save
	SaveSystem.Init()
	SkillSystem.Init(save)
	DialogueSystem.Init(save, Data.Dialogue, self:_effectsHandler())
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
	NotificationSystem.Init()
	AudioManager.Init(game:GetService("SoundService"))

	self.save = save
	self.player = player

	self:_wire()
	return self
end

function Game.new(save: Types.SaveData, player: Player?)
	return new(save, player)
end

-- Builds the effects handler injected into DialogueSystem (keeps it decoupled).
function Game:_effectsHandler()
	local self = self
	return {
		ApplySkillGain = function(skill: Types.SkillId, amount: number)
			SkillSystem.AddXP(skill, amount)
		end,
		ApplyUnlock = function(kind: Types.UnlockKind, id: string)
			self.save.unlocked[kind][id] = true
			SkillSystem.OnUnlock:Fire(kind, id)
		end,
		ApplyRelationship = function(npc: string, delta: number)
			NPCSystem.SetRelationship(npc, delta)
		end,
		ApplyFlag = function(key: string, value: boolean)
			self.save.endingFlags[key] = value
		end,
		ApplyJournal = function(category: Types.JournalCategory, key: string)
			JournalSystem.Record(category, key)
			self.save.discovered[category][key] = true
		end,
		ApplyInventory = function(item: string, count: number)
			InventorySystem.Add(item, count)
		end,
	}
end

function Game:_wire()
	-- Skill unlocks -> notification
	SkillSystem.OnUnlock:Connect(function(kind, id)
		NotificationSystem.Toast("Unlock: " .. kind .. " / " .. id, "unlock")
		AudioManager.Sfx("unlock")
	end)

	-- Mini-game complete -> rewards
	MiniGameSystem.OnComplete:Connect(function(_instanceId, result: Types.MiniGameResult)
		local skill = MiniGameSkill[result.kind] or "CulturalUnderstanding"
		local xp = math.floor(result.score / 10) -- 0..10
		if result.success then
			xp += 5
		end
		SkillSystem.AddXP(skill, xp)
		JournalSystem.Record("discoveries", result.kind .. "_played")
		NotificationSystem.Toast(
			result.kind .. ": " .. (result.success and "sukses" or "gagal") .. " (" .. result.score .. ")",
			result.success and "good" or "bad"
		)
		AudioManager.Sfx(result.success and "minigame_win" or "minigame_lose")
		-- Advance any matching quest progress
		self:_advanceMiniGameQuests(result.kind, result.success)
	end)

	-- Quest complete -> reward + area unlock (Rule 1) + journal
	QuestSystem.OnComplete:Connect(function(id, _kind)
		local def = Data.Quests[id]
		if def ~= nil and def.reward ~= nil then
			if def.reward.item ~= nil then
				InventorySystem.Add(def.reward.item, def.reward.count or 1)
			end
			if def.reward.skill ~= nil then
				SkillSystem.AddXP(def.reward.skill, def.reward.skillXp or 0)
			end
		end
		JournalSystem.Record("completedQuests", id)
		NotificationSystem.Toast("Quest selesai: " .. id, "quest")
		AudioManager.Sfx("quest_done")
		-- Rule 1: completing a main quest unlocks the next area
		if def ~= nil and def.unlocksArea ~= nil then
			AreaManager.Unlock(def.unlocksArea)
			AreaManager.Load(def.unlocksArea)
			GameManager.AdvanceArea(def.unlocksArea)
		end
		-- Achievement checks
		for aid, _ in pairs(Data.Achievements) do
			if AchievementSystem.Check(aid) then
				AchievementSystem.Unlock(aid)
			end
		end
	end)

	-- NPC relationship milestones
	NPCSystem.OnRelationship:Connect(function(npc, value)
		if value >= 100 then
			NotificationSystem.Toast(npc .. " memandangmu sebagai sahabat budaya", "friend")
		end
	end)

	-- Achievement unlock -> notification
	AchievementSystem.OnUnlock:Connect(function(id)
		NotificationSystem.Achievement(id, id)
		AudioManager.Sfx("achievement")
	end)
end

function Game:_advanceMiniGameQuests(kind: Types.MiniGameKind, success: boolean)
	if not success then
		return
	end
	for id, q in pairs(self.save.quests.active) do
		local def = Data.Quests[id]
		if def ~= nil and def.miniGame == kind then
			QuestSystem.Update(id, 1)
		end
	end
end

-- Public high-level actions used by UI / server
function Game:StartDialogue(nodeId: string, npc: string)
	DialogueSystem.Start(nodeId, npc)
end

function Game:ChooseDialogue(optionIndex: number)
	DialogueSystem.Choose(optionIndex)
end

function Game:LaunchMiniGame(kind: Types.MiniGameKind, cfg: table): string
	AudioManager.Sfx("minigame_start")
	return MiniGameSystem.Launch(kind, cfg)
end

function Game:SubmitMiniGame(instanceId: string, result: Types.MiniGameResult)
	MiniGameSystem.Submit(instanceId, result)
end

function Game:AcceptQuest(id: string)
	QuestSystem.Accept(id)
end

function Game:Interact(objectId: string)
	if self.player ~= nil then
		InteractionSystem.Prompt(self.player, objectId)
	else
		InteractionSystem.Prompt(game:GetService("Players"):GetPlayers()[1], objectId)
	end
end

function Game:SpawnNPC(id: string): boolean
	return NPCSystem.Spawn(id)
end

function Game:EvaluateEnding(): Types.EndingId
	return EndingSystem.Evaluate()
end

function Game:GetSave(): Types.SaveData
	return self.save
end

function Game:Save()
	if self.player ~= nil then
		SaveSystem.Save(self.player, self.save)
	end
end

return Game
