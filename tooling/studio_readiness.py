#!/usr/bin/env python3
"""Studio readiness checks for Jejak Nusantara.

Validates things that headless luau smoke tests cannot:
1. Entry scripts are Script / LocalScript (not ModuleScript)
2. Place tree has expected folders
3. Require path depths look correct relative to file location
"""
from __future__ import annotations
import re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
RBXLX = ROOT / "build" / "JejakNusantara.rbxlx"
fail = 0

def ok(msg): print(f"  PASS: {msg}")
def bad(msg):
    global fail
    fail += 1
    print(f"  FAIL: {msg}")

print("[studio-readiness] entry script classes in .rbxlx")
if not RBXLX.exists():
    bad("build/JejakNusantara.rbxlx missing — run rojo build first")
else:
    text = RBXLX.read_text(encoding="utf-8", errors="ignore")
    def class_of(name: str) -> str | None:
        # Find Item that contains Name=name and capture class attribute of that Item
        # Pattern: <Item class="X" ...> ... <string name="Name">NAME</string>
        for m in re.finditer(r'<Item class="([^"]+)"[^>]*>\s*<Properties>\s*<string name="Name">([^<]+)</string>', text):
            if m.group(2) == name:
                return m.group(1)
        return None
    gs = class_of("GameServer")
    gc = class_of("GameClient")
    if gs == "Script": ok(f"GameServer is Script")
    else: bad(f"GameServer class is {gs!r}, expected Script (use .server.luau)")
    if gc == "LocalScript": ok(f"GameClient is LocalScript")
    else: bad(f"GameClient class is {gc!r}, expected LocalScript (use .client.luau)")
    for name in ["JN", "Modules", "Systems", "UI", "Data", "MiniGames", "Util"]:
        if f'<string name="Name">{name}</string>' in text:
            ok(f"place contains {name}")
        else:
            bad(f"place missing folder/module {name}")

print("[studio-readiness] require path depth vs filesystem location")
# Rules:
# - file under Modules/Systems/*.luau (not MiniGames): Types = Parent.Parent.Types
# - file under Modules/Systems/MiniGames/*.luau: Types = Parent.Parent.Parent.Types
# - file under Modules/UI/*.luau: Types = Parent.Parent.Types; Systems = Parent.Parent.Systems
# - file under Modules/*.luau: Types = Parent.Types
# - UIController must not require script.Parent.UI (UI is sibling of Systems under Modules)

checks = []
for p in SRC.rglob("*.luau"):
    rel = p.relative_to(SRC).as_posix()
    body = p.read_text(encoding="utf-8")
    requires = re.findall(r'require\(([^)]+)\)', body)
    for req in requires:
        req = req.strip()
        if "script.Parent" not in req:
            continue
        depth = req.count("Parent")
        # flag obvious mistakes
        if "Systems/UIController" in rel or rel.endswith("Systems/UIController.luau"):
            if "script.Parent.UI" in req or "script.Parent.Types" == req or req.endswith("script.Parent.Types"):
                bad(f"{rel}: bad UIController require {req}")
                continue
        if "/MiniGames/" in rel:
            if "script.Parent.Parent.Types" in req and "Parent.Parent.Parent.Types" not in req:
                bad(f"{rel}: MiniGames Types depth too shallow: {req}")
                continue
            if "script.Parent.Parent.Util" in req and "Parent.Parent.Parent.Util" not in req:
                bad(f"{rel}: MiniGames Util depth too shallow: {req}")
                continue
        checks.append((rel, req, depth))

# positive: UIController should use Parent.Parent.UI
uic = SRC / "ReplicatedStorage/Modules/Systems/UIController.luau"
if uic.exists():
    t = uic.read_text()
    if "script.Parent.Parent.UI.UIBase" in t and "script.Parent.QuestSystem" in t:
        ok("UIController require paths use Modules + sibling Systems")
    else:
        bad("UIController require paths still incorrect")

# MiniGames sample
rhythm = SRC / "ReplicatedStorage/Modules/Systems/MiniGames/Rhythm.luau"
if rhythm.exists():
    t = rhythm.read_text()
    if "script.Parent.Parent.Parent.Types" in t:
        ok("MiniGames Rhythm Types depth is Parent.Parent.Parent")
    else:
        bad("MiniGames Rhythm Types depth still wrong")

print("[studio-readiness] entry file extensions")
if (SRC / "ServerScriptService/GameServer.server.luau").exists():
    ok("GameServer.server.luau present")
else:
    bad("missing GameServer.server.luau")
if (SRC / "StarterPlayer/StarterPlayerScripts/GameClient.client.luau").exists():
    ok("GameClient.client.luau present")
else:
    bad("missing GameClient.client.luau")

if fail:
    print(f"== STUDIO READINESS FAILED ({fail}) ==")
    sys.exit(1)
print("== STUDIO READINESS PASSED ==")
sys.exit(0)
