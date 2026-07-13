--! UI/QuestTracker.luau
--! Live quest tracker (top-right). Binds to QuestSystem active quests.
local Types = require(script.Parent.Parent.Types)
local UIBase = require(script.Parent.UIBase)
local QuestSystem = require(script.Parent.Parent.Systems.QuestSystem)

export type QuestTrackerApi = {
	Build: (parent: Instance) -> Frame,
	Refresh: (self: Frame) -> (),
}

local QuestTracker = {} :: QuestTrackerApi

function QuestTracker.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.28, 0, 0.35, 0), UDim2.new(0.7, 0, 0.02, 0), UIBase.Theme.panel)
	f.Name = "QuestTracker"
	UIBase.Label(f, "MISI", UDim2.new(1, -10, 0, 24), UDim2.new(0, 5, 0, 4))
	local list = UIBase.Frame(f, UDim2.new(1, -10, 1, -30), UDim2.new(0, 5, 0, 28), UIBase.Theme.panel)
	list.Name = "List"
	QuestTracker.Refresh(f)
	return f
end

function QuestTracker.Refresh(self: Frame)
	local list = self:FindFirstChild("List")
	if list == nil then
		return
	end
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local y = 0
	for _, q in ipairs(QuestSystem.GetActive()) do
		UIBase.Label(
			list,
			q.title .. " (" .. q.progress .. "/" .. q.goal .. ")",
			UDim2.new(1, -8, 0, 20),
			UDim2.new(0, 4, 0, y)
		)
		y += 22
	end
end

return QuestTracker
