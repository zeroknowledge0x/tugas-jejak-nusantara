--[[
    ============================================
    JEJAK NUSANTARA v4.0 - COMPLETE SERVER SCRIPT
    ============================================
    Place in: ServerScriptService (Script)
    
    Features:
    - 5 NPCs with ProximityPrompt
    - 4 portals with ProximityPrompt + level gating
    - Quiz system (4 wilayah, 12 soal)
    - Dialogue system with branching choices & state machine
    - XP, Level, Coin system
    - DataStore save/load
    - Journal system
    - 3 Endings (Budayawan / Penjelajah / Pemula)
    
    v4.0 fixes:
    - Bug #1: activeNPC tracking per player
    - Bug #2: quizId sent with QuizStart
    - Bug #3: proper dialogue state machine
    - Added: DataStore, endings, level progression, journal
]]

print("🎮 Jejak Nusantara v4.0 - Loading...")

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
Players.CharacterAutoLoads = true
local RS = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")

-- ============================================
-- DATA STORE (lazy init — won't crash if API disabled)
-- ============================================
local dataStore = nil
local function getDataStore()
    if dataStore then return dataStore end
    -- Studio / unpublished place: never call GetDataStore (engine error bypasses pcall)
    local RunService = game:GetService("RunService")
    if RunService:IsStudio() or game.PlaceId == 0 then
        return nil
    end
    local ok, ds = pcall(function()
        return DataStoreService:GetDataStore("JejakNusantara_v4")
    end)
    if ok then dataStore = ds end
    return dataStore
end

-- ============================================
-- CREATE REMOTE EVENTS
-- ============================================
local function createRemote(className, name)
    local r = Instance.new(className)
    r.Name = name
    r.Parent = RS
    return r
end

-- Game Flow
createRemote("RemoteEvent", "GameStart")
createRemote("RemoteEvent", "DialogueStart")
createRemote("RemoteEvent", "DialogueEnd")
createRemote("RemoteEvent", "DialogueChoice")

-- Quiz
createRemote("RemoteEvent", "QuizStart")
createRemote("RemoteEvent", "QuizAnswer")
createRemote("RemoteEvent", "QuizEnd")

-- Progression
createRemote("RemoteEvent", "ShowNotification")
createRemote("RemoteEvent", "StateUpdate")
createRemote("RemoteFunction", "GetPlayerData")

-- New for v4
createRemote("RemoteEvent", "JournalUpdate")
createRemote("RemoteEvent", "EndingTriggered")
createRemote("RemoteEvent", "LevelUnlocked")
createRemote("RemoteEvent", "TalkRequest")
createRemote("RemoteEvent", "PortalRequest")

print("✅ Remote events created!")

-- ============================================
-- QUIZ DATA
-- ============================================
local QUIZZES = {
    quiz_jawa = {
        title = "Quiz Budaya Jawa",
        questions = {
            {q = "Apa nama rumah adat Jawa Tengah?", a = {"Joglo", "Rumah Gadang", "Tongkonan", "Honai"}, correct = 1},
            {q = "Alat musik tradisional Jawa?", a = {"Angklung", "Gamelan", "Sasando", "Kolintang"}, correct = 2},
            {q = "Tarian tradisional dari Jawa?", a = {"Tari Kecak", "Tari Piring", "Tari Gambyong", "Tari Saman"}, correct = 3}
        }
    },
    quiz_sumatra = {
        title = "Quiz Budaya Sumatra",
        questions = {
            {q = "Apa nama rumah adat Sumatra Barat?", a = {"Joglo", "Rumah Gadang", "Tongkonan", "Honai"}, correct = 2},
            {q = "Tarian tradisional dari Sumatra?", a = {"Tari Kecak", "Tari Piring", "Tari Saman", "Tari Gambyong"}, correct = 3},
            {q = "Alat musik dari Sumatra?", a = {"Gamelan", "Angklung", "Sasando", "Kolintang"}, correct = 2}
        }
    },
    quiz_bali = {
        title = "Quiz Budaya Bali",
        questions = {
            {q = "Apa nama pura terkenal di Bali?", a = {"Pura Besakih", "Pura Ulun Danu", "Pura Tanah Lot", "Pura Uluwatu"}, correct = 1},
            {q = "Tarian tradisional dari Bali?", a = {"Tari Kecak", "Tari Piring", "Tari Saman", "Tari Gambyong"}, correct = 1},
            {q = "Upacara adat di Bali?", a = {"Ngaben", "Rambu Solo", "Tabuik", "Seren Taun"}, correct = 1}
        }
    },
    quiz_papua = {
        title = "Quiz Budaya Papua",
        questions = {
            {q = "Apa nama rumah adat Papua?", a = {"Joglo", "Rumah Gadang", "Tongkonan", "Honai"}, correct = 4},
            {q = "Tarian tradisional dari Papua?", a = {"Tari Kecak", "Tari Piring", "Tari Selamat Datang", "Tari Gambyong"}, correct = 3},
            {q = "Senjata tradisional Papua?", a = {"Keris", "Rencong", "Parang", "Tombak"}, correct = 4}
        }
    }
}

-- ============================================
-- DIALOGUE DATA
-- ============================================
local DIALOGUES = {
    Dosen = {
        name = "Pak Dosen",
        lines = {
            {
                text = "Selamat datang, mahasiswa! Saya akan mengajak kalian menjelajahi budaya Indonesia melalui game ini.",
                choices = {
                    {text = "Siap, Pak!", next = 2},
                    {text = "Apa yang harus saya lakukan?", next = 3}
                }
            },
            {
                text = "Bagus! Klik portal di setiap wilayah untuk mempelajari budayanya. Setiap wilayah punya quiz!",
                choices = {
                    {text = "Saya mengerti!", next = 4},
                    {text = "Tunjukkan caranya", next = 5}
                }
            },
            {
                text = "Kalian akan belajar budaya dari 4 wilayah: Jawa, Sumatra, Bali, dan Papua. Klik portal untuk mulai!",
                choices = {
                    {text = "Siap!", next = 4}
                }
            },
            {
                text = "Selamat belajar! Semoga kalian menjadi generasi yang mencintai budaya Indonesia!",
                choices = {
                    {text = "Terima kasih, Pak!", action = "end"}
                }
            },
            {
                text = "Lihat ada 4 portal berwarna di sekitar kalian. Klik salah satu untuk masuk ke wilayah tersebut!",
                choices = {
                    {text = "Baik, Pak!", action = "end"}
                }
            }
        }
    },
    Karso = {
        name = "Pak Karso",
        lines = {
            {
                text = "Sugeng rawuh! Saya Pak Karso, budayawan dari Jawa Tengah. Mau tahu apa tentang budaya Jawa?",
                choices = {
                    {text = "Apa itu Gamelan?", next = 2},
                    {text = "Ceritakan tentang batik", next = 3},
                    {text = "Apa rumah adat Jawa?", next = 4}
                }
            },
            {
                text = "Gamelan adalah ansambel musik tradisional Jawa. Alat musiknya terdiri dari bonang, saron, gong, dan lainnya. Bunyinya khas dan menenangkan!",
                choices = {
                    {text = "Menarik!", next = 5}
                }
            },
            {
                text = "Batik adalah seni menggambar di kain menggunakan malam (lilin). Setiap motif punya makna filosofis. Batik sudah diakui UNESCO!",
                choices = {
                    {text = "Luar biasa!", next = 5}
                }
            },
            {
                text = "Rumah adat Jawa Tengah adalah Joglo. Bentuknya unik dengan atap menjulang tinggi, melambangkan gunung yang menjulang.",
                choices = {
                    {text = "Keren!", next = 5}
                }
            },
            {
                text = "Jawa punya budaya yang sangat kaya. Dari wayang kulit, tari gambyong, hingga kuliner gudeg dan soto!",
                choices = {
                    {text = "Terima kasih, Pak Karso!", action = "end"}
                }
            }
        }
    },
    Ratna = {
        name = "Ibu Ratna",
        lines = {
            {
                text = "Halo! Saya Ibu Ratna dari Sumatra Barat. Mau tahu tentang budaya Minangkabau?",
                choices = {
                    {text = "Apa itu Rumah Gadang?", next = 2},
                    {text = "Ceritakan tentang rendang", next = 3},
                    {text = "Apa tarian khas Sumatra?", next = 4}
                }
            },
            {
                text = "Rumah Gadang adalah rumah adat Minangkabau dengan atap runcing seperti tanduk kerbau. Simbol kekuatan dan kearifan!",
                choices = {
                    {text = "Indah sekali!", next = 5}
                }
            },
            {
                text = "Rendang adalah masakan daging dengan santan dan rempah. Dimasak berjam-jam hingga kering. Dinobatkan sebagai makanan terenak di dunia!",
                choices = {
                    {text = "Lapar jadinya!", next = 5}
                }
            },
            {
                text = "Tari Piring berasal dari Sumatra Barat. Penari membawa piring di tangan dan bergerak lincah. Sangat indah!",
                choices = {
                    {text = "Ingin lihat!", next = 5}
                }
            },
            {
                text = "Sumatra kaya akan budaya! Dari Tor-tor Batak, randai Minang, hingga kuliner pempek Palembang!",
                choices = {
                    {text = "Terima kasih, Ibu Ratna!", action = "end"}
                }
            }
        }
    },
    Wayan = {
        name = "Mang Wayan",
        lines = {
            {
                text = "Om Swastiastu! Saya Mang Wayan dari Bali. Mau tahu tentang Pulau Dewata?",
                choices = {
                    {text = "Apa itu Pura?", next = 2},
                    {text = "Ceritakan tentang Tari Kecak", next = 3},
                    {text = "Apa upacara khas Bali?", next = 4}
                }
            },
            {
                text = "Pura adalah tempat ibadah umat Hindu Bali. Ada ribuan pura di Bali! Yang terkenal adalah Pura Besakih dan Tanah Lot.",
                choices = {
                    {text = "Megah!", next = 5}
                }
            },
            {
                text = "Tari Kecak adalah tari massal yang dibawakan puluhan penari sambil duduk melingkar dan meneriakkan 'cak-cak-cak'. Sangat ikonik!",
                choices = {
                    {text = "Ingin nonton!", next = 5}
                }
            },
            {
                text = "Ngaben adalah upacara kremasi jenazah. Bali memang unik! Ada juga Nyepi, hari di mana seluruh Bali sunyi senyap.",
                choices = {
                    {text = "Menarik!", next = 5}
                }
            },
            {
                text = "Bali terkenal dengan seni, budaya, dan alamnya. Dari tari barong, ukiran kayu, hingga kuliner babi guling!",
                choices = {
                    {text = "Terima kasih, Mang Wayan!", action = "end"}
                }
            }
        }
    },
    Yanu = {
        name = "Bapak Yanu",
        lines = {
            {
                text = "Halo! Saya Bapak Yanu dari Papua. Mau tahu tentang tanah Cenderawasih?",
                choices = {
                    {text = "Apa itu Honai?", next = 2},
                    {text = "Ceritakan tentang tari Papua", next = 3},
                    {text = "Apa senjata khas Papua?", next = 4}
                }
            },
            {
                text = "Honai adalah rumah tradisional Papua berbentuk bulat dengan atap jerami. Di dalamnya hangat dan nyaman!",
                choices = {
                    {text = "Unik!", next = 5}
                }
            },
            {
                text = "Tari Selamat Datang adalah tari penyambutan dari Papua. Penari membawa tombak dan perisai, gerakannya gagah!",
                choices = {
                    {text = "Keren!", next = 5}
                }
            },
            {
                text = "Papua punya senjata tradisional seperti tombak, panah, dan parang. Juga ada alat musik tifa yang bunyinya khas!",
                choices = {
                    {text = "Menarik!", next = 5}
                }
            },
            {
                text = "Papua surga tersembunyi Indonesia! Dari Raja Ampat, Danau Sentani, hingga burung Cenderawasih yang indah!",
                choices = {
                    {text = "Terima kasih, Bapak Yanu!", action = "end"}
                }
            }
        }
    }
}

-- ============================================
-- PORTAL UNLOCK ORDER
-- ============================================
local PORTAL_ORDER = {
    {quizId = "quiz_jawa", portalName = "PortalJawa"},
    {quizId = "quiz_sumatra", portalName = "PortalSumatra"},
    {quizId = "quiz_bali", portalName = "PortalBali"},
    {quizId = "quiz_papua", portalName = "PortalPapua"},
}

-- ============================================
-- ENDING DATA
-- ============================================
local ENDINGS = {
    budayawan = {
        title = "🏆 Budayawan Nusantara",
        description = "Kamu telah menyelesaikan semua quiz dan mengumpulkan pengetahuan budaya yang luar biasa! Kamu adalah pewaris budaya Indonesia yang sesungguhnya. Teruslah melestarikan kekayaan nusantara!",
        color = {255, 215, 0},
    },
    penjelajah = {
        title = "🗺️ Penjelajah Budaya",
        description = "Kamu sudah menjelajahi cukup banyak budaya Indonesia! Meskipun belum sempurna, semangat eksplorasimu patut diacungi jempol. Teruslah belajar!",
        color = {0, 200, 200},
    },
    pemula = {
        title = "🌱 Pemula",
        description = "Perjalanan budaya baru dimulai! Masih banyak yang bisa dipelajari. Jangan menyerah, teruslah bertualang dan berinteraksi dengan NPC untuk belajar lebih banyak!",
        color = {200, 200, 200},
    },
}

print("✅ Game data loaded!")

-- ============================================
-- PLAYER DATA (with DataStore persistence)
-- ============================================
local playerData = {}
local playerActiveNPC = {} -- Bug #1 fix: track which NPC each player is talking to
local playerDialogueLine = {} -- Bug #3 fix: track current dialogue line per player

local function createDefaultData()
    return {
        level = 1,
        xp = 0,
        xpToNext = 1000,
        coins = 0,
        completedQuizzes = {},
        talkCount = 0,
        journal = {},
        unlockedPortals = {quiz_jawa = true},
    }
end

local function loadPlayerData(player)
    local store = getDataStore()
    if store == nil then
        -- Studio / unpublished: local-only session
        return nil
    end
    local success, data = pcall(function()
        return store:GetAsync("player_" .. player.UserId)
    end)
    if success and data then
        local merged = createDefaultData()
        for k, v in pairs(data) do
            merged[k] = v
        end
        if not merged.unlockedPortals then
            merged.unlockedPortals = {quiz_jawa = true}
        end
        if not merged.journal then
            merged.journal = {}
        end
        return merged
    end
    return nil
end

local function savePlayerData(player)
    local data = playerData[player.UserId]
    if not data then return end
    local store = getDataStore()
    if store == nil then
        return -- Studio local session: no DataStore
    end
    local success, err = pcall(function()
        store:SetAsync("player_" .. player.UserId, data)
    end)
    if success then
        print("[DataStore] Saved: " .. player.Name)
    else
        warn("[DataStore] Save failed: " .. player.Name .. " Error: " .. tostring(err))
    end
end

local function getPlayerData(player)
    if not playerData[player.UserId] then
        playerData[player.UserId] = createDefaultData()
    end
    return playerData[player.UserId]
end

-- GetPlayerData RemoteFunction
RS.GetPlayerData.OnServerInvoke = function(player)
    return getPlayerData(player)
end

-- ============================================
-- STATE SYNC HELPER
-- ============================================
local function syncState(player, key, value)
    RS.StateUpdate:FireClient(player, key, value)
end

-- ============================================
-- XP, COIN, LEVEL SYSTEM
-- ============================================
local function addXP(player, amount)
    local data = getPlayerData(player)
    data.xp = data.xp + amount

    -- Level up check
    while data.xp >= data.xpToNext do
        data.xp = data.xp - data.xpToNext
        data.level = data.level + 1
        data.xpToNext = data.xpToNext + 500
        RS.ShowNotification:FireClient(player, "🎉 Level Up! Level " .. data.level)
        syncState(player, "level", data.level)
    end

    RS.ShowNotification:FireClient(player, "+" .. amount .. " XP")
    syncState(player, "xp", data.xp)
    syncState(player, "xpToNext", data.xpToNext)
end

local function addCoins(player, amount)
    local data = getPlayerData(player)
    data.coins = data.coins + amount
    RS.ShowNotification:FireClient(player, "+" .. amount .. " Koin 💰")
    syncState(player, "coins", data.coins)
end

-- ============================================
-- JOURNAL SYSTEM
-- ============================================
local function addJournalEntry(player, entry)
    local data = getPlayerData(player)
    table.insert(data.journal, {text = entry, time = os.time()})
    RS.JournalUpdate:FireClient(player, entry)
end

-- ============================================
-- ENDING SYSTEM
-- ============================================
local function checkAndTriggerEnding(player)
    local data = getPlayerData(player)
    local quizCount = 0
    for _ in pairs(data.completedQuizzes) do
        quizCount = quizCount + 1
    end

    local endingId, endingData

    if quizCount >= 4 and data.xp >= 500 then
        endingId = "budayawan"
        endingData = ENDINGS.budayawan
    elseif quizCount >= 2 and data.xp >= 200 then
        endingId = "penjelajah"
        endingData = ENDINGS.penjelajah
    else
        endingId = "pemula"
        endingData = ENDINGS.pemula
    end

    data.currentEnding = endingId
    RS.EndingTriggered:FireClient(player, endingId, endingData)
    addJournalEntry(player, "🎬 Perjalanan berakhir! Gelar: " .. endingData.title)
    savePlayerData(player)
    print("[Ending] " .. endingId .. " for " .. player.Name)
end

-- ============================================
-- PORTAL UNLOCK HELPER
-- ============================================
local function unlockNextPortal(player, completedQuizId)
    local data = getPlayerData(player)
    -- Find which quiz was just completed and unlock the next one
    for i, entry in ipairs(PORTAL_ORDER) do
        if entry.quizId == completedQuizId and i < #PORTAL_ORDER then
            local nextEntry = PORTAL_ORDER[i + 1]
            if not data.unlockedPortals[nextEntry.quizId] then
                data.unlockedPortals[nextEntry.quizId] = true
                local quiz = QUIZZES[nextEntry.quizId]
                RS.ShowNotification:FireClient(player, "🔓 Portal baru terbuka: " .. quiz.title)
                RS.LevelUnlocked:FireClient(player, nextEntry.quizId)
                addJournalEntry(player, "🔓 Portal terbuka: " .. quiz.title)
            end
            break
        end
    end
end

-- ============================================
-- NPC CREATION FUNCTION (PROPER R6 RIG)
-- ============================================
local function createNPC(name, position, dialogueId, bodyColor, shirtColor, pantsColor)
    local model = Instance.new("Model")
    model.Name = name

    local skinColor = bodyColor or Color3.fromRGB(200, 150, 100)
    local topColor = shirtColor or Color3.fromRGB(50, 50, 150)
    local bottomColor = pantsColor or Color3.fromRGB(50, 50, 100)

    -- HumanoidRootPart (invisible anchor, center of character)
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.CFrame = CFrame.new(position + Vector3.new(0, 2.5, 0))
    hrp.Anchored = true
    hrp.CanCollide = false
    hrp.Transparency = 1
    hrp.Parent = model

    -- Torso (visible, colored as shirt)
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.CFrame = CFrame.new(position + Vector3.new(0, 2.5, 0))
    torso.Anchored = true
    torso.CanCollide = false
    torso.Color = topColor
    torso.Parent = model

    -- Head (cubic so mesh makes it round)
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 2, 2)
    head.CFrame = CFrame.new(position + Vector3.new(0, 4.5, 0))
    head.Anchored = true
    head.CanCollide = true
    head.Color = skinColor
    head.Parent = model

    -- Head mesh for round shape
    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType = Enum.MeshType.Head
    headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
    headMesh.Parent = head

    -- Face: use SurfaceGui for guaranteed visibility
    local faceGui = Instance.new("SurfaceGui")
    faceGui.Name = "FaceGui"
    faceGui.Face = Enum.NormalId.Front
    faceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    faceGui.PixelsPerStud = 50
    faceGui.Parent = head

    -- Left eye (bigger, more visible)
    local leftEye = Instance.new("Frame")
    leftEye.Name = "LeftEye"
    leftEye.Size = UDim2.new(0.2, 0, 0.2, 0)
    leftEye.Position = UDim2.new(0.2, 0, 0.25, 0)
    leftEye.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    leftEye.BorderSizePixel = 0
    leftEye.Parent = faceGui

    -- Right eye (bigger, more visible)
    local rightEye = Instance.new("Frame")
    rightEye.Name = "RightEye"
    rightEye.Size = UDim2.new(0.2, 0, 0.2, 0)
    rightEye.Position = UDim2.new(0.6, 0, 0.25, 0)
    rightEye.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    rightEye.BorderSizePixel = 0
    rightEye.Parent = faceGui

    -- Mouth (smile, bigger)
    local mouth = Instance.new("Frame")
    mouth.Name = "Mouth"
    mouth.Size = UDim2.new(0.4, 0, 0.1, 0)
    mouth.Position = UDim2.new(0.3, 0, 0.6, 0)
    mouth.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    mouth.BorderSizePixel = 0
    mouth.Parent = faceGui

    -- Eyebrows for more expression
    local leftBrow = Instance.new("Frame")
    leftBrow.Name = "LeftBrow"
    leftBrow.Size = UDim2.new(0.2, 0, 0.05, 0)
    leftBrow.Position = UDim2.new(0.2, 0, 0.18, 0)
    leftBrow.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    leftBrow.BorderSizePixel = 0
    leftBrow.Parent = faceGui

    local rightBrow = Instance.new("Frame")
    rightBrow.Name = "RightBrow"
    rightBrow.Size = UDim2.new(0.2, 0, 0.05, 0)
    rightBrow.Position = UDim2.new(0.6, 0, 0.18, 0)
    rightBrow.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    rightBrow.BorderSizePixel = 0
    rightBrow.Parent = faceGui

    -- Hair for Dosen (special case)
    if name == "Pak Dosen" then
        local hair = Instance.new("Part")
        hair.Name = "Hair"
        hair.Size = Vector3.new(2.3, 0.5, 2.3)
        hair.CFrame = CFrame.new(position + Vector3.new(0, 5.8, 0))
        hair.Anchored = true
        hair.CanCollide = false
        hair.Color = Color3.fromRGB(40, 40, 40)
        hair.Material = Enum.Material.SmoothPlastic
        hair.Parent = model

        -- Mortarboard (graduation cap) for Pak Dosen
        local cap = Instance.new("Part")
        cap.Name = "Cap"
        cap.Size = Vector3.new(2.8, 0.2, 2.8)
        cap.CFrame = CFrame.new(position + Vector3.new(0, 6.3, 0))
        cap.Anchored = true
        cap.CanCollide = false
        cap.Color = Color3.fromRGB(20, 20, 20)
        cap.Material = Enum.Material.SmoothPlastic
        cap.Parent = model

        local topFlat = Instance.new("Part")
        topFlat.Name = "CapTop"
        topFlat.Size = Vector3.new(3.2, 0.15, 3.2)
        topFlat.CFrame = CFrame.new(position + Vector3.new(0, 6.45, 0))
        topFlat.Anchored = true
        topFlat.CanCollide = false
        topFlat.Color = Color3.fromRGB(20, 20, 20)
        topFlat.Material = Enum.Material.SmoothPlastic
        topFlat.Parent = model
    end

    -- Left Arm
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.CFrame = CFrame.new(position + Vector3.new(-1.5, 3.5, 0))
    leftArm.Anchored = true
    leftArm.CanCollide = false
    leftArm.Color = skinColor
    leftArm.Parent = model

    -- Right Arm
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.CFrame = CFrame.new(position + Vector3.new(1.5, 3.5, 0))
    rightArm.Anchored = true
    rightArm.CanCollide = false
    rightArm.Color = skinColor
    rightArm.Parent = model

    -- Left Leg
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.CFrame = CFrame.new(position + Vector3.new(-0.5, 1.5, 0))
    leftLeg.Anchored = true
    leftLeg.CanCollide = false
    leftLeg.Color = bottomColor
    leftLeg.Parent = model

    -- Right Leg
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.CFrame = CFrame.new(position + Vector3.new(0.5, 1.5, 0))
    rightLeg.Anchored = true
    rightLeg.CanCollide = false
    rightLeg.Color = bottomColor
    rightLeg.Parent = model

    -- Shirt instance (colors torso in Roblox character system)
    local shirt = Instance.new("Shirt")
    shirt.Name = "Shirt"
    shirt.Parent = model

    -- Pants instance (colors legs in Roblox character system)
    local pants = Instance.new("Pants")
    pants.Name = "Pants"
    pants.Parent = model

    -- Body Colors (skin tone for R6 rig)
    local bodyColors = Instance.new("BodyColors")
    bodyColors.HeadColor3 = skinColor
    bodyColors.LeftArmColor3 = skinColor
    bodyColors.RightArmColor3 = skinColor
    bodyColors.TorsoColor3 = topColor
    bodyColors.LeftLegColor3 = bottomColor
    bodyColors.RightLegColor3 = bottomColor
    bodyColors.Parent = model

    -- Humanoid (makes it a proper character)
    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model

    model.PrimaryPart = hrp

    -- BIG visible name tag
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Size = UDim2.new(0, 260, 0, 65)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 80
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 0.2
    nameLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Text = "💬 " .. name
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    -- Rounded corners on name tag
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = nameLabel

    -- Start dialogue (shared by ProximityPrompt + ClickDetector)
    local function startTalk(player)
        if not player or not player:IsA("Player") then return end
        -- Allow re-talk: clear stuck state after 60s implicitly by forcing open if same NPC
        if playerActiveNPC[player.UserId] and playerActiveNPC[player.UserId] ~= dialogueId then
            print("[NPC] Player " .. player.Name .. " already in dialogue — clearing stuck state")
            playerActiveNPC[player.UserId] = nil
            playerDialogueLine[player.UserId] = nil
        elseif playerActiveNPC[player.UserId] == dialogueId then
            -- Re-open same dialogue
            playerActiveNPC[player.UserId] = nil
        end

        local data = getPlayerData(player)
        if not data then
            warn("[NPC] ERROR: No player data for " .. player.Name)
            return
        end

        data.talkCount = (data.talkCount or 0) + 1
        print("[NPC] " .. player.Name .. " talking to " .. name .. " (talk #" .. data.talkCount .. ")")

        playerActiveNPC[player.UserId] = dialogueId
        playerDialogueLine[player.UserId] = 1

        local dialogue = DIALOGUES[dialogueId]
        if dialogue then
            RS.DialogueStart:FireClient(player, dialogue, dialogueId)
            addJournalEntry(player, "💬 Berbicara dengan " .. dialogue.name)
            print("[NPC] Dialogue started: " .. dialogueId)
        else
            warn("[NPC] ERROR: No dialogue found for " .. dialogueId)
            playerActiveNPC[player.UserId] = nil
            playerDialogueLine[player.UserId] = nil
        end
    end

    -- ProximityPrompt on HEAD (not invisible HRP) — LoS was blocked by torso
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Bicara"
    prompt.ObjectText = name
    prompt.MaxActivationDistance = 20
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.Style = Enum.ProximityPromptStyle.Default
    prompt.Parent = head

    prompt.Triggered:Connect(startTalk)

    -- Backup: click NPC body
    local click = Instance.new("ClickDetector")
    click.MaxActivationDistance = 20
    click.Parent = torso
    click.MouseClick:Connect(startTalk)

    model:SetAttribute("DialogueId", dialogueId)
    model:SetAttribute("IsNPC", true)
    head:SetAttribute("DialogueId", dialogueId)
    model.Parent = workspace
    print("[NPC] Created: " .. name .. " at " .. tostring(position))
    return model
