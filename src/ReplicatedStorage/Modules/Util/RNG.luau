--! RNG.luau
--! Seedable RNG wrapper for deterministic mini-game layouts / secrets.

local RNG = {}
RNG.__index = RNG

function RNG.new(seed: number?)
	local self = setmetatable({}, RNG) :: any
	self._rng = Random.new(seed or os.clock())
	return self
end

function RNG:NextInteger(min: number, max: number): number
	return self._rng:NextInteger(min, max)
end

function RNG:NextNumber(min: number?, max: number?): number
	return self._rng:NextNumber(min or 0, max or 1)
end

function RNG:Pick<T>(list: { T }): T
	return list[self._rng:NextInteger(1, #list)]
end

function RNG:Shuffle<T>(list: { T }): { T }
	local out = table.clone(list)
	for i = #out, 2, -1 do
		local j = self._rng:NextInteger(1, i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

return RNG
