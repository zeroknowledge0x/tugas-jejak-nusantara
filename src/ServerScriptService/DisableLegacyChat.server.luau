--! DisableLegacyChat.server.luau (ServerScriptService)
--! Disables Roblox's built-in (legacy) chat so the benign
--! "GetCore: PlayerBlockedEvent" CoreScript warning never fires.
--! The default chat scripts only load if Chat.LoadDefaultChat is true.
local ok, chat = pcall(function() return game:GetService("Chat") end)
if ok and chat then
	chat.LoadDefaultChat = false
	warn("[JN] Legacy chat disabled (LoadDefaultChat = false)")
end