end

-- ============================================
-- PORTAL CREATION FUNCTION
-- ============================================
local function createPortal(name, position, destination, color, label, quizId)
    local portal = Instance.new("Part")
    portal.Name = name
    portal.Size = Vector3.new(8, 10, 2)
    portal.Position = position
    portal.Anchored = true
    portal.CanCollide = false
    portal.Color = color
    portal.Material = Enum.Material.Neon
    portal.Transparency = 0.3

    -- Portal frame
    local frame = Instance.new("Part")
    frame.Name = "Frame"
    frame.Size = Vector3.new(10, 12, 1)
    frame.Position = position
    frame.Anchored = true
    frame.CanCollide = true
    frame.Color = Color3.fromRGB(139, 90, 43)
    frame.Material = Enum.Material.Wood
    frame.Parent = portal

    -- Label
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 8, 0)
    billboard.Parent = portal

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 0.5
    textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = label
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboard

    -- ProximityPrompt
    portal:SetAttribute("IsPortal", true)
    portal:SetAttribute("QuizId", quizId)
    portal:SetAttribute("Destination", string.format("%f,%f,%f", destination.X, destination.Y, destination.Z))
    portal:SetAttribute("Label", label)

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Masuk"
    prompt.ObjectText = label
    prompt.MaxActivationDistance = 22
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = portal

    prompt.Triggered:Connect(function(player)
        local data = getPlayerData(player)
        if not data then
            warn("[Portal] ERROR: No player data for " .. player.Name)
            return
        end

        print("[Portal] " .. player.Name .. " trying to enter " .. name .. " (quiz: " .. quizId .. ")")

        if not data.unlockedPortals[quizId] then
            RS.ShowNotification:FireClient(player, "🔒 Portal terkunci. Bicara dengan Pak Dosen / selesaikan quiz sebelumnya.")
            print("[Portal] Portal locked for " .. player.Name)
            return
        end

        -- Always teleport into the region (gameplay = enter zone)
        local character = player.Character
        if character then
            local hrp2 = character:FindFirstChild("HumanoidRootPart")
            if hrp2 then
                hrp2.CFrame = CFrame.new(destination + Vector3.new(0, 3, 0))
                print("[Portal] Teleported " .. player.Name .. " to " .. tostring(destination))
            end
        end
        RS.ShowNotification:FireClient(player, "🌍 Memasuki " .. (label or name))

        -- Start quiz only if not finished yet
        if data.completedQuizzes[quizId] then
            RS.ShowNotification:FireClient(player, "✅ Wilayah ini sudah tuntas. Jelajahi atau kembali ke kampus.")
            print("[Portal] Revisit completed zone: " .. quizId)
            return
        end

        local quizData = QUIZZES[quizId]
        if quizData then
            task.delay(0.6, function()
                RS.QuizStart:FireClient(player, quizData, quizId, 1)
            end)
            addJournalEntry(player, "📝 Memasuki quiz: " .. quizData.title)
            print("[Portal] Quiz started: " .. quizId .. " for " .. player.Name)
        else
            warn("[Portal] ERROR: No quiz data for " .. quizId)
        end
    end)

    portal.Parent = workspace
    print("[Portal] Created: " .. name)
    return portal
