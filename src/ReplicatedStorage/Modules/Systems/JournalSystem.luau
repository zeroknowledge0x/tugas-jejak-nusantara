--! JournalSystem.luau
--! Auto-records everything the player discovers; computes completion %.
--! Journal completion influences endings (binding requirement).
--! Public API:
--!   JournalSystem.Init(save: SaveData)
--!   JournalSystem.Record(category: JournalCategory, key: string)
--!   JournalSystem.IsLogged(category: JournalCategory, key: string): boolean
--!   JournalSystem.GetCompletion(): number (0..100)
--!   JournalSystem.OnRecord: Signal(category, key)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type JournalSystemApi = {
	Init: (save: Types.SaveData) -> (),
	Record: (category: Types.JournalCategory, key: string) -> (),
	IsLogged: (category: Types.JournalCategory, key: string) -> boolean,
	GetCompletion: () -> number,
	OnRecord: Signal.Signal<Types.JournalCategory, string>,
}

local JournalSystem = {} :: JournalSystemApi
JournalSystem.OnRecord = Signal.new()

local save: Types.SaveData? = nil

-- Weights per category for completion %. Sum ~= 100; normalized at read time.
local Weights: { [Types.JournalCategory]: number } = {
	locations = 10,
	npcs = 12,
	food = 10,
	music = 10,
	dance = 10,
	artifacts = 12,
	history = 12,
	discoveries = 8,
	secrets = 10,
	puzzleProgress = 6,
	completedQuests = 10,
}

function JournalSystem.Init(s: Types.SaveData)
	save = s
end

function JournalSystem.Record(category: Types.JournalCategory, key: string)
	assert(save, "JournalSystem not initialized")
	if save.journal.logged[category] == nil then
		save.journal.logged[category] = {}
	end
	if save.journal.logged[category][key] then
		return
	end
	save.journal.logged[category][key] = true
	JournalSystem.OnRecord:Fire(category, key)
	JournalSystem._recompute()
end

function JournalSystem.IsLogged(category: Types.JournalCategory, key: string): boolean
	assert(save, "JournalSystem not initialized")
	return save.journal.logged[category] ~= nil and save.journal.logged[category][key] == true
end

function JournalSystem.GetCompletion(): number
	assert(save, "JournalSystem not initialized")
	return save.journal.completion
end

function JournalSystem._recompute()
	assert(save, "JournalSystem not initialized")
	local total = 0
	for _, w in pairs(Weights) do
		total += w
	end
	local got = 0
	for cat, w in pairs(Weights) do
		local n = 0
		local t = save.journal.logged[cat]
		if t ~= nil then
			for _ in pairs(t) do
				n += 1
			end
		end
		got += w * math.min(1, n / 4) -- assume ~4 entries per category to "fill"
	end
	save.journal.completion = math.floor((got / total) * 100)
end

return JournalSystem
