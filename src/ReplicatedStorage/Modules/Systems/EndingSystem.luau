--! EndingSystem.luau
--! Multi-factor ending scoring (not XP-only). Binding requirement.
--! Public API:
--!   EndingSystem.Init(save: SaveData, data: {[any]:any})
--!   EndingSystem.Evaluate(): EndingId
--!   EndingSystem.GetSummary(ending: EndingId): {title:string, body:string}
--!   EndingSystem.OnEnding: Signal(EndingId)

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type EndingSystemApi = {
	Init: (save: Types.SaveData, data: { [any]: any }) -> (),
	Evaluate: () -> Types.EndingId,
	GetSummary: (ending: Types.EndingId) -> { title: string, body: string },
	OnEnding: Signal.Signal<Types.EndingId>,
}

local EndingSystem = {} :: EndingSystemApi
EndingSystem.OnEnding = Signal.new()

local save: Types.SaveData? = nil
local data: { [any]: any }? = nil

function EndingSystem.Init(s: Types.SaveData, d: { [any]: any })
	save = s
	data = d
end

function EndingSystem.Evaluate(): Types.EndingId
	assert(save, "EndingSystem not initialized")
	local s = save
	local journal = JournalCompletionCached(s)
	local decision = s.skills.DecisionMaking
	local culture = s.skills.CulturalUnderstanding
	local secrets = 0
	for _ in pairs(s.discovered.secrets) do
		secrets += 1
	end
	local completed = 0
	for _ in pairs(s.completedAreas) do
		completed += 1
	end

	-- Alternative endings require DecisionMaking>=T3 and high journal completion
	if decision >= Types.Constants.SKILL_T3 and journal >= 80 then
		if secrets >= 3 then
			return "Guardian" -- protected the culture's hidden knowledge
		end
		return "Lorekeeper" -- mastered & documented the culture
	end

	-- Base PDF endings
	if completed >= 5 and culture >= Types.Constants.SKILL_T2 then
		return "Success"
	elseif completed >= 5 then
		return "Adequate"
	end
	return "Explorative"
end

function EndingSystem.GetSummary(ending: Types.EndingId): { title: string, body: string }
	assert(data, "EndingSystem not initialized")
	local d = data
	if d ~= nil and d.summaries ~= nil and d.summaries[ending] ~= nil then
		return d.summaries[ending]
	end
	return { title = ending, body = "Ending." }
end

-- Local helper to avoid cross-require during init ordering.
function JournalCompletionCached(s: Types.SaveData): number
	return s.journal.completion
end

return EndingSystem
