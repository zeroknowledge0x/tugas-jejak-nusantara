--! AudioManager.luau
--! Ambient loops, area BGM, NPC/SFX cues, mini-game & reward feedback.
--! Graceful no-op if assets absent (headless-safe).
--! Public API:
--!   AudioManager.Init(soundService: SoundService)
--!   AudioManager.PlayBgm(area: AreaId)
--!   AudioManager.SetAmbient(area: AreaId)
--!   AudioManager.Sfx(name: string)
--!   AudioManager.StopAll()
--!   AudioManager.OnSfx: Signal(name)
--!   AudioManager.ToggleMusic(): boolean
--!   AudioManager.ToggleSfx(): boolean

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type AudioManagerApi = {
	Init: (soundService: SoundService) -> (),
	PlayBgm: (area: Types.AreaId) -> (),
	SetAmbient: (area: Types.AreaId) -> (),
	Sfx: (name: string) -> (),
	StopAll: () -> (),
	ToggleMusic: () -> boolean,
	ToggleSfx: () -> boolean,
	OnSfx: Signal.Signal<string>,
}

local AudioManager = {} :: AudioManagerApi
AudioManager.OnSfx = Signal.new()

local service: SoundService? = nil
local currentBgm: Sound? = nil
local musicOn = true
local sfxOn = true

function AudioManager.Init(soundService: SoundService)
	service = soundService
end

function AudioManager.PlayBgm(area: Types.AreaId)
	if service == nil or not musicOn then
		return
	end
	AudioManager.OnSfx:Fire("bgm:" .. area)
end

function AudioManager.SetAmbient(area: Types.AreaId)
	if service == nil or not musicOn then
		return
	end
	AudioManager.OnSfx:Fire("ambient:" .. area)
end

function AudioManager.Sfx(name: string)
	if service == nil or not sfxOn then
		return
	end
	AudioManager.OnSfx:Fire(name)
end

function AudioManager.StopAll()
	if currentBgm ~= nil then
		currentBgm:Stop()
		currentBgm = nil
	end
end

function AudioManager.ToggleMusic(): boolean
	musicOn = not musicOn
	return musicOn
end

function AudioManager.ToggleSfx(): boolean
	sfxOn = not sfxOn
	return sfxOn
end

return AudioManager
