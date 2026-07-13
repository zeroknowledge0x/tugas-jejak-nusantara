--! UI/SettingsUI.luau (audio/music volume, sfx toggle)
local UIBase = require(script.Parent.UIBase)
local AudioManager = require(script.Parent.Parent.Systems.AudioManager)

export type SettingsUIApi = { Build: (parent: Instance) -> Frame }

local SettingsUI = {} :: SettingsUIApi

function SettingsUI.Build(parent: Instance): Frame
	local f = UIBase.Frame(parent, UDim2.new(0.5, 0, 0.6, 0), UDim2.new(0.25, 0, 0.2, 0), UIBase.Theme.panel)
	f.Name = "SettingsUI"
	f.Visible = false
	UIBase.Label(f, "PENGATURAN", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 6))
	UIBase.Button(f, "Musik: Nyala", UDim2.new(1, -40, 0, 32), UDim2.new(0, 20, 0, 50), function(b)
		local on = AudioManager.ToggleMusic()
		b.Text = on and "Musik: Nyala" or "Musik: Mati"
	end)
	UIBase.Button(f, "SFX: Nyala", UDim2.new(1, -40, 0, 32), UDim2.new(0, 20, 0, 90), function(b)
		local on = AudioManager.ToggleSfx()
		b.Text = on and "SFX: Nyala" or "SFX: Mati"
	end)
	return f
end

return SettingsUI
