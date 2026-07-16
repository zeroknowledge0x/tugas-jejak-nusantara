--[[
    ============================================
    JEJAK NUSANTARA v4.0 - CLIENT SCRIPT
    ============================================
    Place in: StarterPlayer/StarterPlayerScripts (LocalScript)
    
    Features:
    - Main Menu UI
    - Dialogue UI with recursive choice handling (Bug #4 fix)
    - Quiz UI using server-sent quizId (Bug #2 fix)
    - HUD (Level, XP, Coins)
    - Journal panel (J key)
    - Ending screen
    - Notification System
    
    v4.0 fixes:
    - Bug #4: recursive dialogue display
    - Bug #5: removed duplicate selectedAnswer
    - Added: Journal, Ending screen, quizId tracking
]]

print("🎮 GameClient v4.6 - Loading...")

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Force third-person camera on YOUR character (fixes freecam / invisible self)
local function bindCamera(character)
	if not character then return end
	local hum = character:WaitForChild("Humanoid", 10)
	local cam = workspace.CurrentCamera
	if hum and cam then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
		cam.FieldOfView = 70
	end
	-- Ensure local character parts are visible
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.LocalTransparencyModifier = 0
		end
	end
end
player.CharacterAdded:Connect(bindCamera)
if player.Character then
	task.spawn(bindCamera, player.Character)
end
task.spawn(function()
	-- If character still missing (Studio race), ask server via LoadCharacter path
	task.wait(2)
	if not player.Character then
		warn("[Client] No character after 2s — retry camera bind when it appears")
	end
end)


-- State
local currentDialogue = nil
local currentQuiz = nil
local currentQuizId = nil -- Bug #2 fix: track quizId from server

-- ============================================
-- WAIT FOR REMOTES (created by server)
-- ============================================
local function waitRemote(name)
	local r = RS:WaitForChild(name, 30)
	if not r then
		warn("[Client] MISSING remote: " .. name)
	else
		print("[Client] remote ok: " .. name)
	end
	return r
end

local RE_GameStart        = waitRemote("GameStart")
local RE_DialogueStart    = waitRemote("DialogueStart")
local RE_DialogueEnd      = waitRemote("DialogueEnd")
local RE_DialogueChoice   = waitRemote("DialogueChoice")
local RE_QuizStart        = waitRemote("QuizStart")
local RE_QuizAnswer       = waitRemote("QuizAnswer")
local RE_QuizEnd          = waitRemote("QuizEnd")
local RE_ShowNotification = waitRemote("ShowNotification")
local RE_StateUpdate      = waitRemote("StateUpdate")
local RF_GetPlayerData    = waitRemote("GetPlayerData")
local RE_JournalUpdate    = waitRemote("JournalUpdate")
local RE_EndingTriggered  = waitRemote("EndingTriggered")
local RE_LevelUnlocked    = waitRemote("LevelUnlocked")
local RE_TalkRequest      = waitRemote("TalkRequest")
local RE_PortalRequest    = waitRemote("PortalRequest")

print("✅ Remotes ready!")
local currentQuestionIndex = 1
local selectedAnswer = nil
local journalEntries = {}
local journalVisible = false
local endingShown = false

-- ============================================
-- SCREEN GUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JejakNusantaraUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 50
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============================================
-- MAIN MENU
-- ============================================
local mainMenu = Instance.new("Frame")
mainMenu.Name = "MainMenu"
mainMenu.Size = UDim2.new(1, 0, 1, 0)
mainMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainMenu.BorderSizePixel = 0
mainMenu.Visible = true
mainMenu.Parent = screenGui

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 32, 28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 28, 28))
}
gradient.Parent = mainMenu

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.8, 0, 0.15, 0)
titleLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "JEJAK NUSANTARA"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainMenu

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(0.6, 0, 0.06, 0)
subtitleLabel.Position = UDim2.new(0.2, 0, 0.25, 0)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Dialog → Portal → Quiz → 4 wilayah → Ending"
subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
subtitleLabel.TextScaled = true
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.Parent = mainMenu

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0.2, 0, 0.04, 0)
versionLabel.Position = UDim2.new(0.4, 0, 0.32, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v4.6 · Nusantara"
versionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
versionLabel.TextScaled = true
versionLabel.Font = Enum.Font.Gotham
versionLabel.Parent = mainMenu

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0.3, 0, 0.08, 0)
startButton.Position = UDim2.new(0.35, 0, 0.45, 0)
startButton.BackgroundColor3 = Color3.fromRGB(196, 80, 40)
startButton.Text = "🎮 MULAI PETUALANGAN"
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextScaled = true
startButton.Font = Enum.Font.GothamBold
startButton.Parent = mainMenu

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 10)
startCorner.Parent = startButton

