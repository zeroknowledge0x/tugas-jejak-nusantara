--! Table.luau
--! Small table utilities. Avoids reimplementing in every system.

local Table = {}

function Table.clone<T>(t: { [any]: T }): { [any]: T }
	local out = {}
	for k, v in pairs(t) do
		out[k] = v
	end
	return out
end

function Table.keys<T>(t: { [any]: T }): { any }
	local out = {}
	for k, _ in pairs(t) do
		table.insert(out, k)
	end
	return out
end

function Table.count(t: { [any]: any }): number
	local n = 0
	for _, _ in pairs(t) do
		n += 1
	end
	return n
end

function Table.shallowEqual(a: { [any]: any }, b: { [any]: any }): boolean
	if Table.count(a) ~= Table.count(b) then
		return false
	end
	for k, v in pairs(a) do
		if b[k] ~= v then
			return false
		end
	end
	return true
end

function Table.firstKey<T>(t: { [any]: T }): any
	for k, _ in pairs(t) do
		return k
	end
	return nil
end

return Table
