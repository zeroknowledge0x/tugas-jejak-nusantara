--! Data.luau (content layer)
--! All narrative/content lives here as data. Phase 6: full 5-level expansion,
--! faithful to the GDD PDFs (rhythm L1, dance L2, negotiation L3, history L4,
--! revival finale L5). Each level carries story, NPCs, dialogue, quests,
--! mini-game configs, secrets, and journal entries.

local Types = require(script.Parent.Types)

local Data = {}

-- =========================================================
-- LEVEL 1 — Rumah Budaya (Angklung / Rhythm / Observation)
-- =========================================================
Data.NPCs = {
	Budi = {
		id = "Budi",
		name = "Budi",
		personality = "Hangat, sabar, penuh tawa. Pengrajin angklung desa.",
		homeArea = "RumahBudaya",
		relationshipStart = 10,
		teaching = "Laras angklung: nada diatur dari ruang tabung bambu.",
		quests = { "q_learn_angklung" },
		reactions = { happy = "Wah, kamu cepat tangkap!", neutral = "Coba lagi, pelan-pelan." },
		schedule = {
			{ from = 6, to = 12, position = Vector3.new(10, 0, 0), activity = "menganyam" },
			{ from = 12, to = 18, position = Vector3.new(20, 0, 0), activity = "mengajar" },
		},
	},
	IbuSari = {
		id = "IbuSari",
		name = "Ibu Sari",
		personality = "Ramah, suka bercerita soal asal-usul desa.",
		homeArea = "RumahBudaya",
		relationshipStart = 5,
		teaching = "Rumah budaya menyimpan memori leluhur.",
		quests = { "q_listen_story" },
		reactions = { neutral = "Duduklah, anak muda." },
	},
	Kyai = {
		id = "Kyai",
		name = "Kyai",
		personality = "Bijaksana, sedikit misterius. Penjaga rumah budaya.",
		homeArea = "RumahBudaya",
		relationshipStart = 0,
		teaching = "Sejarah adalah jejak yang bicara jika kita mau mengamati.",
		appearanceGate = { completedArea = "RumahBudaya" },
		quests = { "q_hidden_scroll" },
		reactions = { neutral = "Kamu sudah siap mendengar yang tersembunyi?" },
	},
}

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
			{ text = "Nanti saja.", next = nil },
		},
	},
	budi_teach = {
		id = "budi_teach",
		npc = "Budi",
		speaker = "NPC",
		text = "Bagus! Sekarang mainkan irama sederhana di alat ini.",
		choices = nil,
	},
	ibu_story = {
		id = "ibu_story",
		npc = "IbuSari",
		speaker = "NPC",
		text = "Desa ini dulu riuh dengan gamelan tiap panen.",
		choices = {
			{
				text = "Ceritakan lagi! (CulturalUnderstanding +10)",
				next = nil,
				effect = {
					skill = "CulturalUnderstanding",
					skillXp = 10,
					journal = { category = "history", key = "desa_panen" },
				},
			},
		},
	},
	kyai_secret = {
		id = "kyai_secret",
		npc = "Kyai",
		speaker = "NPC",
		text = "Ada naskah tersembunyi. Hanya yang sungguh mencari yang boleh tahu.",
		requires = { skill = "DecisionMaking", min = 70 },
		choices = {
			{
				text = "Saya akan menjaganya. (flag: protectKnowledge)",
				next = nil,
				effect = { flag = { key = "protectKnowledge", value = true } },
			},
		},
	},
}

Data.Quests = {
	q_learn_angklung = {
		id = "q_learn_angklung",
		kind = "Main",
		title = "Belajar Angklung",
		area = "RumahBudaya",
		desc = "Mainkan irama angklung bersama Budi.",
		goal = 1,
		miniGame = "Rhythm",
		reward = { item = "AngklungMini", count = 1, skill = "CulturalUnderstanding", skillXp = 15 },
		unlocksArea = "DesaBudaya",
	},
	q_listen_story = {
		id = "q_listen_story",
		kind = "Side",
		title = "Kisah Desa",
		area = "RumahBudaya",
		desc = "Dengarkan cerita Ibu Sari.",
		goal = 1,
		reward = { skill = "CulturalUnderstanding", skillXp = 10 },
	},
	q_observe_courtyard = {
		id = "q_observe_courtyard",
		kind = "Exploration",
		title = "Amati Halaman",
		area = "RumahBudaya",
		desc = "Temukan 3 benda unik di halaman rumah budaya.",
		goal = 3,
		miniGame = "Observation",
		reward = { skill = "Observation", skillXp = 10 },
	},
	q_hidden_scroll = {
		id = "q_hidden_scroll",
		kind = "Hidden",
		title = "Naskah Tersembunyi",
		area = "RumahBudaya",
		desc = "Temukan naskah yang dijaga Kyai.",
		goal = 1,
		hidden = true,
		gatedBy = { completedArea = "RumahBudaya" },
		reward = { item = "NaskahKuno", count = 1 },
	},
}

