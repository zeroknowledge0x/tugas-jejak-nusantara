--! MiniGames/HistoryPuzzle.luau
--! Historical reconstruction puzzle (Level 4). Player orders events into a
--! correct chronological sequence.
--! Public API: HistoryPuzzle.Create(cfg), HistoryPuzzle.Evaluate(inst, order)

local Types = require(script.Parent.Parent.Parent.Types)

export type HistoryPuzzleInstance = {
	kind: "HistoryPuzzle",
	correct: { number }, -- canonical order of event ids
}

local HistoryPuzzle = {}

function HistoryPuzzle.Create(cfg: table): HistoryPuzzleInstance
	-- cfg.events is an array of {id, year}; sort by year for the correct order.
	local evs = (cfg and cfg.events) or {}
	local sorted = {}
	for i, e in ipairs(evs) do
		sorted[i] = e
	end
	table.sort(sorted, function(a, b)
		return a.year < b.year
	end)
	local correct = {}
	for i, e in ipairs(sorted) do
		correct[i] = e.id
	end
	return { kind = "HistoryPuzzle", correct = correct }
end

function HistoryPuzzle.Evaluate(inst: HistoryPuzzleInstance, order: { number }): Types.MiniGameResult
	local correct = 0
	local adjacent = 0
	for i, id in ipairs(order) do
		if id == inst.correct[i] then
			correct += 1
		end
		if i > 1 and inst.correct[i - 1] == order[i - 1] and id == inst.correct[i] then
			adjacent += 1
		end
	end
	local n = #inst.correct
	local score = math.floor(((correct / n) * 0.7 + (adjacent / math.max(1, n - 1)) * 0.3) * 100)
	return { kind = "HistoryPuzzle", score = score, success = score >= 60, perfect = correct == n }
end

return HistoryPuzzle