startButton.MouseEnter:Connect(function()
    TweenService:Create(startButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 120, 50)}):Play()
end)
startButton.MouseLeave:Connect(function()
    TweenService:Create(startButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(196, 80, 40)}):Play()
end)

-- ============================================
-- HUD
-- ============================================
local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.Size = UDim2.new(0, 250, 0, 120)
hud.Position = UDim2.new(1, -260, 0, 10)
hud.BackgroundColor3 = Color3.fromRGB(20, 28, 24)
hud.BackgroundTransparency = 0.3
hud.Visible = false
hud.Parent = screenGui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 10)
hudCorner.Parent = hud

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(1, -20, 0, 25)
levelLabel.Position = UDim2.new(0, 10, 0, 5)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "Level 1"
levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
levelLabel.TextScaled = true
levelLabel.Font = Enum.Font.GothamBold
levelLabel.Parent = hud

local xpBarBg = Instance.new("Frame")
xpBarBg.Size = UDim2.new(1, -20, 0, 15)
xpBarBg.Position = UDim2.new(0, 10, 0, 35)
xpBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
xpBarBg.Parent = hud

local xpBarCorner = Instance.new("UICorner")
xpBarCorner.CornerRadius = UDim.new(0, 4)
xpBarCorner.Parent = xpBarBg

local xpBar = Instance.new("Frame")
xpBar.Name = "Fill"
xpBar.Size = UDim2.new(0, 0, 1, 0)
xpBar.BackgroundColor3 = Color3.fromRGB(218, 165, 32)
xpBar.Parent = xpBarBg

local xpBarFillCorner = Instance.new("UICorner")
xpBarFillCorner.CornerRadius = UDim.new(0, 4)
xpBarFillCorner.Parent = xpBar

local xpText = Instance.new("TextLabel")
xpText.Size = UDim2.new(1, 0, 1, 0)
xpText.BackgroundTransparency = 1
xpText.Text = "0 / 1000 XP"
xpText.TextColor3 = Color3.fromRGB(255, 255, 255)
xpText.TextScaled = true
xpText.Font = Enum.Font.GothamBold
xpText.ZIndex = 2
xpText.Parent = xpBarBg

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(1, -20, 0, 25)
coinsLabel.Position = UDim2.new(0, 10, 0, 55)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "💰 0"
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Parent = hud

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(1, -20, 0, 20)
hintLabel.Position = UDim2.new(0, 10, 0, 85)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "E=Bicara/Portal · J=Jurnal · jatuh=checkpoint"
hintLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
hintLabel.TextScaled = true
hintLabel.Font = Enum.Font.Gotham

hintLabel.Parent = hud

-- OBJECTIVE TRACKER (game loop visible)
local objectivePanel = Instance.new("Frame")
objectivePanel.Name = "ObjectivePanel"
objectivePanel.Size = UDim2.new(0, 320, 0, 110)
objectivePanel.Position = UDim2.new(0, 12, 0, 12)
objectivePanel.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
objectivePanel.BackgroundTransparency = 0.15
objectivePanel.Visible = false
objectivePanel.Parent = screenGui
local opCorner = Instance.new("UICorner")
opCorner.CornerRadius = UDim.new(0, 10)
opCorner.Parent = objectivePanel
local opStroke = Instance.new("UIStroke")
opStroke.Color = Color3.fromRGB(218, 165, 32)
opStroke.Thickness = 1.5
opStroke.Transparency = 0.3
opStroke.Parent = objectivePanel
local objTitle = Instance.new("TextLabel")
objTitle.Size = UDim2.new(1, -16, 0, 24)
objTitle.Position = UDim2.new(0, 8, 0, 6)
objTitle.BackgroundTransparency = 1
objTitle.Text = "TUJUAN MISI"
objTitle.TextColor3 = Color3.fromRGB(255, 210, 80)
objTitle.TextXAlignment = Enum.TextXAlignment.Left
objTitle.Font = Enum.Font.GothamBold
objTitle.TextScaled = true
objTitle.Parent = objectivePanel
local objBody = Instance.new("TextLabel")
objBody.Name = "Body"
objBody.Size = UDim2.new(1, -16, 0, 70)
objBody.Position = UDim2.new(0, 8, 0, 32)
objBody.BackgroundTransparency = 1
objBody.Text = "1) Bicara dengan Pak Dosen (E)\n2) Masuk PORTAL di kampus (E)\n3) Kerjakan QUIZ di wilayah\n4) Selesaikan 4 wilayah → Ending"
objBody.TextColor3 = Color3.fromRGB(230, 230, 235)
objBody.TextXAlignment = Enum.TextXAlignment.Left
objBody.TextYAlignment = Enum.TextYAlignment.Top
objBody.Font = Enum.Font.Gotham
objBody.TextSize = 14
objBody.TextWrapped = true
objBody.Parent = objectivePanel

