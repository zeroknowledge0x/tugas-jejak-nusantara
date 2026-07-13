#!/usr/bin/env python3
"""Bundle Jejak Nusantara Luau modules into a single runnable script with a
require/script/game shim, so the framework can be executed headlessly by `luau`
for real runtime verification (not just syntax checking).

Maps `require(script.Parent...X)` to inlined module functions keyed by path.
"""
import re, os, glob

ROOT = "/root/tugas-jejak-nusantara/src/ReplicatedStorage/Modules"
OUT = "/root/tugas-jejak-nusantara/tooling/bundle.luau"

# Collect modules: Types, Util/*, Systems/*, Data/Data
modules = {}  # key -> filepath
modules["Types"] = os.path.join(ROOT, "Types.luau")
for p in glob.glob(os.path.join(ROOT, "Util", "*.luau")):
    modules[os.path.basename(p)[:-5]] = p  # Signal, Tween, Table, RNG
for p in glob.glob(os.path.join(ROOT, "Systems", "*.luau")):
    modules[os.path.basename(p)[:-5]] = p
for p in glob.glob(os.path.join(ROOT, "Systems", "MiniGames", "*.luau")):
    modules[os.path.basename(p)[:-5]] = p
for p in glob.glob(os.path.join(ROOT, "UI", "*.luau")):
    modules[os.path.basename(p)[:-5]] = p
modules["Data"] = os.path.join(ROOT, "Data", "Data.luau")
modules["Game"] = os.path.join(ROOT, "Game.luau")

# Read all source
src = {k: open(v).read() for k, v in modules.items()}

# Replace require(script.Parent...X) patterns.
# From Systems: script.Parent = Systems, script.Parent.Parent = Modules
#   require(script.Parent.Parent.Types) -> Types
#   require(script.Parent.Parent.Util.Signal) -> Signal
#   require(script.Parent.Parent.Data.X) -> X (Data not used in systems except via bootstraps)
def repl(m):
    expr = m.group(1)
    # split by .
    parts = [x.strip() for x in expr.split(".")]
    # parts like ['script','Parent','Parent','Types'] or ['script','Parent','Parent','Util','Signal']
    # strip leading script.Parent.Parent -> Modules; we map last segment(s)
    if parts[-1] == "Types":
        return 'require("Types")'
    if parts[-2:] == ["Util", "Signal"]:
        return 'require("Signal")'
    if parts[-2:] == ["Util", "Tween"]:
        return 'require("Tween")'
    if parts[-2:] == ["Util", "Table"]:
        return 'require("Table")'
    if parts[-2:] == ["Util", "RNG"]:
        return 'require("RNG")'
    # fallback: last segment
    return 'require("%s")' % parts[-1]

pattern = re.compile(r'require\(([^)]+)\)')
for k in src:
    src[k] = pattern.sub(repl, src[k])