end

-- ============================================
-- WORLD CREATION - BUILDING HELPERS
-- ============================================

-- Helper: build a simple house/building
local function buildHouse(parent, pos, w, h, d, wallColor, roofColor, name)
    local model = Instance.new("Model")
    model.Name = name or "Building"

    -- Floor
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(w, 0.5, d)
    floor.Position = pos + Vector3.new(0, 0.25, 0)
    floor.Anchored = true
    floor.Color = Color3.fromRGB(120, 90, 50)
    floor.Material = Enum.Material.Wood
    floor.Parent = model

    -- 4 Walls
    local walls = {
        {Vector3.new(0, h/2, d/2), Vector3.new(w, h, 1)},   -- Front
        {Vector3.new(0, h/2, -d/2), Vector3.new(w, h, 1)},  -- Back
        {Vector3.new(-w/2, h/2, 0), Vector3.new(1, h, d)},  -- Left
        {Vector3.new(w/2, h/2, 0), Vector3.new(1, h, d)},   -- Right
    }
    for i, wdata in ipairs(walls) do
        local wall = Instance.new("Part")
        wall.Name = "Wall" .. i
        wall.Size = wdata[2]
        wall.Position = pos + wdata[1]
        wall.Anchored = true
        wall.Color = wallColor
        wall.Material = Enum.Material.Wood
        wall.Parent = model
    end

    -- Door opening (front wall, remove middle)
    local door = Instance.new("Part")
    door.Name = "Door"
    door.Size = Vector3.new(3, 5, 1.2)
    door.Position = pos + Vector3.new(0, 2.5, d/2)
    door.Anchored = true
    door.Color = Color3.fromRGB(60, 35, 15)
    door.Material = Enum.Material.Wood
    door.Transparency = 0.3
    door.Parent = model

    -- Roof
    local roof = Instance.new("Part")
    roof.Name = "Roof"
    roof.Size = Vector3.new(w + 3, 1, d + 3)
    roof.Position = pos + Vector3.new(0, h + 0.5, 0)
    roof.Anchored = true
    roof.Color = roofColor
    roof.Material = Enum.Material.Slate
    roof.Parent = model

    -- Roof peak
    local peak = Instance.new("Part")
    peak.Name = "RoofPeak"
    peak.Size = Vector3.new(w * 0.3, 2, d * 0.3)
    peak.Position = pos + Vector3.new(0, h + 2, 0)
    peak.Anchored = true
    peak.Color = roofColor
    peak.Material = Enum.Material.Slate
    peak.Parent = model

    model.Parent = parent or workspace
    return model
end

-- Helper: build a tree
local function buildTree(parent, pos, height)
    local h = height or math.random(8, 14)
    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Size = Vector3.new(1.5, h, 1.5)
    trunk.Position = pos + Vector3.new(0, h/2, 0)
    trunk.Anchored = true
    trunk.Color = Color3.fromRGB(100, 70, 30)
    trunk.Material = Enum.Material.Wood
    trunk.Parent = parent

    for i = 0, 2 do
        local s = 8 - i * 2
        local canopy = Instance.new("Part")
        canopy.Name = "Canopy" .. i
        canopy.Size = Vector3.new(s, 3, s)
        canopy.Position = pos + Vector3.new(0, h + i * 2, 0)
        canopy.Anchored = true
        canopy.Color = Color3.fromRGB(40 + i*10, 120 + i*20, 40)
        canopy.Material = Enum.Material.Grass
        canopy.Parent = parent
    end
end

-- Helper: build water pond
local function buildWater(parent, pos, size)
    local water = Instance.new("Part")
    water.Name = "Water"
    water.Size = size or Vector3.new(20, 0.3, 20)
    water.Position = pos
    water.Anchored = true
    water.Color = Color3.fromRGB(50, 130, 200)
    water.Material = Enum.Material.Glass
    water.Transparency = 0.4
    water.CanCollide = false
    water.Parent = parent
end

-- Helper: build a candi/temple (tiered structure)
local function buildTemple(parent, pos, height)
    local h = height or 12
    local model = Instance.new("Model")
    model.Name = "Candi"

    for i = 0, 3 do
        local s = 14 - i * 3
        local tier = Instance.new("Part")
        tier.Name = "Tier" .. i
        tier.Size = Vector3.new(s, 3, s)
        tier.Position = pos + Vector3.new(0, i * 3 + 1.5, 0)
        tier.Anchored = true
        tier.Color = Color3.fromRGB(180, 170, 140)
        tier.Material = Enum.Material.Slate
        tier.Parent = model

        -- Stairs on each tier
        if i < 3 then
            local stair = Instance.new("Part")
            stair.Name = "Stairs" .. i
            stair.Size = Vector3.new(3, 1, 3)
            stair.Position = pos + Vector3.new(0, i * 3 + 0.5, s/2 + 1)
            stair.Anchored = true
            stair.Color = Color3.fromRGB(200, 180, 100)
            stair.Material = Enum.Material.SmoothPlastic
            stair.Parent = model
        end
    end

    -- Top stupa
    local stupa = Instance.new("Part")
    stupa.Name = "Stupa"
    stupa.Size = Vector3.new(4, 6, 4)
    stupa.Position = pos + Vector3.new(0, 15, 0)
    stupa.Anchored = true
    stupa.Color = Color3.fromRGB(200, 180, 100)
    stupa.Material = Enum.Material.Neon
    stupa.Transparency = 0.2
    stupa.Shape = Enum.PartType.Ball
    stupa.Parent = model

    model.Parent = parent or workspace
end

-- Helper: build a gate/portal frame (BIGGER GLOW)
local function buildPortalFrame(parent, pos, color)
    local model = Instance.new("Model")
    model.Name = "PortalFrame"

    -- Left pillar
    local left = Instance.new("Part")
    left.Name = "LeftPillar"
    left.Size = Vector3.new(2, 14, 2)
    left.Position = pos + Vector3.new(-5, 7, 0)
    left.Anchored = true
    left.Color = Color3.fromRGB(139, 90, 43)
    left.Material = Enum.Material.Wood
    left.Parent = model

    -- Right pillar
    local right = Instance.new("Part")
    right.Name = "RightPillar"
    right.Size = Vector3.new(2, 14, 2)
    right.Position = pos + Vector3.new(5, 7, 0)
    right.Anchored = true
    right.Color = Color3.fromRGB(139, 90, 43)
    right.Material = Enum.Material.Wood
    right.Parent = model

    -- Top beam
    local beam = Instance.new("Part")
    beam.Name = "TopBeam"
    beam.Size = Vector3.new(12, 2, 2)
    beam.Position = pos + Vector3.new(0, 14, 0)
    beam.Anchored = true
    beam.Color = Color3.fromRGB(139, 90, 43)
    beam.Material = Enum.Material.Wood
    beam.Parent = model

    -- Portal glow (BIGGER and more visible)
    local glow = Instance.new("Part")
    glow.Name = "Glow"
    glow.Size = Vector3.new(10, 14, 2)
    glow.Position = pos + Vector3.new(0, 7, 0)
    glow.Anchored = true
    glow.CanCollide = false
    glow.Color = color
    glow.Material = Enum.Material.Neon
    glow.Transparency = 0.15
    glow.Parent = model

    -- PointLight for extra glow visibility
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 2
    light.Range = 30
    light.Parent = glow

    model.Parent = parent or workspace
end

-- Helper: build market stall
local function buildStall(parent, pos, roofColor, name)
    local model = Instance.new("Model")
    model.Name = name or "Stall"

    -- Table
    local table_ = Instance.new("Part")
    table_.Name = "Table"
    table_.Size = Vector3.new(8, 1, 5)
    table_.Position = pos + Vector3.new(0, 2, 0)
    table_.Anchored = true
    table_.Color = Color3.fromRGB(140, 100, 50)
    table_.Material = Enum.Material.Wood
    table_.Parent = model

    -- Roof
    local roof = Instance.new("Part")
    roof.Name = "Roof"
    roof.Size = Vector3.new(10, 0.5, 7)
    roof.Position = pos + Vector3.new(0, 5, 0)
    roof.Anchored = true
    roof.Color = roofColor
    roof.Material = Enum.Material.Slate
    roof.Parent = model

    -- 4 Poles
    for _, xOff in ipairs({-4, 4}) do
        for _, zOff in ipairs({-2.5, 2.5}) do
            local pole = Instance.new("Part")
            pole.Name = "Pole"
            pole.Size = Vector3.new(0.5, 4, 0.5)
            pole.Position = pos + Vector3.new(xOff, 3.5, zOff)
            pole.Anchored = true
            pole.Color = Color3.fromRGB(120, 80, 30)
            pole.Material = Enum.Material.Wood
            pole.Parent = model
        end
    end

    model.Parent = parent or workspace
end

-- Helper: add a floating region label
local function addLabel(text, pos)
    local adornee = Instance.new("Part")
    adornee.Name = "Label_" .. text
    adornee.Size = Vector3.new(1, 1, 1)
    adornee.Position = pos
    adornee.Anchored = true
    adornee.CanCollide = false
    adornee.Transparency = 1
    adornee.Parent = workspace

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 300, 0, 60)
    bb.StudsOffset = Vector3.new(0, 0, 0)
    bb.AlwaysOnTop = false
    bb.Adornee = adornee
    bb.Parent = workspace

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 0.5
    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Text = text
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb
end