local function setObjective(text)
	objBody.Text = text
	objectivePanel.Visible = true
end


-- ============================================
-- DIALOGUE UI
-- ============================================
local dialogueFrame = Instance.new("Frame")
dialogueFrame.Name = "Dialogue"
dialogueFrame.Size = UDim2.new(0.7, 0, 0.42, 0)
dialogueFrame.Position = UDim2.new(0.15, 0, 0.52, 0)
dialogueFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 22)
dialogueFrame.BackgroundTransparency = 0.05
dialogueFrame.Visible = false
dialogueFrame.ZIndex = 50
dialogueFrame.Parent = screenGui

local dialogueCorner = Instance.new("UICorner")
dialogueCorner.CornerRadius = UDim.new(0, 15)
dialogueCorner.Parent = dialogueFrame

local npcName = Instance.new("TextLabel")
npcName.Size = UDim2.new(1, -20, 0, 30)
npcName.Position = UDim2.new(0, 10, 0, 10)
npcName.BackgroundTransparency = 1
npcName.Text = "NPC"
npcName.TextColor3 = Color3.fromRGB(255, 200, 100)
npcName.TextScaled = true
npcName.Font = Enum.Font.GothamBold
npcName.Parent = dialogueFrame

local dialogueText = Instance.new("TextLabel")
dialogueText.Size = UDim2.new(1, -20, 0, 50)
dialogueText.Position = UDim2.new(0, 10, 0, 45)
dialogueText.BackgroundTransparency = 1
dialogueText.Text = ""
dialogueText.TextColor3 = Color3.fromRGB(255, 255, 255)
dialogueText.TextScaled = true
dialogueText.Font = Enum.Font.Gotham
dialogueText.TextWrapped = true
dialogueText.Parent = dialogueFrame

local choicesFrame = Instance.new("ScrollingFrame")
choicesFrame.Name = "Choices"
choicesFrame.Size = UDim2.new(1, -20, 0, 120)
choicesFrame.Position = UDim2.new(0, 10, 0, 100)
choicesFrame.BackgroundTransparency = 1
choicesFrame.ScrollBarThickness = 6
choicesFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
choicesFrame.Parent = dialogueFrame

local choicesLayout = Instance.new("UIListLayout")
choicesLayout.Padding = UDim.new(0, 5)
choicesLayout.SortOrder = Enum.SortOrder.LayoutOrder
choicesLayout.Parent = choicesFrame

-- ============================================
-- QUIZ UI
-- ============================================
local quizFrame = Instance.new("Frame")
quizFrame.Name = "Quiz"
quizFrame.Size = UDim2.new(0.5, 0, 0.55, 0)
quizFrame.Position = UDim2.new(0.25, 0, 0.2, 0)
quizFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
quizFrame.BackgroundTransparency = 0.1
quizFrame.Visible = false
quizFrame.Parent = screenGui

local quizCorner = Instance.new("UICorner")
quizCorner.CornerRadius = UDim.new(0, 15)
quizCorner.Parent = quizFrame

local quizTitle = Instance.new("TextLabel")
quizTitle.Size = UDim2.new(1, -20, 0, 40)
quizTitle.Position = UDim2.new(0, 10, 0, 10)
quizTitle.BackgroundTransparency = 1
quizTitle.Text = "Quiz"
quizTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
quizTitle.TextScaled = true
quizTitle.Font = Enum.Font.GothamBold
quizTitle.Parent = quizFrame

