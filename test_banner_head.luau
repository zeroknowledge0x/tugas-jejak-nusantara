-- headless mock test for GameClient banner (no real Roblox needed)
-- stub minimal Roblox API so we can prove the script does not crash before banner

local realWarn = warn
local printed = {}
local function myprint(...) table.insert(printed, table.concat({...}, " ")) end

-- fake instances
local function inst(kind)
	local t = { ClassName = kind or "Instance", Children = {}, Parent = nil }
	setmetatable(t, { __index = function(s,k)
		if k == "GetChildren" then return function() return s.Children end end
		if k == "WaitForChild" then return function(_,n) return inst(n) end end
		if k == "FindFirstChild" then return function(_,n) return inst(n) end end
		return rawget(s,k)
	end })
	return t
end

local services = {}
local function svc(name)
	if services[name] == nil then
		services[name] = inst(name)
	end
	return services[name]
end

game = {
	GetService = svc,
	PlaceId = 0,
}

local Players = inst("Players")
Players.LocalPlayer = inst("Player")
Players.LocalPlayer.PlayerGui = inst("PlayerGui")
svc("Players").LocalPlayer = Players.LocalPlayer

Instance = { new = function(kind) return inst(kind) end }
Enum = { Font = { GothamBold = "GothamBold" } }
Color3 = { fromRGB = function() return {} end }
UDim2 = { new = function() return {} end }
Vector3 = { new = function() return {} end }
BrickColor = { new = function() return {} end }
task = { delay = function() end, wait = function() end }
require = function() error("mock require") end

-- load only the banner portion: redefine require to fail safely
require = function() error("mock require") end

-- run the actual GameClient but stop after banner (we just want to prove banner shows)
local path = arg and arg[1] or "src/StarterPlayer/StarterPlayerScripts/GameClient.client.luau"
local f = loadfile(path)
if not f then
	realWarn("LOADFILE FAILED for " .. path)
else
	local ok, e = pcall(f)
	if not ok then realWarn("HEAD CRASHED: "..tostring(e)) end
end

realWarn("BANNER TEST DONE — if you saw 'JN GameClient STARTED' printed above, the script runs and banner code executes.")
