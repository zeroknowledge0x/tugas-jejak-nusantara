--! Data.luau (content layer)
--! All narrative/content lives here as data, not logic. Systems read this.
--! Authored progressively in Phase 6 (levels). Placeholders now.

local Data = {}

-- NPC definitions (Phase 6 fills real content)
Data.NPCs = {} :: { [string]: any }

-- Dialogue trees keyed by node id
Data.Dialogue = {} :: { [string]: any }

-- Quests keyed by id
Data.Quests = {} :: { [string]: any }

-- Areas: RumahBudaya hub + 5 levels
Data.Areas = {} :: { [any]: any }

-- Mini-game configs keyed by id
Data.MiniGames = {} :: { [string]: any }

-- Ending scoring rules
Data.Endings = {} :: { [any]: any }

-- Achievements keyed by id
Data.Achievements = {} :: { [string]: any }

-- Skill thresholds (also in Types.Constants; surfaced here for designer tuning)
Data.SkillThresholds = {
	T1 = 20,
	T2 = 45,
	T3 = 70,
}

return Data
