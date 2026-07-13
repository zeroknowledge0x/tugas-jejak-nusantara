--! MiniGames/CultureActivity.luau
--! Interactive culture activity (e.g. arrange offerings, prepare food).
--! Player performs an ordered set of steps; scored on correctness.
--! Public API: CultureActivity.Create(cfg), CultureActivity.Evaluate(inst, steps)

local Types = require(script.Parent.Parent.Parent.Types)

export type CultureActivityInstance = {
	kind: "CultureActivity",
	correctSteps: { string },
}

local CultureActivity = {}

function CultureActivity.Create(cfg: table): CultureActivityInstance
	return { kind = "CultureActivity", correctSteps = (cfg and cfg.steps) or {} }
end

function CultureActivity.Evaluate(inst: CultureActivityInstance, steps: { string }): Types.MiniGameResult
	local correct = 0
	for i, want in ipairs(inst.correctSteps) do
		if steps[i] == want then
			correct += 1
		end
	end
	local n = math.max(1, #inst.correctSteps)
	local score = math.floor((correct / n) * 100)
	return { kind = "CultureActivity", score = score, success = score >= 60, perfect = correct == n }
end

return CultureActivity
