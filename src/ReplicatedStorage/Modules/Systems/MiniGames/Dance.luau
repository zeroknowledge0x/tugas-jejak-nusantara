--! MiniGames/Dance.luau
--! Traditional dance movement mini-game (Level 2). Player follows a sequence
--! of directional poses; scored by timing + correctness.
--! Public API: Dance.Create(cfg), Dance.Evaluate(inst, seq)

local RNG = require(script.Parent.Parent.Parent.Util.RNG)
local Types = require(script.Parent.Parent.Parent.Types)

export type Pose = "Up" | "Down" | "Left" | "Right" | "Spin"
export type DanceInstance = {
	kind: "Dance",
	sequence: { Pose },
	tolerance: number,
}

local POSES: { Pose } = { "Up", "Down", "Left", "Right", "Spin" }

local Dance = {}

function Dance.Create(cfg: table): DanceInstance
	local rng = RNG.new((cfg and cfg.seed) or 99)
	local n = (cfg and cfg.steps) or 5
	local seq = {}
	for _ = 1, n do
		table.insert(seq, POSES[math.floor(rng:Next() * #POSES) + 1])
	end
	return { kind = "Dance", sequence = seq, tolerance = (cfg and cfg.tolerance) or 0.1 }
end

function Dance.Evaluate(inst: DanceInstance, seq: { Pose }): Types.MiniGameResult
	local correct = 0
	for i, target in ipairs(inst.sequence) do
		if seq[i] == target then
			correct += 1
		end
	end
	local score = math.floor((correct / #inst.sequence) * 100)
	return { kind = "Dance", score = score, success = score >= 60, perfect = correct == #inst.sequence }
end

return Dance