-- ============================================
-- NEW DECORATION HELPERS
-- ============================================

-- Helper: build a lamp post
local function buildLampPost(parent, pos)
    local model = Instance.new("Model")
    model.Name = "LampPost"

    -- Pole
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.5, 8, 0.5)
    pole.Position = pos + Vector3.new(0, 4, 0)
    pole.Anchored = true
    pole.Color = Color3.fromRGB(50, 50, 50)
    pole.Material = Enum.Material.Metal
    pole.Parent = model

    -- Arm
    local arm = Instance.new("Part")
    arm.Name = "Arm"
    arm.Size = Vector3.new(2, 0.4, 0.4)
    arm.Position = pos + Vector3.new(0, 8.2, 0)
    arm.Anchored = true
    arm.Color = Color3.fromRGB(50, 50, 50)
    arm.Material = Enum.Material.Metal
    arm.Parent = model

    -- Lamp head
    local lamp = Instance.new("Part")
    lamp.Name = "Lamp"
    lamp.Size = Vector3.new(1.5, 1, 1.5)
    lamp.Position = pos + Vector3.new(0, 8.5, 0)
    lamp.Anchored = true
    lamp.CanCollide = false
    lamp.Color = Color3.fromRGB(255, 255, 200)
    lamp.Material = Enum.Material.Neon
    lamp.Transparency = 0.2
    lamp.Parent = model

    -- Light
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 240, 200)
    light.Brightness = 1.5
    light.Range = 25
    light.Parent = lamp

    model.Parent = parent or workspace
end

-- Helper: build a wooden bench
local function buildBench(parent, pos, rotY)
    local model = Instance.new("Model")
    model.Name = "Bench"
    local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY or 0), 0)

    -- Seat
    local seat = Instance.new("Part")
    seat.Name = "Seat"
    seat.Size = Vector3.new(6, 0.5, 2)
    seat.CFrame = cf * CFrame.new(0, 1.5, 0)
    seat.Anchored = true
    seat.Color = Color3.fromRGB(140, 100, 50)
    seat.Material = Enum.Material.Wood
    seat.Parent = model

    -- Backrest
    local back = Instance.new("Part")
    back.Name = "Back"
    back.Size = Vector3.new(6, 2, 0.5)
    back.CFrame = cf * CFrame.new(0, 3, -1)
    back.Anchored = true
    back.Color = Color3.fromRGB(140, 100, 50)
    back.Material = Enum.Material.Wood
    back.Parent = model

    -- Left leg
    local ll = Instance.new("Part")
    ll.Name = "LeftLeg"
    ll.Size = Vector3.new(0.5, 1.5, 2)
    ll.CFrame = cf * CFrame.new(-2.5, 0.75, 0)
    ll.Anchored = true
    ll.Color = Color3.fromRGB(80, 60, 30)
    ll.Material = Enum.Material.Wood
    ll.Parent = model

    -- Right leg
    local rl = Instance.new("Part")
    rl.Name = "RightLeg"
    rl.Size = Vector3.new(0.5, 1.5, 2)
    rl.CFrame = cf * CFrame.new(2.5, 0.75, 0)
    rl.Anchored = true
    rl.Color = Color3.fromRGB(80, 60, 30)
    rl.Material = Enum.Material.Wood
    rl.Parent = model

    model.Parent = parent or workspace
end

-- Helper: build a fence section
local function buildFence(parent, pos, length, rotY)
    local model = Instance.new("Model")
    model.Name = "Fence"
    local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY or 0), 0)

    -- Horizontal rail (top)
    local railTop = Instance.new("Part")
    railTop.Name = "RailTop"
    railTop.Size = Vector3.new(length, 0.4, 0.4)
    railTop.CFrame = cf * CFrame.new(0, 2.5, 0)
    railTop.Anchored = true
    railTop.Color = Color3.fromRGB(180, 140, 80)
    railTop.Material = Enum.Material.Wood
    railTop.Parent = model

    -- Horizontal rail (bottom)
    local railBot = Instance.new("Part")
    railBot.Name = "RailBot"
    railBot.Size = Vector3.new(length, 0.4, 0.4)
    railBot.CFrame = cf * CFrame.new(0, 1.2, 0)
    railBot.Anchored = true
    railBot.Color = Color3.fromRGB(180, 140, 80)
    railBot.Material = Enum.Material.Wood
    railBot.Parent = model

    -- Vertical posts
    local numPosts = math.max(2, math.floor(length / 3) + 1)
    for i = 0, numPosts - 1 do
        local xOff = -length/2 + (length / (numPosts - 1)) * i
        local post = Instance.new("Part")
        post.Name = "Post" .. i
        post.Size = Vector3.new(0.5, 3, 0.5)
        post.CFrame = cf * CFrame.new(xOff, 1.5, 0)
        post.Anchored = true
        post.Color = Color3.fromRGB(120, 80, 30)
        post.Material = Enum.Material.Wood
        post.Parent = model
    end

    model.Parent = parent or workspace
end

-- Helper: build a flag pole with Indonesian flag
local function buildFlagPole(parent, pos)
    local model = Instance.new("Model")
    model.Name = "FlagPole"

    -- Pole
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.4, 16, 0.4)
    pole.Position = pos + Vector3.new(0, 8, 0)
    pole.Anchored = true
    pole.Color = Color3.fromRGB(180, 180, 180)
    pole.Material = Enum.Material.Metal
    pole.Parent = model

    -- Ball on top
    local ball = Instance.new("Part")
    ball.Name = "Ball"
    ball.Size = Vector3.new(0.8, 0.8, 0.8)
    ball.Position = pos + Vector3.new(0, 16.4, 0)
    ball.Anchored = true
    ball.Shape = Enum.PartType.Ball
    ball.Color = Color3.fromRGB(255, 215, 0)
    ball.Material = Enum.Material.Metal
    ball.Parent = model

    -- Red stripe (top half of flag)
    local red = Instance.new("Part")
    red.Name = "RedStripe"
    red.Size = Vector3.new(4, 1.5, 0.1)
    red.Position = pos + Vector3.new(2, 14.75, 0)
    red.Anchored = true
    red.CanCollide = false
    red.Color = Color3.fromRGB(255, 0, 0)
    red.Material = Enum.Material.SmoothPlastic
    red.Parent = model

    -- White stripe (bottom half of flag)
    local white = Instance.new("Part")
    white.Name = "WhiteStripe"
    white.Size = Vector3.new(4, 1.5, 0.1)
    white.Position = pos + Vector3.new(2, 13.25, 0)
    white.Anchored = true
    white.CanCollide = false
    white.Color = Color3.fromRGB(255, 255, 255)
    white.Material = Enum.Material.SmoothPlastic
    white.Parent = model

    model.Parent = parent or workspace
end

-- Helper: build a flower bed
local function buildFlowerBed(parent, pos, sizeX, sizeZ, flowerColor)
    local model = Instance.new("Model")
    model.Name = "FlowerBed"

    -- Dirt base
    local dirt = Instance.new("Part")
    dirt.Name = "Dirt"
    dirt.Size = Vector3.new(sizeX, 0.4, sizeZ)
    dirt.Position = pos + Vector3.new(0, 0.2, 0)
    dirt.Anchored = true
    dirt.Color = Color3.fromRGB(90, 60, 30)
    dirt.Material = Enum.Material.Ground
    dirt.Parent = model

    -- Border stones
    for _, offset in ipairs({
        Vector3.new(0, 0.3, sizeZ/2), Vector3.new(0, 0.3, -sizeZ/2),
        Vector3.new(sizeX/2, 0.3, 0), Vector3.new(-sizeX/2, 0.3, 0),
    }) do
        local stone = Instance.new("Part")
        stone.Name = "Border"
        local sx = (math.abs(offset.X) > 0.1) and 0.5 or sizeX
        local sz = (math.abs(offset.Z) > 0.1) and 0.5 or sizeZ
        stone.Size = Vector3.new(sx, 0.6, sz)
        stone.Position = pos + offset
        stone.Anchored = true
        stone.Color = Color3.fromRGB(160, 150, 130)
        stone.Material = Enum.Material.Slate
        stone.Parent = model
    end

    -- Flowers (small colored blocks)
    local fc = flowerColor or Color3.fromRGB(255, 100, 150)
    local altColors = {
        fc,
        Color3.fromRGB(255, 200, 50),
        Color3.fromRGB(200, 80, 200),
        Color3.fromRGB(255, 150, 100),
    }
    for i = 1, 12 do
        local flower = Instance.new("Part")
        flower.Name = "Flower" .. i
        flower.Size = Vector3.new(0.6, 0.8, 0.6)
        local fx = pos.X + math.random(-sizeX/2 + 1, sizeX/2 - 1)
        local fz = pos.Z + math.random(-sizeZ/2 + 1, sizeZ/2 - 1)
        flower.Position = Vector3.new(fx, 0.8, fz)
        flower.Anchored = true
        flower.CanCollide = false
        flower.Color = altColors[math.random(1, #altColors)]
        flower.Material = Enum.Material.SmoothPlastic
        flower.Shape = Enum.PartType.Ball
        flower.Parent = model
    end

    model.Parent = parent or workspace
end

-- Helper: build a decorative rock
local function buildRock(parent, pos, size)
    local rock = Instance.new("Part")
    rock.Name = "Rock"
    rock.Size = size or Vector3.new(2, 1.5, 2)
    rock.Position = pos + Vector3.new(0, (size and size.Y or 1.5) / 2, 0)
    rock.Anchored = true
    rock.Color = Color3.fromRGB(130, 125, 110)
    rock.Material = Enum.Material.Slate
    rock.Parent = parent or workspace
end

-- Helper: build a sign post
local function buildSignPost(parent, pos, text, textColor)
    local model = Instance.new("Model")
    model.Name = "SignPost"

    -- Post
    local post = Instance.new("Part")
    post.Name = "Post"
    post.Size = Vector3.new(0.5, 5, 0.5)
    post.Position = pos + Vector3.new(0, 2.5, 0)
    post.Anchored = true
    post.Color = Color3.fromRGB(100, 70, 30)
    post.Material = Enum.Material.Wood
    post.Parent = model

    -- Sign board
    local sign = Instance.new("Part")
    sign.Name = "Sign"
    sign.Size = Vector3.new(6, 3, 0.5)
    sign.Position = pos + Vector3.new(0, 5.5, 0)
    sign.Anchored = true
    sign.Color = Color3.fromRGB(60, 40, 20)
    sign.Material = Enum.Material.Wood
    sign.Parent = model

    -- SurfaceGui with text
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.Parent = sign

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = textColor or Color3.fromRGB(255, 248, 220)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = gui

    -- Back face too
    local gui2 = Instance.new("SurfaceGui")
    gui2.Face = Enum.NormalId.Back
    gui2.Parent = sign

    local lbl2 = Instance.new("TextLabel")
    lbl2.Size = UDim2.new(1, 0, 1, 0)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = text
    lbl2.TextColor3 = textColor or Color3.fromRGB(255, 248, 220)
    lbl2.TextScaled = true
    lbl2.Font = Enum.Font.GothamBold
    lbl2.Parent = gui2

    model.Parent = parent or workspace
end

-- Helper: build a stone path (series of stepping stones)
local function buildStonePath(parent, fromPos, toPos, width)
    local dist = (toPos - fromPos).Magnitude
    local dir = (toPos - fromPos).Unit
    local numStones = math.max(3, math.floor(dist / 4))
    local w = width or 3

    for i = 0, numStones do
        local t = i / numStones
        local pos = fromPos:Lerp(toPos, t)
        local stone = Instance.new("Part")
        stone.Name = "Stone" .. i
        stone.Size = Vector3.new(w + math.random() * 0.5, 0.2, 2 + math.random() * 0.5)
        stone.Position = pos + Vector3.new(
            (math.random() - 0.5) * 0.5,
            0.6,
            (math.random() - 0.5) * 0.5
        )
        stone.Anchored = true
        stone.Color = Color3.fromRGB(
            170 + math.random(-10, 10),
            160 + math.random(-10, 10),
            140 + math.random(-10, 10)
        )
        stone.Material = Enum.Material.Slate
        stone.Parent = parent or workspace
    end
end

-- ============================================
-- LIGHTING SETUP
-- ============================================
local function setupLighting()
    -- Clear existing lighting children
    for _, child in ipairs(Lighting:GetChildren()) do
        child:Destroy()
    end

    -- Dusk / soft night — not blinding bright
    Lighting.ClockTime = 19.5
    Lighting.GeographicLatitude = -6
    Lighting.Brightness = 1.1
    Lighting.Ambient = Color3.fromRGB(45, 48, 60)
    Lighting.OutdoorAmbient = Color3.fromRGB(70, 75, 95)
    Lighting.FogStart = 40
    Lighting.FogEnd = 280
    Lighting.FogColor = Color3.fromRGB(30, 35, 50)
    Lighting.GlobalShadows = true
    Lighting.EnvironmentDiffuseScale = 0.4
    Lighting.EnvironmentSpecularScale = 0.3

    local atmo = Instance.new("Atmosphere")
    atmo.Name = "NusantaraDusk"
    atmo.Density = 0.45
    atmo.Offset = 0.15
    atmo.Color = Color3.fromRGB(120, 130, 160)
    atmo.Decay = Color3.fromRGB(60, 50, 70)
    atmo.Glare = 0.05
    atmo.Haze = 2.2
    atmo.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "Bloom"
    bloom.Intensity = 0.25
    bloom.Size = 18
    bloom.Threshold = 1.5
    bloom.Parent = Lighting

    local sky = Instance.new("Sky")
    sky.Name = "DuskSky"
    sky.CelestialBodiesShown = true
    sky.StarCount = 4000
    sky.SunAngularSize = 12
    sky.MoonAngularSize = 11
    sky.Parent = Lighting

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "SoftTone"
    cc.Brightness = -0.04
    cc.Contrast = 0.08
    cc.Saturation = 0.05
    cc.TintColor = Color3.fromRGB(230, 235, 255)
    cc.Parent = Lighting

    print("✅ Lighting setup complete!")
end

-- ============================================
-- WORLD CREATION (MASSIVELY EXPANDED)
-- ============================================

-- ============================================
-- ADDITIONAL DECORATIVE HELPERS (Design Taste)
-- ============================================

-- Helper: build a lamp post
local function buildLampPost(parent, pos)
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.4, 8, 0.4)
    pole.Position = pos + Vector3.new(0, 4, 0)
    pole.Anchored = true
    pole.Color = Color3.fromRGB(40, 40, 40)
    pole.Material = Enum.Material.Metal
    pole.Parent = parent

    local lamp = Instance.new("Part")
    lamp.Name = "Lamp"
    lamp.Size = Vector3.new(1.5, 1, 1.5)
    lamp.Position = pos + Vector3.new(0, 8.5, 0)
    lamp.Anchored = true
    lamp.Color = Color3.fromRGB(255, 240, 180)
    lamp.Material = Enum.Material.Neon
    lamp.Parent = parent

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 230, 180)
    light.Brightness = 1.5
    light.Range = 25
    light.Parent = lamp
