--! UI/InventoryUI.luau
local UIBase = require(script.Parent.UIBase)
local InventorySystem = require(script.Parent.Parent.Systems.InventorySystem)

export type InventoryUIApi = { Build: (parent: Instance) -> Frame, Refresh: (self: Frame) -> () }

local InventoryUI = {} :: InventoryUIApi

function InventoryUI.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.5, 0, 0.7, 0), UDim2.new(0.25, 0, 0.15, 0), UIBase.Theme.panel)
	f.Name = "InventoryUI"
	f.Visible = false
	UIBase.Label(f, "INVENTARIS", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 6))
	local body = UIBase.Frame(f, UDim2.new(1, -20, 1, -44), UDim2.new(0, 10, 0, 38), UIBase.Theme.bg)
	body.Name = "Body"
	InventoryUI.Refresh(f)
	return f
end

function InventoryUI.Refresh(self: Frame)
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
	for item, count in pairs(InventorySystem.GetAll()) do
		UIBase.Label(body, item .. " x" .. count, UDim2.new(1, -8, 0, 24), UDim2.new(0, 4, 0, y))
		y += 28
	end
end

return InventoryUI