local quizQuestion = Instance.new("TextLabel")
quizQuestion.Size = UDim2.new(1, -20, 0, 60)
quizQuestion.Position = UDim2.new(0, 10, 0, 55)
quizQuestion.BackgroundTransparency = 1
quizQuestion.Text = ""
quizQuestion.TextColor3 = Color3.fromRGB(255, 255, 255)
quizQuestion.TextScaled = true
quizQuestion.Font = Enum.Font.Gotham
quizQuestion.TextWrapped = true
quizQuestion.Parent = quizFrame

local quizAnswers = Instance.new("Frame")
quizAnswers.Name = "Answers"
quizAnswers.Size = UDim2.new(1, -20, 0, 200)
quizAnswers.Position = UDim2.new(0, 10, 0, 120)
quizAnswers.BackgroundTransparency = 1
quizAnswers.Parent = quizFrame

local quizAnswersLayout = Instance.new("UIListLayout")
quizAnswersLayout.Padding = UDim.new(0, 5)
quizAnswersLayout.SortOrder = Enum.SortOrder.LayoutOrder
quizAnswersLayout.Parent = quizAnswers

local quizProgress = Instance.new("TextLabel")
quizProgress.Size = UDim2.new(1, -20, 0, 30)
quizProgress.Position = UDim2.new(0, 10, 0, 330)
quizProgress.BackgroundTransparency = 1
quizProgress.Text = ""
quizProgress.TextColor3 = Color3.fromRGB(100, 255, 100)
quizProgress.TextScaled = true
quizProgress.Font = Enum.Font.Gotham
quizProgress.Parent = quizFrame

-- ============================================
-- JOURNAL PANEL
-- ============================================
local journalFrame = Instance.new("Frame")
journalFrame.Name = "Journal"
journalFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
journalFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
journalFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
journalFrame.BackgroundTransparency = 0.05
journalFrame.Visible = false
journalFrame.Parent = screenGui

local journalCorner = Instance.new("UICorner")
journalCorner.CornerRadius = UDim.new(0, 12)
journalCorner.Parent = journalFrame

local journalTitle = Instance.new("TextLabel")
journalTitle.Size = UDim2.new(1, -20, 0, 35)
journalTitle.Position = UDim2.new(0, 10, 0, 5)
journalTitle.BackgroundTransparency = 1
journalTitle.Text = "📖 Jurnal Petualangan"
journalTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
journalTitle.TextScaled = true
journalTitle.Font = Enum.Font.GothamBold
journalTitle.Parent = journalFrame

local journalScroll = Instance.new("ScrollingFrame")
journalScroll.Size = UDim2.new(1, -20, 1, -50)
journalScroll.Position = UDim2.new(0, 10, 0, 40)
journalScroll.BackgroundTransparency = 1
journalScroll.ScrollBarThickness = 6
journalScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
journalScroll.Parent = journalFrame

local journalLayout = Instance.new("UIListLayout")
journalLayout.Padding = UDim.new(0, 3)
journalLayout.SortOrder = Enum.SortOrder.LayoutOrder
journalLayout.Parent = journalScroll

local closeJournalBtn = Instance.new("TextButton")
closeJournalBtn.Size = UDim2.new(0, 30, 0, 30)
closeJournalBtn.Position = UDim2.new(1, -35, 0, 5)
closeJournalBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeJournalBtn.Text = "X"
closeJournalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeJournalBtn.TextScaled = true
closeJournalBtn.Font = Enum.Font.GothamBold
closeJournalBtn.Parent = journalFrame

local closeJournalCorner = Instance.new("UICorner")
closeJournalCorner.CornerRadius = UDim.new(0, 6)
closeJournalCorner.Parent = closeJournalBtn

closeJournalBtn.MouseButton1Click:Connect(function()
    journalFrame.Visible = false
    journalVisible = false
end)

-- ============================================
-- ENDING SCREEN
-- ============================================
local endingFrame = Instance.new("Frame")
endingFrame.Name = "Ending"
endingFrame.Size = UDim2.new(1, 0, 1, 0)
endingFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
endingFrame.BackgroundTransparency = 0
endingFrame.Visible = false
endingFrame.ZIndex = 100
endingFrame.Parent = screenGui

local endingTitle = Instance.new("TextLabel")
endingTitle.Size = UDim2.new(0.8, 0, 0.12, 0)
endingTitle.Position = UDim2.new(0.1, 0, 0.1, 0)
endingTitle.BackgroundTransparency = 1
endingTitle.Text = ""
endingTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
endingTitle.TextScaled = true
endingTitle.Font = Enum.Font.GothamBold
endingTitle.ZIndex = 101
endingTitle.Parent = endingFrame