end

-- Helper: build a bench
local function buildBench(parent, pos, facing)
    local seat = Instance.new("Part")
    seat.Name = "Seat"
    seat.Size = Vector3.new(4, 0.4, 1.5)
    seat.Position = pos + Vector3.new(0, 1.2, 0)
    seat.Anchored = true
    seat.Color = Color3.fromRGB(120, 80, 40)
    seat.Material = Enum.Material.Wood
    seat.Parent = parent

    local back = Instance.new("Part")
    back.Name = "Back"
    back.Size = Vector3.new(4, 1.5, 0.3)
    back.Position = pos + Vector3.new(0, 2.2, -0.6)
    back.Anchored = true
    back.Color = Color3.fromRGB(120, 80, 40)
    back.Material = Enum.Material.Wood
    back.Parent = parent

    for _, xOff in ipairs({-1.5, 1.5}) do
        local leg = Instance.new("Part")
        leg.Name = "Leg"
        leg.Size = Vector3.new(0.4, 1.2, 1.5)
        leg.Position = pos + Vector3.new(xOff, 0.6, 0)
        leg.Anchored = true
        leg.Color = Color3.fromRGB(60, 40, 20)
        leg.Material = Enum.Material.Wood
        leg.Parent = parent
    end
end

-- Helper: build a flower bed
local function buildFlowerBed(parent, pos, size, flowerColor)
    local bed = Instance.new("Part")
    bed.Name = "FlowerBed"
    bed.Size = size or Vector3.new(6, 0.3, 3)
    bed.Position = pos + Vector3.new(0, 0.15, 0)
    bed.Anchored = true
    bed.Color = Color3.fromRGB(80, 50, 20)
    bed.Material = Enum.Material.Ground
    bed.Parent = parent

    local fc = flowerColor or Color3.fromRGB(255, 100, 150)
    for i = 1, 5 do
        local flower = Instance.new("Part")
        flower.Name = "Flower"
        flower.Size = Vector3.new(0.6, 0.8, 0.6)
        flower.Position = pos + Vector3.new(math.random(-2, 2), 0.7, math.random(-1, 1))
        flower.Anchored = true
        flower.Color = fc
        flower.Material = Enum.Material.SmoothPlastic
        flower.Shape = Enum.PartType.Ball
        flower.Parent = parent
    end
end

-- Helper: build decorative rocks
local function buildRock(parent, pos, size)
    local rock = Instance.new("Part")
    rock.Name = "Rock"
    rock.Size = size or Vector3.new(2, 1.5, 2)
    rock.Position = pos + Vector3.new(0, 0.75, 0)
    rock.Anchored = true
    rock.Color = Color3.fromRGB(140, 135, 125)
    rock.Material = Enum.Material.Slate
    rock.Parent = parent
end

-- Helper: build a campfire
local function buildCampfire(parent, pos)
    -- Stone ring
    for i = 0, 7 do
        local angle = (i / 8) * math.pi * 2
        local stone = Instance.new("Part")
        stone.Name = "Stone"
        stone.Size = Vector3.new(1, 0.6, 1)
        stone.Position = pos + Vector3.new(math.cos(angle) * 2, 0.3, math.sin(angle) * 2)
        stone.Anchored = true
        stone.Color = Color3.fromRGB(120, 115, 110)
        stone.Material = Enum.Material.Slate
        stone.Parent = parent
    end

    -- Logs
    for i = 0, 2 do
        local angle = (i / 3) * math.pi * 2
        local log = Instance.new("Part")
        log.Name = "Log"
        log.Size = Vector3.new(2.5, 0.4, 0.4)
        log.Position = pos + Vector3.new(0, 0.4 + i * 0.2, 0)
        log.Anchored = true
        log.CFrame = CFrame.new(log.Position) * CFrame.Angles(0, angle, 0)
        log.Color = Color3.fromRGB(80, 50, 20)
        log.Material = Enum.Material.Wood
        log.Parent = parent
    end

    -- Fire (neon)
    local fire = Instance.new("Part")
    fire.Name = "Fire"
    fire.Size = Vector3.new(1.2, 2, 1.2)
    fire.Position = pos + Vector3.new(0, 1.5, 0)
    fire.Anchored = true
    fire.CanCollide = false
    fire.Color = Color3.fromRGB(255, 120, 20)
    fire.Material = Enum.Material.Neon
    fire.Parent = parent

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 150, 50)
    light.Brightness = 2
    light.Range = 30
    light.Parent = fire
end

-- Helper: build a flag pole with Indonesian flag
local function buildFlag(parent, pos, flagColor)
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.3, 12, 0.3)
    pole.Position = pos + Vector3.new(0, 6, 0)
    pole.Anchored = true
    pole.Color = Color3.fromRGB(180, 180, 180)
    pole.Material = Enum.Material.Metal
    pole.Parent = parent

    local flag = Instance.new("Part")
    flag.Name = "Flag"
    flag.Size = Vector3.new(4, 2.5, 0.1)
    flag.Position = pos + Vector3.new(2, 10.5, 0)
    flag.Anchored = true
    flag.Color = flagColor or Color3.fromRGB(255, 0, 0)
    flag.Material = Enum.Material.SmoothPlastic
    flag.Parent = parent
end

-- Helper: build a fence section
local function buildFence(parent, startPos, endPos, height)
    local h = height or 2
    local diff = endPos - startPos
    local len = diff.Magnitude
    local mid = (startPos + endPos) / 2

    local rail = Instance.new("Part")
    rail.Name = "FenceRail"
    rail.Size = Vector3.new(len, 0.3, 0.3)
    rail.Position = mid + Vector3.new(0, h, 0)
    rail.Anchored = true
    rail.CFrame = CFrame.new(rail.Position, endPos + Vector3.new(0, h, 0))
    rail.Color = Color3.fromRGB(140, 100, 50)
    rail.Material = Enum.Material.Wood
    rail.Parent = parent

    -- Posts every 4 studs
    local posts = math.floor(len / 4)
    for i = 0, posts do
        local t = i / posts
        local postPos = startPos:Lerp(endPos, t)
        local post = Instance.new("Part")
        post.Name = "FencePost"
        post.Size = Vector3.new(0.3, h + 0.5, 0.3)
        post.Position = postPos + Vector3.new(0, (h + 0.5) / 2, 0)
        post.Anchored = true
        post.Color = Color3.fromRGB(120, 80, 35)
        post.Material = Enum.Material.Wood
        post.Parent = parent
    end
end

-- Helper: build a window on a building wall
local function buildWindow(parent, pos)
    local frame = Instance.new("Part")
    frame.Name = "WindowFrame"
    frame.Size = Vector3.new(2.5, 2.5, 0.2)
    frame.Position = pos
    frame.Anchored = true
    frame.Color = Color3.fromRGB(100, 70, 30)
    frame.Material = Enum.Material.Wood
    frame.Parent = parent

    local glass = Instance.new("Part")
    glass.Name = "Glass"
    glass.Size = Vector3.new(2, 2, 0.1)
    glass.Position = pos + Vector3.new(0, 0, 0.1)
    glass.Anchored = true
    glass.Color = Color3.fromRGB(180, 220, 255)
    glass.Material = Enum.Material.Glass
    glass.Transparency = 0.5
    glass.Parent = parent
end

-- Helper: build a signpost with directions
local function buildSignpost(parent, pos, texts)
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.4, 6, 0.4)
    pole.Position = pos + Vector3.new(0, 3, 0)
    pole.Anchored = true
    pole.Color = Color3.fromRGB(100, 70, 30)
    pole.Material = Enum.Material.Wood
    pole.Parent = parent

    for i, text in ipairs(texts or {}) do
        local sign = Instance.new("Part")
        sign.Name = "Sign" .. i
        sign.Size = Vector3.new(5, 1.2, 0.3)
        sign.Position = pos + Vector3.new(0, 5 + (i - 1) * 1.5, 0)
        sign.Anchored = true
        sign.Color = Color3.fromRGB(140, 100, 50)
        sign.Material = Enum.Material.Wood
        sign.Parent = parent

        local gui = Instance.new("SurfaceGui")
        gui.Face = Enum.NormalId.Front
        gui.Parent = sign
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold
        lbl.TextColor3 = Color3.fromRGB(255, 248, 230)
        lbl.Parent = gui
    end
end