-- =========================================================
-- LEVEL 2 — Sanggar Seni (Traditional Dance / Movement)
-- =========================================================
Data.NPCs.Seniman = {
	id = "Seniman",
	name = "Seniman",
	personality = "Ekspresif, disiplin, mencintai gerak.",
	homeArea = "SanggarSeni",
	relationshipStart = 5,
	teaching = "Tari bukan sekadar gerak, tapi narasi tubuh.",
	quests = { "q_learn_dance" },
	reactions = { happy = "Gerakmu mulai hidup!", neutral = "Rasakan iramanya." },
}
Data.Dialogue.dance_intro = {
	id = "dance_intro",
	npc = "Seniman",
	speaker = "NPC",
	text = "Mari belajar langkah tari tradisi. Ikuti polanya.",
	choices = {
		{ text = "Ayo! (Communication +10)", next = nil, effect = { skill = "Communication", skillXp = 10 } },
	},
}
Data.Quests.q_learn_dance = {
	id = "q_learn_dance",
	kind = "Main",
	title = "Tarian Tradisi",
	area = "SanggarSeni",
	desc = "Praktikkan urutan gerak tari bersama Seniman.",
	goal = 1,
	miniGame = "Dance",
	reward = { item = "Selendang", count = 1, skill = "CulturalUnderstanding", skillXp = 15 },
	unlocksArea = "PasarTradisional",
}
Data.Quests.q_dance_rehearsal = {
	id = "q_dance_rehearsal",
	kind = "Npc",
	title = "Latihan Bersama",
	area = "SanggarSeni",
	desc = "Selesaikan 2 kali latihan tari.",
	goal = 2,
	miniGame = "Dance",
	reward = { skill = "CulturalUnderstanding", skillXp = 10 },
}

-- =========================================================
-- LEVEL 3 — Pasar Tradisional (Negotiation / Food / Economy)
-- =========================================================
Data.NPCs.Pedagang = {
	id = "Pedagang",
	name = "Pedagang",
	personality = "Cerdik, ramah, pandai menawar.",
	homeArea = "PasarTradisional",
	relationshipStart = 5,
	teaching = "Harga adalah seni; adil bagi penjual dan pembeli.",
	quests = { "q_negotiate" },
	reactions = { happy = "Transaksi yang saling menguntungkan!", neutral = "Berapa kau sanggup bayar?" },
}
Data.Dialogue.market_intro = {
	id = "market_intro",
	npc = "Pedagang",
	speaker = "NPC",
	text = "Mau beli kerajinan? Kita bisa sepakat.",
	choices = {
		{
			text = "Tawar dengan bijak. (DecisionMaking +10)",
			next = nil,
			effect = { skill = "DecisionMaking", skillXp = 10, journal = { category = "food", key = "makanan_pasar" } },
		},
	},
}
Data.Quests.q_negotiate = {
	id = "q_negotiate",
	kind = "Main",
	title = "Tawar Menawar",
	area = "PasarTradisional",
	desc = "Capai harga adil dengan Pedagang.",
	goal = 1,
	miniGame = "Negotiation",
	reward = { item = "KerajinanTangan", count = 1, skill = "Communication", skillXp = 15 },
	unlocksArea = "TempatBersejarah",
}
Data.Quests.q_find_food = {
	id = "q_find_food",
	kind = "Exploration",
	title = "Cicipi Kuliner",
	area = "PasarTradisional",
	desc = "Temukan 3 makanan tradisional di pasar.",
	goal = 3,
	reward = { skill = "CulturalUnderstanding", skillXp = 10 },
}

-- =========================================================
-- LEVEL 4 — Tempat Bersejarah (Puzzles / Observation)
-- =========================================================
Data.NPCs.PenjagaSejarah = {
	id = "PenjagaSejarah",
	name = "Penjaga Sejarah",
	personality = "Tenang, berwibawa, menjaga kebenaran masa lalu.",
	homeArea = "TempatBersejarah",
	relationshipStart = 5,
	teaching = "Simbol tersembunyi menuntun pada kisah yang hilang.",
	quests = { "q_history_puzzle" },
	reactions = { neutral = "Amati dinding ini baik-baik." },
}
Data.Quests.q_history_puzzle = {
	id = "q_history_puzzle",
	kind = "Main",
	title = "Rekonstruksi Sejarah",
	area = "TempatBersejarah",
	desc = "Susun peristiwa bersejarah ke urutan yang benar.",
	goal = 1,
	miniGame = "HistoryPuzzle",
	reward = { item = "ArtefakKuno", count = 1, skill = "ProblemSolving", skillXp = 15 },
	unlocksArea = "KebangkitanTradisi",
}
Data.Quests.q_find_symbols = {
	id = "q_find_symbols",
	kind = "Exploration",
	title = "Simbol Tersembunyi",
	area = "TempatBersejarah",
	desc = "Temukan 4 simbol terukir di situs.",
	goal = 4,
	miniGame = "Observation",
	reward = { skill = "Observation", skillXp = 10 },
}

