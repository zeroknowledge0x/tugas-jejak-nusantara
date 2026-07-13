--! UI/AreaProgressUI.luau (per-area completion)
local UIBase = require(script.Parent.Parent.UI.UIBase)
local AreaManager = require(script.Parent.Parent.Systems.AreaManager)

export type AreaProgressUIApi = { Build: (parent: Instance) -> Frame, Refresh: (self: Frame) -> () }

local AreaProgressUI = {} :: AreaProgressUIApi

function AreaProgressUI.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.3, 0, 0.4, 0), UDim2.new(0.02, 0, 0.5, 0), UIBase.Theme.panel)
	f.Name = "AreaProgressUI"
	UIBase.Label(f, "PROGRES AREA", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 6))
	local body = UIBase.Frame(f, UDim2.new(1, -20, 1, -40), UDim2.new(0, 10, 0, 38), UIBase.Theme.bg)
	body.Name = "Body"
	AreaProgressUI.Refresh(f)
	return f
end

function AreaProgressUI.Refresh(self: Frame)
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
		local pct = state.secretsTotal > 0 and math.floor((state.secretsFound / state.secretsTotal) * 100) or 0
		UIBase.Label(
			body,
			id .. " — rahasia " .. pct .. "%" .. (state.mainComplete and " ✓" or ""),
			UDim2.new(1, -8, 0, 24),
			UDim2.new(0, 4, 0, y)
		)
		y += 28
	end
end

return AreaProgressUI