local endingDesc = Instance.new("TextLabel")
endingDesc.Size = UDim2.new(0.7, 0, 0.25, 0)
endingDesc.Position = UDim2.new(0.15, 0, 0.25, 0)
endingDesc.BackgroundTransparency = 1
endingDesc.Text = ""
endingDesc.TextColor3 = Color3.fromRGB(220, 220, 220)
endingDesc.TextScaled = true
endingDesc.Font = Enum.Font.Gotham
endingDesc.TextWrapped = true
endingDesc.ZIndex = 101
endingDesc.Parent = endingFrame

local endingStats = Instance.new("TextLabel")
endingStats.Size = UDim2.new(0.5, 0, 0.15, 0)
endingStats.Position = UDim2.new(0.25, 0, 0.55, 0)
endingStats.BackgroundTransparency = 1
endingStats.Text = ""
endingStats.TextColor3 = Color3.fromRGB(200, 200, 200)
endingStats.TextScaled = true
endingStats.Font = Enum.Font.Gotham
endingStats.TextWrapped = true
endingStats.ZIndex = 101
endingStats.Parent = endingFrame

local endingRestartBtn = Instance.new("TextButton")
endingRestartBtn.Size = UDim2.new(0.3, 0, 0.07, 0)
endingRestartBtn.Position = UDim2.new(0.35, 0, 0.75, 0)
endingRestartBtn.BackgroundColor3 = Color3.fromRGB(196, 80, 40)
endingRestartBtn.Text = "🔄 Main Lagi"
endingRestartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
endingRestartBtn.TextScaled = true
endingRestartBtn.Font = Enum.Font.GothamBold
endingRestartBtn.ZIndex = 101
endingRestartBtn.Parent = endingFrame

local endingRestartCorner = Instance.new("UICorner")
endingRestartCorner.CornerRadius = UDim.new(0, 10)
endingRestartCorner.Parent = endingRestartBtn

endingRestartBtn.MouseButton1Click:Connect(function()
    endingFrame.Visible = false
    mainMenu.Visible = true
    hud.Visible = false
    endingShown = false
end)

-- ============================================
-- NOTIFICATION
-- ============================================
local notifFrame = Instance.new("Frame")
notifFrame.Size = UDim2.new(0.4, 0, 0.08, 0)
notifFrame.Position = UDim2.new(0.3, 0, 0.05, 0)
notifFrame.BackgroundColor3 = Color3.fromRGB(196, 80, 40)
notifFrame.BackgroundTransparency = 0.2
notifFrame.Visible = false
notifFrame.ZIndex = 50
notifFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notifFrame

local notifText = Instance.new("TextLabel")
notifText.Size = UDim2.new(1, -20, 1, -10)
notifText.Position = UDim2.new(0, 10, 0, 5)
notifText.BackgroundTransparency = 1
notifText.Text = ""
notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
notifText.TextScaled = true
notifText.Font = Enum.Font.GothamBold
notifText.ZIndex = 51
notifText.Parent = notifFrame

print("✅ UI created!")

-- ============================================
-- UI FUNCTIONS
-- ============================================
local notifQueue = {}
local notifActive = false

local function processNotifQueue()
    if notifActive then return end
    if #notifQueue == 0 then return end
    notifActive = true
    local text = table.remove(notifQueue, 1)
    notifText.Text = text
    notifFrame.Visible = true
    task.delay(2.5, function()
        notifFrame.Visible = false
        notifActive = false
        if #notifQueue > 0 then
            task.defer(processNotifQueue)
        end
    end)
end

local function showNotification(text)
    table.insert(notifQueue, text)
    processNotifQueue()
end

local function typewriterEffect(textLabel, fullText)
    textLabel.Text = ""
    for i = 1, #fullText do
        textLabel.Text = string.sub(fullText, 1, i)
        task.wait(0.02)
    end
end

local function updateHUD()
    local data = RF_GetPlayerData:InvokeServer()
    if data then
        levelLabel.Text = "Level " .. (data.level or 1)
        local xpPct = (data.xp or 0) / (data.xpToNext or 1000)
        xpBar.Size = UDim2.new(math.min(xpPct, 1), 0, 1, 0)
        xpText.Text = (data.xp or 0) .. " / " .. (data.xpToNext or 1000) .. " XP"
        coinsLabel.Text = "💰 " .. (data.coins or 0)
    end
