--! UI/AchievementToast.luau (achievement popups)
local UIBase = require(script.Parent.Parent.UI.UIBase)

export type AchievementToastApi = { Build: (parent: Instance) -> Frame, Pop: (self: Frame, name: string) -> () }

local AchievementToast = {} :: AchievementToastApi

function AchievementToast.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.3, 0, 0.12, 0), UDim2.new(0.35, 0, 0.02, 0), UIBase.Theme.accent)
	f.Name = "AchievementToast"
	f.Visible = false
	UIBase.Label(f, "", UDim2.new(1, -20, 1, -10), UDim2.new(0, 10, 0, 5)).Name = "Text"
	f.TextColor3 = Color3.fromRGB(20, 20, 20)
	return f
end

function AchievementToast.Pop(self: Frame, name: string)
	local t = self:FindFirstChild("Text")
	if t ~= nil then
		t.Text = "🏆 " .. name
	end
	self.Visible = true
	task.delay(3, function()
		if self:IsA("GuiObject") then
			self.Visible = false
		end
	end)
end

return AchievementToast
