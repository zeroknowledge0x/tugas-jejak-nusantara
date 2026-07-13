--! MiniGames/Negotiation.luau
--! Market negotiation mini-game (Level 3). Player picks offers; a hidden fair
--! price exists; scoring rewards landing near fair value without overpaying.
--! Public API: Negotiation.Create(cfg), Negotiation.Evaluate(inst, offer)

local Types = require(script.Parent.Parent.Parent.Types)

export type NegotiationInstance = {
	kind: "Negotiation",
	fairPrice: number,
}

local Negotiation = {}

function Negotiation.Create(cfg: table): NegotiationInstance
	return {
		kind = "Negotiation",
		fairPrice = (cfg and cfg.fairPrice) or 5000,
	}
end

function Negotiation.Evaluate(inst: NegotiationInstance, offer: number): Types.MiniGameResult
	local diff = offer - inst.fairPrice
	local absd = math.abs(diff)
	-- best: exact fair; overpay penalized more than underpay (merchant won't sell)
	local penalty = diff > 0 and absd * 1.5 or absd
	local score = math.max(0, math.floor(100 - (penalty / inst.fairPrice) * 200))
	return { kind = "Negotiation", score = score, success = score >= 60, perfect = absd == 0 }
end

return Negotiation