end

-- ============================================
-- JOURNAL FUNCTIONS
-- ============================================
local function addJournalEntry(text)
    table.insert(journalEntries, text)
    local entry = Instance.new("TextLabel")
    entry.Size = UDim2.new(1, -10, 0, 25)
    entry.BackgroundTransparency = 1
    entry.Text = text
    entry.TextColor3 = Color3.fromRGB(200, 200, 180)
    entry.TextScaled = true
    entry.Font = Enum.Font.Gotham
    entry.TextWrapped = true
    entry.TextXAlignment = Enum.TextXAlignment.Left
    entry.LayoutOrder = #journalEntries
    entry.Parent = journalScroll
    -- Update canvas size
    journalScroll.CanvasSize = UDim2.new(0, 0, 0, #journalEntries * 28)
end

local function toggleJournal()
    journalVisible = not journalVisible
    journalFrame.Visible = journalVisible
end

-- ============================================
-- DIALOGUE FUNCTIONS (Bug #4 fix: recursive)
-- ============================================
local function clearChoices()
    for _, child in ipairs(choicesFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function showDialogueLine(dialogueData, lineIndex)
    local line = dialogueData.lines[lineIndex]
    if not line then return end

    -- Typewriter the text
    task.spawn(function()
        typewriterEffect(dialogueText, line.text)
    end)

    -- Clear old choices
    clearChoices()

    -- Wait a moment for typewriter to start, then show choices
    task.wait(0.1)

    if line.choices then
        -- Update canvas size based on choice count
        local choiceCount = #line.choices
        choicesFrame.CanvasSize = UDim2.new(0, 0, 0, choiceCount * 40)

        for i, choice in ipairs(line.choices) do
            local btn = Instance.new("TextButton")
            btn.Name = "Choice" .. i
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.BackgroundColor3 = Color3.fromRGB(40, 70, 80)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextScaled = true
            btn.Font = Enum.Font.Gotham
            btn.Text = choice.text
            btn.LayoutOrder = i
            btn.Parent = choicesFrame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = btn

            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 110, 100)}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 70, 80)}):Play()
            end)

            btn.MouseButton1Click:Connect(function()
                if choice.action == "end" then
                    -- Tell server to end dialogue
                    RE_DialogueChoice:FireServer(i)
                elseif choice.next then
                    -- Bug #4 fix: tell server which choice we picked
                    -- Server will send back next line via DialogueStart
                    RE_DialogueChoice:FireServer(i)
                end
            end)
        end
    end
end

local function showDialogue(data, dialogueId)
    if typeof(data) ~= "table" then
        warn("[Client] showDialogue bad data: " .. typeof(data))
        return
    end
    currentDialogue = data
    npcName.Text = data.name or tostring(dialogueId) or "NPC"
    dialogueFrame.Visible = true
    dialogueFrame.ZIndex = 100
    screenGui.DisplayOrder = 100
    print("[Client] showDialogue: " .. tostring(npcName.Text) .. " id=" .. tostring(dialogueId))

    local startLine = data.startLine or 1
    local okLine, errLine = pcall(function()
        showDialogueLine(data, startLine)
    end)
    if not okLine then
        warn("[Client] showDialogueLine error: " .. tostring(errLine))
        local lines = data.lines
        if type(lines) == "table" and lines[1] then
            dialogueText.Text = tostring(lines[1].text or "")
        end
    end
end

-- ============================================
-- QUIZ FUNCTIONS (Bug #2 fix: use server quizId)
-- ============================================
local function showQuiz(quizData, quizId, questionIndex)
    currentQuiz = quizData
    currentQuizId = quizId -- Bug #2 fix: store quizId from server
    currentQuestionIndex = questionIndex
    selectedAnswer = nil -- Bug #5 fix: only one reset

    quizTitle.Text = quizData.title
    quizProgress.Text = "Soal " .. currentQuestionIndex .. " dari " .. #quizData.questions

    local question = quizData.questions[currentQuestionIndex]
    quizQuestion.Text = question.q

    -- Clear old answers
    for _, child in ipairs(quizAnswers:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    -- Create answer buttons
    for i, answer in ipairs(question.a) do
        local btn = Instance.new("TextButton")
        btn.Name = "Answer" .. i
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(40, 70, 80)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.Gotham
        btn.Text = answer
        btn.LayoutOrder = i
        btn.Parent = quizAnswers

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        btn.MouseEnter:Connect(function()
            if not selectedAnswer then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 110, 100)}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if not selectedAnswer then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 70, 80)}):Play()
            end
        end)

        btn.MouseButton1Click:Connect(function()
            if selectedAnswer then return end
            selectedAnswer = i

            -- Visual feedback
            for _, child in ipairs(quizAnswers:GetChildren()) do
                if child:IsA("TextButton") then
                    child.AutoButtonColor = false
                    if child == btn then
                        child.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                    else
                        child.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                    end
                end
            end

            -- Bug #2 fix: send server-sent quizId
            task.delay(1.5, function()
                RE_QuizAnswer:FireServer(currentQuestionIndex, i, currentQuizId)
            end)
        end)
    end

    quizFrame.Visible = true
