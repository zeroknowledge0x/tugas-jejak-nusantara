--! UI/SkillProgressUI.luau
local UIBase = require(script.Parent.Parent.UI.UIBase)
local SkillSystem = require(script.Parent.Parent.Systems.SkillSystem)
local Types = require(script.Parent.Parent.Types)

export type SkillProgressUIApi = { Build: (parent: Instance) -> Frame, Refresh: (self: Frame) -> () }

local SkillProgressUI = {} :: SkillProgressUIApi

function SkillProgressUI.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.3, 0, 0.4, 0), UDim2.new(0.02, 0, 0.05, 0), UIBase.Theme.panel)
	f.Name = "SkillProgressUI"
	UIBase.Label(f, "KEMAMPUAN", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 6))
	local body = UIBase.Frame(f, UDim2.new(1, -20, 1, -40), UDim2.new(0, 10, 0, 38), UIBase.Theme.bg)
	body.Name = "Body"
	SkillProgressUI.Refresh(f)
	return f
end

function SkillProgressUI.Refresh(self: Frame)
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
	for _, sid in ipairs(Types.SkillOrder) do
		local v = SkillSystem.GetValue(sid)
		local lvl = SkillSystem.GetLevel(sid)
		UIBase.Label(body, sid .. " T" .. lvl .. " (" .. v .. ")", UDim2.new(1, -8, 0, 24), UDim2.new(0, 4, 0, y))
		y += 28
	end
end

return SkillProgressUI
