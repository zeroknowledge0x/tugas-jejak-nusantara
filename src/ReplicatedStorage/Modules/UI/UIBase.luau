--! UI/UIBase.luau
--! Shared helpers for building modern Roblox UI (ScreenGui + frames).
--! All screens are data-bound and use smooth transitions via Tween util.
--! Headless-safe: only uses Instance/UDim2/Color3 (no Player required at build).

local Tween = require(script.Parent.Parent.Util.Tween)

export type UITheme = {
	bg: Color3,
	panel: Color3,
	accent: Color3,
	text: Color3,
	font: Enum.Font,
}

export type UIBaseApi = {
	Theme: UITheme,
	Frame: (parent: Instance, size: UDim2, pos: UDim2, color: Color3) -> Frame,
	Label: (parent: Instance, text: string, size: UDim2, pos: UDim2) -> TextLabel,
	Button: (parent: Instance, text: string, size: UDim2, pos: UDim2, onClick: () -> ()) -> TextButton,
	FadeIn: (frame: GuiObject) -> (),
	FadeOut: (frame: GuiObject, onDone: () -> ()?) -> (),
}

local UIBase = {} :: UIBaseApi

UIBase.Theme = {
	bg = Color3.fromRGB(18, 20, 28),
	panel = Color3.fromRGB(30, 34, 46),
	accent = Color3.fromRGB(240, 180, 60),
	text = Color3.fromRGB(240, 240, 245),
	font = Enum.Font.Gotham,
}

function UIBase.Frame(parent: Instance, size: UDim2, pos: UDim2, color: Color3): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

function UIBase.Label(parent: Instance, text: string, size: UDim2, pos: UDim2): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = UIBase.Theme.text
	l.Font = UIBase.Theme.font
	l.TextScaled = true
	l.Parent = parent
	return l
end

function UIBase.Button(parent: Instance, text: string, size: UDim2, pos: UDim2, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = UIBase.Theme.accent
	b.TextColor3 = Color3.fromRGB(20, 20, 20)
	b.Font = UIBase.Theme.font
	b.Text = text
	b.TextScaled = true
	b.AutoButtonColor = true
	b.Parent = parent
	if onClick ~= nil then
		b.Activated:Connect(onClick)
	end
	return b
end

function UIBase.FadeIn(frame: GuiObject)
	frame.BackgroundTransparency = 1
	Tween.To(frame, { BackgroundTransparency = 0 }, { time = 0.25 })
end

function UIBase.FadeOut(frame: GuiObject, onDone: () -> ()?)
	Tween.To(frame, { BackgroundTransparency = 1 }, {
		time = 0.25,
		completed = function()
			if frame:IsA("GuiObject") then
				frame.Visible = false
			end
			if onDone ~= nil then
				onDone()
			end
		end,
	})
end

return UIBase
