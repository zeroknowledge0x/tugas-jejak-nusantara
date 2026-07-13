--! DialogueUI.luau
--! Branching dialogue panel with choices. Binds to DialogueSystem.
local Types = require(script.Parent.Parent.Types)
local UIBase = require(script.Parent.UIBase)
local DialogueSystem = require(script.Parent.Parent.Systems.DialogueSystem)

export type DialogueUIApi = {
	Build: (parent: Instance) -> Frame,
	Show: (self: Frame, node: Types.DialogueNode) -> (),
}

local DialogueUI = {} :: DialogueUIApi

function DialogueUI.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.6, 0, 0.3, 0), UDim2.new(0.2, 0, 0.65, 0), UIBase.Theme.panel)
	f.Name = "DialogueUI"
	f.Visible = false
	local text = UIBase.Label(f, "", UDim2.new(1, -20, 0.5, 0), UDim2.new(0, 10, 0, 8))
	text.Name = "Text"
	local choices = UIBase.Frame(f, UDim2.new(1, -20, 0.5, -10), UDim2.new(0, 10, 0.5, 5), UIBase.Theme.panel)
	choices.Name = "Choices"
	return f
end

function DialogueUI.Show(self: Frame, node: Types.DialogueNode)
	self.Visible = true
	local txt = self:FindFirstChild("Text")
	if txt ~= nil and txt:IsA("TextLabel") then
		txt.Text = node.speaker .. ": " .. node.text
	end
	local choices = self:FindFirstChild("Choices")
	if choices ~= nil then
		for _, c in ipairs(choices:GetChildren()) do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end
		local y = 0
		if node.choices ~= nil then
			for i, ch in ipairs(node.choices) do
				UIBase.Button(choices, ch.text, UDim2.new(1, -8, 0, 28), UDim2.new(0, 4, 0, y), function()
					DialogueSystem.Choose(i)
				end)
				y += 32
			end
		end
	end
end

return DialogueUI
