--! MiniGames/PatternMatching.luau
--! Pattern matching (batik/weaving motifs). Player continues a sequence.
--! Public API: PatternMatching.Create(cfg), PatternMatching.Evaluate(inst, next)

local RNG = require(script.Parent.Parent.Util.RNG)
local Types = require(script.Parent.Parent.Types)

export type PatternInstance = {
	kind: "PatternMatching",
	sequence: { number },
	answer: number,
}

local PatternMatching = {}

-- Generates an arithmetic-ish motif sequence; answer is the next element.
function PatternMatching.Create(cfg: table): PatternInstance
	local rng = RNG.new((cfg and cfg.seed) or 7)
	local start = math.floor(rng:Next() * 4) + 1
	local step = math.floor(rng:Next() * 3) + 1
	local seq = {}
	local v = start
	for _ = 1, 4 do
		table.insert(seq, v)
		v += step
	end
	return { kind = "PatternMatching", sequence = seq, answer = v }
end

function PatternMatching.Evaluate(inst: PatternInstance, guess: number): Types.MiniGameResult
	local ok = guess == inst.answer
	return { kind = "PatternMatching", score = ok and 100 or 0, success = ok, perfect = ok }
end

return PatternMatching