-- =========================================================
-- LEVEL 5 — Kebangkitan Tradisi (Finale / uses everything)
-- =========================================================
Data.NPCs.KepalaDesa = {
	id = "KepalaDesa",
	name = "Kepala Desa",
	personality = "Bijak, menggalang persatuan warga.",
	homeArea = "KebangkitanTradisi",
	relationshipStart = 10,
	teaching = "Tradisi hidup bila diturunkan, bukan disimpan.",
	quests = { "q_revival" },
}
Data.Quests.q_revival = {
	id = "q_revival",
	kind = "Main",
	title = "Kebangkitan Tradisi",
	area = "KebangkitanTradisi",
	desc = "Satukan warga dan pentaskan tradisi yang dihidupkan kembali.",
	goal = 1,
	miniGame = "CultureActivity",
	reward = { item = "MahkotaBudaya", count = 1, skill = "CulturalUnderstanding", skillXp = 20 },
	-- Rule 5: completing the final main quest triggers the ending (no further area)
}

-- =========================================================
-- Mini-game configs (per quest/area)
-- =========================================================
Data.MiniGames = {
	q_learn_angklung = { kind = "Rhythm", cfg = { beats = 6, seed = 11 } },
	q_observe_courtyard = {
		kind = "Observation",
		cfg = { targets = { "Prasasti", "GamelanTua", "UkiranPintu" }, distractors = { "BatuBiasa" } },
	},
	q_learn_dance = { kind = "Dance", cfg = { steps = 5, seed = 22 } },
	q_dance_rehearsal = { kind = "Dance", cfg = { steps = 4, seed = 33 } },
	q_negotiate = { kind = "Negotiation", cfg = { fairPrice = 5000 } },
	q_find_food = {
		kind = "Observation",
		cfg = { targets = { "Sate", "KueTradisional", "MinumanHerbal" }, distractors = { "MakananModern" } },
	},
	q_history_puzzle = {
		kind = "HistoryPuzzle",
		cfg = {
			events = {
				{ id = 1, year = 1600 },
				{ id = 2, year = 1750 },
				{ id = 3, year = 1900 },
				{ id = 4, year = 1945 },
			},
		},
	},
	q_find_symbols = {
		kind = "Observation",
		cfg = { targets = { "Matahari", "Naga", "Bunga", "Perahu" }, distractors = { "Coretan" } },
	},
	q_revival = {
		kind = "CultureActivity",
		cfg = { steps = { "KumpulkanWarga", "PentaskanTari", "MainkanGamelan", "BagikanKisah" } },
	},
}

-- =========================================================
-- Areas
-- =========================================================
Data.Areas = {
	RumahBudaya = { id = "RumahBudaya", name = "Rumah Budaya", music = "ambient_culture" },
	DesaBudaya = { id = "DesaBudaya", name = "Desa Budaya", music = "ambient_village" },
	SanggarSeni = { id = "SanggarSeni", name = "Sanggar Seni", music = "ambient_art" },
	PasarTradisional = { id = "PasarTradisional", name = "Pasar Tradisional", music = "ambient_market" },
	TempatBersejarah = { id = "TempatBersejarah", name = "Tempat Bersejarah", music = "ambient_history" },
	KebangkitanTradisi = { id = "KebangkitanTradisi", name = "Kebangkitan Tradisi", music = "ambient_finale" },
}

-- =========================================================
-- Achievements
-- =========================================================
Data.Achievements = {
	first_step = {
		id = "first_step",
		name = "Langkah Pertama",
		desc = "Selesaikan satu quest.",
		test = function(s)
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
		test = function(s)
			return (s.skills.CulturalUnderstanding or 0) >= Types.Constants.SKILL_T2
		end,
	},
	rhythm_master = {
		id = "rhythm_master",
		name = "Mahir Angklung",
		desc = "Menang mini-game Rhythm sempurna.",
		test = function(s)
			return s.achievements.rhythm_master == true
		end,
	},
	guardian = {
		id = "guardian",
		name = "Penjaga Jejak",
		desc = "Lindungi naskah tersembunyi.",
		test = function(s)
			return s.endingFlags.protectKnowledge == true
		end,
	},
}

-- =========================================================
-- Endings
-- =========================================================
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
