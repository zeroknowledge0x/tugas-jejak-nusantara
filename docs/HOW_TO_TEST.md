# How to test Jejak Nusantara (Studio ZIP flow)

## Critical
You open the **prebuilt place file**, not the source tree:

```
places/JejakNusantara.rbxlx
```

## Ritual (do not skip)
1. **Delete** the old extracted folder completely.
2. GitHub → repo `zeroknowledge0x/tugas-jejak-nusantara` → **Code → Download ZIP** (branch `main`).
3. Extract to a **new** folder name (example: `jn_fresh`).
4. Fully quit Roblox Studio (Task Manager: no `RobloxStudioBeta.exe`).
5. Open **only** `jn_fresh/places/JejakNusantara.rbxlx` (double-click that file).
6. Press **Play** (not just Run-server-only).

## What you must see
- Green grass baseplate + yellow spawn pad
- Blue neon block labeled **BUDI**
- Top bar: `JEJAK NUSANTARA — Play mode…`
- Output: `[JN] GameClient STARTED` then `[JN] WorldBuilder ready…`
- After ~1s: dialogue UI (`Halo! Mau belajar angklung?`)

## Ignore these (engine noise, not your code)
- `GetCore: PlayerBlockedEvent… ChatMain`
- `PlatformLeaderboard…`

## Do NOT reopen from Studio “Recent”
Studio Recent may open an old saved `.rbxl` from Documents. Always open the new ZIP’s `.rbxlx`.
