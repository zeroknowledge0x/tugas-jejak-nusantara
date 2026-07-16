# How to test

1. Delete old extract folder
2. Download ZIP (`main`)
3. Open `places/JejakNusantara.rbxlx` (not Studio Recent `.rbxl`)
4. **Break On Error → Never**
5. Play

## Expected
- Main menu with Start
- Output: `JEJAK NUSANTARA v4.0 - READY!` and `GameClient v4.0 - Loading...`
- NPCs with ProximityPrompt (E)
- After Start: HUD level/XP/coins

## Ignore
- `PlayerBlockedEvent` / `PlatformLeaderboard` (engine)
- If viewport freezes: press **F5 / Resume**, then set Break On Error Never