local function createWorld()
    print("🌍 Creating world...")

    -- ==========================================
    -- GROUND PLATFORMS (5 areas)
    -- ==========================================
    -- Dark void under islands (not one giant bright map)
    local void = Instance.new("Part")
    void.Name = "VoidFloor"
    void.Size = Vector3.new(1200, 2, 1200)
    void.Position = Vector3.new(0, -40, 0)
    void.Anchored = true
    void.CanCollide = true
    void.Color = Color3.fromRGB(12, 14, 22)
    void.Material = Enum.Material.SmoothPlastic
    void.Parent = workspace

    -- Soft mist slabs between islands (visual separation)
    for i, pos in ipairs({
        Vector3.new(0, -2, -100), Vector3.new(0, -2, 100),
        Vector3.new(-100, -2, 0), Vector3.new(100, -2, 0),
    }) do
        local mist = Instance.new("Part")
        mist.Name = "Mist" .. i
        mist.Size = Vector3.new(40, 1, 40)
        mist.Position = pos
        mist.Anchored = true
        mist.CanCollide = false
        mist.Transparency = 0.7
        mist.Color = Color3.fromRGB(40, 50, 70)
        mist.Material = Enum.Material.ForceField
        mist.Parent = workspace
    end

    -- Kampus platform (white stone)
    local kampus = Instance.new("Part")
    kampus.Name = "KampusPlatform"
    kampus.Size = Vector3.new(60, 1, 60)
    kampus.Position = Vector3.new(0, 0.5, 0)
    kampus.Anchored = true
    kampus.Color = Color3.fromRGB(220, 220, 210)
    kampus.Material = Enum.Material.Concrete
    kampus.Parent = workspace

    -- Jawa platform (warm sand)
    local jawaP = Instance.new("Part")
    jawaP.Name = "JawaPlatform"
    jawaP.Size = Vector3.new(80, 1, 80)
    jawaP.Position = Vector3.new(-280, 0.5, -280)
    jawaP.Anchored = true
    jawaP.Color = Color3.fromRGB(180, 150, 100)
    jawaP.Material = Enum.Material.Sand
    jawaP.Parent = workspace

    -- Sumatra platform (dark earth)
    local sumatraP = Instance.new("Part")
    sumatraP.Name = "SumatraPlatform"
    sumatraP.Size = Vector3.new(80, 1, 80)
    sumatraP.Position = Vector3.new(280, 0.5, -280)
    sumatraP.Anchored = true
    sumatraP.Color = Color3.fromRGB(140, 120, 80)
    sumatraP.Material = Enum.Material.Slate
    sumatraP.Parent = workspace

    -- Bali platform (light stone)
    local baliP = Instance.new("Part")
    baliP.Name = "BaliPlatform"
    baliP.Size = Vector3.new(80, 1, 80)
    baliP.Position = Vector3.new(-280, 0.5, 280)
    baliP.Anchored = true
    baliP.Color = Color3.fromRGB(200, 190, 170)
    baliP.Material = Enum.Material.Limestone
    baliP.Parent = workspace

    -- Papua platform (dark green)
    local papuaP = Instance.new("Part")
    papuaP.Name = "PapuaPlatform"
    papuaP.Size = Vector3.new(80, 1, 80)
    papuaP.Position = Vector3.new(280, 0.5, 280)
    papuaP.Anchored = true
    papuaP.Color = Color3.fromRGB(60, 100, 50)
    papuaP.Material = Enum.Material.Grass
    papuaP.Parent = workspace

    -- ==========================================
    -- PATHS connecting areas
    -- ==========================================
    local paths = {
        {Vector3.new(0, 0.6, -30), Vector3.new(60, 0.3, 6)},   -- Kampus → Jawa
        {Vector3.new(30, 0.6, 0), Vector3.new(6, 0.3, 60)},    -- Kampus → Sumatra (right)
        {Vector3.new(-30, 0.6, 0), Vector3.new(6, 0.3, 60)},   -- Kampus → Bali (left)
        {Vector3.new(0, 0.6, 30), Vector3.new(60, 0.3, 6)},    -- Kampus → Papua
    }
    for i, pdata in ipairs(paths) do
        local path = Instance.new("Part")
        path.Name = "Path" .. i
        path.Size = pdata[2]
        path.Position = pdata[1]
        path.Anchored = true
        path.Color = Color3.fromRGB(180, 160, 120)
        path.Material = Enum.Material.Cobblestone
        path.Parent = workspace
    end

    -- ==========================================
    -- STONE PATHS between areas
    -- ==========================================
    buildStonePath(workspace, Vector3.new(0, 0, 25), Vector3.new(0, 0, 60), 4)
    buildStonePath(workspace, Vector3.new(0, 0, -25), Vector3.new(0, 0, -60), 4)
    buildStonePath(workspace, Vector3.new(25, 0, 0), Vector3.new(60, 0, 0), 4)
    buildStonePath(workspace, Vector3.new(-25, 0, 0), Vector3.new(-60, 0, 0), 4)

    -- ==========================================
    -- KAMPUS AREA (spawn) - MASSIVELY EXPANDED
    -- ==========================================
    -- Main building
    buildHouse(workspace, Vector3.new(0, 0, -15), 20, 10, 14,
        Color3.fromRGB(200, 190, 170), Color3.fromRGB(150, 60, 30), "Gedung_Kampus")

    -- Library building (left of main)
    buildHouse(workspace, Vector3.new(-18, 0, -18), 12, 8, 10,
        Color3.fromRGB(190, 180, 160), Color3.fromRGB(120, 50, 25), "Perpustakaan")

    -- Guard post (right of main)
    buildHouse(workspace, Vector3.new(20, 0, -20), 6, 5, 6,
        Color3.fromRGB(180, 170, 150), Color3.fromRGB(100, 80, 60), "Pos_Satpam")

    -- Welcome sign
    local sign = Instance.new("Part")
    sign.Name = "WelcomeSign"
    sign.Size = Vector3.new(14, 3, 0.5)
    sign.Position = Vector3.new(0, 8, 0)
    sign.Anchored = true
    sign.Color = Color3.fromRGB(60, 40, 20)
    sign.Material = Enum.Material.Wood
    sign.Parent = workspace

    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign
    local signTxt = Instance.new("TextLabel")
    signTxt.Size = UDim2.new(1, 0, 1, 0)
    signTxt.BackgroundTransparency = 1
    signTxt.Text = "🇮🇩 JEJAK NUSANTARA 🇮🇩\nPetualangan Budaya Indonesia"
    signTxt.TextColor3 = Color3.fromRGB(255, 248, 230)
    signTxt.TextScaled = true
    signTxt.Font = Enum.Font.GothamBold
    signTxt.Parent = signGui

    -- Spawn
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "SpawnPoint"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 1.5, 8)
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Duration = 0
    spawn.Neutral = true
    spawn.Enabled = true
    spawn.Color = Color3.fromRGB(218, 165, 32)
    spawn.Material = Enum.Material.Neon
    spawn.Transparency = 0.2
    spawn.Parent = workspace

    -- Kampus trees (8 trees around perimeter)
    for _, tpos in ipairs({
        Vector3.new(-25, 0, -25), Vector3.new(25, 0, -25),
        Vector3.new(-25, 0, 25), Vector3.new(25, 0, 25),
        Vector3.new(-28, 0, -10), Vector3.new(28, 0, -10),
        Vector3.new(-28, 0, 10), Vector3.new(28, 0, 10),
    }) do buildTree(workspace, tpos, 10) end

    -- Flag poles near kampus entrance
    buildFlag(workspace, Vector3.new(-8, 0, 12), Color3.fromRGB(255, 0, 0))
    buildFlag(workspace, Vector3.new(8, 0, 12), Color3.fromRGB(255, 255, 255))

    -- Lamp posts along kampus paths
    for _, lpos in ipairs({
        Vector3.new(-15, 0, 5), Vector3.new(15, 0, 5),
        Vector3.new(-15, 0, -5), Vector3.new(15, 0, -5),
        Vector3.new(0, 0, 20), Vector3.new(0, 0, -28),
    }) do buildLampPost(workspace, lpos) end

    -- Benches near buildings
    buildBench(workspace, Vector3.new(12, 0, -8), 0)
    buildBench(workspace, Vector3.new(-12, 0, -8), 0)
    buildBench(workspace, Vector3.new(0, 0, 18), 180)
    buildBench(workspace, Vector3.new(-8, 0, 22), 90)

    -- Flower beds around kampus
    buildFlowerBed(workspace, Vector3.new(-15, 0, -12), Vector3.new(8, 0.3, 3), Color3.fromRGB(255, 100, 150))
    buildFlowerBed(workspace, Vector3.new(15, 0, -12), Vector3.new(8, 0.3, 3), Color3.fromRGB(255, 200, 50))
    buildFlowerBed(workspace, Vector3.new(-20, 0, 15), Vector3.new(6, 0.3, 4), Color3.fromRGB(200, 100, 255))
    buildFlowerBed(workspace, Vector3.new(20, 0, 15), Vector3.new(6, 0.3, 4), Color3.fromRGB(100, 200, 255))

    -- Campfire in kampus courtyard
    buildCampfire(workspace, Vector3.new(0, 0, 0))

    -- Decorative rocks
    buildRock(workspace, Vector3.new(-22, 0, -18), Vector3.new(3, 2, 2))
    buildRock(workspace, Vector3.new(22, 0, -18), Vector3.new(2.5, 1.8, 2.5))
    buildRock(workspace, Vector3.new(-18, 0, 22), Vector3.new(2, 1.5, 2))
    buildRock(workspace, Vector3.new(18, 0, 22), Vector3.new(2.5, 2, 2))

    -- Signpost near spawn
    buildSignpost(workspace, Vector3.new(5, 0, 20), {
        "← Jawa | Sumatra →",
        "← Bali | Papua →",
    })

    -- Flower beds around kampus
    buildFlowerBed(workspace, Vector3.new(-20, 0, 20), Vector3.new(8, 0.4, 4), Color3.fromRGB(255, 100, 150))
    buildFlowerBed(workspace, Vector3.new(20, 0, 20), Vector3.new(8, 0.4, 4), Color3.fromRGB(255, 200, 50))
    buildFlowerBed(workspace, Vector3.new(-20, 0, -24), Vector3.new(6, 0.4, 3), Color3.fromRGB(200, 100, 255))
    buildFlowerBed(workspace, Vector3.new(20, 0, -24), Vector3.new(6, 0.4, 3), Color3.fromRGB(100, 200, 255))

    -- Decorative rocks near kampus
    buildRock(workspace, Vector3.new(-22, 0, 15), Vector3.new(2.5, 1.8, 2.5))
    buildRock(workspace, Vector3.new(22, 0, 15), Vector3.new(2, 1.5, 2))
    buildRock(workspace, Vector3.new(24, 0, -18), Vector3.new(3, 2, 3))

    -- Sign posts at path intersections
    buildSignPost(workspace, Vector3.new(0, 0, 26), "→ Papua | ← Bali\n↓ Jawa | ↑ Sumatra")
    buildSignPost(workspace, Vector3.new(-26, 0, 0), "← Wilayah Bali")
    buildSignPost(workspace, Vector3.new(26, 0, 0), "Wilayah Sumatra →")
    buildSignPost(workspace, Vector3.new(0, 0, -26), "Wilayah Jawa ↓")

    -- ==========================================
    -- JAWA AREA (Rumah Joglo + Gamelan + More)
    -- ==========================================
    -- Rumah Joglo (traditional Javanese house)
    buildHouse(workspace, Vector3.new(-130, 0, -140), 18, 10, 14,
        Color3.fromRGB(160, 120, 60), Color3.fromRGB(100, 50, 20), "Rumah_Joglo")

    -- Pendopo (open pavilion)
    buildHouse(workspace, Vector3.new(-110, 0, -120), 14, 8, 14,
        Color3.fromRGB(180, 140, 80), Color3.fromRGB(120, 60, 25), "Pendopo")

    -- Gamelan stage
    local stage = Instance.new("Part")
    stage.Name = "GamelanStage"
    stage.Size = Vector3.new(16, 1, 10)
    stage.Position = Vector3.new(-100, 0.5, -100)
    stage.Anchored = true
    stage.Color = Color3.fromRGB(140, 90, 40)
    stage.Material = Enum.Material.Wood
    stage.Parent = workspace

    -- Warung (food stall) extra building
    buildStall(workspace, Vector3.new(-140, 0, -100), Color3.fromRGB(180, 60, 30), "Warung_Jawa")
    buildStall(workspace, Vector3.new(-100, 0, -140), Color3.fromRGB(160, 120, 40), "Kios_Batik_Jawa")

    -- Javanese temple (small candi)
    buildTemple(workspace, Vector3.new(-140, 0, -130), 8)

    -- Sawah (rice field - green flat)
    local sawah = Instance.new("Part")
    sawah.Name = "Sawah"
    sawah.Size = Vector3.new(30, 0.3, 20)
    sawah.Position = Vector3.new(-140, 0.15, -100)
    sawah.Anchored = true
    sawah.Color = Color3.fromRGB(100, 180, 60)
    sawah.Material = Enum.Material.Grass
    sawah.Parent = workspace

    -- Jawa water feature
    buildWater(workspace, Vector3.new(-100, 0.15, -140), Vector3.new(15, 0.3, 15))

    -- Jawa decorations
    buildLampPost(workspace, Vector3.new(-120, 0, -120))
    buildLampPost(workspace, Vector3.new(-140, 0, -120))
    buildFlowerBed(workspace, Vector3.new(-115, 0, -135), Vector3.new(6, 0.3, 3), Color3.fromRGB(255, 200, 50))
    buildSignpost(workspace, Vector3.new(-95, 0, -120), {"Rumah Joglo", "Pendopo", "Gamelan"})

    -- Jawa trees
    for _, tpos in ipairs({
        Vector3.new(-150, 0, -150), Vector3.new(-90, 0, -150),
        Vector3.new(-150, 0, -90), Vector3.new(-90, 0, -90),
        Vector3.new(-140, 0, -130), Vector3.new(-100, 0, -140),
    }) do buildTree(workspace, tpos, 12) end

    -- Jawa benches and lamp
    buildBench(workspace, Vector3.new(-105, 0, -108), 45)
    buildLampPost(workspace, Vector3.new(-115, 0, -108))
    buildLampPost(workspace, Vector3.new(-95, 0, -108))

    -- Jawa flower beds
    buildFlowerBed(workspace, Vector3.new(-125, 0, -108), Vector3.new(6, 0.4, 4), Color3.fromRGB(255, 180, 50))
    buildFlowerBed(workspace, Vector3.new(-105, 0, -148), Vector3.new(5, 0.4, 3), Color3.fromRGB(255, 120, 80))

    -- Jawa sign
    buildSignPost(workspace, Vector3.new(-120, 0, -95), "🏛️ Wilayah Jawa\nBudaya Jawa Tengah", Color3.fromRGB(255, 200, 100))

    -- Jawa rocks
    buildRock(workspace, Vector3.new(-150, 0, -110), Vector3.new(3, 2, 2.5))
    buildRock(workspace, Vector3.new(-88, 0, -135), Vector3.new(2, 1.5, 2))

    -- ==========================================
    -- SUMATRA AREA (Rumah Gadang + Market + More)
    -- ==========================================
    -- Rumah Gadang (Minangkabau house with horn-like roof)
    buildHouse(workspace, Vector3.new(130, 0, -140), 20, 10, 14,
        Color3.fromRGB(170, 130, 70), Color3.fromRGB(180, 50, 30), "Rumah_Gadang")

    -- Additional house
    buildHouse(workspace, Vector3.new(110, 0, -120), 12, 8, 10,
        Color3.fromRGB(150, 110, 60), Color3.fromRGB(160, 60, 30), "Rumah_Minang")

    -- Extra building: community hall
    buildHouse(workspace, Vector3.new(140, 0, -125), 14, 8, 12,
        Color3.fromRGB(165, 125, 65), Color3.fromRGB(140, 40, 25), "Balai_Masyarakat")

    -- Market stalls
    buildStall(workspace, Vector3.new(140, 0, -100), Color3.fromRGB(200, 80, 30), "Kios_Rendang")
    buildStall(workspace, Vector3.new(140, 0, -115), Color3.fromRGB(30, 150, 200), "Kios_Batik")
    buildStall(workspace, Vector3.new(130, 0, -100), Color3.fromRGB(200, 180, 30), "Kios_Kopi")

    -- Sumatra water (small river)
    buildWater(workspace, Vector3.new(110, 0.15, -100), Vector3.new(8, 0.3, 20))

    -- Sumatra trees (8 trees)
    for _, tpos in ipairs({
        Vector3.new(100, 0, -150), Vector3.new(150, 0, -150),
        Vector3.new(100, 0, -90), Vector3.new(150, 0, -90),
        Vector3.new(155, 0, -130), Vector3.new(105, 0, -145),
        Vector3.new(95, 0, -110), Vector3.new(155, 0, -105),
    }) do buildTree(workspace, tpos, 11) end

    -- Sumatra decorations
    buildLampPost(workspace, Vector3.new(120, 0, -120))
    buildLampPost(workspace, Vector3.new(140, 0, -120))
    buildFlowerBed(workspace, Vector3.new(125, 0, -135), Vector3.new(6, 0.3, 3), Color3.fromRGB(255, 150, 50))
    buildSignpost(workspace, Vector3.new(105, 0, -120), {"Rumah Gadang", "Pasar", "Balai"})

    -- Sumatra benches and lamps
    buildBench(workspace, Vector3.new(120, 0, -108), -30)
    buildLampPost(workspace, Vector3.new(125, 0, -108))
    buildLampPost(workspace, Vector3.new(115, 0, -108))

    -- Sumatra flower beds
    buildFlowerBed(workspace, Vector3.new(115, 0, -130), Vector3.new(5, 0.4, 4), Color3.fromRGB(255, 50, 50))

    -- Sumatra sign
    buildSignPost(workspace, Vector3.new(120, 0, -95), "🟢 Wilayah Sumatra\nBudaya Minangkabau", Color3.fromRGB(100, 255, 100))

    -- Sumatra rocks
    buildRock(workspace, Vector3.new(100, 0, -130), Vector3.new(2.5, 2, 2))
    buildRock(workspace, Vector3.new(152, 0, -115), Vector3.new(2, 1.5, 3))

    -- ==========================================
    -- BALI AREA (Pura + Sanggar + More)
    -- ==========================================
    -- Pura (temple)
    buildTemple(workspace, Vector3.new(-120, 0, 110), 14)

    -- Sanggar tari (dance studio)
    buildHouse(workspace, Vector3.new(-100, 0, 140), 16, 10, 12,
        Color3.fromRGB(200, 180, 140), Color3.fromRGB(100, 40, 20), "Sanggar_Tari")

    -- Bale (open pavilion)
    buildHouse(workspace, Vector3.new(-140, 0, 130), 10, 7, 10,
        Color3.fromRGB(190, 170, 130), Color3.fromRGB(80, 35, 15), "Bale_Bali")

    -- Extra: offering shrine
    buildHouse(workspace, Vector3.new(-110, 0, 115), 8, 6, 8,
        Color3.fromRGB(195, 185, 150), Color3.fromRGB(90, 45, 20), "Pura_Kecil")

    -- Bali market
    buildStall(workspace, Vector3.new(-100, 0, 120), Color3.fromRGB(200, 150, 50), "Kios_Souvenir")

    -- Bali water garden
    buildWater(workspace, Vector3.new(-130, 0.15, 150), Vector3.new(18, 0.3, 12))
    buildWater(workspace, Vector3.new(-100, 0.15, 155), Vector3.new(10, 0.3, 8))

    -- Bali trees (8 trees)
    for _, tpos in ipairs({
        Vector3.new(-150, 0, 100), Vector3.new(-90, 0, 100),
        Vector3.new(-150, 0, 155), Vector3.new(-90, 0, 155),
        Vector3.new(-155, 0, 130), Vector3.new(-85, 0, 125),
        Vector3.new(-130, 0, 105), Vector3.new(-110, 0, 155),
    }) do buildTree(workspace, tpos, 9) end

    -- Bali decorations
    buildLampPost(workspace, Vector3.new(-108, 0, 130))
    buildLampPost(workspace, Vector3.new(-132, 0, 130))
    buildFlowerBed(workspace, Vector3.new(-125, 0, 120), Vector3.new(7, 0.3, 4), Color3.fromRGB(255, 100, 50))
    buildFlowerBed(workspace, Vector3.new(-95, 0, 145), Vector3.new(5, 0.3, 3), Color3.fromRGB(255, 200, 0))
    buildSignpost(workspace, Vector3.new(-120, 0, 98), {"Pura Besakih", "Sanggar Tari", "Bale Bali"})
    buildBench(workspace, Vector3.new(-115, 0, 125), 0)
    buildBench(workspace, Vector3.new(-135, 0, 145), 45)

    -- Bali rocks (volcanic)
    buildRock(workspace, Vector3.new(-150, 0, 115), Vector3.new(3, 2.5, 3))
    buildRock(workspace, Vector3.new(-88, 0, 140), Vector3.new(2.5, 2, 2))

    -- ==========================================
    -- PAPUA AREA (Honai + Jungle + More)
    -- ==========================================
    -- Honai (round traditional house - approximated with cylinder)
    local honai = Instance.new("Model")
    honai.Name = "Honai"

    local honaiBase = Instance.new("Part")
    honaiBase.Name = "Base"
    honaiBase.Size = Vector3.new(10, 6, 10)
    honaiBase.Position = Vector3.new(120, 3, 120)
    honaiBase.Anchored = true
    honaiBase.Color = Color3.fromRGB(120, 80, 40)
    honaiBase.Material = Enum.Material.Wood
    honaiBase.Shape = Enum.PartType.Cylinder
    honaiBase.Parent = honai

    local honaiRoof = Instance.new("Part")
    honaiRoof.Name = "Roof"
    honaiRoof.Size = Vector3.new(12, 3, 12)
    honaiRoof.Position = Vector3.new(120, 7.5, 120)
    honaiRoof.Anchored = true
    honaiRoof.Color = Color3.fromRGB(80, 60, 30)
    honaiRoof.Material = Enum.Material.Slate
    honaiRoof.Shape = Enum.PartType.Cylinder
    honaiRoof.Parent = honai

    honai.Parent = workspace

    -- Second honai
    local honai2 = Instance.new("Model")
    honai2.Name = "Honai2"

    local h2Base = Instance.new("Part")
    h2Base.Name = "Base"
    h2Base.Size = Vector3.new(8, 5, 8)
    h2Base.Position = Vector3.new(140, 2.5, 130)
    h2Base.Anchored = true
    h2Base.Color = Color3.fromRGB(100, 70, 35)
    h2Base.Material = Enum.Material.Wood
    h2Base.Shape = Enum.PartType.Cylinder
    h2Base.Parent = honai2

    local h2Roof = Instance.new("Part")
    h2Roof.Name = "Roof"
    h2Roof.Size = Vector3.new(10, 2.5, 10)
    h2Roof.Position = Vector3.new(140, 6.25, 130)
    h2Roof.Anchored = true
    h2Roof.Color = Color3.fromRGB(70, 50, 25)
    h2Roof.Material = Enum.Material.Slate
    h2Roof.Shape = Enum.PartType.Cylinder
    h2Roof.Parent = honai2

    honai2.Parent = workspace

    -- Third honai (workshop)
    local honai3 = Instance.new("Model")
    honai3.Name = "Honai3"

    local h3Base = Instance.new("Part")
    h3Base.Name = "Base"
    h3Base.Size = Vector3.new(9, 5.5, 9)
    h3Base.Position = Vector3.new(105, 2.75, 135)
    h3Base.Anchored = true
    h3Base.Color = Color3.fromRGB(110, 75, 38)
    h3Base.Material = Enum.Material.Wood
    h3Base.Shape = Enum.PartType.Cylinder
    h3Base.Parent = honai3

    local h3Roof = Instance.new("Part")
    h3Roof.Name = "Roof"
    h3Roof.Size = Vector3.new(11, 2.8, 11)
    h3Roof.Position = Vector3.new(105, 6.7, 135)
    h3Roof.Anchored = true
    h3Roof.Color = Color3.fromRGB(65, 48, 22)
    h3Roof.Material = Enum.Material.Slate
    h3Roof.Shape = Enum.PartType.Cylinder
    h3Roof.Parent = honai3

    honai3.Parent = workspace

    -- Papua market
    buildStall(workspace, Vector3.new(135, 0, 105), Color3.fromRGB(150, 100, 40), "Kios_Papua")

    -- Papua dense jungle (10 trees)
    for _, tpos in ipairs({
        Vector3.new(100, 0, 100), Vector3.new(150, 0, 100),
        Vector3.new(100, 0, 150), Vector3.new(150, 0, 150),
        Vector3.new(110, 0, 130), Vector3.new(140, 0, 110),
        Vector3.new(130, 0, 145), Vector3.new(105, 0, 115),
        Vector3.new(155, 0, 135), Vector3.new(95, 0, 145),
    }) do buildTree(workspace, tpos, 14) end

    -- Papua pond
    buildWater(workspace, Vector3.new(140, 0.15, 110), Vector3.new(12, 0.3, 12))

    -- Papua decorations
    buildLampPost(workspace, Vector3.new(132, 0, 108))
    buildLampPost(workspace, Vector3.new(118, 0, 130))
    buildFlowerBed(workspace, Vector3.new(125, 0, 120), Vector3.new(5, 0.3, 3), Color3.fromRGB(100, 200, 100))
    buildSignpost(workspace, Vector3.new(120, 0, 98), {"Honai", "Hutan", "Danau"})
    buildBench(workspace, Vector3.new(130, 0, 115), 90)

    -- Papua rocks
    buildRock(workspace, Vector3.new(100, 0, 120), Vector3.new(3.5, 2.5, 3))
    buildRock(workspace, Vector3.new(150, 0, 145), Vector3.new(2.5, 2, 2))
    buildRock(workspace, Vector3.new(110, 0, 150), Vector3.new(2, 1.5, 2.5))

    -- ==========================================
    -- PORTALS (with visible gate frames + BIGGER glow)
    -- ==========================================
    buildPortalFrame(workspace, Vector3.new(-80, 0, -80), Color3.fromRGB(255, 215, 0))
    createPortal("PortalJawa", Vector3.new(-28, 6, -28), Vector3.new(-280, 4, -280),
        Color3.fromRGB(255, 215, 0), "🟡 Wilayah Jawa", "quiz_jawa")

    buildPortalFrame(workspace, Vector3.new(80, 0, -80), Color3.fromRGB(0, 200, 0))
    createPortal("PortalSumatra", Vector3.new(28, 6, -28), Vector3.new(280, 4, -280),
        Color3.fromRGB(0, 200, 0), "🟢 Wilayah Sumatra", "quiz_sumatra")

    buildPortalFrame(workspace, Vector3.new(-80, 0, 80), Color3.fromRGB(0, 150, 255))
    createPortal("PortalBali", Vector3.new(-28, 6, 28), Vector3.new(-280, 4, 280),
        Color3.fromRGB(0, 150, 255), "🔵 Wilayah Bali", "quiz_bali")

    buildPortalFrame(workspace, Vector3.new(80, 0, 80), Color3.fromRGB(150, 0, 200))
    createPortal("PortalPapua", Vector3.new(28, 6, 28), Vector3.new(280, 4, 280),
        Color3.fromRGB(150, 0, 200), "🟣 Wilayah Papua", "quiz_papua")

    -- Portal area decorations (flowers near portals)
    buildFlowerBed(workspace, Vector3.new(-85, 0, -72), Vector3.new(5, 0.4, 3), Color3.fromRGB(255, 215, 0))
    buildFlowerBed(workspace, Vector3.new(85, 0, -72), Vector3.new(5, 0.4, 3), Color3.fromRGB(0, 200, 0))
    buildFlowerBed(workspace, Vector3.new(-85, 0, 88), Vector3.new(5, 0.4, 3), Color3.fromRGB(0, 150, 255))
    buildFlowerBed(workspace, Vector3.new(85, 0, 88), Vector3.new(5, 0.4, 3), Color3.fromRGB(150, 0, 200))

    -- Portal lamp posts
    buildLampPost(workspace, Vector3.new(-86, 0, -78))
    buildLampPost(workspace, Vector3.new(86, 0, -78))
    buildLampPost(workspace, Vector3.new(-86, 0, 82))
    buildLampPost(workspace, Vector3.new(86, 0, 82))

    -- ==========================================
    -- NPCs (proper R6 rigs, near their area centers)
    -- ==========================================
    createNPC("Pak Dosen", Vector3.new(15, 1, 15), "Dosen",
        Color3.fromRGB(200, 150, 100), Color3.fromRGB(50, 50, 150), Color3.fromRGB(40, 40, 80))
    createNPC("Pak Karso", Vector3.new(-280, 1, -280), "Karso",
        Color3.fromRGB(180, 130, 90), Color3.fromRGB(200, 50, 50), Color3.fromRGB(80, 60, 30))
    createNPC("Ibu Ratna", Vector3.new(280, 1, -280), "Ratna",
        Color3.fromRGB(210, 160, 110), Color3.fromRGB(200, 100, 150), Color3.fromRGB(60, 80, 40))
    createNPC("Mang Wayan", Vector3.new(-280, 1, 280), "Wayan",
        Color3.fromRGB(170, 130, 80), Color3.fromRGB(255, 200, 100), Color3.fromRGB(50, 50, 50))
    createNPC("Bapak Yanu", Vector3.new(280, 1, 280), "Yanu",
        Color3.fromRGB(90, 60, 40), Color3.fromRGB(150, 80, 30), Color3.fromRGB(60, 40, 20))

    -- ==========================================
    -- REGION LABELS
    -- ==========================================
    addLabel("🏫 KAMPUS (Spawn)", Vector3.new(0, 12, 0))
    addLabel("🟡 Wilayah Jawa", Vector3.new(-280, 14, -280))
    addLabel("🟢 Wilayah Sumatra", Vector3.new(280, 14, -280))
    addLabel("🔵 Wilayah Bali", Vector3.new(-280, 14, 280))
    addLabel("🟣 Wilayah Papua", Vector3.new(280, 14, 280))

    -- ==========================================
    -- SCATTERED DECORATIVE TREES (main area)
    -- ==========================================
    for _, tpos in ipairs({
        Vector3.new(-45, 0, -45), Vector3.new(45, 0, -45),
        Vector3.new(-45, 0, 45), Vector3.new(45, 0, 45),
        Vector3.new(-55, 0, 5), Vector3.new(55, 0, 5),
        Vector3.new(5, 0, -55), Vector3.new(5, 0, 55),
        Vector3.new(-35, 0, 35), Vector3.new(35, 0, -35),
        Vector3.new(-50, 0, -20), Vector3.new(50, 0, 20),
    }) do buildTree(workspace, tpos, math.random(8, 13)) end

    -- Scattered decorative rocks in main area
    buildRock(workspace, Vector3.new(-40, 0, -10), Vector3.new(2, 1.5, 2))
    buildRock(workspace, Vector3.new(40, 0, 10), Vector3.new(2.5, 1.8, 2))
    buildRock(workspace, Vector3.new(10, 0, -45), Vector3.new(2, 1.2, 2.5))

    -- Extra flower patches in main area
    buildFlowerBed(workspace, Vector3.new(-35, 0, 15), Vector3.new(6, 0.4, 3), Color3.fromRGB(255, 150, 200))
    buildFlowerBed(workspace, Vector3.new(35, 0, -15), Vector3.new(6, 0.4, 3), Color3.fromRGB(200, 255, 100))

    -- Lamp posts along main paths
    buildLampPost(workspace, Vector3.new(-35, 0, 0))
    buildLampPost(workspace, Vector3.new(35, 0, 0))
    buildLampPost(workspace, Vector3.new(0, 0, -35))
    buildLampPost(workspace, Vector3.new(0, 0, 35))

    -- ==========================================
    -- SETUP LIGHTING
    -- ==========================================
    setupLighting()

    print("✅ World created!")
