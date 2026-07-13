--! MiniGames/Rhythm.luau
--! Angklung rhythm mini-game (Level 1). Player matches a beat pattern.
--! Pure scoring logic (headless-testable). UI layer drives input.
--! Public API:
--!   Rhythm.Create(cfg): instance
--!   Rhythm.Evaluate(inst, answer): MiniGameResult

local RNG = require(script.Parent.Parent.Util.RNG)
local Types = require(script.Parent.Parent.Types)

export type RhythmInstance = {
	kind: "Rhythm",
	pattern: { number }, -- normalized beat times 0..1
	tolerance: number,
}

local Rhythm = {}

function Rhythm.Create(cfg: table): RhythmInstance
	local seed = (cfg and cfg.seed) or 1234
	local rng = RNG.new(seed)
	local count = (cfg and cfg.beats) or 6
	local pattern = {}
	local t = 0.1
	for _ = 1, count do
		t = math.min(0.95, t + rng:Next() * 0.18 + 0.07)
		table.insert(pattern, t)
	end
	return {
		kind = "Rhythm",
		pattern = pattern,
		tolerance = (cfg and cfg.tolerance) or 0.08,
	}
end

function Rhythm.Evaluate(inst: RhythmInstance, answer: { number }): Types.MiniGameResult
	local pattern = inst.pattern
	local tol = inst.tolerance
	local hits = 0
	for i, target in ipairs(pattern) do
		local got = answer[i]
		if got ~= nil and math.abs(got - target) <= tol then
			hits += 1
		end
	end
	local score = math.floor((hits / #pattern) * 100)
	return {
		kind = "Rhythm",
		score = score,
		success = score >= 60,
		perfect = hits == #pattern,
	}
end

return Rhythm
