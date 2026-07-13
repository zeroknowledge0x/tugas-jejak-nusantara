--! UI/EndingSummaryUI.luau (final ending based on whole journey)
local UIBase = require(script.Parent.Parent.UI.UIBase)
local EndingSystem = require(script.Parent.Parent.Systems.EndingSystem)
local Data = require(script.Parent.Parent.Data.Data)

export type EndingSummaryUIApi =
	{ Build: (parent: Instance) -> Frame, Show: (self: Frame, ending: Types.EndingId) -> () }

local EndingSummaryUI = {} :: EndingSummaryUIApi

function EndingSummaryUI.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.7, 0, 0.8, 0), UDim2.new(0.15, 0, 0.1, 0), UIBase.Theme.panel)
	f.Name = "EndingSummaryUI"
	f.Visible = false
	local title = UIBase.Label(f, "", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 20))
	title.Name = "Title"
	title.TextSize = 36
	local desc = UIBase.Label(f, "", UDim2.new(1, -40, 0.6, 0), UDim2.new(0, 20, 0, 90))
	desc.Name = "Desc"
	desc.TextWrapped = true
	return f
end

function EndingSummaryUI.Show(self: Frame, ending: Types.EndingId)
	self.Visible = true
	local sum = Data.Endings.summaries[ending]
	local title = self:FindFirstChild("Title")
	local desc = self:FindFirstChild("Desc")
	if title ~= nil and sum ~= nil then
		title.Text = sum.title
	end
	if desc ~= nil and sum ~= nil then
		desc.Text = sum.desc
	end
end

return EndingSummaryUI