end

-- ============================================
-- DIALOGUE HANDLER (Bug #3 fix: proper state machine)
-- ============================================
RS.DialogueChoice.OnServerEvent:Connect(function(player, choiceIndex)
    print("[Dialogue] " .. player.Name .. " chose option " .. tostring(choiceIndex))
    
    local dialogueId = playerActiveNPC[player.UserId]
    if not dialogueId then
        print("[Dialogue] No active NPC for " .. player.Name .. " (ignored)")
        return
    end

    local dialogue = DIALOGUES[dialogueId]
    if not dialogue then
        warn("[Dialogue] No dialogue data for " .. dialogueId)
        return
    end

    local currentLine = playerDialogueLine[player.UserId] or 1
    local line = dialogue.lines[currentLine]
    if not line then
        warn("[Dialogue] No line at index " .. tostring(currentLine))
        return
    end

    local choice = line.choices[choiceIndex]
    if not choice then
        warn("[Dialogue] No choice at index " .. tostring(choiceIndex))
        return
    end

    print("[Dialogue] Choice: " .. (choice.text or "no text") .. " -> " .. (choice.next or choice.action or "end"))

    if choice.action == "end" then
        -- End dialogue
        playerActiveNPC[player.UserId] = nil
        playerDialogueLine[player.UserId] = nil
        RS.DialogueEnd:FireClient(player)
        addJournalEntry(player, "💬 Selesai bicara dengan " .. dialogue.name)
    elseif choice.next then
        -- Navigate to next line
        playerDialogueLine[player.UserId] = choice.next
        local nextLine = dialogue.lines[choice.next]
        if nextLine then
            -- Send the next line data to the client
            -- The client will handle displaying it (recursive)
            RS.DialogueStart:FireClient(player, {
                name = dialogue.name,
                lines = dialogue.lines,
                startLine = choice.next,
            }, dialogueId)
        else
            -- Invalid next, end dialogue
            playerActiveNPC[player.UserId] = nil
            playerDialogueLine[player.UserId] = nil
            RS.DialogueEnd:FireClient(player)
        end
    end
end)

-- ============================================
-- QUIZ HANDLER (Bug #2 fix: use quizId param)
-- ============================================
RS.QuizAnswer.OnServerEvent:Connect(function(player, questionIndex, answerIndex, quizId)
    print("[Quiz] " .. player.Name .. " answered Q" .. tostring(questionIndex) .. " with " .. tostring(answerIndex) .. " for quiz " .. tostring(quizId))
    
    local quiz = QUIZZES[quizId]
    if not quiz then
        warn("[Quiz] Invalid quizId: " .. tostring(quizId))
        return
    end

    local question = quiz.questions[questionIndex]
    if not question then
        warn("[Quiz] Invalid question index: " .. tostring(questionIndex))
        return
    end

    local isCorrect = (answerIndex == question.correct)
    print("[Quiz] Answer " .. (isCorrect and "CORRECT" or "WRONG") .. " (expected " .. tostring(question.correct) .. ")")
    
    local results = {
        quizId = quizId,
        questionIndex = questionIndex,
        isCorrect = isCorrect,
        correctAnswer = question.correct,
    }

    if isCorrect then
        addXP(player, 50)
        addCoins(player, 25)
        RS.ShowNotification:FireClient(player, "✅ Jawaban Benar!")
        addJournalEntry(player, "✅ Benar: " .. question.q)
    else
        RS.ShowNotification:FireClient(player, "❌ Jawaban Salah!")
        addJournalEntry(player, "❌ Salah: " .. question.q)
    end

    -- Next question or end quiz
    if questionIndex < #quiz.questions then
        -- Bug #2 fix: send quizId with QuizStart
        RS.QuizStart:FireClient(player, quiz, quizId, questionIndex + 1)
    else
        -- Quiz completed
        local data = getPlayerData(player)
        if not data.completedQuizzes[quizId] then
            data.completedQuizzes[quizId] = true
            addXP(player, 100)
            addCoins(player, 50)
            addJournalEntry(player, "🎉 Quiz selesai: " .. quiz.title)
            unlockNextPortal(player, quizId)

            -- Check if all 4 quizzes are done -> trigger ending
            local quizCount = 0
            for _ in pairs(data.completedQuizzes) do
                quizCount = quizCount + 1
            end
            if quizCount >= 4 then
                task.delay(3, function()
                    checkAndTriggerEnding(player)
                end)
            end
        end
        RS.QuizEnd:FireClient(player, quizId, results)
    end
end)


-- ============================================
-- TALK REQUEST (client fallback if prompt flaky)
-- ============================================
local function beginDialogue(player, dialogueId)
    if not player or not dialogueId then return end
    local dialogue = DIALOGUES[dialogueId]
    if not dialogue then
        warn("[NPC] No dialogue for id " .. tostring(dialogueId))
        return
    end
    local data = getPlayerData(player)
    if not data then return end
    data.talkCount = (data.talkCount or 0) + 1
    playerActiveNPC[player.UserId] = dialogueId
    playerDialogueLine[player.UserId] = 1
    RS.DialogueStart:FireClient(player, dialogue, dialogueId)
    addJournalEntry(player, "💬 Berbicara dengan " .. dialogue.name)
    print("[NPC] Dialogue started via beginDialogue: " .. dialogueId .. " for " .. player.Name)
end

RS.TalkRequest.OnServerEvent:Connect(function(player, dialogueId)
    print("[TalkRequest] " .. player.Name .. " -> " .. tostring(dialogueId))
    -- Clear stuck state always on explicit request
    playerActiveNPC[player.UserId] = nil
    playerDialogueLine[player.UserId] = nil
    beginDialogue(player, dialogueId)
end)


-- ============================================
-- PORTAL REQUEST (client E / prompt fallback)
-- ============================================
local PORTAL_META = {
    PortalJawa = { quizId = "quiz_jawa", destination = Vector3.new(-280, 4, -280), label = "Wilayah Jawa" },
    PortalSumatra = { quizId = "quiz_sumatra", destination = Vector3.new(280, 4, -280), label = "Wilayah Sumatra" },
    PortalBali = { quizId = "quiz_bali", destination = Vector3.new(-280, 4, 280), label = "Wilayah Bali" },
    PortalPapua = { quizId = "quiz_papua", destination = Vector3.new(280, 4, 280), label = "Wilayah Papua" },
    quiz_jawa = { quizId = "quiz_jawa", destination = Vector3.new(-280, 4, -280), label = "Wilayah Jawa" },
    quiz_sumatra = { quizId = "quiz_sumatra", destination = Vector3.new(280, 4, -280), label = "Wilayah Sumatra" },
    quiz_bali = { quizId = "quiz_bali", destination = Vector3.new(-280, 4, 280), label = "Wilayah Bali" },
    quiz_papua = { quizId = "quiz_papua", destination = Vector3.new(280, 4, 280), label = "Wilayah Papua" },
}

local function enterPortalById(player, portalKey)
    local meta = PORTAL_META[portalKey]
    if not meta then
        warn("[Portal] Unknown key " .. tostring(portalKey))
        return
    end
    local data = getPlayerData(player)
    if not data then return end
    local quizId = meta.quizId
    if not data.unlockedPortals[quizId] then
        RS.ShowNotification:FireClient(player, "🔒 Portal terkunci. Selesaikan quiz sebelumnya / bicara Pak Dosen.")
        return
    end
    local character = player.Character
    if character then
        local hrp2 = character:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            hrp2.CFrame = CFrame.new(meta.destination + Vector3.new(0, 3, 0))
        end
    end
    RS.ShowNotification:FireClient(player, "🌍 Memasuki " .. meta.label)
    if data.completedQuizzes[quizId] then
        RS.ShowNotification:FireClient(player, "✅ Wilayah ini sudah tuntas.")
        return
    end
    local quizData = QUIZZES[quizId]
    if quizData then
        task.delay(0.6, function()
            RS.QuizStart:FireClient(player, quizData, quizId, 1)
        end)
        addJournalEntry(player, "📝 Memasuki quiz: " .. quizData.title)
    end
end

RS.PortalRequest.OnServerEvent:Connect(function(player, portalKey)
    print("[PortalRequest] " .. player.Name .. " -> " .. tostring(portalKey))
    enterPortalById(player, portalKey)
end)

-- ============================================
-- GAME START HANDLER
-- ============================================
RS.GameStart.OnServerEvent:Connect(function(player)
    local data = getPlayerData(player)
    data.gameStarted = true
    addJournalEntry(player, "🎮 Petualangan dimulai!")
    RS.ShowNotification:FireClient(player, "Selamat datang di Jejak Nusantara!")
    print("[GameManager] Game started for: " .. player.Name)
end)

-- ============================================
-- PLAYER LIFECYCLE
-- ============================================
local function setupPlayer(player)
    print("[GameManager] Player joined: " .. player.Name)

    local okLoad, saved = pcall(loadPlayerData, player)
    if okLoad and saved then
        playerData[player.UserId] = saved
        print("[GameManager] Loaded data for: " .. player.Name)
    else
        if not okLoad then
            warn("[GameManager] loadPlayerData error: " .. tostring(saved))
        end
        playerData[player.UserId] = createDefaultData()
        print("[GameManager] Using default data for: " .. player.Name)
    end

    playerActiveNPC[player.UserId] = nil
    playerDialogueLine[player.UserId] = nil

    local function onCharacter(character)
        local hrp = character:WaitForChild("HumanoidRootPart", 10)
        local hum = character:WaitForChild("Humanoid", 10)
        if hrp then
            -- Stand on golden spawn pad (kampus)
            hrp.CFrame = CFrame.new(0, 6, 10)
            print("[GameManager] Character placed for " .. player.Name)
        end
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
        -- Keep character fully visible
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name ~= "HumanoidRootPart" then
                    part.Transparency = math.min(part.Transparency, 0)
                end
                part.LocalTransparencyModifier = 0
            end
        end
    end

    player.CharacterAdded:Connect(onCharacter)
    if player.Character then
        task.spawn(onCharacter, player.Character)
    else
        task.defer(function()
            if player.Parent and not player.Character then
                player:LoadCharacter()
            end
        end)
    end
end

Players.PlayerAdded:Connect(setupPlayer)
-- Studio race: player may already exist before this script runs
for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(setupPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    playerData[player.UserId] = nil
    playerActiveNPC[player.UserId] = nil
    playerDialogueLine[player.UserId] = nil
    print("[GameManager] Player leaving: " .. player.Name)
end)

-- Auto-save every 60 seconds
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
    end
end)

-- ============================================
-- CREATE WORLD
-- ============================================
local ok, err = pcall(createWorld)
if not ok then
    warn("⚠️ createWorld error: " .. tostring(err))
    warn("⚠️ Game will still run but world may be incomplete")
end

print("✅ All systems ready!")
print("🎮 ============================================")
print("🎮 JEJAK NUSANTARA v4.0 - READY!")
print("🎮 Click ▶ PLAY untuk mulai!")
print("🎮 ============================================")
