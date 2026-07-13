--! MiniGames/Observation.luau
--! Observation / hidden-object mini-game (shared by L1 observation & L4).
--! Player identifies N target items among distractors from a described scene.
--! Public API: Observation.Create(cfg), Observation.Evaluate(inst, picks)

local Types = require(script.Parent.Parent.Types)

export type ObservationInstance = {
	kind: "Observation",
	targets: { string },
	distractors: { string },
}

local Observation = {}

function Observation.Create(cfg: table): ObservationInstance
	return {
		kind = "Observation",
		targets = (cfg and cfg.targets) or {},
		distractors = (cfg and cfg.distractors) or {},
	}
end

function Observation.Evaluate(inst: ObservationInstance, picks: { string }): Types.MiniGameResult
	local found = 0
	local wrong = 0
	local targetSet = {}
	for _, t in ipairs(inst.targets) do
		targetSet[t] = true
	end
	for _, p in ipairs(picks) do
		if targetSet[p] then
			found += 1
		else
			wrong += 1
		end
	end
	local n = #inst.targets
	local score = math.max(0, math.floor(((found / n) - (wrong / math.max(1, n)) * 0.5) * 100))
	return { kind = "Observation", score = score, success = score >= 60, perfect = found == n and wrong == 0 }
end

return Observation
