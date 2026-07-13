--! UI/PauseUI.luau
local UIBase = require(script.Parent.UIBase)

export type PauseUIApi = { Build: (parent: Instance, onResume: () -> (), onSettings: () -> ()) -> Frame }

local PauseUI = {} :: PauseUIApi

function PauseUI.Build(parent: Instance, onResume: () -> (), onSettings: () -> ()): Frame
	local f = UIBase.Frame(parent, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(0, 0, 0))
	f.BackgroundTransparency = 0.6
	f.Name = "PauseUI"
	f.Visible = false
	UIBase.Label(f, "JEDA", UDim2.new(0, 200, 0, 40), UDim2.new(0.5, -100, 0.3, -20))
	UIBase.Button(f, "Lanjut", UDim2.new(0, 200, 0, 36), UDim2.new(0.5, -100, 0.4, 0), onResume or function() end)
	UIBase.Button(
		f,
		"Pengaturan",
		UDim2.new(0, 200, 0, 36),
		UDim2.new(0.5, -100, 0.4, 44),
		onSettings or function() end
	)
	return f
end

return PauseUI
