--! Data.luau (content layer)
--! All narrative/content lives here as data, not logic. Systems read this.
--! Authored progressively; Phase 6 expands per-level. This is the binding
--! content that the orchestrator wires together.

local Types = require(script.Parent.Types)

local Data = {}

-- NPC definitions (personality, teaching, schedule, appearance gating).
-- NPCs are NOT quiz terminals: they teach through dialogue choices & reactions.
Data.NPCs = {
	Budi = {
		id = "Budi",
		name = "Budi",
		personality = "Hangat, sabar, penuh tawa. Pengrajin angklung desa.",
		homeArea = "RumahBudaya",
		relationshipStart = 10,
		teaching = "Laras angklung: nada diatur dari ruang tabung bambu.",
		quests = { "q_learn_angklung" },
		reactions = {
			happy = "Wah, kamu cepat tangkap!",
			neutral = "Coba lagi, pelan-pelan.",
		},
		schedule = {
			{ from = 6, to = 12, position = Vector3.new(10, 0, 0), activity = "menganyam" },
			{ from = 12, to = 18, position = Vector3.new(20, 0, 0), activity = "mengajar" },
		},
	},
	Kyai = {
		id = "Kyai",
		name = "Kyai",
		personality = "Bijaksana, sedikit misterius. Penjaga rumah budaya.",
		homeArea = "RumahBudaya",
		relationshipStart = 0,
		teaching = "Sejarah adalah jejak yang bicara jika kita mau mengamati.",
		appearanceGate = { completedArea = "RumahBudaya" }, -- appears after area done
		quests = { "q_hidden_scroll" },
		reactions = {
			neutral = "Kamu sudah siap mendengar yang tersembunyi?",
		},
	},
}

-- Dialogue trees. Choices have real effects (skill/unlock/relationship/flag/journal/item).
Data.Dialogue = {
	intro_budi = {
		id = "intro_budi",
		npc = "Budi",
		speaker = "NPC",
		text = "Halo! Mau belajar angklung? Ikuti iramanya.",
		choices = {
			{
				text = "Ajari saya! (Observation +10, dapat AngklungMini)",
				next = "budi_teach",
				effect = {
					skill = "Observation",
					skillXp = 10,
					item = "AngklungMini",
					journal = { category = "music", key = "angklung" },
				},
			},
			{
				text = "Nanti saja.",
				next = nil,
			},
		},
	},
	budi_teach = {
		id = "budi_teach",
		npc = "Budi",
		speaker = "NPC",
		text = "Bagus! Sekarang mainkan irama sederhana di alat ini.",
		choices = nil,
	},
	kyai_secret = {
		id = "kyai_secret",
		npc = "Kyai",
		speaker = "NPC",
		text = "Ada naskah tersembunyi. Hanya yang sungguh mencari yang boleh tahu.",
		requires = { skill = "DecisionMaking", min = 70 },
		choices = {
			{
				text = "Saya akan menjaganya. (flag: protectKnowledge=true)",
				next = nil,
				effect = { flag = { key = "protectKnowledge", value = true } },
			},
		},
	},
}

-- Quest definitions. Main quest completion unlocks the next area (Rule 1).
Data.Quests = {
	q_learn_angklung = {
		id = "q_learn_angklung",
		kind = "Main",
		title = "Belajar Angklung",
		desc = "Mainkan irama angklung bersama Budi.",
		area = "RumahBudaya",
		goal = 1,
		miniGame = "Rhythm",
		reward = { item = "AngklungMini", count = 1, skill = "CulturalUnderstanding", skillXp = 15 },
		unlocksArea = "DesaBudaya",
	},
	q_observe_market = {
		id = "q_observe_market",
		kind = "Exploration",
		title = "Amati Pasar",
		desc = "Temukan 3 benda unik di pasar tradisional.",
		area = "PasarTradisional",
		goal = 3,
		hidden = false,
	},
	q_hidden_scroll = {
		id = "q_hidden_scroll",
		kind = "Hidden",
		title = "Naskah Tersembunyi",
		desc = "Temukan naskah yang dijaga Kyai.",
		area = "RumahBudaya",
		goal = 1,
		hidden = true,
		gatedBy = { completedArea = "RumahBudaya" },
	},
}

-- Area definitions (used by AreaManager.Load; gameplay data expanded in Phase 6).
Data.Areas = {
	RumahBudaya = { id = "RumahBudaya", name = "Rumah Budaya", music = "ambient_culture" },
	DesaBudaya = { id = "DesaBudaya", name = "Desa Budaya", music = "ambient_village" },
	SanggarSeni = { id = "SanggarSeni", name = "Sanggar Seni", music = "ambient_art" },
	PasarTradisional = { id = "PasarTradisional", name = "Pasar Tradisional", music = "ambient_market" },
	TempatBersejarah = { id = "TempatBersejarah", name = "Tempat Bersejarah", music = "ambient_history" },
	KebangkitanTradisi = { id = "KebangkitanTradisi", name = "Kebangkitan Tradisi", music = "ambient_finale" },
}

-- Achievement definitions (pure functions over save state).
Data.Achievements = {
	first_step = {
		id = "first_step",
		name = "Langkah Pertama",
		desc = "Selesaikan satu quest.",
		test = function(s: Types.SaveData)
			for _ in pairs(s.quests.completed) do
				return true
			end
			return false
		end,
	},
	culture_scholar = {
		id = "culture_scholar",
		name = "Cendekia Budaya",
		desc = "CulturalUnderstanding mencapai T2.",
		test = function(s: Types.SaveData)
			return (s.skills.CulturalUnderstanding or 0) >= Types.Constants.SKILL_T2
		end,
	},
}

-- Ending summaries (shown by EndingSystem).
Data.Endings = {
	summaries = {
		Success = { title = "Pewaris Budaya", desc = "Kamu membangkitkan tradisi dan menyatukan desa." },
		Adequate = { title = "Pengembara Bisu", desc = "Kamu lewat, tapi banyak yang tak kau pahami." },
		Explorative = { title = "Penjelajah Rasa", desc = "Kamu menjelajah luas namun dangkal." },
		Guardian = { title = "Penjaga Jejak", desc = "Kamu melindungi rahasia yang seharusnya terjaga." },
		Lorekeeper = { title = "Penyimpan Kisah", desc = "Kau jadi penutur kisah nusantara." },
	},
}

return Data
