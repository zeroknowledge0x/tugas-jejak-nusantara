# Jejak Nusantara (tugas)

Playable Roblox edu-game: 5 NPCs, 4 regions, quiz, XP/level/coins, journal, 3 endings.

Built from the proven **jejak-nusantara-final v4.0** single-script architecture (CompleteGame + GameClient), not the broken modular UI tree.

## Play (ZIP download)

1. Download ZIP from `main`
2. Open **`places/JejakNusantara.rbxlx`** in Roblox Studio
3. Set **Break On Error → Never** (script editor debug menu)
4. Press **Play**

You should see:
- Main menu **JEJAK NUSANTARA** → Start
- Green world + campus + 5 NPCs + portals
- Talk (E) → dialogue → portals → quiz

## Source

| File | Role |
|------|------|
| `src/ServerScriptService/CompleteGame.server.luau` | World, NPCs, portals, remotes, save, quiz |
| `src/StarterPlayer/StarterPlayerScripts/GameClient.client.luau` | Menu, HUD, dialogue, quiz, journal, ending |

## Docs

GDD PDFs + TDD live under `docs/`.
