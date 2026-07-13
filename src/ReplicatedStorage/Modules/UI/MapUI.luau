--! UI/MapUI.luau (world map with area states)
local UIBase = require(script.Parent.UIBase)
local AreaManager = require(script.Parent.Parent.Systems.AreaManager)

export type MapUIApi = { Build: (parent: Instance) -> Frame, Refresh: (self: Frame) -> () }

local MapUI = {} :: MapUIApi

function MapUI.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.6, 0, 0.7, 0), UDim2.new(0.2, 0, 0.15, 0), UIBase.Theme.panel)
	f.Name = "MapUI"
	f.Visible = false
	UIBase.Label(f, "PETA DUNIA", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 6))
	local body = UIBase.Frame(f, UDim2.new(1, -20, 1, -44), UDim2.new(0, 10, 0, 38), UIBase.Theme.bg)
	body.Name = "Body"
	MapUI.Refresh(f)
	return f
end

function MapUI.Refresh(self: Frame)
	local body = self:FindFirstChild("Body")
	if body == nil then
		return
	end
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local y = 0
	for id, state in pairs(AreaManager.GetStates()) do
		local mark = state.unlocked and (state.entered and "✓" or "🔒?") or "🔒"
		UIBase.Label(body, mark .. " " .. id, UDim2.new(1, -8, 0, 24), UDim2.new(0, 4, 0, y))
		y += 28
	end
end

return MapUI
