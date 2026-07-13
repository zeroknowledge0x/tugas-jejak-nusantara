--! MiniGames/HiddenObject.luau
--! Hidden object search (secrets/scavenger). Player locates items by clue.
--! Public API: HiddenObject.Create(cfg), HiddenObject.Evaluate(inst, foundIds)

local Types = require(script.Parent.Parent.Parent.Types)

export type HiddenObjectInstance = {
	kind: "HiddenObject",
	secretIds: { string },
}

local HiddenObject = {}

function HiddenObject.Create(cfg: table): HiddenObjectInstance
	return { kind = "HiddenObject", secretIds = (cfg and cfg.secretIds) or {} }
end

function HiddenObject.Evaluate(inst: HiddenObjectInstance, foundIds: { string }): Types.MiniGameResult
	local got = 0
	local set = {}
	for _, s in ipairs(inst.secretIds) do
		set[s] = true
	end
	for _, f in ipairs(foundIds) do
		if set[f] then
			got += 1
		end
	end
	local n = math.max(1, #inst.secretIds)
	local score = math.floor((got / n) * 100)
	return { kind = "HiddenObject", score = score, success = score >= 60, perfect = got == #inst.secretIds }
end

return HiddenObject
