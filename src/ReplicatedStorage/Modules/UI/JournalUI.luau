--! UI/JournalUI.luau
--! Journal with categories (locations, NPCs, food, music, dance, artifacts,
--! history, discoveries, secrets, puzzle progress, completed quests).
local UIBase = require(script.Parent.UIBase)
local JournalSystem = require(script.Parent.Parent.Systems.JournalSystem)
local Types = require(script.Parent.Parent.Types)

export type JournalUIApi = { Build: (parent: Instance) -> Frame, Refresh: (self: Frame) -> () }

local JournalUI = {} :: JournalUIApi

function JournalUI.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.7, 0, 0.8, 0), UDim2.new(0.15, 0, 0.1, 0), UIBase.Theme.panel)
	f.Name = "JournalUI"
	f.Visible = false
	UIBase.Label(
		f,
		"JURNAL  (Lengkap: " .. math.floor(JournalSystem.GetCompletion()) .. "%)",
		UDim2.new(1, -20, 0, 30),
		UDim2.new(0, 10, 0, 6)
	)
	local body = UIBase.Frame(f, UDim2.new(1, -20, 1, -44), UDim2.new(0, 10, 0, 38), UIBase.Theme.bg)
	body.Name = "Body"
	JournalUI.Refresh(f)
	return f
end

function JournalUI.Refresh(self: Frame)
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
	local cats: { Types.JournalCategory } = {
		"locations",
		"npcs",
		"food",
		"music",
		"dance",
		"artifacts",
		"history",
		"discoveries",
		"secrets",
		"puzzleProgress",
		"completedQuests",
	}
	for _, cat in ipairs(cats) do
		local entries = JournalSystem.GetCategory(cat)
		if #entries > 0 then
			UIBase.Label(
				body,
				cat .. ": " .. table.concat(entries, ", "),
				UDim2.new(1, -8, 0, 36),
				UDim2.new(0, 4, 0, y)
			)
			y += 40
		end
	end
end

return JournalUI
