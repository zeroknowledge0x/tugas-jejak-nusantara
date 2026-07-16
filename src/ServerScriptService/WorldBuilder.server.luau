--! WorldBuilder.server.luau
--! Builds a visible playable world on the SERVER so the place is never empty,
--! even if the client LocalScript fails. Creates Baseplate, SpawnLocation, and
--! NPC Budi (with BillboardGui + ProximityPrompt).

local Workspace = game:GetService("Workspace")

local function ensureBaseplate()
	local existing = Workspace:FindFirstChild("Baseplate")
	if existing then
		return existing
	end
	local p = Instance.new("Part")
	p.Name = "Baseplate"
	p.Size = Vector3.new(256, 4, 256)
	p.Position = Vector3.new(0, -2, 0)
	p.Anchored = true
	p.Color = Color3.fromRGB(40, 160, 70)
	p.Material = Enum.Material.Grass
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = Workspace
	return p
end

local function ensureSpawn()
	local existing = Workspace:FindFirstChild("SpawnLocation")
	if existing then
		return existing
	end
	local s = Instance.new("SpawnLocation")
	s.Name = "SpawnLocation"
	s.Size = Vector3.new(6, 1, 6)
	s.Position = Vector3.new(0, 0.5, 0)
	s.Anchored = true
	s.Duration = 0
	s.Neutral = true
	s.Color = Color3.fromRGB(255, 220, 80)
	s.Material = Enum.Material.Neon
	s.Parent = Workspace
	return s
end

local function ensureBudi()
	local existing = Workspace:FindFirstChild("Budi")
	if existing then
		return existing
	end
	local part = Instance.new("Part")
	part.Name = "Budi"
	part.Size = Vector3.new(2, 5, 2)
	part.Position = Vector3.new(0, 3, -12)
	part.Anchored = true
	part.Color = Color3.fromRGB(30, 120, 255)
	part.Material = Enum.Material.Neon
	part.Parent = Workspace

	local bill = Instance.new("BillboardGui")
	bill.Name = "Label"
	bill.Size = UDim2.new(0, 200, 0, 50)
	bill.StudsOffset = Vector3.new(0, 3.5, 0)
	bill.AlwaysOnTop = true
	bill.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	label.Text = "BUDI — tekan E / klik Bicara"
	label.TextColor3 = Color3.fromRGB(255, 220, 80)
	label.TextScaled = true
	label.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ObjectText = "Budi"
	prompt.ActionText = "Bicara"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = part

	return part
end

ensureBaseplate()
ensureSpawn()
ensureBudi()
print("[JN] WorldBuilder ready: Baseplate + Spawn + Budi")
