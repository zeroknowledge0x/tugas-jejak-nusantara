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

local Types = require(script.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Util.Signal)

export type AudioManagerApi = {
	Init: (soundService: SoundService) -> (),
	PlayBgm: (area: Types.AreaId) -> (),
	SetAmbient: (area: Types.AreaId) -> (),
	Sfx: (name: string) -> (),
	StopAll: () -> (),
	OnSfx: Signal.Signal<string>,
}

local AudioManager = {} :: AudioManagerApi
AudioManager.OnSfx = Signal.new()

local service: SoundService? = nil
local currentBgm: Sound? = nil

function AudioManager.Init(soundService: SoundService)
	service = soundService
end

function AudioManager.PlayBgm(area: Types.AreaId)
	if service == nil then
		return
	end
	-- Asset assignments live in Data in Phase 6; here we only guard existence.
	AudioManager.OnSfx:Fire("bgm:" .. area)
end

function AudioManager.SetAmbient(area: Types.AreaId)
	if service == nil then
		return
	end
	AudioManager.OnSfx:Fire("ambient:" .. area)
end

function AudioManager.Sfx(name: string)
	if service == nil then
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

return AudioManager