end

-- ============================================
-- ENDING SCREEN
-- ============================================
local function showEnding(endingId, endingData)
    if endingShown then return end
    endingShown = true

    endingTitle.Text = endingData.title
    endingDesc.Text = endingData.description

    -- Stats
    local data = RF_GetPlayerData:InvokeServer()
    if data then
        local quizCount = 0
        if data.completedQuizzes then
            for _ in pairs(data.completedQuizzes) do
                quizCount = quizCount + 1
            end
        end
        endingStats.Text = "Level: " .. (data.level or 1)
            .. "  |  XP: " .. (data.xp or 0)
            .. "  |  Koin: " .. (data.coins or 0)
            .. "  |  Quiz: " .. quizCount .. "/4"
    end

    -- Color
    local r, g, b = endingData.color[1], endingData.color[2], endingData.color[3]
    endingTitle.TextColor3 = Color3.fromRGB(r, g, b)

    endingFrame.Visible = true
end


-- Design system: rounded panels + soft gold stroke
local function stylePanel(gui, radius)
	radius = radius or 12
	local c = gui:FindFirstChildOfClass("UICorner")
	if not c then
		c = Instance.new("UICorner")
		c.Parent = gui
	end
	c.CornerRadius = UDim.new(0, radius)
	local s = gui:FindFirstChildOfClass("UIStroke")
	if not s then
		s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(218, 165, 32)
		s.Thickness = 1.5
		s.Transparency = 0.35
		s.Parent = gui
	end
end
stylePanel(hud, 12)
stylePanel(dialogueFrame, 16)
stylePanel(quizFrame, 16)
stylePanel(journalFrame, 14)
stylePanel(endingFrame, 16)
stylePanel(startButton, 12)

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Game Start
startButton.MouseButton1Click:Connect(function()
    mainMenu.Visible = false
    hud.Visible = true
    if objectivePanel then objectivePanel.Visible = true end
    RE_GameStart:FireServer()
    updateHUD()
    if player.Character then
        bindCamera(player.Character)
    end
    if setObjective then
        setObjective("LANGKAH 1: Dekati Pak Dosen (label kuning) → tekan E / Bicara\nLalu cari PORTAL berwarna di tepi kampus → tekan E (Masuk) untuk QUIZ")
    end
end)