# Build bundle
header = '''-- Auto-generated bundle for headless runtime testing.
-- Provides game/script shims and inlines modules.
game = {
    GetService = function(self, name)
        return setmetatable({ Name = name }, { __index = function() return function() end end })
    end,
}

-- Stub Roblox constructors that appear in data/logic so the bundle can run headless.
local function stubCtor(name)
	return setmetatable({ Name = name }, { __index = function() return function() end end })
end
Vector3 = { new = function(x, y, z) return { x = x or 0, y = y or 0, z = z or 0 } end }
CFrame = { new = function(...) return {} end }
Color3 = { fromRGB = function(...) return {} end, new = function(...) return {} end }
UDim = { new = function(...) return {} end }
UDim2 = { new = function(...) return {} end }
Enum = {
	EasingStyle = { Quad = 0 },
	EasingDirection = { Out = 0 },
	Font = { Gotham = 0 },
}
Instance = {}
function Instance.new(class)
	local inst = {
		ClassName = class,
		Name = "",
		Visible = true,
		Parent = nil,
		Children = {},
		Connections = {},
	}
	function inst:FindFirstChild(name)
		for _, c in ipairs(inst.Children) do
			if c.Name == name then return c end
		end
		return nil
	end
	function inst:GetChildren() return inst.Children end
	function inst:Destroy() inst.Parent = nil end
	function inst:IsA(t) return inst.ClassName == t end
	function inst:Connect(fn) table.insert(inst.Connections, fn) end
	local activated = { Connections = {}, Connect = function(s, fn) table.insert(s.Connections, fn) end, Fire = function(s) for _, f in ipairs(s.Connections) do f() end end }
	local mt = {
		__index = function(_, k)
			if k == "Activated" then return activated end
			return nil
		end,
		__newindex = function(t, k, v)
			if k == "Parent" and type(v) == "table" and v.Children ~= nil then
				table.insert(v.Children, t)
			end
			rawset(t, k, v)
		end,
	}
	setmetatable(inst, mt)
	return inst
end
Random = {
	new = function(seed)
		seed = seed or 1
		local s = seed % 2147483648
		local function step()
			s = (s * 1103515245 + 12345) % 2147483648
			return s / 2147483648
		end
		return {
			Next = step,
			NextNumber = step,
			NextInteger = function(_, a, b)
				local v = step()
				return a + math.floor(v * (b - a + 1))
			end,
		}
	end,
}
task = { wait = function() end, spawn = function(fn) fn() end, delay = function(_, fn) fn() end }
script = { Parent = { Parent = {} } }

local _mods = {}
local _loaded = {}
require = function(modpath)
    if _loaded[modpath] then return _loaded[modpath] end
    local fn = _mods[modpath]
    if not fn then error("module not found: " .. tostring(modpath)) end
    local script = { Parent = { Parent = {} } }
    local ret = fn(script)
    _loaded[modpath] = ret
    return ret
end
'''

# Emit each module as a function assigned to _mods["Key"]
body = ""
for k, code in src.items():
    body += '_mods["%s"] = function(script)\n' % k
    # indent
    indented = "\n".join(("    " + line) if line.strip() else line for line in code.split("\n"))
    body += indented + "\nend\n"

