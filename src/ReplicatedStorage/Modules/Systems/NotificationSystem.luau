--! NotificationSystem.luau
--! Toasts & achievement popups. Client-presented; server-safe queue.
--! Public API:
--!   NotificationSystem.Init()
--!   NotificationSystem.Toast(message: string, kind: string?)
--!   NotificationSystem.Achievement(id: string, title: string)
--!   NotificationSystem.OnToast: Signal(message, kind)
--!   NotificationSystem.OnAchievement: Signal(id, title)

local Signal = require(script.Parent.Parent.Util.Signal)

export type NotificationSystemApi = {
	Init: () -> (),
	Toast: (message: string, kind: string?) -> (),
	Achievement: (id: string, title: string) -> (),
	OnToast: Signal.Signal<string, string?>,
	OnAchievement: Signal.Signal<string, string>,
}

local NotificationSystem = {} :: NotificationSystemApi
NotificationSystem.OnToast = Signal.new()
NotificationSystem.OnAchievement = Signal.new()

function NotificationSystem.Init() end

function NotificationSystem.Toast(message: string, kind: string?)
	NotificationSystem.OnToast:Fire(message, kind or "info")
end

function NotificationSystem.Achievement(id: string, title: string)
	NotificationSystem.OnAchievement:Fire(id, title)
end

return NotificationSystem