-- Dialogue Start (Bug #1 fix: server now sends dialogueId too)
if RE_DialogueStart then
	RE_DialogueStart.OnClientEvent:Connect(function(data, dialogueId)
		print("[Client] DialogueStart received id=" .. tostring(dialogueId))
		local success, err = pcall(function()
			showDialogue(data, dialogueId)
		end)
		if not success then
			warn("[Client] showDialogue error: " .. tostring(err))
		end
	end)
else
	warn("[Client] RE_DialogueStart is nil — dialogue will not show")
end

-- Dialogue End
RE_DialogueEnd.OnClientEvent:Connect(function()
    dialogueFrame.Visible = false
    clearChoices()
    currentDialogue = nil
    updateHUD()
end)

-- Quiz Start (Bug #2 fix: receives quizId from server)
RE_QuizStart.OnClientEvent:Connect(function(quizData, quizId, questionIndex)
    showQuiz(quizData, quizId, questionIndex)
    if setObjective then
        setObjective("QUIZ AKTIF: jawab semua soal di layar.\nBenar = XP + koin. Selesai 4 wilayah = Ending.")
    end
end)

-- Quiz End
RE_QuizEnd.OnClientEvent:Connect(function(quizId, results)
    quizFrame.Visible = false
    currentQuiz = nil
    currentQuizId = nil
    showNotification("🎉 Quiz selesai!")
    updateHUD()
end)

-- Notification
RE_ShowNotification.OnClientEvent:Connect(function(text)
    showNotification(text)
end)

-- State Update
RE_StateUpdate.OnClientEvent:Connect(function(key, value)
    updateHUD()
end)

-- Journal Update
RE_JournalUpdate.OnClientEvent:Connect(function(entry)
    addJournalEntry(entry)
end)

-- Level Unlocked
RE_LevelUnlocked.OnClientEvent:Connect(function(levelId)
    showNotification("🔓 Wilayah baru terbuka!")
end)

-- Ending Triggered
RE_EndingTriggered.OnClientEvent:Connect(function(endingId, endingData)
    showEnding(endingId, endingData)
end)

-- Input (J key for journal)
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.J then
        toggleJournal()
    end
end)

-- Periodic HUD update
task.spawn(function()
    while true do
        task.wait(5)
        if hud.Visible then
            updateHUD()
        end
    end
end)


-- ============================================
-- PROMPT FALLBACK (Studio-proof dialogue trigger)
-- ============================================
local ProximityPromptService = game:GetService("ProximityPromptService")

local NPC_NAME_TO_ID = {
	["Pak Dosen"] = "Dosen",
	["Pak Karso"] = "Karso",
	["Ibu Ratna"] = "Ratna",
	["Mang Wayan"] = "Wayan",
	["Bapak Yanu"] = "Yanu",
}

local function requestTalk(dialogueId, reason)
	if not dialogueId then
		warn("[Client] requestTalk missing id (" .. tostring(reason) .. ")")
		return
	end
	if not RE_TalkRequest then
		warn("[Client] TalkRequest remote missing")
		return
	end
	print("[Client] TalkRequest " .. tostring(dialogueId) .. " via " .. tostring(reason))
	RE_TalkRequest:FireServer(dialogueId)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
	if plr ~= player then return end
	if prompt.ActionText == "Masuk" then
		local parent = prompt.Parent
		local key = parent and parent.Name
		if key and RE_PortalRequest then
			print("[Client] Portal prompt -> " .. tostring(key))
			RE_PortalRequest:FireServer(key)
		end
		return
	end
	if prompt.ActionText ~= "Bicara" then return end
	local parent = prompt.Parent
	local dialogueId = nil
	if parent then
		dialogueId = parent:GetAttribute("DialogueId")
		if not dialogueId and parent.Parent then
			dialogueId = parent.Parent:GetAttribute("DialogueId")
		end
	end
	if not dialogueId then
		dialogueId = NPC_NAME_TO_ID[prompt.ObjectText]
	end
	print("[Client] Bicara prompt — server handles dialogue (no double fire)")
end)

local function findNearestNPC(maxDist)
	maxDist = maxDist or 20
	local char = player.Character
	if not char then return nil, nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil, nil end
	local bestId, bestD = nil, maxDist
	for _, inst in ipairs(workspace:GetChildren()) do
		if inst:IsA("Model") and inst:GetAttribute("IsNPC") then
			local id = inst:GetAttribute("DialogueId")
			local part = inst.PrimaryPart or inst:FindFirstChild("Head") or inst:FindFirstChild("Torso")
			if part and id then
				local d = (part.Position - hrp.Position).Magnitude
				if d < bestD then
					bestD = d
					bestId = id
				end
			end
		end
	end
	return bestId, bestD
end

-- E key: talk to nearest NPC (always works even if prompt UI hidden)
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.E then
		-- Prefer NPC if close, else portal
		local id = findNearestNPC(18)
		if id then
			requestTalk(id, "KeyE")
			return
		end
		-- nearest portal
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and RE_PortalRequest then
			local bestKey, bestD = nil, 24
			for _, inst in ipairs(workspace:GetChildren()) do
				if inst:IsA("BasePart") and inst:GetAttribute("IsPortal") then
					local d = (inst.Position - hrp.Position).Magnitude
					if d < bestD then
						bestD = d
						bestKey = inst.Name
					end
				end
			end
			if bestKey then
				print("[Client] E near portal -> " .. bestKey)
				RE_PortalRequest:FireServer(bestKey)
			else
				print("[Client] E: no NPC/portal nearby")
			end
		end
	end
end)


print("✅ GameClient v4.6 ready!")