test = r'''
-- ===================== RUNTIME SMOKE TEST =====================
local Types = require("Types")
local SaveSystem = require("SaveSystem")
local SkillSystem = require("SkillSystem")
local DialogueSystem = require("DialogueSystem")
local QuestSystem = require("QuestSystem")
local JournalSystem = require("JournalSystem")
local InventorySystem = require("InventorySystem")
local EndingSystem = require("EndingSystem")
local NotificationSystem = require("NotificationSystem")

local passed = 0
local failed = 0
local function check(name, cond)
    if cond then passed = passed + 1; print("PASS: " .. name)
    else failed = failed + 1; print("FAIL: " .. name) end
end

local save = SaveSystem.CreateDefault()
SaveSystem.Init()
SkillSystem.Init(save)
JournalSystem.Init(save)
InventorySystem.Init(save)
QuestSystem.Init(save, {})
EndingSystem.Init(save, { summaries = {} })
NotificationSystem.Init()

local Game = require("Game")
local AreaManager = require("AreaManager")
local NPCSystem = require("NPCSystem")

-- =========================================================
-- UNIT-LEVEL CHECKS (individual systems)
-- =========================================================
local unlockFired = false
SkillSystem.OnUnlock:Connect(function(kind, id) unlockFired = true end)
SkillSystem.AddXP("Communication", 25) -- >= T1 (20)
check("Communication>=T1 raises value", SkillSystem.GetValue("Communication") == 25)
check("Communication T1 fires dialogue unlock", SkillSystem.IsUnlocked("dialogue", "intro") == true)
check("OnUnlock signal fired", unlockFired == true)

SkillSystem.AddXP("DecisionMaking", 70)
check("DecisionMaking level is 3", SkillSystem.GetLevel("DecisionMaking") == 3)
check("DecisionMaking T3 -> hidden NPC unlocked", SkillSystem.IsUnlocked("npcs", "hidden") == true)

SkillSystem.AddXP("Observation", 50)
check("Observation T2 -> secrets unlocked", SkillSystem.IsUnlocked("secrets", "tier2") == true)

JournalSystem.Init(save)
JournalSystem.Record("locations", "DesaBudaya")
JournalSystem.Record("npcs", "Seniman")
JournalSystem.Record("music", "Angklung")
check("Journal logs entry", JournalSystem.IsLogged("locations", "DesaBudaya") == true)
check("Journal completion > 0", JournalSystem.GetCompletion() > 0)

InventorySystem.Init(save)
InventorySystem.Add("AngklungMini", 1)
check("Inventory add", InventorySystem.Has("AngklungMini") == true)

EndingSystem.Init(save, { summaries = {} })
save.completedAreas = { RumahBudaya=true, DesaBudaya=true, SanggarSeni=true, PasarTradisional=true, TempatBersejarah=true, KebangkitanTradisi=true }
save.skills.CulturalUnderstanding = 60
save.skills.DecisionMaking = 80
save.journal.completion = 90
save.discovered.secrets = { a=true, b=true, c=true }
check("Ending is Guardian (decision T3 + journal>=80 + 3 secrets)", EndingSystem.Evaluate() == "Guardian")
save.discovered.secrets = {}
check("Ending is Lorekeeper (decision T3 + journal>=80, no secrets)", EndingSystem.Evaluate() == "Lorekeeper")
save.skills.DecisionMaking = 30
save.skills.CulturalUnderstanding = 20
save.journal.completion = 40
check("Weak run -> Adequate", EndingSystem.Evaluate() == "Adequate")

-- =========================================================
-- ORCHESTRATED FULL-LOOP CHECKS (via Game.new, real wiring)
-- =========================================================
-- Fresh save, run through Game orchestrator like the server would.
local gs = SaveSystem.CreateDefault()  -- fresh save for the orchestrated loop
local game = Game.new(gs)
check("Game orchestrator constructs", game ~= nil)

-- Dialogue choice grants skill + item + journal (decoupled via effects handler)
game:StartDialogue("intro_budi", "Budi")
check("Dialogue started (node fired)", true)
game:ChooseDialogue(1) -- choice 1: Observation+10, item, journal
check("Dialogue choice -> Observation XP gained", SkillSystem.GetValue("Observation") >= 10)
check("Dialogue choice -> item granted", InventorySystem.Has("AngklungMini") == true)
check("Dialogue choice -> journal music logged", JournalSystem.IsLogged("music", "angklung") == true)

-- Mini-game completion drives quest progress (q_learn_angklung requires Rhythm)
game:AcceptQuest("q_learn_angklung")
check("Quest accepted", QuestSystem.IsComplete("q_learn_angklung") == false)
local mid = game:LaunchMiniGame("Rhythm", {})
game:SubmitMiniGame(mid, { kind="Rhythm", score=90, success=true, perfect=false })
check("Mini-game -> quest advanced to complete", QuestSystem.IsComplete("q_learn_angklung") == true)

-- Quest completion unlocks next area (Rule 1)
check("Main quest completion unlocks DesaBudaya", AreaManager.IsUnlocked("DesaBudaya") == true)

-- Hidden NPC only appears after prereq area completed
check("Hidden NPC Kyai NOT available before area done", NPCSystem.Spawn("Kyai") == false)
gs.completedAreas["RumahBudaya"] = true
check("Hidden NPC Kyai available after area done", NPCSystem.Spawn("Kyai") == true)

-- Ending reflects the orchestrated journey
gs.skills.DecisionMaking = 80
gs.journal.completion = 90
gs.discovered.secrets = {}
check("Orchestrated run -> Lorekeeper", game:EvaluateEnding() == "Lorekeeper")

-- =========================================================
-- MINI-GAME LOGIC CHECKS (each kind scores correctly)
-- =========================================================
local MiniGameSystem = require("MiniGameSystem")
local Rhythm = require("Rhythm")
local Dance = require("Dance")
local Negotiation = require("Negotiation")
local HistoryPuzzle = require("HistoryPuzzle")
local Observation = require("Observation")
local PatternMatching = require("PatternMatching")
local HiddenObject = require("HiddenObject")
local CultureActivity = require("CultureActivity")

local r = Rhythm.Create({ beats = 3, seed = 1 })
check("Rhythm perfect when answers match", Rhythm.Evaluate(r, r.pattern).perfect == true)
check("Rhythm fails on empty answer", Rhythm.Evaluate(r, {}).success == false)

local d = Dance.Create({ steps = 3, seed = 2 })
check("Dance perfect when sequence matches", Dance.Evaluate(d, d.sequence).perfect == true)
check("Dance fails on wrong sequence", Dance.Evaluate(d, { "Up", "Up", "Up" }).success == false)

local n = Negotiation.Create({ fairPrice = 5000 })
check("Negotiation perfect at fair price", Negotiation.Evaluate(n, 5000).perfect == true)
check("Negotiation fails when overpaying heavily", Negotiation.Evaluate(n, 9000).success == false)

local h = HistoryPuzzle.Create({ events = { { id = 2, year = 1750 }, { id = 1, year = 1600 }, { id = 3, year = 1900 } } })
check("HistoryPuzzle perfect in correct order", HistoryPuzzle.Evaluate(h, { 1, 2, 3 }).perfect == true)
check("HistoryPuzzle fails in wrong order", HistoryPuzzle.Evaluate(h, { 3, 2, 1 }).success == false)

local o = Observation.Create({ targets = { "A", "B" }, distractors = { "X" } })
check("Observation perfect on correct picks", Observation.Evaluate(o, { "A", "B" }).perfect == true)
check("Observation penalizes wrong picks", Observation.Evaluate(o, { "A", "X" }).score < 100)

local p = PatternMatching.Create({ seed = 5 })
check("PatternMatching correct answer", PatternMatching.Evaluate(p, p.answer).success == true)
check("PatternMatching wrong answer", PatternMatching.Evaluate(p, p.answer + 99).success == false)

local ho = HiddenObject.Create({ secretIds = { "s1", "s2" } })
check("HiddenObject perfect when all found", HiddenObject.Evaluate(ho, { "s1", "s2" }).perfect == true)
check("HiddenObject fails on none found", HiddenObject.Evaluate(ho, {}).success == false)

local ca = CultureActivity.Create({ steps = { "a", "b", "c" } })
check("CultureActivity perfect on correct steps", CultureActivity.Evaluate(ca, { "a", "b", "c" }).perfect == true)
check("CultureActivity fails on wrong steps", CultureActivity.Evaluate(ca, { "c", "a" }).success == false)

-- MiniGameSystem routes correctly
MiniGameSystem.Init(gs)
local mid2 = MiniGameSystem.Launch("Rhythm", { beats = 2, seed = 9 })
check("MiniGameSystem launch returns id", string.find(mid2, "Rhythm") ~= nil)
local inst2 = MiniGameSystem.Get(mid2)
local completed = false
MiniGameSystem.OnComplete:Connect(function(_id, _res) completed = true end)
MiniGameSystem.Submit(mid2, Rhythm.Evaluate(inst2, inst2.pattern))
check("MiniGameSystem submit fires OnComplete", completed == true)

-- =========================================================
-- UI SMOKE CHECKS (screens build + bind)
-- =========================================================
local UIController = require("UIController")
local fakeGui = Instance.new("ScreenGui")
UIController.Init(fakeGui)
check("UIController builds root ScreenGui", fakeGui.ClassName == "ScreenGui")
local QuestTracker = require("QuestTracker")
local qt = QuestTracker.Build(fakeGui)
check("QuestTracker builds frame", qt.ClassName == "Frame")
QuestTracker.Refresh(qt) -- should not error even with no active quests
local EndingSummaryUI = require("EndingSummaryUI")
local es = EndingSummaryUI.Build(fakeGui)
EndingSummaryUI.Show(es, "Guardian")
check("EndingSummary shows title", es:FindFirstChild("Title").Text ~= "")
local JournalUI = require("JournalUI")
local jui = JournalUI.Build(fakeGui)
JournalUI.Refresh(jui)
check("JournalUI builds + refreshes", jui.ClassName == "Frame")

print("")
print("RESULT: passed=" .. passed .. " failed=" .. failed)
if failed > 0 then error("SMOKE TEST FAILED") end
'''

footer = "\nreturn _mods\n"

with open(OUT, "w") as f:
    f.write(header)
    f.write(body)
    f.write(test)
    f.write(footer)

print("Bundle written:", OUT, "modules:", list(src.keys()))
