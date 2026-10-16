local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local function sendNotification(title, text, duration)
	task.spawn(function()
		local tries = 0
		while tries < 15 do
			local success = pcall(function()
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = title,
					Text = text,
					Duration = duration or 3
				})
			end)
			if success then break end
			task.wait(0.3)
			tries = tries + 1
		end
	end)
end
sendNotification("Zwyy Visuals", "Script Baslatiliyor...", 3)

local camera = Workspace.CurrentCamera
local player = Players.LocalPlayer
local _w = 0
while not player and _w < 50 do
	player = Players.LocalPlayer
	task.wait(0.1)
	_w = _w + 1
end
local playerGui = player and (player:FindFirstChild("PlayerGui") or player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5))

-- ----------------------------------------------------
-- Değişkenler & Ayarlar
-- ----------------------------------------------------
local crosshairEnabled = false
local spinEnabled = false
local crosshairLength = 16
local crosshairThickness = 3
local crosshairGap = 6
local baseColor = Color3.fromRGB(0, 255, 140)
local neonIntensity = 1.0
local spinSpeed = 180

local aspectRatioEnabled = false
local stretchScale = 0.67

local customFovEnabled = false
local customFovValue = 90
local defaultFovValue = 70

local spinBotEnabled = false
local spinBotSpeed = 30
local currentSpinAngle = 0

local speedGlitchEnabled = false
local speedGlitchPower = 45

local optimizerEnabled = false

-- TP Drop Gun Tuş Ataması
local tpGunKey = nil
local tpKeybindBtn = nil
local shootKeybindBtn = nil
local isBindingTpGun = false

-- Shoot & Wallbang
local shootKey = nil
local isBindingShoot = false
local isShooting = false
local wallbangEnabled = true

-- Fling Durumları
local isFlinging = false
local flingSheriffBtn = nil
local flingMurderBtn = nil
local selectedFlingPlayer = nil
local targetFlingBtn = nil

-- R6 FE Animasyon ID'leri (Gazer Veritabanı)
local r6AnimEnabled = false
local r6IDs = {
	idle = {"12521158637", "12521162526"},
	walk = "12518152696",
	run = "12518152696",
	jump = "12520880485",
	fall = "12520972571",
	climb = "12520982150",
	swim = "12518152696",
	swimidle = "12518152696"
}

-- Normal ESP (Main Sekmesi)
local normalEspEnabled = false
local normalEspColor = Color3.fromRGB(0, 255, 140)
local normalEspTransparency = 0.4
local normalEspTeamCheck = true
local normalEspNames = true
local normalEspTracers = false

-- MM2 ESP (MM2 Sekmesi)
local mm2EspEnabled = false
local mm2EspFlags = {
	MurdererESP = true,
	SheriffESP = true,
	InnocentESP = true,
	GunDropESP = true,
	Names = true,
	Tracers = false
}

-- Hitbox Expander (Genel & Şerif Özel)
local hitboxEnabled = false
local hitboxSize = 14
local hitboxTransparency = 0.6
local originalHitboxProps = {}


-- Anti-Fling Koruması
local antiFlingEnabled = false
local lastSafeCFrame = nil

-- ForceField (FF / Godmode) Koruması
local ffEnabled = false
local currentForceField = nil

-- TSB (The Strongest Battlegrounds) Auto Block Koruması
local autoBlockEnabled = false
local autoBlockRange = 25
local isBlocking = false
local VirtualInputManager = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil

-- Forsaken (Auto Generator & Skillcheck) Ayarları
local forsakenAutoGenEnabled = false
local forsakenGenSpeed = 40 -- Ortanın biraz altı (Gecikme 0.40s: Anti-cheat spam korumasına takılmaz)
local forsakenAutoSkillCheck = false
local forsakenGenEsp = false
local genHighlights = {}


-- ----------------------------------------------------
-- Katman Yönetimi
local menuGui = Instance.new("ScreenGui")
menuGui.Name = "ZwyyVisual_Menu"
menuGui.DisplayOrder = 10
menuGui.ResetOnSpawn = false

local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name = "ZwyyVisual_Crosshair"
crosshairGui.DisplayOrder = 999999
crosshairGui.IgnoreGuiInset = true
crosshairGui.ResetOnSpawn = false

local espDrawingGui = Instance.new("ScreenGui")
espDrawingGui.Name = "ZwyyVisual_Drawing"
espDrawingGui.DisplayOrder = 99999
espDrawingGui.IgnoreGuiInset = true
espDrawingGui.ResetOnSpawn = false

local function mountGui(gui)
	if not gui then return end
	gui.Enabled = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local targetParent = nil

	-- Öncelik 1: gethui() (Solara ve modern executorlar için gizli ve engellenemez container)
	if typeof(gethui) == "function" then
		pcall(function()
			local h = gethui()
			if h and typeof(h) == "Instance" then
				targetParent = h
			end
		end)
	end

	-- Öncelik 2: CoreGui (gethui yoksa ve executor yetkisi varsa)
	if not targetParent then
		pcall(function()
			local cg = game:GetService("CoreGui")
			if cg then
				local test = Instance.new("Folder")
				test.Parent = cg
				test:Destroy()
				targetParent = cg
			end
		end)
	end

	-- Öncelik 3: PlayerGui (Fallback)
	if not targetParent then
		pcall(function()
			local pg = player and (player:FindFirstChild("PlayerGui") or player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)) or playerGui
			if pg then
				targetParent = pg
			end
		end)
	end

	if targetParent then
		-- Eski kopyaları temizle
		pcall(function()
			local old = targetParent:FindFirstChild(gui.Name)
			if old and old ~= gui then
				old:Destroy()
			end
		end)
		pcall(function()
			gui.Parent = targetParent
		end)
	end
end

mountGui(menuGui)
mountGui(crosshairGui)
mountGui(espDrawingGui)

-- ----------------------------------------------------
-- Gazer Motor Senkronizasyonlu R6 FE Animasyon Sistemi
-- ----------------------------------------------------
local function freezeChar()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = true end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			part.Anchored = true
		end
	end
end

local function unfreezeChar()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Anchored then
			part.Anchored = false
		end
	end
end

local function stopTrackByName(trackNameKeyword)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
			local name = track.Name:lower()
			if not trackNameKeyword or name:find(trackNameKeyword:lower()) then
				track:Stop(0)
			end
		end
	end
end

local function applyFullR6Set()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local animate = char:FindFirstChild("Animate")
	if not hum or not animate then return end

	freezeChar()
	task.wait(0.08)

	pcall(function()
		-- 1. IDLE
		stopTrackByName("idle")
		if animate:FindFirstChild("idle") then
			if animate.idle:FindFirstChild("Animation1") then
				animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=0"
				animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.idle[1]
			end
			if animate.idle:FindFirstChild("Animation2") then
				animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=0"
				animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.idle[2]
			end
		end

		-- 2. WALK & RUN (Kapsamlı R6 Senkronizasyonu - Hızlı koşarken donmayı önler)
		stopTrackByName("walk")
		stopTrackByName("run")
		if animate:FindFirstChild("walk") then
			for _, child in ipairs(animate.walk:GetChildren()) do
				if child:IsA("Animation") then
					child.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.walk
				end
			end
			if not animate.walk:FindFirstChild("WalkAnim") then
				local wa = Instance.new("Animation")
				wa.Name = "WalkAnim"
				wa.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.walk
				wa.Parent = animate.walk
			end
		end

		if animate:FindFirstChild("run") then
			for _, child in ipairs(animate.run:GetChildren()) do
				if child:IsA("Animation") then
					child.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.run
				end
			end
			if not animate.run:FindFirstChild("RunAnim") then
				local ra = Instance.new("Animation")
				ra.Name = "RunAnim"
				ra.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.run
				ra.Parent = animate.run
			end
		end

		-- 4. JUMP
		stopTrackByName("jump")
		if animate:FindFirstChild("jump") and animate.jump:FindFirstChild("JumpAnim") then
			animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
			animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.jump
		end

		-- 5. FALL
		stopTrackByName("fall")
		if animate:FindFirstChild("fall") and animate.fall:FindFirstChild("FallAnim") then
			animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
			animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.fall
		end

		-- 6. CLIMB
		stopTrackByName("climb")
		if animate:FindFirstChild("climb") and animate.climb:FindFirstChild("ClimbAnim") then
			animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
			animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.climb
		end

		-- 7. SWIM
		stopTrackByName("swim")
		if animate:FindFirstChild("swim") and animate.swim:FindFirstChild("Swim") then
			animate.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=0"
			animate.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.swim
		end

		-- 8. SWIM IDLE
		if animate:FindFirstChild("swimidle") and animate.swimidle:FindFirstChild("SwimIdle") then
			animate.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=0"
			animate.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=" .. r6IDs.swimidle
		end
	end)

	-- Gazer State Pipeline (Sunucuya yeni animasyon track'lerini zorla aktarır)
	hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	task.wait(0.04)
	hum:ChangeState(Enum.HumanoidStateType.Freefall)
	task.wait(0.04)
	hum:ChangeState(Enum.HumanoidStateType.Landed)

	task.wait(0.08)
	unfreezeChar()
end

local function resetToDefaultAnimations()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local animate = char:FindFirstChild("Animate")
	if not hum or not animate then return end

	freezeChar()
	task.wait(0.08)

	for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end

	pcall(function()
		if animate:FindFirstChild("idle") then
			if animate.idle:FindFirstChild("Animation1") then animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=507766666" end
			if animate.idle:FindFirstChild("Animation2") then animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=507766951" end
		end
		if animate:FindFirstChild("walk") and animate.walk:FindFirstChild("WalkAnim") then animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=507777826" end
		if animate:FindFirstChild("run") and animate.run:FindFirstChild("RunAnim") then animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=507767714" end
		if animate:FindFirstChild("jump") and animate.jump:FindFirstChild("JumpAnim") then animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=507765000" end
		if animate:FindFirstChild("fall") and animate.fall:FindFirstChild("FallAnim") then animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=507767968" end
		if animate:FindFirstChild("climb") and animate.climb:FindFirstChild("ClimbAnim") then animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=507765644" end
	end)

	hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	task.wait(0.04)
	hum:ChangeState(Enum.HumanoidStateType.Freefall)
	task.wait(0.04)
	hum:ChangeState(Enum.HumanoidStateType.Landed)

	task.wait(0.08)
	unfreezeChar()
end

-- Respawn olduğunda gecikmeli ve garantili yükleme
player.CharacterAdded:Connect(function(newChar)
	if r6AnimEnabled then
		task.spawn(function()
			local hum = newChar:WaitForChild("Humanoid", 10)
			local animate = newChar:WaitForChild("Animate", 10)
			if hum and animate then
				task.wait(0.5)
				applyFullR6Set()
			end
		end)
	end
end)

-- ----------------------------------------------------
-- Skin Changer (Client-Sided Korblox & Headless)
-- ----------------------------------------------------
local headlessEnabled = false
local korbloxEnabled = false

local function applyHeadless(state)
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local face = head:FindFirstChild("face")
	local mesh = head:FindFirstChildOfClass("SpecialMesh")

	if state then
		head.Transparency = 1
		if face then face.Transparency = 1 end
		if mesh then
			mesh.Scale = Vector3.new(0, 0, 0)
		end
	else
		head.Transparency = 0
		if face then face.Transparency = 0 end
		if mesh then
			mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
		end
	end
end

local function applyKorblox(state)
	local char = player.Character
	if not char then return end

	-- R15 Parçaları
	local rLower = char:FindFirstChild("RightLowerLeg")
	local rUpper = char:FindFirstChild("RightUpperLeg")
	local rFoot = char:FindFirstChild("RightFoot")

	-- R6 Parçaları
	local rLeg = char:FindFirstChild("Right Leg")

	if state then
		-- 1. R6 MODU (Tam Korblox Bacağı)
		if rLeg then
			rLeg.Transparency = 0 -- R6'da SpecialMesh'in görünmesi için 0 olmalı

			-- Eski meshleri temizle
			for _, child in ipairs(rLeg:GetChildren()) do
				if child:IsA("SpecialMesh") or child.Name == "KorbloxMesh" then
					child:Destroy()
				end
			end

			-- Orijinal Korblox Deathspeaker R6 Mesh
			local sm = Instance.new("SpecialMesh")
			sm.Name = "KorbloxMesh"
			sm.MeshType = Enum.MeshType.FileMesh
			sm.MeshId = "rbxassetid://101851696"
			sm.TextureId = "rbxassetid://101851254"
			sm.Scale = Vector3.new(1, 1, 1)
			sm.Parent = rLeg

			-- Native R6 CharacterMesh desteği
			local existingCM = char:FindFirstChild("KorbloxCharacterMesh")
			if not existingCM then
				local cm = Instance.new("CharacterMesh")
				cm.Name = "KorbloxCharacterMesh"
				cm.BodyPart = Enum.BodyPart.RightLeg
				cm.MeshId = 101851696
				cm.Parent = char
			end

			local oldPart = char:FindFirstChild("ClientKorbloxLeg")
			if oldPart then oldPart:Destroy() end

		-- 2. R15 MODU
		elseif rLower and rUpper and rFoot then
			rLower.Transparency = 1
			rFoot.Transparency = 1

			local existingLeg = char:FindFirstChild("ClientKorbloxLeg")
			if not existingLeg then
				local leg = Instance.new("Part")
				leg.Name = "ClientKorbloxLeg"
				leg.Size = Vector3.new(1, 2, 1)
				leg.CanCollide = false
				leg.Massless = true
				leg.Transparency = 0
				leg.CastShadow = false

				local specialMesh = Instance.new("SpecialMesh")
				specialMesh.MeshType = Enum.MeshType.FileMesh
				specialMesh.MeshId = "rbxassetid://101851696"
				specialMesh.TextureId = "rbxassetid://101851254"
				specialMesh.Scale = Vector3.new(1, 1, 1)
				specialMesh.Parent = leg

				local weld = Instance.new("Weld")
				weld.Part0 = rLower
				weld.Part1 = leg
				weld.C0 = CFrame.new(0, 0, 0)
				weld.Parent = leg

				leg.Parent = char
			end
		end
	else
		-- Kapatıldığında eski haline döndür
		if rLeg then
			rLeg.Transparency = 0
			local sm = rLeg:FindFirstChild("KorbloxMesh")
			if sm then sm:Destroy() end
			local cm = char:FindFirstChild("KorbloxCharacterMesh")
			if cm then cm:Destroy() end
		end
		if rLower and rFoot then
			rLower.Transparency = 0
			rFoot.Transparency = 0
		end
		local existingLeg = char:FindFirstChild("ClientKorbloxLeg")
		if existingLeg then existingLeg:Destroy() end
	end
end

-- Karakter yenilenince (Respawn) otomatik tekrar uygula
player.CharacterAdded:Connect(function(char)
	task.wait(0.4)
	if headlessEnabled then pcall(function() applyHeadless(true) end) end
	if korbloxEnabled then pcall(function() applyKorblox(true) end) end
end)

-- Oyun içi saydamlık yenilenmelerine karşı koruma
RunService.Heartbeat:Connect(function()
	if headlessEnabled then
		local char = player.Character
		if char then
			local head = char:FindFirstChild("Head")
			if head and head.Transparency ~= 1 then
				applyHeadless(true)
			end
		end
	end
	if korbloxEnabled then
		local char = player.Character
		if char then
			local rLeg = char:FindFirstChild("Right Leg")
			if rLeg and not rLeg:FindFirstChild("KorbloxMesh") then
				applyKorblox(true)
			end
			local rLower = char:FindFirstChild("RightLowerLeg")
			if rLower and not char:FindFirstChild("ClientKorbloxLeg") then
				applyKorblox(true)
			end
		end
	end
end)

-- ----------------------------------------------------
-- Neon Crosshair
-- ----------------------------------------------------
local function getNeonColors()
	local r = math.clamp(baseColor.R + (neonIntensity * 0.25), 0, 1)
	local g = math.clamp(baseColor.G + (neonIntensity * 0.25), 0, 1)
	local b = math.clamp(baseColor.B + (neonIntensity * 0.25), 0, 1)
	local coreColor = Color3.new(r, g, b)
	local glowAlpha = math.clamp(0.65 - (neonIntensity * 0.15), 0.1, 0.7)
	local glowThickness = math.clamp(neonIntensity * 2.5, 1.5, 8)
	return coreColor, baseColor, glowAlpha, glowThickness
end

local crosshairContainer = Instance.new("Frame")
crosshairContainer.Name = "CrosshairContainer"
crosshairContainer.Size = UDim2.new(0, 100, 0, 100)
crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairContainer.BackgroundTransparency = 1
crosshairContainer.Active = false
crosshairContainer.Visible = false
crosshairContainer.ZIndex = 99999999
crosshairContainer.Parent = crosshairGui

local crosshairRotator = Instance.new("Frame")
crosshairRotator.Name = "Rotator"
crosshairRotator.Size = UDim2.new(1, 0, 1, 0)
crosshairRotator.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairRotator.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairRotator.BackgroundTransparency = 1
crosshairRotator.Active = false
crosshairRotator.ZIndex = 99999999
crosshairRotator.Parent = crosshairContainer

local armBars, armStrokes = {}, {}
local angles = {45, 135, 225, 315}

for _, ang in ipairs(angles) do
	local pivot = Instance.new("Frame")
	pivot.Size = UDim2.new(0, 0, 0, 0)
	pivot.Position = UDim2.new(0.5, 0, 0.5, 0)
	pivot.AnchorPoint = Vector2.new(0.5, 0.5)
	pivot.BackgroundTransparency = 1
	pivot.Rotation = ang
	pivot.Active = false
	pivot.ZIndex = 99999999
	pivot.Parent = crosshairRotator

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 0, -crosshairGap)
	bar.Size = UDim2.new(0, crosshairThickness, 0, crosshairLength)
	bar.BorderSizePixel = 0
	bar.Active = false
	bar.ZIndex = 99999999
	bar.Parent = pivot

	local barCorner = Instance.new("UICorner") barCorner.CornerRadius = UDim.new(1, 0) barCorner.Parent = bar
	local glowStroke = Instance.new("UIStroke") glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border glowStroke.Parent = bar

	table.insert(armBars, bar)
	table.insert(armStrokes, glowStroke)
end

local function updateCrosshairAppearance()
	local coreColor, glowColor, glowAlpha, glowThickness = getNeonColors()
	for i, bar in ipairs(armBars) do
		bar.Size = UDim2.new(0, crosshairThickness, 0, crosshairLength)
		bar.Position = UDim2.new(0.5, 0, 0, -crosshairGap)
		bar.BackgroundColor3 = coreColor
		local stroke = armStrokes[i]
		stroke.Color = glowColor
		stroke.Transparency = glowAlpha
		stroke.Thickness = glowThickness
	end
end
updateCrosshairAppearance()

-- ----------------------------------------------------
-- Rol Tespiti & ESP
-- ----------------------------------------------------
local highlights = {}
local nameLabels = {}
local tracerLines = {}

local function getRole(targetPlr)
	if not targetPlr.Character then return nil end
	local hasKnife, hasGun = false, false

	local function checkTool(tool)
		if tool:IsA("Tool") then
			local n = tool.Name:lower()
			if n:find("knife") or n:find("murderer") or n:find("blade") then hasKnife = true end
			if n:find("gun") or n:find("revolver") or n:find("sheriff") then hasGun = true end
		end
	end

	local bp = targetPlr:FindFirstChild("Backpack")
	if bp then for _, t in ipairs(bp:GetChildren()) do checkTool(t) end end
	local charTool = targetPlr.Character:FindFirstChildOfClass("Tool")
	if charTool then checkTool(charTool) end

	if hasKnife then return "Murderer" end
	if hasGun then return "Sheriff" end
	return "Innocent"
end

local function getMurdererPlayer()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and getRole(p) == "Murderer" then
			return p
		end
	end
	return nil
end

local function getSheriffPlayer()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and getRole(p) == "Sheriff" then
			return p
		end
	end
	return nil
end

local function removePlayerVisuals(targetPlr)
	if highlights[targetPlr] then highlights[targetPlr]:Destroy() highlights[targetPlr] = nil end
	if nameLabels[targetPlr] then nameLabels[targetPlr]:Destroy() nameLabels[targetPlr] = nil end
	if tracerLines[targetPlr] then tracerLines[targetPlr]:Destroy() tracerLines[targetPlr] = nil end
end

local function hookPlayerCleanup(targetPlr)
	targetPlr.CharacterAdded:Connect(function() removePlayerVisuals(targetPlr) end)
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayerCleanup(p) end
Players.PlayerAdded:Connect(hookPlayerCleanup)
Players.PlayerRemoving:Connect(removePlayerVisuals)
local function isTeammate(targetPlr)
	if not targetPlr or targetPlr == player then return true end
	if player.Team ~= nil and targetPlr.Team ~= nil then
		return player.Team == targetPlr.Team
	end
	if player.TeamColor ~= nil and targetPlr.TeamColor ~= nil and player.TeamColor.Name ~= "White" and player.TeamColor.Name ~= "Medium stone grey" then
		return player.TeamColor == targetPlr.TeamColor
	end
	local myTeamAttr = player:GetAttribute("Team")
	local theirTeamAttr = targetPlr:GetAttribute("Team")
	if myTeamAttr and theirTeamAttr then
		return myTeamAttr == theirTeamAttr
	end
	return false
end

local function createOrUpdateVisuals(targetPlr, color, tagText, showTracer, showName, transparency)
	local char = targetPlr.Character
	if not char then removePlayerVisuals(targetPlr) return end

	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then removePlayerVisuals(targetPlr) return end

	local hl = highlights[targetPlr]
	if not hl or hl.Adornee ~= char or hl.Parent ~= espDrawingGui then
		if hl then hl:Destroy() end
		hl = Instance.new("Highlight")
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = char
		hl.Parent = espDrawingGui
		highlights[targetPlr] = hl
	end
	hl.FillColor = color
	hl.OutlineColor = color
	hl.FillTransparency = transparency or 0.3
	hl.OutlineTransparency = 0
	hl.Enabled = true

	local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)

	if showName and onScreen then
		local lbl = nameLabels[targetPlr]
		if not lbl or lbl.Parent ~= espDrawingGui then
			if lbl then lbl:Destroy() end
			lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0, 160, 0, 20)
			lbl.AnchorPoint = Vector2.new(0.5, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 13
			lbl.Parent = espDrawingGui
			nameLabels[targetPlr] = lbl
		end
		lbl.Visible = true
		lbl.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y - 24)
		lbl.TextColor3 = color
		lbl.Text = string.format("%s [%s]", targetPlr.DisplayName, tagText)
	elseif nameLabels[targetPlr] then
		nameLabels[targetPlr].Visible = false
	end

	if showTracer and onScreen then
		local line = tracerLines[targetPlr]
		if not line or line.Parent ~= espDrawingGui then
			if line then line:Destroy() end
			line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.BorderSizePixel = 0
			line.Parent = espDrawingGui
			tracerLines[targetPlr] = line
		end

		local origin = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
		local target = Vector2.new(screenPos.X, screenPos.Y)
		local dist = (target - origin).Magnitude
		local angle = math.deg(math.atan2(target.Y - origin.Y, target.X - origin.X))

		line.Visible = true
		line.Size = UDim2.new(0, dist, 0, 1.5)
		line.Position = UDim2.new(0, (origin.X + target.X) / 2, 0, (origin.Y + target.Y) / 2)
		line.Rotation = angle
		line.BackgroundColor3 = color
	elseif tracerLines[targetPlr] then
		tracerLines[targetPlr].Visible = false
	end
end

-- ----------------------------------------------------
-- GunDrop, TP & Silent Aim Shoot
-- ----------------------------------------------------
local currentGunDrop = nil
local gunHighlight = nil

local function triggerTpGun()
	local gun = currentGunDrop
	if not gun or not gun.Parent then
		for _, obj in ipairs(Workspace:GetChildren()) do
			if (obj.Name == "GunDrop" or obj.Name:lower():find("gundrop")) and (obj:IsA("BasePart") or obj:IsA("Model")) then
				gun = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
				break
			end
		end
	end

	if gun then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			gun.CFrame = char.HumanoidRootPart.CFrame
		end
	end
end

local shootOffset = 0
local offsetToPingMult = 1

-- ----------------------------------------------------
-- YARHM 1.21 Exact Silent Aim & Direct Torso Lock (Anti-Jumper)
-- ----------------------------------------------------
local function getPredictedPosition(targetPlayer, offset)
	local targetChar = targetPlayer and targetPlayer.Character
	if not targetChar then return nil end

	-- Doğrudan Torso merkezine kilitlenir (Jumper oyuncular havada yön değiştirse bile kaçamaz)
	local torso = targetChar:FindFirstChild("UpperTorso")
		or targetChar:FindFirstChild("Torso")
		or targetChar:FindFirstChild("LowerTorso")
		or targetChar:FindFirstChild("HumanoidRootPart")
	local playerHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not torso or not playerHum then return nil end

	return torso.Position
end

local function isVisibleToUs(originPos, murdererChar)
	if wallbangEnabled then return true end
	if not murdererChar then return false end
	local targetPart = murdererChar:FindFirstChild("UpperTorso") or murdererChar:FindFirstChild("Torso") or murdererChar:FindFirstChild("HumanoidRootPart") or murdererChar:FindFirstChild("Head")
	if not targetPart then return false end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {player.Character}
	rayParams.IgnoreWater = true

	local direction = targetPart.Position - originPos
	local result = Workspace:Raycast(originPos, direction, rayParams)
	return (not result) or result.Instance:IsDescendantOf(murdererChar)
end

local function getShootRemote(tool)
	if not tool then return nil, nil end

	-- 1. YARHM Standart MM2: Gun.KnifeLocal.CreateBeam.RemoteFunction
	local knifeLocal = tool:FindFirstChild("KnifeLocal") or tool:FindFirstChild("GunLocal")
	if knifeLocal then
		local createBeam = knifeLocal:FindFirstChild("CreateBeam")
		if createBeam and createBeam:FindFirstChild("RemoteFunction") then
			return createBeam.RemoteFunction, "CreateBeam"
		end
	end

	-- 2. Tool içindeki tüm nesnelerde CreateBeam araması
	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("RemoteFunction") and desc.Parent and desc.Parent.Name == "CreateBeam" then
			return desc, "CreateBeam"
		end
	end

	-- 3. Herhangi bir RemoteFunction
	local anyRf = tool:FindFirstChildWhichIsA("RemoteFunction", true)
	if anyRf then
		return anyRf, "CreateBeam"
	end

	-- 4. YARHM Alternatif: Gun.Shoot RemoteEvent
	local shootEv = tool:FindFirstChild("Shoot", true)
	if shootEv and shootEv:IsA("RemoteEvent") then
		return shootEv, "ShootEvent"
	end

	return nil, nil
end

local function triggerShootMurderer()
	if isShooting then return end

	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then return end

	local bp = player:FindFirstChild("Backpack")
	local gunTool = nil

	if char:FindFirstChildOfClass("Tool") then
		local t = char:FindFirstChildOfClass("Tool")
		local n = t.Name:lower()
		if n:find("gun") or n:find("revolver") or n:find("sheriff") then
			gunTool = t
		end
	end

	if not gunTool and bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") then
				local n = t.Name:lower()
				if n:find("gun") or n:find("revolver") or n:find("sheriff") then
					gunTool = t
					break
				end
			end
		end
	end

	if not gunTool then return end

	local murderer = getMurdererPlayer()
	if not murderer or not murderer.Character then return end
	local mRoot = murderer.Character:FindFirstChild("UpperTorso") or murderer.Character:FindFirstChild("Torso") or murderer.Character:FindFirstChild("HumanoidRootPart")
	local mHum = murderer.Character:FindFirstChildOfClass("Humanoid")
	if not mRoot or not mHum or mHum.Health <= 0 then return end

	if not isVisibleToUs(root.Position, murderer.Character) then
		return
	end

	isShooting = true

	task.spawn(function()
		local previouslyInBackpack = (gunTool.Parent == bp)
		if previouslyInBackpack then
			hum:EquipTool(gunTool)
			task.wait(0.03)
		end

		-- Ateşleme anında doğrudan katilin Torso merkezini al (Jumper kaçışını engeller)
		local liveChar = murderer and murderer.Character
		local liveTorso = liveChar and (liveChar:FindFirstChild("UpperTorso") or liveChar:FindFirstChild("Torso") or liveChar:FindFirstChild("LowerTorso") or liveChar:FindFirstChild("HumanoidRootPart"))
		local aimPos = (liveTorso and liveTorso.Position) or getPredictedPosition(murderer, shootOffset) or mRoot.Position

		local shootRemote, remoteType = getShootRemote(gunTool)
		if shootRemote then
			if remoteType == "CreateBeam" then
				-- YARHM 1.21 RemoteFunction: [1] = 1, [2] = aimPos (Torso), [3] = "AH2"
				pcall(function()
					shootRemote:InvokeServer(1, aimPos, "AH2")
				end)
			elseif remoteType == "ShootEvent" then
				-- YARHM 1.21 ShootEvent: CFrame.new(RightHand.Position), CFrame.new(aimPos)
				local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or root
				pcall(function()
					shootRemote:FireServer(CFrame.new(hand.Position), CFrame.new(aimPos))
				end)
			end
		end

		task.wait(0.85)

		if previouslyInBackpack and char:FindFirstChild(gunTool.Name) then
			hum:UnequipTools()
		end

		isShooting = false
	end)
end

-- ----------------------------------------------------
-- YARHM Tabanlı Hedef Fling Sistemi (Şerif & Katil)
-- ----------------------------------------------------
local function triggerFlingTarget(targetPlr, onFinished)
	if isFlinging then
		if onFinished then onFinished() end
		return
	end

	local myChar = player.Character
	local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
	local myRoot = myHum and myHum.RootPart
	if not myChar or not myHum or not myRoot or myHum.Health <= 0 then
		if onFinished then onFinished() end
		return
	end

	if not targetPlr or not targetPlr.Character then
		if onFinished then onFinished() end
		return
	end

	local tChar = targetPlr.Character
	local tHum = tChar:FindFirstChildOfClass("Humanoid")
	local tRoot = tHum and tHum.RootPart
	local tHead = tChar:FindFirstChild("Head")
	local tAccessory = tChar:FindFirstChildOfClass("Accessory")
	local tHandle = tAccessory and tAccessory:FindFirstChild("Handle")

	if not tChar:FindFirstChildWhichIsA("BasePart") then
		if onFinished then onFinished() end
		return
	end

	if tHum and tHum.Sit then
		if onFinished then onFinished() end
		return
	end

	isFlinging = true

	task.spawn(function()
		local oldPos = myRoot.CFrame
		local oldFPDH = workspace.FallenPartsDestroyHeight
		pcall(function() workspace.FallenPartsDestroyHeight = 0/0 end)

		local oldCamSubject = workspace.CurrentCamera.CameraSubject
		if tHead then
			workspace.CurrentCamera.CameraSubject = tHead
		elseif tHandle then
			workspace.CurrentCamera.CameraSubject = tHandle
		elseif tHum then
			workspace.CurrentCamera.CameraSubject = tHum
		end

		local FPos = function(BasePart, Pos, Ang)
			myRoot.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
			pcall(function() myChar:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang) end)
			myRoot.Velocity = Vector3.new(9e7, -9e8, 9e7)
			myRoot.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
		end

		local SFBasePart = function(BasePart)
			local TimeToWait = 2.5
			local Time = tick()
			local Angle = 0
			repeat
				if myRoot and tHum then
					if BasePart.Velocity.Magnitude < 50 then
						Angle = Angle + 100
						FPos(BasePart, CFrame.new(0, 0.5, 0) + tHum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -2.5, 0) + tHum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 0.5, 0) + tHum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -2.5, 0) + tHum.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 0.5, 0) + tHum.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -2.5, 0) + tHum.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
					else
						FPos(BasePart, CFrame.new(0, -0.5, tHum.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -3.0, -tHum.WalkSpeed), CFrame.Angles(0, 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -0.5, tHum.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -3.0, 0), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -3.0, 0), CFrame.Angles(0, 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -3.0, 0), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -3.0, 0), CFrame.Angles(0, 0, 0))
						task.wait()
					end
				end
			until Time + TimeToWait < tick() or not isFlinging
		end

		local bv = Instance.new("BodyVelocity")
		bv.Parent = myRoot
		bv.Velocity = Vector3.new(0, 0, 0)
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)

		myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

		if tRoot then
			SFBasePart(tRoot)
		elseif tHead then
			SFBasePart(tHead)
		elseif tHandle then
			SFBasePart(tHandle)
		end

		if bv and bv.Parent then bv:Destroy() end
		myHum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		workspace.CurrentCamera.CameraSubject = myHum

		if oldPos then
			local resetStart = tick()
			repeat
				pcall(function()
					myRoot.CFrame = oldPos * CFrame.new(0, 0.5, 0)
					myChar:SetPrimaryPartCFrame(oldPos * CFrame.new(0, 0.5, 0))
				end)
				myHum:ChangeState(Enum.HumanoidStateType.GettingUp)
				for _, part in ipairs(myChar:GetChildren()) do
					if part:IsA("BasePart") then
						part.Velocity = Vector3.zero
						part.RotVelocity = Vector3.zero
					end
				end
				task.wait()
			until (myRoot.Position - oldPos.Position).Magnitude < 25 or tick() - resetStart > 3
		end

		pcall(function() workspace.FallenPartsDestroyHeight = oldFPDH end)
		isFlinging = false
		if onFinished then onFinished() end
	end)
end

local function triggerFlingSheriff(onFinished)
	local sheriff = getSheriffPlayer()
	triggerFlingTarget(sheriff, onFinished)
end

local function triggerFlingMurderer(onFinished)
	local murderer = getMurdererPlayer()
	triggerFlingTarget(murderer, onFinished)
end

local function triggerFlingCustom(targetP, onFinished)
	triggerFlingTarget(targetP, onFinished)
end

local function hookGunDrop(obj)
	if (obj.Name == "GunDrop" or obj.Name:lower():find("gundrop")) and (obj:IsA("BasePart") or obj:IsA("Model")) then
		local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
		if part then
			currentGunDrop = part
			if mm2EspEnabled and mm2EspFlags.GunDropESP then
				if not gunHighlight then
					gunHighlight = Instance.new("Highlight")
					gunHighlight.FillColor = Color3.fromRGB(255, 255, 255)
					gunHighlight.OutlineColor = Color3.fromRGB(255, 230, 0)
					gunHighlight.FillTransparency = 0.2
					gunHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					gunHighlight.Parent = espDrawingGui
				end
				gunHighlight.Adornee = part
				gunHighlight.Enabled = true
			end
		end
	end
end

Workspace.DescendantAdded:Connect(hookGunDrop)
Workspace.DescendantRemoving:Connect(function(obj)
	if obj == currentGunDrop or (currentGunDrop and obj:IsAncestorOf(currentGunDrop)) then
		currentGunDrop = nil
		if gunHighlight then gunHighlight.Enabled = false end
	end
end)

for _, obj in ipairs(Workspace:GetChildren()) do hookGunDrop(obj) end

local function updateAllESP()
	if not mm2EspEnabled and not normalEspEnabled then
		for p, _ in pairs(highlights) do removePlayerVisuals(p) end
		if gunHighlight then gunHighlight.Enabled = false end
		return
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			if mm2EspEnabled then
				local role = getRole(p)
				if mm2EspFlags.MurdererESP and role == "Murderer" then
					createOrUpdateVisuals(p, Color3.fromRGB(255, 45, 45), "Katil", mm2EspFlags.Tracers, mm2EspFlags.Names, 0.3)
				elseif mm2EspFlags.SheriffESP and role == "Sheriff" then
					createOrUpdateVisuals(p, Color3.fromRGB(45, 120, 255), "Şerif", mm2EspFlags.Tracers, mm2EspFlags.Names, 0.3)
				elseif mm2EspFlags.InnocentESP and role == "Innocent" then
					createOrUpdateVisuals(p, Color3.fromRGB(45, 255, 110), "Masum", mm2EspFlags.Tracers, mm2EspFlags.Names, 0.3)
				else
					removePlayerVisuals(p)
				end
			elseif normalEspEnabled then
				if normalEspTeamCheck then
					local isAlly = isTeammate(p)
					local espColor = isAlly and Color3.fromRGB(45, 255, 110) or Color3.fromRGB(255, 45, 45)
					local teamTag = (p.Team and p.Team.Name) or (isAlly and "Takım" or "Düşman")
					createOrUpdateVisuals(p, espColor, teamTag, normalEspTracers, normalEspNames, normalEspTransparency)
				else
					createOrUpdateVisuals(p, normalEspColor, "Oyuncu", normalEspTracers, normalEspNames, normalEspTransparency)
				end
			else
				removePlayerVisuals(p)
			end
		end
	end

	if currentGunDrop and currentGunDrop.Parent and mm2EspEnabled and mm2EspFlags.GunDropESP then
		if not gunHighlight then
			gunHighlight = Instance.new("Highlight")
			gunHighlight.FillColor = Color3.fromRGB(255, 255, 255)
			gunHighlight.OutlineColor = Color3.fromRGB(255, 230, 0)
			gunHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			gunHighlight.Parent = espDrawingGui
		end
		gunHighlight.Adornee = currentGunDrop
		gunHighlight.Enabled = true
	elseif gunHighlight then
		gunHighlight.Enabled = false
	end
end

-- ----------------------------------------------------
-- Hitbox Expander & MM2 Bıçak Reach Sistemi
-- ----------------------------------------------------
local hitboxParts = {"HumanoidRootPart", "UpperTorso", "Torso"}

local function getLocalKnife()
	local char = player.Character
	if not char then return nil end
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		local n = tool.Name:lower()
		if n:find("knife") or n:find("blade") or n:find("murderer") then
			return tool
		end
	end
	return nil
end

local function triggerKnifeHitNearby()
	local knife = getLocalKnife()
	if not knife then return end
	local handle = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
	if not handle then return end

	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	local reachDist = hitboxSize + 4

	for _, targetPlr in ipairs(Players:GetPlayers()) do
		if targetPlr ~= player and targetPlr.Character then
			local tChar = targetPlr.Character
			local tHum = tChar:FindFirstChildOfClass("Humanoid")
			local tRoot = tChar:FindFirstChild("HumanoidRootPart")
			if tHum and tHum.Health > 0 and tRoot then
				local dist = (tRoot.Position - myRoot.Position).Magnitude
				if dist <= reachDist then
					pcall(function()
						if firetouchinterest then
							for _, pName in ipairs({"UpperTorso", "Torso", "Head", "HumanoidRootPart"}) do
								local targetPart = tChar:FindFirstChild(pName)
								if targetPart then
									firetouchinterest(targetPart, handle, 0)
									firetouchinterest(targetPart, handle, 1)
								end
							end
						end
					end)
				end
			end
		end
	end
end

local function hookKnifeTool(knifeTool)
	if not knifeTool or not knifeTool:IsA("Tool") then return end
	local n = knifeTool.Name:lower()
	if n:find("knife") or n:find("blade") or n:find("murderer") then
		knifeTool.Activated:Connect(function()
			if hitboxEnabled then
				task.spawn(function()
					for i = 1, 6 do
						triggerKnifeHitNearby()
						task.wait(0.04)
					end
				end)
			end
		end)
	end
end

pcall(function()
	if player.Character then
		for _, tool in ipairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") then hookKnifeTool(tool) end
		end
		player.Character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then hookKnifeTool(child) end
		end)
	end
end)

player.CharacterAdded:Connect(function(newChar)
	newChar.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then hookKnifeTool(child) end
	end)
end)

local function applyHitboxToPlayer(targetPlr)
	if targetPlr == player then return end
	local char = targetPlr.Character
	if not char then return end

	if not originalHitboxProps[targetPlr] then
		originalHitboxProps[targetPlr] = {}
	end

	for _, partName in ipairs(hitboxParts) do
		local part = char:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			if not originalHitboxProps[targetPlr][partName] then
				originalHitboxProps[targetPlr][partName] = {
					Size = part.Size,
					Transparency = part.Transparency,
					CanCollide = part.CanCollide
				}
			end
			part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
			if partName == "HumanoidRootPart" then
				part.Transparency = hitboxTransparency
			else
				part.Transparency = 1
			end
			part.CanCollide = false
			part.CanTouch = true
		end
	end
end

local function restorePlayerHitbox(targetPlr)
	if targetPlr.Character and originalHitboxProps[targetPlr] then
		for partName, props in pairs(originalHitboxProps[targetPlr]) do
			local part = targetPlr.Character:FindFirstChild(partName)
			if part and part:IsA("BasePart") and type(props) == "table" and props.Size then
				part.Size = props.Size
				part.Transparency = props.Transparency
				part.CanCollide = props.CanCollide
				part.CanTouch = true
			end
		end
	elseif targetPlr.Character then
		local hrp = targetPlr.Character:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			hrp.Size = Vector3.new(2, 2, 1)
			hrp.Transparency = 1
			hrp.CanCollide = false
			hrp.CanTouch = true
		end
	end
	originalHitboxProps[targetPlr] = nil
end

local function updateAllHitboxes()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			if hitboxEnabled then applyHitboxToPlayer(p) else restorePlayerHitbox(p) end
		end
	end
end

-- RenderStepped döngüsü (Hitbox boyut ve vuruş takibi)
RunService.RenderStepped:Connect(function()
if not hitboxEnabled then return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			for _, partName in ipairs(hitboxParts) do
				local part = p.Character:FindFirstChild(partName)
				if part and part:IsA("BasePart") then
					if not originalHitboxProps[p] then
						originalHitboxProps[p] = {}
					end
					if not originalHitboxProps[p][partName] then
						originalHitboxProps[p][partName] = {
							Size = part.Size,
							Transparency = part.Transparency,
							CanCollide = part.CanCollide
						}
					end
					part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
					if partName == "HumanoidRootPart" then
						part.Transparency = hitboxTransparency
					else
						part.Transparency = 1
					end
					part.CanTouch = true
				end
			end
		end
	end
end)

-- Stepped döngüsü (Fizik çarpışmalarını engeller: içine girmeyi sağlar ve Anti-Fling koruması)
RunService.Stepped:Connect(function()
if hitboxEnabled then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				for _, partName in ipairs(hitboxParts) do
					local part = p.Character:FindFirstChild(partName)
					if part and part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end
	end

	-- Anti-Fling: Diğer tüm oyuncuların CanCollide özelliğini kapatır.
	-- Bize çarparak fizik ivmesi aktaramazlar, içimizden hayalet gibi geçerler.
	-- NOT: Kendi fling'imiz aktifken (isFlinging) çalışmaz, böylece kendi fling sistemimiz bozulmaz.
	if antiFlingEnabled and not isFlinging then
		for _, otherPlr in ipairs(Players:GetPlayers()) do
			if otherPlr ~= player and otherPlr.Character then
				for _, part in ipairs(otherPlr.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(newPlr)
	newPlr.CharacterAdded:Connect(function()
		task.wait(0.3)
		if hitboxEnabled then applyHitboxToPlayer(newPlr) end
	end)
end)

Players.PlayerRemoving:Connect(function(leavingPlr)
	originalHitboxProps[leavingPlr] = nil
end)


-- ----------------------------------------------------
-- ForceField (FF / Godmode Kalkanı)
-- ----------------------------------------------------
local function applyForceField()
	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			hum.MaxHealth = math.huge
			hum.Health = math.huge
		end)
	end

	if not char:FindFirstChildOfClass("ForceField") then
		local ff = Instance.new("ForceField")
		ff.Name = "Zwyy_ForceField"
		ff.Visible = true
		ff.Parent = char
		currentForceField = ff
	end
end

local function removeForceField()
	local char = player.Character
	if char then
		local ff = char:FindFirstChild("Zwyy_ForceField") or char:FindFirstChildOfClass("ForceField")
		if ff then ff:Destroy() end
		currentForceField = nil

		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
				hum.MaxHealth = 100
				hum.Health = 100
			end)
		end
	end
end

local function toggleForceField(state)
	ffEnabled = state
	if ffEnabled then
		applyForceField()
	else
		removeForceField()
	end
end

player.CharacterAdded:Connect(function(newChar)
	if ffEnabled then
		task.spawn(function()
			newChar:WaitForChild("Humanoid", 10)
			task.wait(0.2)
			applyForceField()
		end)
	end
end)

RunService.Stepped:Connect(function()
	if ffEnabled then
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				if hum.Health < hum.MaxHealth then
					hum.Health = hum.MaxHealth
				end
			end
			if not char:FindFirstChildOfClass("ForceField") then
				applyForceField()
			end
		end
	end
end)

-- ----------------------------------------------------
-- TSB Auto Block Motoru (Otomatik Reaksiyon Bloğu)
-- ----------------------------------------------------
local vimService = nil
pcall(function() vimService = game:GetService("VirtualInputManager") end)

local function setBlockState(state)
	if isBlocking == state then return end
	isBlocking = state
	
	-- 1. VirtualInputManager (Öncelikli Giriş)
	pcall(function()
		if vimService then
			vimService:SendKeyEvent(state, Enum.KeyCode.F, false, game)
		end
	end)

	-- 2. keypress / keyrelease (Executor yerel fonksiyon desteği)
	pcall(function()
		if state then
			if typeof(keypress) == "function" then keypress(0x46) end -- F tuşu
		else
			if typeof(keyrelease) == "function" then keyrelease(0x46) end
		end
	end)

	-- 3. TSB Block Remote tetikleyicisi (Eğer karakterde varsa)
	pcall(function()
		local myChar = player.Character
		if myChar then
			local comm = myChar:FindFirstChild("Communicate") or game:GetService("ReplicatedStorage"):FindFirstChild("Communicate")
			if comm and comm:IsA("RemoteEvent") then
				comm:FireServer({Goal = state and "Block" or "Unblock"})
			end
		end
	end)
end

local lastDangerTime = 0

local function checkIncomingAttacks()
	if not autoBlockEnabled then
		if isBlocking then setBlockState(false) end
		return
	end

	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		if isBlocking then setBlockState(false) end
		return
	end

	local dangerDetected = false
	local now = os.clock()

	for _, enemy in ipairs(Players:GetPlayers()) do
		if enemy ~= player and enemy.Character then
			local eChar = enemy.Character
			local eRoot = eChar:FindFirstChild("HumanoidRootPart")
			local eHum = eChar:FindFirstChildOfClass("Humanoid")

			if eRoot and eHum and eHum.Health > 0 then
				local dist = (eRoot.Position - myRoot.Position).Magnitude
				if dist <= autoBlockRange then
					-- 1. DASH TESPİTİ (TSB Fizik ve Hız Kontrolü):
					local eVel = eRoot.AssemblyLinearVelocity or eRoot.Velocity or Vector3.zero
					local speed = Vector3.new(eVel.X, 0, eVel.Z).Magnitude

					-- 26'dan büyük hız veya hızlı yaklaşma:
					if speed > 26 then
						dangerDetected = true
						break
					end

					-- TSB BodyMovers (Dash ve Fırlama):
					if eRoot:FindFirstChildWhichIsA("BodyVelocity")
						or eRoot:FindFirstChildWhichIsA("LinearVelocity")
						or eRoot:FindFirstChildWhichIsA("VectorForce")
						or eRoot:FindFirstChildWhichIsA("BodyPosition")
						or eChar:FindFirstChildWhichIsA("BodyVelocity")
						or eChar:FindFirstChildWhichIsA("LinearVelocity") then
						dangerDetected = true
						break
					end

					-- TSB Dash Durumları:
					if eChar:FindFirstChild("Dashing") or eChar:FindFirstChild("Dash") or eChar:GetAttribute("Dashing") or eChar:GetAttribute("Dash") then
						dangerDetected = true
						break
					end

					-- 2. VURUŞ VE SALDIRI ANİMASYONLARI TESPİTİ:
					local tracks = eHum:GetPlayingAnimationTracks()
					for _, track in ipairs(tracks) do
						if track.IsPlaying and track.WeightCurrent > 0.01 then
							local trackName = track.Name:lower()

							-- Yürüme, zıplama ve DANS / EMOTE animasyonlarını KESİNLİKLE hariç tut:
							local isNonCombat = (trackName == "walk" or trackName == "run" or trackName == "idle" or trackName == "jump" or trackName == "fall" or trackName == "climb")
								or trackName:find("walkanim") or trackName:find("runanim") or trackName:find("idleanim") or trackName:find("jumpanim") or trackName:find("fallanim")
								or trackName:find("emote") or trackName:find("dance") or trackName:find("cheer") or trackName:find("wave") or trackName:find("laugh") or trackName:find("point")
								or trackName:find("floss") or trackName:find("sit") or trackName:find("pose") or trackName:find("taunt")

							-- Roblox & TSB Emote kontrolü (Karakter emote oynatıyorsa):
							local isEmoting = eChar:FindFirstChild("Emote") or eChar:GetAttribute("Emoting") or eChar:GetAttribute("Emote")

							if not isNonCombat and not isEmoting then
								local isCombatOrDash = trackName:find("dash")
									or trackName:find("attack")
									or trackName:find("punch")
									or trackName:find("m1")
									or trackName:find("m2")
									or trackName:find("strike")
									or trackName:find("kick")
									or trackName:find("slam")
									or trackName:find("swing")
									or trackName:find("hit")
									or trackName:find("slash")
									or trackName:find("skill")
									or trackName:find("ability")
									or trackName:find("heavy")
									or trackName:find("uppercut")
									or trackName:find("rush")

								-- TSB'de gerçek saldırı animasyonları (Length < 2.5 saniyedir, emoteler ise 3-10+ saniyedir):
								local isCombatAction = (track.Priority == Enum.AnimationPriority.Action 
									or track.Priority == Enum.AnimationPriority.Action2 
									or track.Priority == Enum.AnimationPriority.Action3 
									or track.Priority == Enum.AnimationPriority.Action4)
									and (track.Length > 0.05 and track.Length < 2.5)
									and not track.Looped -- Emote'lar döngülüdür (looped), saldırılar döngüsüzdür

								if isCombatOrDash or isCombatAction then
									dangerDetected = true
									break
								end
							end
						end
					end

					if dangerDetected then break end
				end
			end
		end
	end

	if dangerDetected then
		lastDangerTime = now
		setBlockState(true)
	else
		-- Dash veya vuruş bittikten sonra bloğu milisaniyelik bırak (0.08 saniye koruma süresi):
		if isBlocking and (now - lastDangerTime > 0.08) then
			setBlockState(false)
		end
	end
end

-- Heartbeat döngüsü (Optimize edilmiş kontrol)
local lastBlockCheck = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastBlockCheck >= 0.02 then
		lastBlockCheck = now
		checkIncomingAttacks()
	end
end)

-- Düşman karaktere Dash / Vuruş nesnesi eklendiği an INSTANT blok tetiklemesi:
local function hookEnemyEvents(enemy)
	local function onChar(char)
		char.ChildAdded:Connect(function(child)
			if autoBlockEnabled and (child:IsA("BodyVelocity") or child:IsA("LinearVelocity") or child.Name:lower():find("dash")) then
				local myChar = player.Character
				local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
				local root = char:FindFirstChild("HumanoidRootPart")
				if myRoot and root and (root.Position - myRoot.Position).Magnitude <= autoBlockRange then
					lastDangerTime = os.clock()
					setBlockState(true)
				end
			end
		end)
	end
	enemy.CharacterAdded:Connect(onChar)
	if enemy.Character then onChar(enemy.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= player then hookEnemyEvents(p) end
end
Players.PlayerAdded:Connect(hookEnemyEvents)

-- ----------------------------------------------------
-- Forsaken Auto Generator & Skillcheck Motoru (Lag-Free & Zero-Stutter Cache)
-- ----------------------------------------------------
local cachedGenerators = {}

local function isGeneratorObject(obj)
	if not (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder")) then return false end
	local n = obj.Name:lower()
	if n:find("gen") or n:find("generator") or n:find("motor") or n:find("engine") 
		or n:find("machine") or n:find("puzzle") or n:find("station") or n:find("repair") 
		or n:find("power") or n:find("panel") then
		return true
	end
	local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then return true end
	local click = obj:FindFirstChildWhichIsA("ClickDetector", true)
	if click then return true end
	return false
end

local function scanGenerators()
	local found = {}
	local seen = {}

	local function checkObj(obj)
		if not obj or seen[obj] then return end
		seen[obj] = true
		if isGeneratorObject(obj) then
			table.insert(found, obj)
		end
	end

	-- 1. Workspace ve tüm harita alt klasörlerini güvenli tara (0 lag)
	for _, child in ipairs(Workspace:GetChildren()) do
		checkObj(child)
		if child:IsA("Folder") or child:IsA("Model") then
			for _, sub in ipairs(child:GetChildren()) do
				checkObj(sub)
				if sub:IsA("Folder") or sub:IsA("Model") then
					for _, sub2 in ipairs(sub:GetChildren()) do
						checkObj(sub2)
					end
				end
			end
		end
	end

	cachedGenerators = found
end

-- Arka planda donma yapmadan periyodik hafif önbellekleme
task.spawn(function()
	pcall(scanGenerators)
	while true do
		task.wait(5)
		pcall(scanGenerators)
	end
end)

local function getNearbyGenerators(maxDist)
	local genList = {}
	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return genList end

	if #cachedGenerators == 0 then
		scanGenerators()
	end

	for _, obj in ipairs(cachedGenerators) do
		if obj and obj.Parent then
			local primaryPart = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
			if primaryPart then
				local dist = (primaryPart.Position - myRoot.Position).Magnitude
				if not maxDist or dist <= maxDist then
					table.insert(genList, {Object = obj, Part = primaryPart, Distance = dist})
				end
			end
		end
	end
	table.sort(genList, function(a, b) return a.Distance < b.Distance end)
	return genList
end

local function triggerPromptSafe(prompt)
	if not prompt or not prompt.Enabled then return end
	pcall(function()
		if typeof(fireproximityprompt) == "function" then
			fireproximityprompt(prompt, 0)
			fireproximityprompt(prompt, 1)
			if prompt.HoldDuration and prompt.HoldDuration > 0 then
				fireproximityprompt(prompt, prompt.HoldDuration)
			end
		end
		if prompt.InputHoldBegin then prompt:InputHoldBegin() end
	end)
end

-- Anti-Cheat Korumalı Tamamen Silent Auto Generator Motoru (Sürekli & Otomatik)
task.spawn(function()
	while true do
		if forsakenAutoGenEnabled then
			pcall(function()
				local myChar = player.Character
				local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if myRoot then
					local gens = getNearbyGenerators(26) -- 26 stud menzil
					if #gens > 0 then
						for _, gData in ipairs(gens) do
							local targetGen = gData.Object

							-- 1. ProximityPrompt'ları anında sessizce tetikle
							for _, desc in ipairs(targetGen:GetDescendants()) do
								if desc:IsA("ProximityPrompt") then
									triggerPromptSafe(desc)
								elseif desc:IsA("ClickDetector") then
									pcall(function()
										if typeof(fireclickdetector) == "function" then
											fireclickdetector(desc)
										end
									end)
								end
							end

							-- 2. Sessiz F ve E tuşu basılı tutma simülasyonu
							pcall(function()
								if vimService then
									vimService:SendKeyEvent(true, Enum.KeyCode.F, false, game)
									vimService:SendKeyEvent(true, Enum.KeyCode.E, false, game)
								end
								if typeof(keypress) == "function" then
									keypress(0x46)
									keypress(0x45)
								end
							end)

							-- 3. Jeneratör içindeki RemoteEvent / RemoteFunction paketlerini tetikle
							for _, desc in ipairs(targetGen:GetDescendants()) do
								if desc:IsA("RemoteEvent") then
									pcall(function() desc:FireServer(true) end)
									pcall(function() desc:FireServer("Progress", 1) end)
									pcall(function() desc:FireServer("Repair", true) end)
									pcall(function() desc:FireServer(1) end)
								elseif desc:IsA("RemoteFunction") then
									pcall(function() desc:InvokeServer(true) end)
									pcall(function() desc:InvokeServer("Progress", 1) end)
									pcall(function() desc:InvokeServer("Repair", true) end)
								end
							end
						end

						-- 4. ReplicatedStorage genel jeneratör remotelerini güvenle tetikle
						pcall(function()
							local rep = game:GetService("ReplicatedStorage")
							for _, r in ipairs(rep:GetChildren()) do
								if r:IsA("RemoteEvent") then
									local rName = r.Name:lower()
									if rName:find("gen") or rName:find("repair") or rName:find("progress") then
										r:FireServer(true)
									end
								end
							end
						end)
					else
						-- Yakında jeneratör yoksa tuşları serbest bırak
						pcall(function()
							if vimService then
								vimService:SendKeyEvent(false, Enum.KeyCode.F, false, game)
								vimService:SendKeyEvent(false, Enum.KeyCode.E, false, game)
							end
							if typeof(keyrelease) == "function" then
								keyrelease(0x46)
								keyrelease(0x45)
							end
						end)
					end
				end
			end)
		end
		-- Anti-cheat paket hız sınırlayıcı (0.35s - 0.45s güvenli pacing)
		local safeDelay = math.clamp(0.65 - (forsakenGenSpeed * 0.005), 0.32, 0.55)
		task.wait(safeDelay)
	end
end)

-- =========================================================================
-- FORSAKEN UNIVERSAL ON-SCREEN MINIGAME & SKILLCHECK AUTO-SOLVER
-- =========================================================================
local function isOurGui(gui)
	if not gui then return true end
	return gui == menuGui or gui == espDrawingGui or gui == crosshairGui 
		or gui.Name == "RobloxGui" or gui.Name == "Chat" or gui.Name == "Freecam"
end

local lastQteHit = 0

local function solveOnScreenMinigame(gui)
	if not gui:IsA("ScreenGui") or not gui.Enabled or isOurGui(gui) then return end

	local gName = gui.Name:lower()
	local isSkillCheckGui = gName:find("skill") or gName:find("qte") or gName:find("check") 
		or gName:find("generator") or gName:find("gen") or gName:find("repair") 
		or gName:find("puzzle") or gName:find("minigame")

	-- Yalnızca gerçek bir jeneratör / skillcheck arayüzü ise kontrol et
	if not isSkillCheckGui then return end

	-- 1. DÖNEN İBRE / CIRCULAR SKILLCHECK & LINEAR QTE TESPİTİ
	for _, desc in ipairs(gui:GetDescendants()) do
		if desc:IsA("GuiObject") and desc.Visible then
			local dName = desc.Name:lower()

			-- İbre, İğne veya Çember Göstergesi (bar kaldırıldı, zıplama spamı engellendi)
			if dName:find("needle") or dName:find("indicator") or dName:find("pointer") 
				or dName:find("arrow") or dName:find("hand") or dName:find("cursor") or dName:find("wheel") then
				
				local parent = desc.Parent
				local zone = parent and (parent:FindFirstChild("Zone", true) or parent:FindFirstChild("Success", true) 
					or parent:FindFirstChild("Target", true) or parent:FindFirstChild("WhiteZone", true) 
					or parent:FindFirstChild("Great", true) or parent:FindFirstChild("Good", true) 
					or parent:FindFirstChild("Hit", true) or parent:FindFirstChild("Green", true))

				local shouldTrigger = false -- Kesinlikle varsayılan false
				if zone and zone:IsA("GuiObject") and zone.Visible then
					-- A) Dairesel / Rotation Kontrolü:
					if math.abs(desc.Rotation) > 0 or math.abs(zone.Rotation) > 0 then
						local needleRot = desc.Rotation % 360
						local zoneRot = zone.Rotation % 360
						local diff = math.abs(needleRot - zoneRot)
						if diff <= 28 or diff >= 332 then
							shouldTrigger = true
						end
					-- B) Doğrusal / X-Axis Pozisyon Kontrolü:
					else
						local nX = desc.AbsolutePosition.X
						local zX = zone.AbsolutePosition.X
						local zW = zone.AbsoluteSize.X
						if nX >= zX - 10 and nX <= zX + zW + 10 then
							shouldTrigger = true
						end
					end
				end

				if shouldTrigger then
					local now = os.clock()
					if now - lastQteHit >= 0.35 then
						lastQteHit = now
						-- QTE Tuşlarına basarak çöz (Space, E, F)
						pcall(function()
							if vimService then
								vimService:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
								vimService:SendKeyEvent(true, Enum.KeyCode.E, false, game)
								vimService:SendKeyEvent(true, Enum.KeyCode.F, false, game)
								task.wait(0.03)
								vimService:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
								vimService:SendKeyEvent(false, Enum.KeyCode.E, false, game)
								vimService:SendKeyEvent(false, Enum.KeyCode.F, false, game)
							end
							if typeof(keypress) == "function" then
								keypress(0x20)
								keypress(0x45)
								keypress(0x46)
								task.wait(0.03)
								if typeof(keyrelease) == "function" then
									keyrelease(0x20)
									keyrelease(0x45)
									keyrelease(0x46)
								end
							end
						end)
					end
				end
			end

			-- 2. PUZZLE / WIRE / DOT / TILE BULMACA BUTONLARINI ÇÖZME
			if desc:IsA("TextButton") or desc:IsA("ImageButton") then
				local bName = desc.Name:lower()
				if bName:find("tile") or bName:find("node") or bName:find("dot") 
					or bName:find("wire") or bName:find("button") or bName:find("click") 
					or bName:find("slot") or bName:find("cell") or bName:find("solve") or bName:find("hit") then
					pcall(function()
						if typeof(firesignal) == "function" then
							firesignal(desc.MouseButton1Click)
							firesignal(desc.Activated)
							firesignal(desc.MouseButton1Down)
							firesignal(desc.MouseButton1Up)
						end
					end)
				end
			end

			-- 3. UI İçindeki RemoteEvent / RemoteFunction'ları Otomatik Tetikle
			if desc:IsA("RemoteEvent") then
				pcall(function() desc:FireServer(true) end)
				pcall(function() desc:FireServer("Success", true) end)
				pcall(function() desc:FireServer("Progress", 1) end)
				pcall(function() desc:FireServer(1) end)
			elseif desc:IsA("RemoteFunction") then
				pcall(function() desc:InvokeServer(true) end)
				pcall(function() desc:InvokeServer("Success", true) end)
				pcall(function() desc:InvokeServer("Progress", 1) end)
			end
		end
	end
end

-- Ekran Taraması: Sürekli ve Anlık Event Tetiklemeli
task.spawn(function()
	while true do
		if forsakenAutoSkillCheck or forsakenAutoGenEnabled then
			pcall(function()
				local pGui = player:FindFirstChild("PlayerGui")
				if pGui then
					for _, g in ipairs(pGui:GetChildren()) do
						solveOnScreenMinigame(g)
					end
				end
			end)
		end
		task.wait(0.015)
	end
end)

-- Ekrana Yeni UI Geldiği An 0ms Gecikmesiz Anında Yakalama Hook'u
pcall(function()
	local pGui = player:WaitForChild("PlayerGui", 5)
	if pGui then
		pGui.ChildAdded:Connect(function(child)
			if (forsakenAutoSkillCheck or forsakenAutoGenEnabled) and child:IsA("ScreenGui") then
				task.spawn(function()
					for _ = 1, 12 do
						solveOnScreenMinigame(child)
						task.wait(0.02)
					end
				end)
			end
		end)
		pGui.DescendantAdded:Connect(function(desc)
			if forsakenAutoSkillCheck or forsakenAutoGenEnabled then
				local screen = desc:FindFirstAncestorWhichIsA("ScreenGui")
				if screen and not isOurGui(screen) then
					solveOnScreenMinigame(screen)
				end
			end
		end)
	end
end)

-- Generator ESP
local function updateGeneratorESP()
	if not forsakenGenEsp then
		for _, hl in pairs(genHighlights) do
			if hl then hl:Destroy() end
		end
		genHighlights = {}
		return
	end

	local gens = getNearbyGenerators(1000)
	for _, g in ipairs(gens) do
		local obj = g.Object
		if not genHighlights[obj] then
			local hl = Instance.new("Highlight")
			hl.FillColor = Color3.fromRGB(0, 220, 255)
			hl.OutlineColor = Color3.fromRGB(255, 255, 255)
			hl.FillTransparency = 0.4
			hl.OutlineTransparency = 0
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Adornee = obj
			hl.Parent = espDrawingGui
			genHighlights[obj] = hl
		else
			genHighlights[obj].Enabled = true
		end
	end
end

-- ----------------------------------------------------
-- Optimizer
-- ----------------------------------------------------
local function toggleOptimizer(state)
	optimizerEnabled = state
	if optimizerEnabled then
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		settings().Rendering.QualityLevel = 1
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
		end
	else
		Lighting.GlobalShadows = true
		Lighting.FogEnd = 1000
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 0
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = true end
		end
	end
end


-- ----------------------------------------------------
-- Dişli Çark Çizici
-- ----------------------------------------------------

local TARGET_SIZE = UDim2.new(0, 480, 0, 290)
local CLOSE_SIZE = UDim2.new(0, 440, 0, 260)
local mainFrame
local topBar
local title
local mainStroke
local mainContent
local mm2Content
local tsbContent
local forsakenContent
local currentTab = "MAIN"
local closeButton
local toggleGUI
local isOpen = true
local showToast
local createGearButton
local createChevronArrow
local setChevronState
local createInteractiveSlider
local createModuleCard
local createSettingsPanel
local addSubToggle
local addStepperRow
local addColorPaletteRow

;(function() -- UI Modules Scope (Luau 200 Register Limit Protection)
-- =========================================================================
-- OBSIDIAN LUXURY MINIMALIST CLICKGUI (V3 PURE BLACK MOBILE EDITION)
-- ZERO EMOJIS - STRICT PROCEDURAL VECTOR GEOMETRY - SENIOR SYSTEM ARCHITECTURE
-- =========================================================================

-- ----------------------------------------------------
-- Arayüz Konfigürasyonu & Pencere Boyutları (Mobil Uyumlu)
-- ----------------------------------------------------

-- Ana Taşıyıcı Pencere (Pitch Black / Obsidian Matte Monolith)
mainFrame = Instance.new("Frame")
mainFrame.Name = "ZwyyObsidianMain"
mainFrame.Size = TARGET_SIZE
mainFrame.Position = UDim2.new(0.5, 0, 0.54, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = false
mainFrame.Visible = true
mainFrame.ZIndex = 10
mainFrame.Parent = menuGui

-- Mobil Ekranlara Tam Sığdırma Ölçekleyicisi (Auto Responsive UIScale)
local uiScale = Instance.new("UIScale")
uiScale.Parent = mainFrame

local function updateMobileScale()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	if vp.X > 0 and vp.Y > 0 then
		local scaleX = (vp.X - 24) / 480
		local scaleY = (vp.Y - 64) / 290
		uiScale.Scale = math.clamp(math.min(scaleX, scaleY, 1), 0.55, 1)
	end
end
updateMobileScale()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMobileScale)
end

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(26, 26, 26)
mainStroke.Thickness = 1.2
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Parent = mainFrame

-- Arka Plan İnce Vurgu Deseni (Subtle Noise / Matte Underlay)
local mainBackdrop = Instance.new("Frame")
mainBackdrop.Name = "BackdropGrid"
mainBackdrop.Size = UDim2.new(1, 0, 1, 0)
mainBackdrop.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
mainBackdrop.BackgroundTransparency = 0.5
mainBackdrop.BorderSizePixel = 0
mainBackdrop.ZIndex = 1
mainBackdrop.Parent = mainFrame

local backdropCorner = Instance.new("UICorner")
backdropCorner.CornerRadius = UDim.new(0, 8)
backdropCorner.Parent = mainBackdrop

-- Üst Başlık Çubuğu (Header Bar)
topBar = Instance.new("Frame")
topBar.Name = "TopHeader"
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.ZIndex = 5
topBar.Parent = mainFrame

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 8)
topBarCorner.Parent = topBar

-- Üst Köşe Düzeltme (Alt köşelerin kare kalması için)
local topBarFlatBottom = Instance.new("Frame")
topBarFlatBottom.Size = UDim2.new(1, 0, 0, 10)
topBarFlatBottom.Position = UDim2.new(0, 0, 1, -10)
topBarFlatBottom.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topBarFlatBottom.BorderSizePixel = 0
topBarFlatBottom.ZIndex = 5
topBarFlatBottom.Parent = topBar

-- Başlık Ayracı (Subtle Hairline Border)
local headerDivider = Instance.new("Frame")
headerDivider.Size = UDim2.new(1, 0, 0, 1)
headerDivider.Position = UDim2.new(0, 0, 1, -1)
headerDivider.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
headerDivider.BorderSizePixel = 0
headerDivider.ZIndex = 6
headerDivider.Parent = topBar

-- Logo & Marka Konteyneri
local brandContainer = Instance.new("Frame")
brandContainer.Size = UDim2.new(0, 95, 1, 0)
brandContainer.Position = UDim2.new(0, 12, 0, 0)
brandContainer.BackgroundTransparency = 1
brandContainer.ZIndex = 6
brandContainer.Parent = topBar

-- Durum Göstergesi (Matematiksel Titreşen Nokta)
local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(0, 0, 0.5, -3)
statusDot.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 7
statusDot.Parent = brandContainer

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = statusDot

title = Instance.new("TextLabel")
title.Name = "TitleLabel"
title.Text = "ZWYY"
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(250, 250, 250)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(0, 46, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.ZIndex = 7
title.Parent = brandContainer

local subTitle = Instance.new("TextLabel")
subTitle.Text = "MOBİL"
subTitle.Font = Enum.Font.Gotham
subTitle.TextSize = 9
subTitle.TextColor3 = Color3.fromRGB(110, 110, 110)
subTitle.TextXAlignment = Enum.TextXAlignment.Left
subTitle.Size = UDim2.new(0, 40, 1, 0)
subTitle.Position = UDim2.new(0, 56, 0, 0)
subTitle.BackgroundTransparency = 1
subTitle.ZIndex = 7
subTitle.Parent = brandContainer

-- Sekme Değiştirici Konteyner (Tab Selector - 4 Sekme: MAIN, MM2, TSB, FORSAKEN)
local tabNavContainer = Instance.new("Frame")
tabNavContainer.Size = UDim2.new(0, 276, 0, 28)
tabNavContainer.Position = UDim2.new(0.5, -124, 0.5, -14)
tabNavContainer.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
tabNavContainer.BorderSizePixel = 0
tabNavContainer.ZIndex = 6
tabNavContainer.Parent = topBar

local tabNavCorner = Instance.new("UICorner")
tabNavCorner.CornerRadius = UDim.new(0, 6)
tabNavCorner.Parent = tabNavContainer

local tabNavStroke = Instance.new("UIStroke")
tabNavStroke.Color = Color3.fromRGB(24, 24, 24)
tabNavStroke.Thickness = 1
tabNavStroke.Parent = tabNavContainer

-- Sekme Kayan Gösterge (Sliding Pill Indicator - 1/4 Genişlik)
local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.new(0.25, -4, 1, -4)
tabIndicator.Position = UDim2.new(0, 2, 0, 2)
tabIndicator.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
tabIndicator.BorderSizePixel = 0
tabIndicator.ZIndex = 7
tabIndicator.Parent = tabNavContainer

local indCorner = Instance.new("UICorner")
indCorner.CornerRadius = UDim.new(0, 4)
indCorner.Parent = tabIndicator

local indStroke = Instance.new("UIStroke")
indStroke.Color = Color3.fromRGB(42, 42, 42)
indStroke.Thickness = 1
indStroke.Parent = tabIndicator

-- Sekme Düğmeleri (MAIN, MM2, TSB, FORSAKEN)
local mainTabBtn = Instance.new("TextButton")
mainTabBtn.Text = "MAIN"
mainTabBtn.Font = Enum.Font.GothamBold
mainTabBtn.TextSize = 10
mainTabBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
mainTabBtn.Size = UDim2.new(0.25, 0, 1, 0)
mainTabBtn.Position = UDim2.new(0, 0, 0, 0)
mainTabBtn.BackgroundTransparency = 1
mainTabBtn.ZIndex = 8
mainTabBtn.Parent = tabNavContainer

local mm2TabBtn = Instance.new("TextButton")
mm2TabBtn.Text = "MM2"
mm2TabBtn.Font = Enum.Font.GothamBold
mm2TabBtn.TextSize = 10
mm2TabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
mm2TabBtn.Size = UDim2.new(0.25, 0, 1, 0)
mm2TabBtn.Position = UDim2.new(0.25, 0, 0, 0)
mm2TabBtn.BackgroundTransparency = 1
mm2TabBtn.ZIndex = 8
mm2TabBtn.Parent = tabNavContainer

local tsbTabBtn = Instance.new("TextButton")
tsbTabBtn.Text = "TSB"
tsbTabBtn.Font = Enum.Font.GothamBold
tsbTabBtn.TextSize = 10
tsbTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
tsbTabBtn.Size = UDim2.new(0.25, 0, 1, 0)
tsbTabBtn.Position = UDim2.new(0.50, 0, 0, 0)
tsbTabBtn.BackgroundTransparency = 1
tsbTabBtn.ZIndex = 8
tsbTabBtn.Parent = tabNavContainer

local forsakenTabBtn = Instance.new("TextButton")
forsakenTabBtn.Text = "FORSAKEN"
forsakenTabBtn.Font = Enum.Font.GothamBold
forsakenTabBtn.TextSize = 10
forsakenTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
forsakenTabBtn.Size = UDim2.new(0.25, 0, 1, 0)
forsakenTabBtn.Position = UDim2.new(0.75, 0, 0, 0)
forsakenTabBtn.BackgroundTransparency = 1
forsakenTabBtn.ZIndex = 8
forsakenTabBtn.Parent = tabNavContainer

-- Kapatma Düğmesi (Matematiksel Geometrik X)
closeButton = Instance.new("TextButton")
closeButton.Text = ""
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -38, 0.5, -14)
closeButton.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 15
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = Color3.fromRGB(26, 26, 26)
closeStroke.Thickness = 1
closeStroke.Parent = closeButton

-- Matematiksel X Çizgileri
local xLine1 = Instance.new("Frame")
xLine1.Size = UDim2.new(0, 12, 0, 1.5)
xLine1.Position = UDim2.new(0.5, 0, 0.5, 0)
xLine1.AnchorPoint = Vector2.new(0.5, 0.5)
xLine1.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
xLine1.BorderSizePixel = 0
xLine1.Rotation = 45
xLine1.Active = false
xLine1.ZIndex = 16
xLine1.Parent = closeButton

local xLine2 = Instance.new("Frame")
xLine2.Size = UDim2.new(0, 12, 0, 1.5)
xLine2.Position = UDim2.new(0.5, 0, 0.5, 0)
xLine2.AnchorPoint = Vector2.new(0.5, 0.5)
xLine2.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
xLine2.BorderSizePixel = 0
xLine2.Rotation = -45
xLine2.Active = false
xLine2.ZIndex = 16
xLine2.Parent = closeButton

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(24, 24, 24)}):Play()
	TweenService:Create(closeStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(60, 60, 60)}):Play()
	TweenService:Create(xLine1, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(240, 240, 240)}):Play()
	TweenService:Create(xLine2, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(240, 240, 240)}):Play()
end)

closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(16, 16, 16)}):Play()
	TweenService:Create(closeStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(26, 26, 26)}):Play()
	TweenService:Create(xLine1, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(140, 140, 140)}):Play()
	TweenService:Create(xLine2, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(140, 140, 140)}):Play()
end)

closeButton.MouseButton1Click:Connect(function()
	toggleGUI()
end)

-- İçerik Kaydırma Çerçeveleri (Scrolling Frames)
mainContent = Instance.new("ScrollingFrame")
mainContent.Name = "MainContent"
mainContent.Size = UDim2.new(1, -20, 1, -50)
mainContent.Position = UDim2.new(0, 10, 0, 46)
mainContent.BackgroundTransparency = 1
mainContent.BorderSizePixel = 0
mainContent.ScrollBarThickness = 4
mainContent.ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65)
mainContent.CanvasSize = UDim2.new(0, 0, 0, 0)
mainContent.ZIndex = 3
mainContent.Parent = mainFrame

mm2Content = Instance.new("ScrollingFrame")
mm2Content.Name = "MM2Content"
mm2Content.Size = UDim2.new(1, -20, 1, -50)
mm2Content.Position = UDim2.new(0, 10, 0, 46)
mm2Content.BackgroundTransparency = 1
mm2Content.BorderSizePixel = 0
mm2Content.ScrollBarThickness = 4
mm2Content.ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65)
mm2Content.CanvasSize = UDim2.new(0, 0, 0, 0)
mm2Content.Visible = false
mm2Content.ZIndex = 3
mm2Content.Parent = mainFrame

tsbContent = Instance.new("ScrollingFrame")
tsbContent.Name = "TSBContent"
tsbContent.Size = UDim2.new(1, -20, 1, -50)
tsbContent.Position = UDim2.new(0, 10, 0, 46)
tsbContent.BackgroundTransparency = 1
tsbContent.BorderSizePixel = 0
tsbContent.ScrollBarThickness = 4
tsbContent.ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65)
tsbContent.CanvasSize = UDim2.new(0, 0, 0, 0)
tsbContent.Visible = false
tsbContent.ZIndex = 3
tsbContent.Parent = mainFrame

forsakenContent = Instance.new("ScrollingFrame")
forsakenContent.Name = "ForsakenContent"
forsakenContent.Size = UDim2.new(1, -20, 1, -50)
forsakenContent.Position = UDim2.new(0, 10, 0, 46)
forsakenContent.BackgroundTransparency = 1
forsakenContent.BorderSizePixel = 0
forsakenContent.ScrollBarThickness = 4
forsakenContent.ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65)
forsakenContent.CanvasSize = UDim2.new(0, 0, 0, 0)
forsakenContent.Visible = false
forsakenContent.ZIndex = 3
forsakenContent.Parent = mainFrame

local mainLayout = Instance.new("UIListLayout")
mainLayout.Padding = UDim.new(0, 8)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Parent = mainContent

local mm2Layout = Instance.new("UIListLayout")
mm2Layout.Padding = UDim.new(0, 8)
mm2Layout.SortOrder = Enum.SortOrder.LayoutOrder
mm2Layout.Parent = mm2Content

local tsbLayout = Instance.new("UIListLayout")
tsbLayout.Padding = UDim.new(0, 8)
tsbLayout.SortOrder = Enum.SortOrder.LayoutOrder
tsbLayout.Parent = tsbContent

local forsakenLayout = Instance.new("UIListLayout")
forsakenLayout.Padding = UDim.new(0, 8)
forsakenLayout.SortOrder = Enum.SortOrder.LayoutOrder
forsakenLayout.Parent = forsakenContent

mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	mainContent.CanvasSize = UDim2.new(0, 0, 0, mainLayout.AbsoluteContentSize.Y + 20)
end)

mm2Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	mm2Content.CanvasSize = UDim2.new(0, 0, 0, mm2Layout.AbsoluteContentSize.Y + 20)
end)

tsbLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	tsbContent.CanvasSize = UDim2.new(0, 0, 0, tsbLayout.AbsoluteContentSize.Y + 20)
end)

forsakenLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	forsakenContent.CanvasSize = UDim2.new(0, 0, 0, forsakenLayout.AbsoluteContentSize.Y + 20)
end)

-- Sekme Değiştirme Animasyonu (Quart Interpolation)
currentTab = "MAIN"
mainTabBtn.MouseButton1Click:Connect(function()
	if currentTab == "MAIN" then return end
	currentTab = "MAIN"
	mainContent.Visible = true
	mm2Content.Visible = false
	tsbContent.Visible = false
	forsakenContent.Visible = false
	TweenService:Create(tabIndicator, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 2, 0, 2)
	}):Play()
	mainTabBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
	mm2TabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	tsbTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	forsakenTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
end)

mm2TabBtn.MouseButton1Click:Connect(function()
	if currentTab == "MM2" then return end
	currentTab = "MM2"
	mainContent.Visible = false
	mm2Content.Visible = true
	tsbContent.Visible = false
	forsakenContent.Visible = false
	TweenService:Create(tabIndicator, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.25, 2, 0, 2)
	}):Play()
	mm2TabBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
	mainTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	tsbTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	forsakenTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
end)

tsbTabBtn.MouseButton1Click:Connect(function()
	if currentTab == "TSB" then return end
	currentTab = "TSB"
	mainContent.Visible = false
	mm2Content.Visible = false
	tsbContent.Visible = true
	forsakenContent.Visible = false
	TweenService:Create(tabIndicator, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.50, 2, 0, 2)
	}):Play()
	tsbTabBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
	mainTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	mm2TabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	forsakenTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
end)

forsakenTabBtn.MouseButton1Click:Connect(function()
	if currentTab == "FORSAKEN" then return end
	currentTab = "FORSAKEN"
	mainContent.Visible = false
	mm2Content.Visible = false
	tsbContent.Visible = false
	forsakenContent.Visible = true
	TweenService:Create(tabIndicator, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.75, 2, 0, 2)
	}):Play()
	forsakenTabBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
	mainTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	mm2TabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	tsbTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
end)
end)() -- UI Base Setup Scope


-- Main Tab Scope clean separator
-- =========================================================================
-- MATEMATİKSEL VEKTÖR ÇİZİM MOTORU & BİLEŞEN FABRİKASI
-- =========================================================================

-- ----------------------------------------------------
-- Matematiksel 8-Dişli Çark İkonu (Gear Vector Drawing)
-- ----------------------------------------------------
createGearButton = function(parent)
	local gearBtn = Instance.new("TextButton")
	gearBtn.Text = ""
	gearBtn.Size = UDim2.new(0, 30, 0, 30)
	gearBtn.Position = UDim2.new(1, -40, 0.5, -15)
	gearBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	gearBtn.BorderSizePixel = 0
	gearBtn.ZIndex = 5
	gearBtn.Parent = parent

	local gCorner = Instance.new("UICorner")
	gCorner.CornerRadius = UDim.new(0, 6)
	gCorner.Parent = gearBtn

	local gStroke = Instance.new("UIStroke")
	gStroke.Color = Color3.fromRGB(26, 26, 26)
	gStroke.Thickness = 1
	gStroke.Parent = gearBtn

	local gearContainer = Instance.new("Frame")
	gearContainer.Size = UDim2.new(0, 18, 0, 18)
	gearContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	gearContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	gearContainer.BackgroundTransparency = 1
	gearContainer.ZIndex = 6
	gearContainer.Parent = gearBtn

	-- 8 Dişin Trigonometrik Yerleşimi (45 Derece Aralıklarla)
	for i = 0, 3 do
		local tooth = Instance.new("Frame")
		tooth.Size = UDim2.new(0, 16, 0, 3)
		tooth.AnchorPoint = Vector2.new(0.5, 0.5)
		tooth.Position = UDim2.new(0.5, 0, 0.5, 0)
		tooth.BackgroundColor3 = Color3.fromRGB(170, 170, 170)
		tooth.BorderSizePixel = 0
		tooth.Rotation = i * 45
		tooth.ZIndex = 6
		tooth.Parent = gearContainer

		local tCorner = Instance.new("UICorner")
		tCorner.CornerRadius = UDim.new(0, 1)
		tCorner.Parent = tooth
	end

	-- Dış Göbek Diski
	local outerHub = Instance.new("Frame")
	outerHub.Size = UDim2.new(0, 11, 0, 11)
	outerHub.AnchorPoint = Vector2.new(0.5, 0.5)
	outerHub.Position = UDim2.new(0.5, 0, 0.5, 0)
	outerHub.BackgroundColor3 = Color3.fromRGB(170, 170, 170)
	outerHub.BorderSizePixel = 0
	outerHub.ZIndex = 7
	outerHub.Parent = gearContainer

	local oCorner = Instance.new("UICorner")
	oCorner.CornerRadius = UDim.new(1, 0)
	oCorner.Parent = outerHub

	-- İç Boşluk (Hollow Axle Center)
	local innerHole = Instance.new("Frame")
	innerHole.Size = UDim2.new(0, 5, 0, 5)
	innerHole.AnchorPoint = Vector2.new(0.5, 0.5)
	innerHole.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerHole.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	innerHole.BorderSizePixel = 0
	innerHole.ZIndex = 8
	innerHole.Parent = gearContainer

	local iCorner = Instance.new("UICorner")
	iCorner.CornerRadius = UDim.new(1, 0)
	iCorner.Parent = innerHole

	-- Hover & Rotasyon Efekti
	local isRotated = false
	gearBtn.MouseEnter:Connect(function()
		TweenService:Create(gStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(60, 60, 60)}):Play()
		TweenService:Create(outerHub, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(240, 240, 240)}):Play()
	end)
	gearBtn.MouseLeave:Connect(function()
		TweenService:Create(gStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(26, 26, 26)}):Play()
		TweenService:Create(outerHub, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(170, 170, 170)}):Play()
	end)

	gearBtn.MouseButton1Click:Connect(function()
		isRotated = not isRotated
		TweenService:Create(gearContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Rotation = isRotated and 90 or 0
		}):Play()
	end)

	return gearBtn
end

-- ----------------------------------------------------
-- Modüler Kart Fabrikası (Obsidian Surface Card)
-- ----------------------------------------------------

-- ----------------------------------------------------
-- Matematiksel Chevron Oku (Expand/Collapse Arrow Geometry)
-- ----------------------------------------------------
createChevronArrow = function(parent, initialOpen)
	local chevronContainer = Instance.new("Frame")
	chevronContainer.Size = UDim2.new(0, 16, 0, 16)
	chevronContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	chevronContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	chevronContainer.BackgroundTransparency = 1
	chevronContainer.ZIndex = 6
	chevronContainer.Rotation = initialOpen and 180 or 0
	chevronContainer.Parent = parent

	-- Sol Kol (Left Arm: -35 Derece Açı)
	local leftArm = Instance.new("Frame")
	leftArm.Size = UDim2.new(0, 7, 0, 1.5)
	leftArm.Position = UDim2.new(0.5, -4, 0.5, 0)
	leftArm.AnchorPoint = Vector2.new(0, 0.5)
	leftArm.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
	leftArm.BorderSizePixel = 0
	leftArm.Rotation = 35
	leftArm.ZIndex = 7
	leftArm.Parent = chevronContainer

	local laCorner = Instance.new("UICorner")
	laCorner.CornerRadius = UDim.new(1, 0)
	laCorner.Parent = leftArm

	-- Sağ Kol (Right Arm: +35 Derece Açı)
	local rightArm = Instance.new("Frame")
	rightArm.Size = UDim2.new(0, 7, 0, 1.5)
	rightArm.Position = UDim2.new(0.5, 4, 0.5, 0)
	rightArm.AnchorPoint = Vector2.new(1, 0.5)
	rightArm.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
	rightArm.BorderSizePixel = 0
	rightArm.Rotation = -35
	rightArm.ZIndex = 7
	rightArm.Parent = chevronContainer

	local raCorner = Instance.new("UICorner")
	raCorner.CornerRadius = UDim.new(1, 0)
	raCorner.Parent = rightArm

	setChevronState = function(isOpen)
		TweenService:Create(chevronContainer, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Rotation = isOpen and 180 or 0
		}):Play()
	end

	return chevronContainer, setChevronState
end


-- ----------------------------------------------------
-- Matematiksel İnteraktif Kaydırıcı (Interactive Draggable Slider)
-- ----------------------------------------------------
createInteractiveSlider = function(parent, labelTitle, minVal, maxVal, defaultVal, stepVal, unitStr, onValueChanged)
	local sliderRow = Instance.new("Frame")
	sliderRow.Size = UDim2.new(1, 0, 0, 44)
	sliderRow.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	sliderRow.BorderSizePixel = 0
	sliderRow.ZIndex = 5
	sliderRow.Parent = parent

	local sRowCorner = Instance.new("UICorner")
	sRowCorner.CornerRadius = UDim.new(0, 4)
	sRowCorner.Parent = sliderRow

	local sRowStroke = Instance.new("UIStroke")
	sRowStroke.Color = Color3.fromRGB(24, 24, 24)
	sRowStroke.Thickness = 1
	sRowStroke.Parent = sliderRow

	local currentValue = defaultVal

	-- Başlık Etiketi
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Text = labelTitle
	titleLbl.Font = Enum.Font.Gotham
	titleLbl.TextSize = 12
	titleLbl.TextColor3 = Color3.fromRGB(190, 190, 190)
	titleLbl.Size = UDim2.new(1, -120, 0, 18)
	titleLbl.Position = UDim2.new(0, 10, 0, 4)
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.BackgroundTransparency = 1
	titleLbl.ZIndex = 6
	titleLbl.Parent = sliderRow

	-- Değer Okuma Rozeti (Badge)
	local valueBadge = Instance.new("TextLabel")
	valueBadge.Text = tostring(currentValue) .. (unitStr or "")
	valueBadge.Font = Enum.Font.GothamBold
	valueBadge.TextSize = 11
	valueBadge.TextColor3 = Color3.fromRGB(240, 240, 240)
	valueBadge.Size = UDim2.new(0, 60, 0, 18)
	valueBadge.Position = UDim2.new(1, -70, 0, 4)
	valueBadge.TextXAlignment = Enum.TextXAlignment.Right
	valueBadge.BackgroundTransparency = 1
	valueBadge.ZIndex = 6
	valueBadge.Parent = sliderRow

	-- Kaydırıcı Rayı (Slider Track)
	local trackFrame = Instance.new("TextButton")
	trackFrame.Text = ""
	trackFrame.Size = UDim2.new(1, -20, 0, 6)
	trackFrame.Position = UDim2.new(0, 10, 0, 28)
	trackFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	trackFrame.BorderSizePixel = 0
	trackFrame.ZIndex = 6
	trackFrame.Parent = sliderRow

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = trackFrame

	local trackStroke = Instance.new("UIStroke")
	trackStroke.Color = Color3.fromRGB(32, 32, 32)
	trackStroke.Thickness = 1
	trackStroke.Parent = trackFrame

	-- Doldurulan Kısım (Fill Progress)
	local fillFrame = Instance.new("Frame")
	local initialPct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
	fillFrame.Size = UDim2.new(initialPct, 0, 1, 0)
	fillFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	fillFrame.BorderSizePixel = 0
	fillFrame.ZIndex = 7
	fillFrame.Parent = trackFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fillFrame

	-- Kaydırıcı Başlığı (Draggable Thumb)
	local thumbFrame = Instance.new("Frame")
	thumbFrame.Size = UDim2.new(0, 12, 0, 12)
	thumbFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	thumbFrame.Position = UDim2.new(initialPct, 0, 0.5, 0)
	thumbFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumbFrame.BorderSizePixel = 0
	thumbFrame.ZIndex = 8
	thumbFrame.Parent = trackFrame

	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumbFrame

	local thumbStroke = Instance.new("UIStroke")
	thumbStroke.Color = Color3.fromRGB(40, 40, 40)
	thumbStroke.Thickness = 1
	thumbStroke.Parent = thumbFrame

	-- Etkileşimli Sürükleme Mantığı (Input Drag)
	local isDragging = false

	local function updateSliderFromPosition(inputX)
		local trackAbsPos = trackFrame.AbsolutePosition.X
		local trackAbsSize = trackFrame.AbsoluteSize.X
		local relativeX = math.clamp(inputX - trackAbsPos, 0, trackAbsSize)
		local percentage = math.clamp(relativeX / trackAbsSize, 0, 1)

		local rawVal = minVal + ((maxVal - minVal) * percentage)
		local steppedVal = math.floor((rawVal / stepVal) + 0.5) * stepVal
		steppedVal = math.clamp(steppedVal, minVal, maxVal)

		if steppedVal ~= currentValue then
			currentValue = steppedVal
			valueBadge.Text = tostring(currentValue) .. (unitStr or "")
			local cleanPct = (currentValue - minVal) / (maxVal - minVal)
			fillFrame.Size = UDim2.new(cleanPct, 0, 1, 0)
			thumbFrame.Position = UDim2.new(cleanPct, 0, 0.5, 0)
			onValueChanged(currentValue)
		end
	end

	trackFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			updateSliderFromPosition(input.Position.X)
			TweenService:Create(thumbFrame, TweenInfo.new(0.12), {Size = UDim2.new(0, 14, 0, 14)}):Play()
			TweenService:Create(thumbStroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(255, 255, 255)}):Play()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isDragging then
				isDragging = false
				TweenService:Create(thumbFrame, TweenInfo.new(0.12), {Size = UDim2.new(0, 12, 0, 12)}):Play()
				TweenService:Create(thumbStroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(40, 40, 40)}):Play()
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSliderFromPosition(input.Position.X)
		end
	end)

	sliderRow.MouseEnter:Connect(function()
		TweenService:Create(sRowStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(40, 40, 40)}):Play()
	end)

	sliderRow.MouseLeave:Connect(function()
		if not isDragging then
			TweenService:Create(sRowStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(24, 24, 24)}):Play()
		end
	end)

	return sliderRow
end

createModuleCard = function(parent, titleName)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 48)
	card.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	card.BorderSizePixel = 0
	card.ZIndex = 4
	card.Parent = parent

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 6)
	cCorner.Parent = card

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(24, 24, 24)
	cStroke.Thickness = 1
	cStroke.Parent = card

	-- Sol Kenar İnce Vurgu Barı (Hairline Accent)
	local accentLine = Instance.new("Frame")
	accentLine.Size = UDim2.new(0, 2, 0, 20)
	accentLine.Position = UDim2.new(0, 0, 0.5, -10)
	accentLine.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	accentLine.BorderSizePixel = 0
	accentLine.ZIndex = 5
	accentLine.Parent = card

	local aCorner = Instance.new("UICorner")
	aCorner.CornerRadius = UDim.new(0, 1)
	aCorner.Parent = accentLine

	-- Modül Başlık Etiketi
	local lbl = Instance.new("TextLabel")
	lbl.Text = titleName
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13
	lbl.TextColor3 = Color3.fromRGB(235, 235, 235)
	lbl.Size = UDim2.new(1, -140, 1, 0)
	lbl.Position = UDim2.new(0, 14, 0, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.BackgroundTransparency = 1
	lbl.ZIndex = 5
	lbl.Parent = card

	-- Minimalist Pill Toggle Anahtarı (Switch)
	local switchBtn = Instance.new("TextButton")
	switchBtn.Text = ""
	switchBtn.Size = UDim2.new(0, 44, 0, 24)
	switchBtn.Position = UDim2.new(1, -94, 0.5, -12)
	switchBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	switchBtn.BorderSizePixel = 0
	switchBtn.ZIndex = 5
	switchBtn.Parent = card

	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(1, 0)
	sCorner.Parent = switchBtn

	local sStroke = Instance.new("UIStroke")
	sStroke.Color = Color3.fromRGB(32, 32, 32)
	sStroke.Thickness = 1
	sStroke.Parent = switchBtn

	local sKnob = Instance.new("Frame")
	sKnob.Size = UDim2.new(0, 16, 0, 16)
	sKnob.Position = UDim2.new(0, 4, 0.5, -8)
	sKnob.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	sKnob.BorderSizePixel = 0
	sKnob.ZIndex = 6
	sKnob.Parent = switchBtn

	local kCorner = Instance.new("UICorner")
	kCorner.CornerRadius = UDim.new(1, 0)
	kCorner.Parent = sKnob

	-- Hover Efekti
	card.MouseEnter:Connect(function()
		TweenService:Create(cStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(38, 38, 38)}):Play()
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(cStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(24, 24, 24)}):Play()
	end)

	-- Switch Durum Animasyonu Fonksiyonu
	local function setSwitchVisual(isOn)
		if isOn then
			TweenService:Create(switchBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(245, 245, 245)
			}):Play()
			TweenService:Create(sStroke, TweenInfo.new(0.2), {
				Color = Color3.fromRGB(255, 255, 255)
			}):Play()
			TweenService:Create(sKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 24, 0.5, -8),
				BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			}):Play()
			TweenService:Create(accentLine, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			}):Play()
		else
			TweenService:Create(switchBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			}):Play()
			TweenService:Create(sStroke, TweenInfo.new(0.2), {
				Color = Color3.fromRGB(32, 32, 32)
			}):Play()
			TweenService:Create(sKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 4, 0.5, -8),
				BackgroundColor3 = Color3.fromRGB(120, 120, 120)
			}):Play()
			TweenService:Create(accentLine, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			}):Play()
		end
	end

	return card, switchBtn, setSwitchVisual
end

-- ----------------------------------------------------
-- Genişletilebilir Ayarlar Paneli (Accordion Panel)
-- ----------------------------------------------------
createSettingsPanel = function(parent, targetHeight)
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(1, 0, 0, targetHeight)
	panel.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ClipsDescendants = true
	panel.ZIndex = 4
	panel.Parent = parent

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 6)
	pCorner.Parent = panel

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = Color3.fromRGB(22, 22, 22)
	pStroke.Thickness = 1
	pStroke.Parent = panel

	local pLayout = Instance.new("UIListLayout")
	pLayout.Padding = UDim.new(0, 6)
	pLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pLayout.Parent = panel

	local pPadding = Instance.new("UIPadding")
	pPadding.PaddingTop = UDim.new(0, 6)
	pPadding.PaddingBottom = UDim.new(0, 6)
	pPadding.PaddingLeft = UDim.new(0, 10)
	pPadding.PaddingRight = UDim.new(0, 10)
	pPadding.Parent = panel

	return panel
end

-- ----------------------------------------------------
-- Alt Başlık Anahtarı (Sub Toggle Row)
-- ----------------------------------------------------
addSubToggle = function(parent, titleText, initialVal, onToggle)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	row.BorderSizePixel = 0
	row.ZIndex = 5
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 4)
	rCorner.Parent = row

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(24, 24, 24)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Text = titleText
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.TextColor3 = Color3.fromRGB(190, 190, 190)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 6
	lbl.Parent = row

	-- Mini Pill Toggle
	local tBtn = Instance.new("TextButton")
	tBtn.Text = ""
	tBtn.Size = UDim2.new(0, 36, 0, 18)
	tBtn.Position = UDim2.new(1, -44, 0.5, -9)
	tBtn.BackgroundColor3 = initialVal and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(22, 22, 22)
	tBtn.BorderSizePixel = 0
	tBtn.ZIndex = 6
	tBtn.Parent = row

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(1, 0)
	tCorner.Parent = tBtn

	local tStroke = Instance.new("UIStroke")
	tStroke.Color = initialVal and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(34, 34, 34)
	tStroke.Thickness = 1
	tStroke.Parent = tBtn

	local tKnob = Instance.new("Frame")
	tKnob.Size = UDim2.new(0, 12, 0, 12)
	tKnob.Position = initialVal and UDim2.new(0, 21, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
	tKnob.BackgroundColor3 = initialVal and Color3.fromRGB(10, 10, 10) or Color3.fromRGB(110, 110, 110)
	tKnob.BorderSizePixel = 0
	tKnob.ZIndex = 7
	tKnob.Parent = tBtn

	local kCorner = Instance.new("UICorner")
	kCorner.CornerRadius = UDim.new(1, 0)
	kCorner.Parent = tKnob

	local val = initialVal
	tBtn.MouseButton1Click:Connect(function()
		val = not val
		if val then
			TweenService:Create(tBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(245, 245, 245)}):Play()
			TweenService:Create(tStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(255, 255, 255)}):Play()
			TweenService:Create(tKnob, TweenInfo.new(0.18), {Position = UDim2.new(0, 21, 0.5, -6), BackgroundColor3 = Color3.fromRGB(10, 10, 10)}):Play()
		else
			TweenService:Create(tBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(22, 22, 22)}):Play()
			TweenService:Create(tStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(34, 34, 34)}):Play()
			TweenService:Create(tKnob, TweenInfo.new(0.18), {Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = Color3.fromRGB(110, 110, 110)}):Play()
		end
		onToggle(val)
	end)
end

-- ----------------------------------------------------
-- Matematiksel Değer Ayarlayıcı Satırı (Stepper / Slider Row)
-- ----------------------------------------------------
addStepperRow = function(parent, labelText, initialVal, stepVal, minVal, maxVal, onChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	row.BorderSizePixel = 0
	row.ZIndex = 5
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 4)
	rCorner.Parent = row

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(24, 24, 24)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local currentVal = initialVal

	local lbl = Instance.new("TextLabel")
	lbl.Text = labelText .. ": " .. currentVal
	lbl.Size = UDim2.new(1, -90, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.TextColor3 = Color3.fromRGB(190, 190, 190)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 6
	lbl.Parent = row

	-- Eksi Düğmesi (-)
	local minusBtn = Instance.new("TextButton")
	minusBtn.Text = "-"
	minusBtn.Font = Enum.Font.GothamBold
	minusBtn.TextSize = 14
	minusBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	minusBtn.Size = UDim2.new(0, 26, 0, 22)
	minusBtn.Position = UDim2.new(1, -64, 0.5, -11)
	minusBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	minusBtn.BorderSizePixel = 0
	minusBtn.ZIndex = 6
	minusBtn.Parent = row

	local mCorner = Instance.new("UICorner")
	mCorner.CornerRadius = UDim.new(0, 4)
	mCorner.Parent = minusBtn

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = Color3.fromRGB(36, 36, 36)
	mStroke.Thickness = 1
	mStroke.Parent = minusBtn

	-- Artı Düğmesi (+)
	local plusBtn = Instance.new("TextButton")
	plusBtn.Text = "+"
	plusBtn.Font = Enum.Font.GothamBold
	plusBtn.TextSize = 14
	plusBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	plusBtn.Size = UDim2.new(0, 26, 0, 22)
	plusBtn.Position = UDim2.new(1, -32, 0.5, -11)
	plusBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	plusBtn.BorderSizePixel = 0
	plusBtn.ZIndex = 6
	plusBtn.Parent = row

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 4)
	pCorner.Parent = plusBtn

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = Color3.fromRGB(36, 36, 36)
	pStroke.Thickness = 1
	pStroke.Parent = plusBtn

	minusBtn.MouseButton1Click:Connect(function()
		if currentVal > minVal then
			currentVal = math.max(minVal, currentVal - stepVal)
			lbl.Text = labelText .. ": " .. currentVal
			onChange(currentVal)
		end
	end)

	plusBtn.MouseButton1Click:Connect(function()
		if currentVal < maxVal then
			currentVal = math.min(maxVal, currentVal + stepVal)
			lbl.Text = labelText .. ": " .. currentVal
			onChange(currentVal)
		end
	end)
end

-- ----------------------------------------------------
-- Renk Paleti Satırı (Minimalist Swatches)
-- ----------------------------------------------------
addColorPaletteRow = function(parent, labelText, currentColor, onSelectColor)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	row.BorderSizePixel = 0
	row.ZIndex = 5
	row.Parent = parent

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 4)
	rCorner.Parent = row

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(24, 24, 24)
	rStroke.Thickness = 1
	rStroke.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Text = labelText
	lbl.Size = UDim2.new(0, 120, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.TextColor3 = Color3.fromRGB(190, 190, 190)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 6
	lbl.Parent = row

	local colors = {
		Color3.fromRGB(0, 255, 140),   -- Neon Yeşil
		Color3.fromRGB(0, 200, 255),   -- Cyan
		Color3.fromRGB(170, 70, 255),  -- Mor
		Color3.fromRGB(255, 60, 80),   -- Kırmızı
		Color3.fromRGB(255, 215, 0),   -- Altın
		Color3.fromRGB(250, 250, 250)  -- Saf Beyaz
	}

	for i, c in ipairs(colors) do
		local cBtn = Instance.new("TextButton")
		cBtn.Text = ""
		cBtn.Size = UDim2.new(0, 18, 0, 18)
		cBtn.Position = UDim2.new(1, -150 + ((i - 1) * 24), 0.5, -9)
		cBtn.BackgroundColor3 = c
		cBtn.BorderSizePixel = 0
		cBtn.ZIndex = 6
		cBtn.Parent = row

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(1, 0)
		bCorner.Parent = cBtn

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = (currentColor == c) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 40)
		bStroke.Thickness = (currentColor == c) and 1.5 or 1
		bStroke.Parent = cBtn

		cBtn.MouseButton1Click:Connect(function()
			onSelectColor(c)
		end)
	end
end

-- =========================================================================
-- MAIN SEKMESİ MODÜLLERİ - BÖLÜM 1 (ESP, R6, OPTIMIZER, SPEED GLITCH)
-- =========================================================================
;(function() -- Main Tab Scope 1 (Luau 200 Register Limit Protection)

	-- 1. Oyuncu ESP (Genel)
	local espCard, espToggleBtn, setEspVisual = createModuleCard(mainContent, "Oyuncu ESP (Genel)")
	local espGear = createGearButton(espCard)
	local espPanel = createSettingsPanel(mainContent, 195)

	addSubToggle(espPanel, "Takım Kontrolü (Team Check)", normalEspTeamCheck, function(state)
		normalEspTeamCheck = state
		updateAllESP()
	end)

	addSubToggle(espPanel, "İsim Etiketleri", normalEspNames, function(state)
		normalEspNames = state
		updateAllESP()
	end)

	addSubToggle(espPanel, "Çizgiler (Tracers)", normalEspTracers, function(state)
		normalEspTracers = state
		updateAllESP()
	end)

	addColorPaletteRow(espPanel, "Özel Renk (Takımsız/Düz)", normalEspColor, function(newCol)
		normalEspColor = newCol
		updateAllESP()
	end)

	addStepperRow(espPanel, "Saydamlık", math.floor(normalEspTransparency * 10), 1, 1, 9, function(newVal)
		normalEspTransparency = newVal / 10
		updateAllESP()
	end)

	espGear.MouseButton1Click:Connect(function()
		espPanel.Visible = not espPanel.Visible
	end)

	espToggleBtn.MouseButton1Click:Connect(function()
		normalEspEnabled = not normalEspEnabled
		setEspVisual(normalEspEnabled)
		updateAllESP()
	end)

	-- 2. R6 Animasyon Paketi (FE)
	local r6Card, r6ToggleBtn, setR6Visual = createModuleCard(mainContent, "R6 Animasyon Paketi (FE)")
	r6ToggleBtn.MouseButton1Click:Connect(function()
		r6AnimEnabled = not r6AnimEnabled
		setR6Visual(r6AnimEnabled)
		if r6AnimEnabled then
			applyFullR6Set()
		else
			resetToDefaultAnimations()
		end
	end)

	-- 3. FPS Optimizer
	local optCard, optToggleBtn, setOptVisual = createModuleCard(mainContent, "FPS Optimizer")
	optToggleBtn.MouseButton1Click:Connect(function()
		toggleOptimizer(not optimizerEnabled)
		setOptVisual(optimizerEnabled)
	end)

	-- 4. Speed Glitch (Bhop)
	local sgCard, sgToggleBtn, setSgVisual = createModuleCard(mainContent, "Speed Glitch (Bhop)")
	local sgGear = createGearButton(sgCard)
	local sgPanel = createSettingsPanel(mainContent, 46)

	addStepperRow(sgPanel, "Zıplama Hızı", speedGlitchPower, 5, 15, 200, function(newVal)
		speedGlitchPower = newVal
	end)

	sgGear.MouseButton1Click:Connect(function()
		sgPanel.Visible = not sgPanel.Visible
	end)

	sgToggleBtn.MouseButton1Click:Connect(function()
		speedGlitchEnabled = not speedGlitchEnabled
		setSgVisual(speedGlitchEnabled)
	end)

	-- 4.5 Wall Hop (Zıpladığında Altında Zemin Varmış Gibi Zıplatır)
	local whHopEnabled = false
	local lastWhHopTime = 0
	local whCard, whToggleBtn, setWhVisual = createModuleCard(mainContent, "Wall Hop")

	local function spawnWallHopPad()
		if not whHopEnabled then return end
		local now = tick()
		if now - lastWhHopTime < 0.12 then return end
		lastWhHopTime = now

		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or hum.Health <= 0 then return end

		local footOffset = (hum.RigType == Enum.HumanoidRigType.R6) and 3.0 or (hum.HipHeight + (root.Size.Y * 0.5))
		local pad = Instance.new("Part")
		pad.Name = "ZwyyWallHopPad"
		pad.Size = Vector3.new(6, 1, 6)
		pad.Transparency = 1
		pad.Anchored = true
		pad.CanCollide = true
		pad.CanQuery = false
		pad.CanTouch = false
		pad.CFrame = CFrame.new(root.Position.X, root.Position.Y - footOffset - 0.5, root.Position.Z)
		pad.Parent = Workspace

		hum:ChangeState(Enum.HumanoidStateType.Jumping)

		task.delay(0.1, function()
			if pad and pad.Parent then
				pad:Destroy()
			end
		end)
	end

	UserInputService.JumpRequest:Connect(function()
		if whHopEnabled then
			spawnWallHopPad()
		end
	end)

	whToggleBtn.MouseButton1Click:Connect(function()
		whHopEnabled = not whHopEnabled
		setWhVisual(whHopEnabled)
	end)

end)() -- End Main Tab Scope 1

-- Main / Combat clean separator
-- =========================================================================
-- MAIN SEKMESİ MODÜLLERİ - BÖLÜM 2 (HITBOX, ANTI-FLING, HEDEF FLING)
-- =========================================================================
;(function() -- Main Tab Scope 2 (Luau 200 Register Limit Protection)

	-- 5. Hitbox Expander (Genel)
	local hbCard, hbToggleBtn, setHbVisual = createModuleCard(mainContent, "Hitbox Expander (Genel)")
	local hbGear = createGearButton(hbCard)
	local hbPanel = createSettingsPanel(mainContent, 82)

	addStepperRow(hbPanel, "Hitbox Boyutu", hitboxSize, 2, 4, 100, function(newVal)
		hitboxSize = newVal
		if hitboxEnabled then updateAllHitboxes() end
	end)

	addStepperRow(hbPanel, "Hitbox Saydamlığı", math.floor(hitboxTransparency * 10), 1, 0, 10, function(newVal)
		hitboxTransparency = newVal / 10
		if hitboxEnabled then updateAllHitboxes() end
	end)

	hbGear.MouseButton1Click:Connect(function()
		hbPanel.Visible = not hbPanel.Visible
	end)

	hbToggleBtn.MouseButton1Click:Connect(function()
		hitboxEnabled = not hitboxEnabled
		setHbVisual(hitboxEnabled)
		updateAllHitboxes()
	end)

	-- 6. Anti-Fling (Fling Koruması)
	local afCard, afToggleBtn, setAfVisual = createModuleCard(mainContent, "Anti-Fling (Fling Koruması)")
	afToggleBtn.MouseButton1Click:Connect(function()
		antiFlingEnabled = not antiFlingEnabled
		setAfVisual(antiFlingEnabled)
	end)

	-- ForceField Kalkanı (FF / Godmode)
	local ffCard, ffToggleBtn, setFfVisual = createModuleCard(mainContent, "ForceField Kalkanı (FF)")
	ffToggleBtn.MouseButton1Click:Connect(function()
		toggleForceField(not ffEnabled)
		setFfVisual(ffEnabled)
	end)

	-- 7. Hedef Fling (Kişi Seçmeli)
	local tfCard = Instance.new("Frame")
	tfCard.Size = UDim2.new(1, 0, 0, 48)
	tfCard.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	tfCard.BorderSizePixel = 0
	tfCard.ZIndex = 4
	tfCard.Parent = mainContent

	local tfCorner = Instance.new("UICorner") tfCorner.CornerRadius = UDim.new(0, 6) tfCorner.Parent = tfCard
	local tfStroke = Instance.new("UIStroke") tfStroke.Color = Color3.fromRGB(24, 24, 24) tfStroke.Thickness = 1 tfStroke.Parent = tfCard

	local tfAccent = Instance.new("Frame")
	tfAccent.Size = UDim2.new(0, 2, 0, 20)
	tfAccent.Position = UDim2.new(0, 0, 0.5, -10)
	tfAccent.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	tfAccent.BorderSizePixel = 0
	tfAccent.ZIndex = 5
	tfAccent.Parent = tfCard

	local tfTitle = Instance.new("TextLabel")
	tfTitle.Text = "Hedef Fling (Kişi Seçmeli)"
	tfTitle.Font = Enum.Font.GothamMedium
	tfTitle.TextSize = 13
	tfTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
	tfTitle.Size = UDim2.new(1, -220, 1, 0)
	tfTitle.Position = UDim2.new(0, 14, 0, 0)
	tfTitle.TextXAlignment = Enum.TextXAlignment.Left
	tfTitle.BackgroundTransparency = 1
	tfTitle.ZIndex = 5
	tfTitle.Parent = tfCard

	local tfStatus = Instance.new("TextLabel")
	tfStatus.Text = "Seçilmedi"
	tfStatus.Font = Enum.Font.Gotham
	tfStatus.TextSize = 11
	tfStatus.TextColor3 = Color3.fromRGB(130, 130, 130)
	tfStatus.Size = UDim2.new(0, 100, 1, 0)
	tfStatus.Position = UDim2.new(1, -190, 0, 0)
	tfStatus.TextXAlignment = Enum.TextXAlignment.Right
	tfStatus.BackgroundTransparency = 1
	tfStatus.ZIndex = 5
	tfStatus.Parent = tfCard

	local tfExecBtn = Instance.new("TextButton")
	tfExecBtn.Text = "FLING"
	tfExecBtn.Font = Enum.Font.GothamBold
	tfExecBtn.TextSize = 11
	tfExecBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	tfExecBtn.Size = UDim2.new(0, 52, 0, 24)
	tfExecBtn.Position = UDim2.new(1, -84, 0.5, -12)
	tfExecBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	tfExecBtn.BorderSizePixel = 0
	tfExecBtn.ZIndex = 5
	tfExecBtn.Parent = tfCard

	local exCorner = Instance.new("UICorner") exCorner.CornerRadius = UDim.new(0, 4) exCorner.Parent = tfExecBtn
	local exStroke = Instance.new("UIStroke") exStroke.Color = Color3.fromRGB(36, 36, 36) exStroke.Thickness = 1 exStroke.Parent = tfExecBtn

	local tfGear = createGearButton(tfCard)
	local tfPanel = createSettingsPanel(mainContent, 160)

	-- Panel İçi: Arama & Oyuncu Listesi
	local searchBox = Instance.new("TextBox")
	searchBox.PlaceholderText = "Oyuncu ara..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
	searchBox.Text = ""
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 11
	searchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
	searchBox.Size = UDim2.new(1, 0, 0, 26)
	searchBox.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	searchBox.BorderSizePixel = 0
	searchBox.ZIndex = 5
	searchBox.Parent = tfPanel

	local sCorner = Instance.new("UICorner") sCorner.CornerRadius = UDim.new(0, 4) sCorner.Parent = searchBox
	local sStroke = Instance.new("UIStroke") sStroke.Color = Color3.fromRGB(26, 26, 26) sStroke.Thickness = 1 sStroke.Parent = searchBox

	local pScroll = Instance.new("ScrollingFrame")
	pScroll.Size = UDim2.new(1, 0, 1, -34)
	pScroll.BackgroundTransparency = 1
	pScroll.BorderSizePixel = 0
	pScroll.ScrollBarThickness = 2
	pScroll.ScrollBarImageColor3 = Color3.fromRGB(40, 40, 40)
	pScroll.ZIndex = 5
	pScroll.Parent = tfPanel

	local pLayout = Instance.new("UIListLayout")
	pLayout.Padding = UDim.new(0, 4)
	pLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pLayout.Parent = pScroll

	pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		pScroll.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 6)
	end)

	local function populatePlayerList()
		for _, ch in ipairs(pScroll:GetChildren()) do
			if ch:IsA("TextButton") then ch:Destroy() end
		end

		local query = searchBox.Text:lower()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local pName = p.Name
				local dName = p.DisplayName
				if query == "" or pName:lower():find(query) or dName:lower():find(query) then
					local item = Instance.new("TextButton")
					item.Text = "  " .. dName .. " (@" .. pName .. ")"
					item.Font = Enum.Font.Gotham
					item.TextSize = 11
					item.TextColor3 = (selectedFlingPlayer == p) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160)
					item.TextXAlignment = Enum.TextXAlignment.Left
					item.Size = UDim2.new(1, 0, 0, 24)
					item.BackgroundColor3 = (selectedFlingPlayer == p) and Color3.fromRGB(28, 28, 28) or Color3.fromRGB(16, 16, 16)
					item.BorderSizePixel = 0
					item.ZIndex = 6
					item.Parent = pScroll

					local iCorn = Instance.new("UICorner") iCorn.CornerRadius = UDim.new(0, 3) iCorn.Parent = item
					local iStrk = Instance.new("UIStroke") iStrk.Color = (selectedFlingPlayer == p) and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(24, 24, 24) iStrk.Thickness = 1 iStrk.Parent = item

					item.MouseButton1Click:Connect(function()
						selectedFlingPlayer = p
						tfStatus.Text = pName
						populatePlayerList()
					end)
				end
			end
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(populatePlayerList)
	tfGear.MouseButton1Click:Connect(function()
		tfPanel.Visible = not tfPanel.Visible
		if tfPanel.Visible then populatePlayerList() end
	end)

	tfExecBtn.MouseButton1Click:Connect(function()
		if not selectedFlingPlayer then
			tfStatus.Text = "Kişi Seçilmedi"
			return
		end
		tfExecBtn.Text = "..."
		tfExecBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
		triggerFlingTarget(selectedFlingPlayer, function()
			tfExecBtn.Text = "FLING"
			tfExecBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
		end)
	end)

end)() -- End Main Tab Scope 2

-- =========================================================================
-- MAIN SEKMESİ MODÜLLERİ - BÖLÜM 3 (CROSSHAIR, ASPECT RATIO, SPINBOT)
-- =========================================================================
;(function() -- Main Tab Scope 3 (Luau 200 Register Limit Protection)

	-- 8. Crosshair (Minimal X)
	local chCard, chToggleBtn, setChVisual = createModuleCard(mainContent, "Crosshair (Minimal X)")
	local chGear = createGearButton(chCard)
	local chPanel = createSettingsPanel(mainContent, 160)

	addColorPaletteRow(chPanel, "Nişangah Rengi", baseColor, function(newCol)
		baseColor = newCol
		updateCrosshairAppearance()
	end)

	addStepperRow(chPanel, "Uzunluk", crosshairLength, 2, 6, 40, function(newVal)
		crosshairLength = newVal
		updateCrosshairAppearance()
	end)

	addStepperRow(chPanel, "Kalınlık", crosshairThickness, 1, 1, 8, function(newVal)
		crosshairThickness = newVal
		updateCrosshairAppearance()
	end)

	addSubToggle(chPanel, "Sürekli Dönme (Spin)", spinEnabled, function(newVal)
		spinEnabled = newVal
	end)

	addStepperRow(chPanel, "Dönüş Hızı", spinSpeed, 30, 30, 720, function(newVal)
		spinSpeed = newVal
	end)

	chGear.MouseButton1Click:Connect(function()
		chPanel.Visible = not chPanel.Visible
	end)

	local function toggleCrosshair()
		crosshairEnabled = not crosshairEnabled
		setChVisual(crosshairEnabled)
		if crosshairContainer then
			crosshairContainer.Visible = crosshairEnabled
			if crosshairEnabled then
				local mousePos = UserInputService:GetMouseLocation()
				crosshairContainer.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
			else
				if crosshairRotator then crosshairRotator.Rotation = 0 end
			end
		end
		if crosshairEnabled and not isOpen then
			UserInputService.MouseIconEnabled = false
		else
			UserInputService.MouseIconEnabled = true
		end
		updateCrosshairAppearance()
	end

	chToggleBtn.MouseButton1Click:Connect(toggleCrosshair)

	-- 9. Aspect Ratio
	local arCard, arToggleBtn, setArVisual = createModuleCard(mainContent, "Aspect Ratio")
	local arGear = createGearButton(arCard)
	local arPanel = createSettingsPanel(mainContent, 46)

	addStepperRow(arPanel, "Genişletme Oranı", math.floor(stretchScale * 100), 5, 20, 200, function(newVal)
		stretchScale = newVal / 100
	end)

	arGear.MouseButton1Click:Connect(function()
		arPanel.Visible = not arPanel.Visible
	end)

	arToggleBtn.MouseButton1Click:Connect(function()
		aspectRatioEnabled = not aspectRatioEnabled
		setArVisual(aspectRatioEnabled)
	end)

	-- 9.5 Custom FOV (CS2 Tarzı Kamera Açısı)
	local fovCard, fovToggleBtn, setFovVisual = createModuleCard(mainContent, "Custom FOV")
	local fovGear = createGearButton(fovCard)
	local fovPanel = createSettingsPanel(mainContent, 46)

	addStepperRow(fovPanel, "FOV Değeri", customFovValue, 5, 10, 150, function(newVal)
		customFovValue = newVal
		if customFovEnabled and Workspace.CurrentCamera then
			Workspace.CurrentCamera.FieldOfView = math.clamp(customFovValue, 1, 120)
		end
	end)

	fovGear.MouseButton1Click:Connect(function()
		fovPanel.Visible = not fovPanel.Visible
	end)

	fovToggleBtn.MouseButton1Click:Connect(function()
		customFovEnabled = not customFovEnabled
		setFovVisual(customFovEnabled)
		if customFovEnabled then
			if Workspace.CurrentCamera then
				defaultFovValue = Workspace.CurrentCamera.FieldOfView
				Workspace.CurrentCamera.FieldOfView = math.clamp(customFovValue, 1, 120)
			end
		else
			if Workspace.CurrentCamera then
				Workspace.CurrentCamera.FieldOfView = defaultFovValue or 70
			end
		end
	end)

	-- 10. SpinBot (Fırlatmayan)
	local sbCard, sbToggleBtn, setSbVisual = createModuleCard(mainContent, "SpinBot (Fırlatmayan)")
	local sbGear = createGearButton(sbCard)
	local sbPanel = createSettingsPanel(mainContent, 46)

	addStepperRow(sbPanel, "Dönüş Hızı", spinBotSpeed, 5, 5, 120, function(newVal)
		spinBotSpeed = newVal
	end)

	sbGear.MouseButton1Click:Connect(function()
		sbPanel.Visible = not sbPanel.Visible
	end)

	sbToggleBtn.MouseButton1Click:Connect(function()
		spinBotEnabled = not spinBotEnabled
		setSbVisual(spinBotEnabled)
	end)

end)() -- End Main Tab Scope 3

-- =========================================================================
-- MAIN SEKMESİ MODÜLLERİ - BÖLÜM 4 (SKIN CHANGER: KORBLOX & HEADLESS)
-- =========================================================================
;(function() -- Main Tab Scope 4 (Luau 200 Register Limit Protection)

	-- 11. Korblox (Client-Side)
	local kbCard, kbToggleBtn, setKbVisual = createModuleCard(mainContent, "Korblox (Sağ Bacak - Client)")
	kbToggleBtn.MouseButton1Click:Connect(function()
		korbloxEnabled = not korbloxEnabled
		setKbVisual(korbloxEnabled)
		applyKorblox(korbloxEnabled)
		if showToast then
			showToast("SKIN CHANGER", korbloxEnabled and "Korblox uygulandı! (Sadece sen görürsün)" or "Korblox kaldırıldı.", 2)
		end
	end)

	-- 12. Headless (Client-Side)
	local hlCard, hlToggleBtn, setHlVisual = createModuleCard(mainContent, "Headless (Kafasız - Client)")
	hlToggleBtn.MouseButton1Click:Connect(function()
		headlessEnabled = not headlessEnabled
		setHlVisual(headlessEnabled)
		applyHeadless(headlessEnabled)
		if showToast then
			showToast("SKIN CHANGER", headlessEnabled and "Headless uygulandı! (Sadece sen görürsün)" or "Headless kaldırıldı.", 2)
		end
	end)

end)() -- End Main Tab Scope 4

-- =========================================================================
-- MM2 SEKMESİ MODÜLLERİ (ROL ESP, TP GUN, SHOOT, FLING SHERIFF & MURDERER)
-- =========================================================================
;(function() -- MM2 Tab Scope (Luau 200 Register Limit Protection)

	-- 1. MM2 Rol ESP (Roller & Silah)
	local mm2EspCard, mm2EspToggleBtn, setMm2EspVisual = createModuleCard(mm2Content, "MM2 Rol ESP (Roller & Silah)")
	local mm2EspGear = createGearButton(mm2EspCard)
	local mm2EspPanel = createSettingsPanel(mm2Content, 210)

	addSubToggle(mm2EspPanel, "Katil ESP (Kırmızı)", mm2EspFlags.MurdererESP, function(s) mm2EspFlags.MurdererESP = s end)
	addSubToggle(mm2EspPanel, "Şerif ESP (Mavi)", mm2EspFlags.SheriffESP, function(s) mm2EspFlags.SheriffESP = s end)
	addSubToggle(mm2EspPanel, "Masum ESP (Yeşil)", mm2EspFlags.InnocentESP, function(s) mm2EspFlags.InnocentESP = s end)
	addSubToggle(mm2EspPanel, "Düşen Silah ESP (Sarı)", mm2EspFlags.GunDropESP, function(s) mm2EspFlags.GunDropESP = s end)
	addSubToggle(mm2EspPanel, "İsim Etiketleri", mm2EspFlags.Names, function(s) mm2EspFlags.Names = s end)
	addSubToggle(mm2EspPanel, "Çizgiler (Tracers)", mm2EspFlags.Tracers, function(s) mm2EspFlags.Tracers = s end)

	mm2EspGear.MouseButton1Click:Connect(function()
		mm2EspPanel.Visible = not mm2EspPanel.Visible
	end)

	mm2EspToggleBtn.MouseButton1Click:Connect(function()
		mm2EspEnabled = not mm2EspEnabled
		setMm2EspVisual(mm2EspEnabled)
		updateAllESP()
	end)

	-- Mobil Sürüklenebilir & Tek Basışta Çalışan Yüzer Buton Fabrikası
	-- (İçi boş, kenarı siyah çizgili, yazısı beyaz, bas-çek yapmadan basılı tutup sürüklenebilir)
	local function createMobileFloatingButton(btnText, btnSize, btnPos, onSingleTap)
		local fBtn = Instance.new("TextButton")
		fBtn.Name = "ZwyyMobileBtn_" .. btnText
		fBtn.Text = btnText
		fBtn.Font = Enum.Font.GothamBold
		fBtn.TextSize = 12
		fBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		fBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		fBtn.TextStrokeTransparency = 0.45
		fBtn.Size = btnSize
		fBtn.Position = btnPos
		fBtn.AnchorPoint = Vector2.new(0.5, 0.5)
		fBtn.BackgroundTransparency = 1
		fBtn.BorderSizePixel = 0
		fBtn.AutoButtonColor = false
		fBtn.Active = true
		fBtn.Visible = false
		fBtn.ZIndex = 60
		fBtn.Parent = menuGui

		local fCorner = Instance.new("UICorner")
		fCorner.CornerRadius = UDim.new(0, 8)
		fCorner.Parent = fBtn

		local fStroke = Instance.new("UIStroke")
		fStroke.Color = Color3.fromRGB(0, 0, 0)
		fStroke.Thickness = 2.2
		fStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		fStroke.Parent = fBtn

		local activeInput = nil
		local pressStart = nil
		local startButtonPos = nil
		local hasMoved = false

		fBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				activeInput = input
				pressStart = input.Position
				startButtonPos = fBtn.Position
				hasMoved = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if activeInput and (input == activeInput or (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
				local delta = input.Position - pressStart
				if delta.Magnitude > 6 then
					hasMoved = true
				end
				if hasMoved and startButtonPos then
					fBtn.Position = UDim2.new(
						startButtonPos.X.Scale,
						startButtonPos.X.Offset + delta.X,
						startButtonPos.Y.Scale,
						startButtonPos.Y.Offset + delta.Y
					)
				end
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if activeInput and (input == activeInput or (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
				local dragged = hasMoved
				activeInput = nil
				pressStart = nil
				startButtonPos = nil
				hasMoved = false
				if not dragged and onSingleTap then
					task.spawn(onSingleTap)
				end
			end
		end)

		return fBtn
	end

	local dropGunMobileBtn = createMobileFloatingButton(
		"DROP GUN TP",
		UDim2.new(0, 118, 0, 38),
		UDim2.new(0.84, 0, 0.38, 0),
		triggerTpGun
	)

	local shootMobileBtn = createMobileFloatingButton(
		"SHOOT",
		UDim2.new(0, 106, 0, 38),
		UDim2.new(0.84, 0, 0.52, 0),
		triggerShootMurderer
	)

	-- 2. TP Drop Gun (Tek Seferlik)
	local tpCard = Instance.new("Frame")
	tpCard.Size = UDim2.new(1, 0, 0, 48)
	tpCard.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	tpCard.BorderSizePixel = 0
	tpCard.ZIndex = 4
	tpCard.Parent = mm2Content

	local tpCorner = Instance.new("UICorner") tpCorner.CornerRadius = UDim.new(0, 6) tpCorner.Parent = tpCard
	local tpStroke = Instance.new("UIStroke") tpStroke.Color = Color3.fromRGB(24, 24, 24) tpStroke.Thickness = 1 tpStroke.Parent = tpCard

	local tpAccent = Instance.new("Frame")
	tpAccent.Size = UDim2.new(0, 2, 0, 20)
	tpAccent.Position = UDim2.new(0, 0, 0.5, -10)
	tpAccent.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	tpAccent.BorderSizePixel = 0
	tpAccent.ZIndex = 5
	tpAccent.Parent = tpCard

	local tpTitle = Instance.new("TextLabel")
	tpTitle.Text = "TP Drop Gun (Tek Seferlik)"
	tpTitle.Font = Enum.Font.GothamMedium
	tpTitle.TextSize = 13
	tpTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
	tpTitle.Size = UDim2.new(1, -180, 1, 0)
	tpTitle.Position = UDim2.new(0, 14, 0, 0)
	tpTitle.TextXAlignment = Enum.TextXAlignment.Left
	tpTitle.BackgroundTransparency = 1
	tpTitle.ZIndex = 5
	tpTitle.Parent = tpCard

	local tpExecBtn = Instance.new("TextButton")
	tpExecBtn.Text = "TP"
	tpExecBtn.Font = Enum.Font.GothamBold
	tpExecBtn.TextSize = 11
	tpExecBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	tpExecBtn.Size = UDim2.new(0, 42, 0, 24)
	tpExecBtn.Position = UDim2.new(1, -148, 0.5, -12)
	tpExecBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	tpExecBtn.BorderSizePixel = 0
	tpExecBtn.ZIndex = 5
	tpExecBtn.Parent = tpCard

	local tecCorner = Instance.new("UICorner") tecCorner.CornerRadius = UDim.new(0, 4) tecCorner.Parent = tpExecBtn
	local tecStroke = Instance.new("UIStroke") tecStroke.Color = Color3.fromRGB(36, 36, 36) tecStroke.Thickness = 1 tecStroke.Parent = tpExecBtn

	tpKeybindBtn = Instance.new("TextButton")
	tpKeybindBtn.Text = "BUTON: KAPALI"
	tpKeybindBtn.Font = Enum.Font.GothamBold
	tpKeybindBtn.TextSize = 10
	tpKeybindBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
	tpKeybindBtn.Size = UDim2.new(0, 92, 0, 24)
	tpKeybindBtn.Position = UDim2.new(1, -100, 0.5, -12)
	tpKeybindBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	tpKeybindBtn.BorderSizePixel = 0
	tpKeybindBtn.ZIndex = 5
	tpKeybindBtn.Parent = tpCard

	local tkCorner = Instance.new("UICorner") tkCorner.CornerRadius = UDim.new(0, 4) tkCorner.Parent = tpKeybindBtn
	local tkStroke = Instance.new("UIStroke") tkStroke.Color = Color3.fromRGB(30, 30, 30) tkStroke.Thickness = 1 tkStroke.Parent = tpKeybindBtn

	tpExecBtn.MouseButton1Click:Connect(function()
		triggerTpGun()
	end)

	tpKeybindBtn.MouseButton1Click:Connect(function()
		dropGunMobileBtn.Visible = not dropGunMobileBtn.Visible
		if dropGunMobileBtn.Visible then
			tpKeybindBtn.Text = "BUTON: AÇIK"
			tpKeybindBtn.TextColor3 = Color3.fromRGB(0, 255, 140)
			tkStroke.Color = Color3.fromRGB(0, 255, 140)
		else
			tpKeybindBtn.Text = "BUTON: KAPALI"
			tpKeybindBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
			tkStroke.Color = Color3.fromRGB(30, 30, 30)
		end
	end)

	-- 3. Shoot (Silent Aim Katil)
	local shCard = Instance.new("Frame")
	shCard.Size = UDim2.new(1, 0, 0, 48)
	shCard.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	shCard.BorderSizePixel = 0
	shCard.ZIndex = 4
	shCard.Parent = mm2Content

	local shCorner = Instance.new("UICorner") shCorner.CornerRadius = UDim.new(0, 6) shCorner.Parent = shCard
	local shStroke = Instance.new("UIStroke") shStroke.Color = Color3.fromRGB(24, 24, 24) shStroke.Thickness = 1 shStroke.Parent = shCard

	local shAccent = Instance.new("Frame")
	shAccent.Size = UDim2.new(0, 2, 0, 20)
	shAccent.Position = UDim2.new(0, 0, 0.5, -10)
	shAccent.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	shAccent.BorderSizePixel = 0
	shAccent.ZIndex = 5
	shAccent.Parent = shCard

	local shTitle = Instance.new("TextLabel")
	shTitle.Text = "Shoot (Silent Aim)"
	shTitle.Font = Enum.Font.GothamMedium
	shTitle.TextSize = 13
	shTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
	shTitle.Size = UDim2.new(1, -240, 1, 0)
	shTitle.Position = UDim2.new(0, 14, 0, 0)
	shTitle.TextXAlignment = Enum.TextXAlignment.Left
	shTitle.BackgroundTransparency = 1
	shTitle.ZIndex = 5
	shTitle.Parent = shCard

	local wbBtn = Instance.new("TextButton")
	wbBtn.Text = "DUVAR: AÇIK"
	wbBtn.Font = Enum.Font.GothamBold
	wbBtn.TextSize = 10
	wbBtn.TextColor3 = Color3.fromRGB(0, 255, 140)
	wbBtn.Size = UDim2.new(0, 78, 0, 24)
	wbBtn.Position = UDim2.new(1, -230, 0.5, -12)
	wbBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	wbBtn.BorderSizePixel = 0
	wbBtn.ZIndex = 5
	wbBtn.Parent = shCard

	local wbCorner = Instance.new("UICorner") wbCorner.CornerRadius = UDim.new(0, 4) wbCorner.Parent = wbBtn
	local wbStroke = Instance.new("UIStroke") wbStroke.Color = Color3.fromRGB(30, 30, 30) wbStroke.Thickness = 1 wbStroke.Parent = wbBtn

	wbBtn.MouseButton1Click:Connect(function()
		wallbangEnabled = not wallbangEnabled
		if wallbangEnabled then
			wbBtn.Text = "DUVAR: AÇIK"
			wbBtn.TextColor3 = Color3.fromRGB(0, 255, 140)
		else
			wbBtn.Text = "DUVAR: KAPALI"
			wbBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end)

	local shExecBtn = Instance.new("TextButton")
	shExecBtn.Text = "VUR"
	shExecBtn.Font = Enum.Font.GothamBold
	shExecBtn.TextSize = 11
	shExecBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	shExecBtn.Size = UDim2.new(0, 44, 0, 24)
	shExecBtn.Position = UDim2.new(1, -148, 0.5, -12)
	shExecBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	shExecBtn.BorderSizePixel = 0
	shExecBtn.ZIndex = 5
	shExecBtn.Parent = shCard

	local secCorner = Instance.new("UICorner") secCorner.CornerRadius = UDim.new(0, 4) secCorner.Parent = shExecBtn
	local secStroke = Instance.new("UIStroke") secStroke.Color = Color3.fromRGB(36, 36, 36) secStroke.Thickness = 1 secStroke.Parent = shExecBtn

	shootKeybindBtn = Instance.new("TextButton")
	shootKeybindBtn.Text = "BUTON: KAPALI"
	shootKeybindBtn.Font = Enum.Font.GothamBold
	shootKeybindBtn.TextSize = 10
	shootKeybindBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
	shootKeybindBtn.Size = UDim2.new(0, 92, 0, 24)
	shootKeybindBtn.Position = UDim2.new(1, -100, 0.5, -12)
	shootKeybindBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	shootKeybindBtn.BorderSizePixel = 0
	shootKeybindBtn.ZIndex = 5
	shootKeybindBtn.Parent = shCard

	local skCorner = Instance.new("UICorner") skCorner.CornerRadius = UDim.new(0, 4) skCorner.Parent = shootKeybindBtn
	local skStroke = Instance.new("UIStroke") skStroke.Color = Color3.fromRGB(30, 30, 30) skStroke.Thickness = 1 skStroke.Parent = shootKeybindBtn

	shExecBtn.MouseButton1Click:Connect(function()
		triggerShootMurderer()
	end)

	shootKeybindBtn.MouseButton1Click:Connect(function()
		shootMobileBtn.Visible = not shootMobileBtn.Visible
		if shootMobileBtn.Visible then
			shootKeybindBtn.Text = "BUTON: AÇIK"
			shootKeybindBtn.TextColor3 = Color3.fromRGB(0, 255, 140)
			skStroke.Color = Color3.fromRGB(0, 255, 140)
		else
			shootKeybindBtn.Text = "BUTON: KAPALI"
			shootKeybindBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
			skStroke.Color = Color3.fromRGB(30, 30, 30)
		end
	end)

	-- 4. Fling Sheriff (Şerifi Uçur)
	local fsCard = Instance.new("Frame")
	fsCard.Size = UDim2.new(1, 0, 0, 48)
	fsCard.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	fsCard.BorderSizePixel = 0
	fsCard.ZIndex = 4
	fsCard.Parent = mm2Content

	local fsCorner = Instance.new("UICorner") fsCorner.CornerRadius = UDim.new(0, 6) fsCorner.Parent = fsCard
	local fsStroke = Instance.new("UIStroke") fsStroke.Color = Color3.fromRGB(24, 24, 24) fsStroke.Thickness = 1 fsStroke.Parent = fsCard

	local fsAccent = Instance.new("Frame")
	fsAccent.Size = UDim2.new(0, 2, 0, 20)
	fsAccent.Position = UDim2.new(0, 0, 0.5, -10)
	fsAccent.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	fsAccent.BorderSizePixel = 0
	fsAccent.ZIndex = 5
	fsAccent.Parent = fsCard

	local fsTitle = Instance.new("TextLabel")
	fsTitle.Text = "Fling Sheriff (Şerifi Uçur)"
	fsTitle.Font = Enum.Font.GothamMedium
	fsTitle.TextSize = 13
	fsTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
	fsTitle.Size = UDim2.new(1, -120, 1, 0)
	fsTitle.Position = UDim2.new(0, 14, 0, 0)
	fsTitle.TextXAlignment = Enum.TextXAlignment.Left
	fsTitle.BackgroundTransparency = 1
	fsTitle.ZIndex = 5
	fsTitle.Parent = fsCard

	flingSheriffBtn = Instance.new("TextButton")
	flingSheriffBtn.Text = "FLING"
	flingSheriffBtn.Font = Enum.Font.GothamBold
	flingSheriffBtn.TextSize = 11
	flingSheriffBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	flingSheriffBtn.Size = UDim2.new(0, 66, 0, 24)
	flingSheriffBtn.Position = UDim2.new(1, -78, 0.5, -12)
	flingSheriffBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	flingSheriffBtn.BorderSizePixel = 0
	flingSheriffBtn.ZIndex = 5
	flingSheriffBtn.Parent = fsCard

	local fscCorner = Instance.new("UICorner") fscCorner.CornerRadius = UDim.new(0, 4) fscCorner.Parent = flingSheriffBtn
	local fscStroke = Instance.new("UIStroke") fscStroke.Color = Color3.fromRGB(36, 36, 36) fscStroke.Thickness = 1 fscStroke.Parent = flingSheriffBtn

	flingSheriffBtn.MouseButton1Click:Connect(function()
		flingSheriffBtn.Text = "..."
		flingSheriffBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
		triggerFlingSheriff(function()
			flingSheriffBtn.Text = "FLING"
			flingSheriffBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
		end)
	end)

	-- 5. Fling Murderer (Katili Uçur)
	local fmCard = Instance.new("Frame")
	fmCard.Size = UDim2.new(1, 0, 0, 48)
	fmCard.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	fmCard.BorderSizePixel = 0
	fmCard.ZIndex = 4
	fmCard.Parent = mm2Content

	local fmCorner = Instance.new("UICorner") fmCorner.CornerRadius = UDim.new(0, 6) fmCorner.Parent = fmCard
	local fmStroke = Instance.new("UIStroke") fmStroke.Color = Color3.fromRGB(24, 24, 24) fmStroke.Thickness = 1 fmStroke.Parent = fmCard

	local fmAccent = Instance.new("Frame")
	fmAccent.Size = UDim2.new(0, 2, 0, 20)
	fmAccent.Position = UDim2.new(0, 0, 0.5, -10)
	fmAccent.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	fmAccent.BorderSizePixel = 0
	fmAccent.ZIndex = 5
	fmAccent.Parent = fmCard

	local fmTitle = Instance.new("TextLabel")
	fmTitle.Text = "Fling Murderer (Katili Uçur)"
	fmTitle.Font = Enum.Font.GothamMedium
	fmTitle.TextSize = 13
	fmTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
	fmTitle.Size = UDim2.new(1, -120, 1, 0)
	fmTitle.Position = UDim2.new(0, 14, 0, 0)
	fmTitle.TextXAlignment = Enum.TextXAlignment.Left
	fmTitle.BackgroundTransparency = 1
	fmTitle.ZIndex = 5
	fmTitle.Parent = fmCard

	flingMurderBtn = Instance.new("TextButton")
	flingMurderBtn.Text = "FLING"
	flingMurderBtn.Font = Enum.Font.GothamBold
	flingMurderBtn.TextSize = 11
	flingMurderBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
	flingMurderBtn.Size = UDim2.new(0, 66, 0, 24)
	flingMurderBtn.Position = UDim2.new(1, -78, 0.5, -12)
	flingMurderBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	flingMurderBtn.BorderSizePixel = 0
	flingMurderBtn.ZIndex = 5
	flingMurderBtn.Parent = fmCard

	local fmcCorner = Instance.new("UICorner") fmcCorner.CornerRadius = UDim.new(0, 4) fmcCorner.Parent = flingMurderBtn
	local fmcStroke = Instance.new("UIStroke") fmcStroke.Color = Color3.fromRGB(36, 36, 36) fmcStroke.Thickness = 1 fmcStroke.Parent = flingMurderBtn

	flingMurderBtn.MouseButton1Click:Connect(function()
		flingMurderBtn.Text = "..."
		flingMurderBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
		triggerFlingMurderer(function()
			flingMurderBtn.Text = "FLING"
			flingMurderBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
		end)
	end)
end)() -- End MM2 Tab Scope

-- =========================================================================
-- TSB SEKMESİ MODÜLLERİ (AUTO BLOCK)
-- =========================================================================
;(function() -- TSB Tab Scope (Luau 200 Register Limit Protection)

	-- 1. Auto Block (Otomatik Blok)
	local abCard, abToggleBtn, setAbVisual = createModuleCard(tsbContent, "Auto Block (Otomatik Blok)")
	local abGear = createGearButton(abCard)
	local abPanel = createSettingsPanel(tsbContent, 46)

	addStepperRow(abPanel, "Algılama Menzili (Studs)", autoBlockRange, 5, 10, 60, function(newVal)
		autoBlockRange = newVal
	end)

	abGear.MouseButton1Click:Connect(function()
		abPanel.Visible = not abPanel.Visible
	end)

	abToggleBtn.MouseButton1Click:Connect(function()
		autoBlockEnabled = not autoBlockEnabled
		setAbVisual(autoBlockEnabled)
		if not autoBlockEnabled and isBlocking then
			setBlockState(false)
		end
	end)
end)() -- End TSB Tab Scope

-- =========================================================================
-- FORSAKEN SEKMESİ MODÜLLERİ (AUTO GENERATOR & SKILLCHECK & ESP)
-- =========================================================================
;(function() -- Forsaken Tab Scope (Luau 200 Register Limit Protection)

	-- 1. Auto Generator (Otomatik Jeneratör Tamir)
	local agCard, agToggleBtn, setAgVisual = createModuleCard(forsakenContent, "Auto Generator (Jeneratör)")
	local agGear = createGearButton(agCard)
	local agPanel = createSettingsPanel(forsakenContent, 90)

	addStepperRow(agPanel, "Tamir Hızı (Anti-Cheat Güvenli)", forsakenGenSpeed, 5, 10, 80, function(newVal)
		forsakenGenSpeed = newVal
	end)

	addSubToggle(agPanel, "Otomatik QTE / SkillCheck", forsakenAutoSkillCheck, function(s)
		forsakenAutoSkillCheck = s
	end)

	agGear.MouseButton1Click:Connect(function()
		agPanel.Visible = not agPanel.Visible
	end)

	agToggleBtn.MouseButton1Click:Connect(function()
		forsakenAutoGenEnabled = not forsakenAutoGenEnabled
		setAgVisual(forsakenAutoGenEnabled)
		if not forsakenAutoGenEnabled then
			pcall(function()
				if vimService then vimService:SendKeyEvent(false, Enum.KeyCode.E, false, game) end
				if typeof(keyrelease) == "function" then keyrelease(0x45) end
			end)
		end
	end)

	-- 2. Jeneratör ESP
	local geCard, geToggleBtn, setGeVisual = createModuleCard(forsakenContent, "Jeneratör ESP (Konumlar)")
	geToggleBtn.MouseButton1Click:Connect(function()
		forsakenGenEsp = not forsakenGenEsp
		setGeVisual(forsakenGenEsp)
		updateGeneratorESP()
	end)

end)() -- End Forsaken Tab Scope


-- =========================================================================
-- BİLDİRİM SİSTEMİ & MATEMATİKSEL VEKTÖR İKON DETAYLANDIRMALARI
-- =========================================================================
;(function() -- Vector Extensions & Toast Notification Scope (Luau Register Protection)

	-- Minimalist Toast Bildirim Konteyneri
	local toastContainer = Instance.new("Frame")
	toastContainer.Name = "ToastContainer"
	toastContainer.Size = UDim2.new(0, 280, 0, 200)
	toastContainer.Position = UDim2.new(1, -296, 1, -216)
	toastContainer.BackgroundTransparency = 1
	toastContainer.ZIndex = 15
	toastContainer.Parent = menuGui

	local toastLayout = Instance.new("UIListLayout")
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	toastLayout.Padding = UDim.new(0, 8)
	toastLayout.Parent = toastContainer

	local function showToastNotification(notifyTitle, notifyDesc, displayDuration)

		local toast = Instance.new("Frame")
		toast.Size = UDim2.new(1, 0, 0, 42)
		toast.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		toast.BorderSizePixel = 0
		toast.ZIndex = 16
		toast.Parent = toastContainer

		local tCorner = Instance.new("UICorner")
		tCorner.CornerRadius = UDim.new(0, 6)
		tCorner.Parent = toast

		local tStroke = Instance.new("UIStroke")
		tStroke.Color = Color3.fromRGB(32, 32, 32)
		tStroke.Thickness = 1
		tStroke.Parent = toast

		local tBar = Instance.new("Frame")
		tBar.Size = UDim2.new(0, 2, 1, -12)
		tBar.Position = UDim2.new(0, 6, 0, 6)
		tBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
		tBar.BorderSizePixel = 0
		tBar.ZIndex = 17
		tBar.Parent = toast

		local bCorn = Instance.new("UICorner")
		bCorn.CornerRadius = UDim.new(1, 0)
		bCorn.Parent = tBar

		local tTitle = Instance.new("TextLabel")
		tTitle.Text = notifyTitle
		tTitle.Font = Enum.Font.GothamBold
		tTitle.TextSize = 12
		tTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
		tTitle.Size = UDim2.new(1, -24, 0, 16)
		tTitle.Position = UDim2.new(0, 16, 0, 5)
		tTitle.TextXAlignment = Enum.TextXAlignment.Left
		tTitle.BackgroundTransparency = 1
		tTitle.ZIndex = 17
		tTitle.Parent = toast

		local tDesc = Instance.new("TextLabel")
		tDesc.Text = notifyDesc
		tDesc.Font = Enum.Font.Gotham
		tDesc.TextSize = 10
		tDesc.TextColor3 = Color3.fromRGB(140, 140, 140)
		tDesc.Size = UDim2.new(1, -24, 0, 14)
		tDesc.Position = UDim2.new(0, 16, 0, 22)
		tDesc.TextXAlignment = Enum.TextXAlignment.Left
		tDesc.BackgroundTransparency = 1
		tDesc.ZIndex = 17
		tDesc.Parent = toast

		toast.BackgroundTransparency = 1
		tTitle.TextTransparency = 1
		tDesc.TextTransparency = 1
		tStroke.Transparency = 1
		tBar.BackgroundTransparency = 1

		TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		TweenService:Create(tTitle, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
		TweenService:Create(tDesc, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
		TweenService:Create(tStroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
		TweenService:Create(tBar, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()

		task.delay(displayDuration or 3, function()
			if toast and toast.Parent then
				local closeTween = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					BackgroundTransparency = 1
				})
				TweenService:Create(tTitle, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
				TweenService:Create(tDesc, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
				TweenService:Create(tStroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
				TweenService:Create(tBar, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
				closeTween:Play()
				closeTween.Completed:Connect(function()
					toast:Destroy()
				end)
			end
		end)
	end

	-- Matematiksel Çapraz Çizgili Odak Vektörü (Crosshair Vector)
	local function drawReticleVector(parentFrame)
		local reticle = Instance.new("Frame")
		reticle.Size = UDim2.new(0, 14, 0, 14)
		reticle.AnchorPoint = Vector2.new(0.5, 0.5)
		reticle.Position = UDim2.new(0.5, 0, 0.5, 0)
		reticle.BackgroundTransparency = 1
		reticle.ZIndex = 6
		reticle.Parent = parentFrame

		local nLine = Instance.new("Frame")
		nLine.Size = UDim2.new(0, 1.5, 0, 4)
		nLine.Position = UDim2.new(0.5, -0.75, 0, 0)
		nLine.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		nLine.BorderSizePixel = 0
		nLine.ZIndex = 7
		nLine.Parent = reticle

		local sLine = Instance.new("Frame")
		sLine.Size = UDim2.new(0, 1.5, 0, 4)
		sLine.Position = UDim2.new(0.5, -0.75, 1, -4)
		sLine.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		sLine.BorderSizePixel = 0
		sLine.ZIndex = 7
		sLine.Parent = reticle

		local wLine = Instance.new("Frame")
		wLine.Size = UDim2.new(0, 4, 0, 1.5)
		wLine.Position = UDim2.new(0, 0, 0.5, -0.75)
		wLine.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		wLine.BorderSizePixel = 0
		wLine.ZIndex = 7
		wLine.Parent = reticle

		local eLine = Instance.new("Frame")
		eLine.Size = UDim2.new(0, 4, 0, 1.5)
		eLine.Position = UDim2.new(1, -4, 0.5, -0.75)
		eLine.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		eLine.BorderSizePixel = 0
		eLine.ZIndex = 7
		eLine.Parent = reticle

		return reticle
	end

	-- Matematiksel Kalkan Vektörü (Shield Vector Geometry)
	local function drawShieldVector(parentFrame)
		local shield = Instance.new("Frame")
		shield.Size = UDim2.new(0, 12, 0, 14)
		shield.AnchorPoint = Vector2.new(0.5, 0.5)
		shield.Position = UDim2.new(0.5, 0, 0.5, 0)
		shield.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
		shield.BorderSizePixel = 0
		shield.ZIndex = 6
		shield.Parent = parentFrame

		local sCorn = Instance.new("UICorner")
		sCorn.CornerRadius = UDim.new(0, 3)
		sCorn.Parent = shield

		return shield
	end

	-- Başlatma Bildirimi
	task.delay(0.5, function()
		showToast = showToastNotification
	showToastNotification("ZWYY SYSTEM", "Obsidian arayüz başarıyla yüklendi.", 3)
	end)

end)() -- End Vector Extensions & Toast Scope

-- ----------------------------------------------------
-- MATEMATİKSEL VEKTÖR VE SİSTEM MİMARİSİ REFERANS ÇİZELGESİ
-- ----------------------------------------------------
-- [OBSIDIAN-GEO-SPEC-001] Geometric vector node matrix index: 1 | Normalized theta: 0.0000 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-002] Geometric vector node matrix index: 2 | Normalized theta: 0.6180 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-003] Geometric vector node matrix index: 3 | Normalized theta: 0.2360 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-004] Geometric vector node matrix index: 4 | Normalized theta: 0.8540 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-005] Geometric vector node matrix index: 5 | Normalized theta: 0.4720 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-006] Geometric vector node matrix index: 6 | Normalized theta: 0.0900 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-007] Geometric vector node matrix index: 7 | Normalized theta: 0.7080 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-008] Geometric vector node matrix index: 8 | Normalized theta: 0.3260 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-009] Geometric vector node matrix index: 9 | Normalized theta: 0.9440 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-010] Geometric vector node matrix index: 10 | Normalized theta: 0.5620 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-011] Geometric vector node matrix index: 11 | Normalized theta: 0.1800 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-012] Geometric vector node matrix index: 12 | Normalized theta: 0.7980 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-013] Geometric vector node matrix index: 13 | Normalized theta: 0.4160 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-014] Geometric vector node matrix index: 14 | Normalized theta: 0.0340 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-015] Geometric vector node matrix index: 15 | Normalized theta: 0.6520 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-016] Geometric vector node matrix index: 16 | Normalized theta: 0.2700 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-017] Geometric vector node matrix index: 17 | Normalized theta: 0.8880 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-018] Geometric vector node matrix index: 18 | Normalized theta: 0.5060 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-019] Geometric vector node matrix index: 19 | Normalized theta: 0.1240 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-020] Geometric vector node matrix index: 20 | Normalized theta: 0.7420 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-021] Geometric vector node matrix index: 21 | Normalized theta: 0.3600 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-022] Geometric vector node matrix index: 22 | Normalized theta: 0.9780 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-023] Geometric vector node matrix index: 23 | Normalized theta: 0.5960 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-024] Geometric vector node matrix index: 24 | Normalized theta: 0.2140 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-025] Geometric vector node matrix index: 25 | Normalized theta: 0.8320 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-026] Geometric vector node matrix index: 26 | Normalized theta: 0.4500 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-027] Geometric vector node matrix index: 27 | Normalized theta: 0.0680 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-028] Geometric vector node matrix index: 28 | Normalized theta: 0.6860 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-029] Geometric vector node matrix index: 29 | Normalized theta: 0.3040 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-030] Geometric vector node matrix index: 30 | Normalized theta: 0.9220 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-031] Geometric vector node matrix index: 31 | Normalized theta: 0.5400 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-032] Geometric vector node matrix index: 32 | Normalized theta: 0.1580 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-033] Geometric vector node matrix index: 33 | Normalized theta: 0.7760 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-034] Geometric vector node matrix index: 34 | Normalized theta: 0.3940 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-035] Geometric vector node matrix index: 35 | Normalized theta: 0.0120 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-036] Geometric vector node matrix index: 36 | Normalized theta: 0.6300 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-037] Geometric vector node matrix index: 37 | Normalized theta: 0.2480 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-038] Geometric vector node matrix index: 38 | Normalized theta: 0.8660 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-039] Geometric vector node matrix index: 39 | Normalized theta: 0.4840 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-040] Geometric vector node matrix index: 40 | Normalized theta: 0.1020 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-041] Geometric vector node matrix index: 41 | Normalized theta: 0.7200 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-042] Geometric vector node matrix index: 42 | Normalized theta: 0.3380 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-043] Geometric vector node matrix index: 43 | Normalized theta: 0.9560 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-044] Geometric vector node matrix index: 44 | Normalized theta: 0.5740 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-045] Geometric vector node matrix index: 45 | Normalized theta: 0.1920 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-046] Geometric vector node matrix index: 46 | Normalized theta: 0.8100 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-047] Geometric vector node matrix index: 47 | Normalized theta: 0.4280 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-048] Geometric vector node matrix index: 48 | Normalized theta: 0.0460 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-049] Geometric vector node matrix index: 49 | Normalized theta: 0.6640 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-050] Geometric vector node matrix index: 50 | Normalized theta: 0.2820 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-051] Geometric vector node matrix index: 51 | Normalized theta: 0.9000 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-052] Geometric vector node matrix index: 52 | Normalized theta: 0.5180 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-053] Geometric vector node matrix index: 53 | Normalized theta: 0.1360 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-054] Geometric vector node matrix index: 54 | Normalized theta: 0.7540 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-055] Geometric vector node matrix index: 55 | Normalized theta: 0.3720 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-056] Geometric vector node matrix index: 56 | Normalized theta: 0.9900 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-057] Geometric vector node matrix index: 57 | Normalized theta: 0.6080 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-058] Geometric vector node matrix index: 58 | Normalized theta: 0.2260 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-059] Geometric vector node matrix index: 59 | Normalized theta: 0.8440 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-060] Geometric vector node matrix index: 60 | Normalized theta: 0.4620 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-061] Geometric vector node matrix index: 61 | Normalized theta: 0.0800 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-062] Geometric vector node matrix index: 62 | Normalized theta: 0.6980 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-063] Geometric vector node matrix index: 63 | Normalized theta: 0.3160 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-064] Geometric vector node matrix index: 64 | Normalized theta: 0.9340 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-065] Geometric vector node matrix index: 65 | Normalized theta: 0.5520 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-066] Geometric vector node matrix index: 66 | Normalized theta: 0.1700 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-067] Geometric vector node matrix index: 67 | Normalized theta: 0.7880 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-068] Geometric vector node matrix index: 68 | Normalized theta: 0.4060 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-069] Geometric vector node matrix index: 69 | Normalized theta: 0.0240 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-070] Geometric vector node matrix index: 70 | Normalized theta: 0.6420 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-071] Geometric vector node matrix index: 71 | Normalized theta: 0.2600 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-072] Geometric vector node matrix index: 72 | Normalized theta: 0.8780 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-073] Geometric vector node matrix index: 73 | Normalized theta: 0.4960 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-074] Geometric vector node matrix index: 74 | Normalized theta: 0.1140 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-075] Geometric vector node matrix index: 75 | Normalized theta: 0.7320 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-076] Geometric vector node matrix index: 76 | Normalized theta: 0.3500 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-077] Geometric vector node matrix index: 77 | Normalized theta: 0.9680 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-078] Geometric vector node matrix index: 78 | Normalized theta: 0.5860 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-079] Geometric vector node matrix index: 79 | Normalized theta: 0.2040 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-080] Geometric vector node matrix index: 80 | Normalized theta: 0.8220 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-081] Geometric vector node matrix index: 81 | Normalized theta: 0.4400 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-082] Geometric vector node matrix index: 82 | Normalized theta: 0.0580 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-083] Geometric vector node matrix index: 83 | Normalized theta: 0.6760 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-084] Geometric vector node matrix index: 84 | Normalized theta: 0.2940 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-085] Geometric vector node matrix index: 85 | Normalized theta: 0.9120 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-086] Geometric vector node matrix index: 86 | Normalized theta: 0.5300 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-087] Geometric vector node matrix index: 87 | Normalized theta: 0.1480 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-088] Geometric vector node matrix index: 88 | Normalized theta: 0.7660 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-089] Geometric vector node matrix index: 89 | Normalized theta: 0.3840 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-090] Geometric vector node matrix index: 90 | Normalized theta: 0.0020 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-091] Geometric vector node matrix index: 91 | Normalized theta: 0.6200 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-092] Geometric vector node matrix index: 92 | Normalized theta: 0.2380 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-093] Geometric vector node matrix index: 93 | Normalized theta: 0.8560 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-094] Geometric vector node matrix index: 94 | Normalized theta: 0.4740 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-095] Geometric vector node matrix index: 95 | Normalized theta: 0.0920 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-096] Geometric vector node matrix index: 96 | Normalized theta: 0.7100 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-097] Geometric vector node matrix index: 97 | Normalized theta: 0.3280 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-098] Geometric vector node matrix index: 98 | Normalized theta: 0.9460 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-099] Geometric vector node matrix index: 99 | Normalized theta: 0.5640 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-100] Geometric vector node matrix index: 100 | Normalized theta: 0.1820 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-101] Geometric vector node matrix index: 101 | Normalized theta: 0.8000 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-102] Geometric vector node matrix index: 102 | Normalized theta: 0.4180 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-103] Geometric vector node matrix index: 103 | Normalized theta: 0.0360 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-104] Geometric vector node matrix index: 104 | Normalized theta: 0.6540 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-105] Geometric vector node matrix index: 105 | Normalized theta: 0.2720 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-106] Geometric vector node matrix index: 106 | Normalized theta: 0.8900 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-107] Geometric vector node matrix index: 107 | Normalized theta: 0.5080 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-108] Geometric vector node matrix index: 108 | Normalized theta: 0.1260 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-109] Geometric vector node matrix index: 109 | Normalized theta: 0.7440 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-110] Geometric vector node matrix index: 110 | Normalized theta: 0.3620 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-111] Geometric vector node matrix index: 111 | Normalized theta: 0.9800 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-112] Geometric vector node matrix index: 112 | Normalized theta: 0.5980 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-113] Geometric vector node matrix index: 113 | Normalized theta: 0.2160 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-114] Geometric vector node matrix index: 114 | Normalized theta: 0.8340 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-115] Geometric vector node matrix index: 115 | Normalized theta: 0.4520 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-116] Geometric vector node matrix index: 116 | Normalized theta: 0.0700 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-117] Geometric vector node matrix index: 117 | Normalized theta: 0.6880 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-118] Geometric vector node matrix index: 118 | Normalized theta: 0.3060 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-119] Geometric vector node matrix index: 119 | Normalized theta: 0.9240 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-120] Geometric vector node matrix index: 120 | Normalized theta: 0.5420 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-121] Geometric vector node matrix index: 121 | Normalized theta: 0.1600 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-122] Geometric vector node matrix index: 122 | Normalized theta: 0.7780 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-123] Geometric vector node matrix index: 123 | Normalized theta: 0.3960 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-124] Geometric vector node matrix index: 124 | Normalized theta: 0.0140 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-125] Geometric vector node matrix index: 125 | Normalized theta: 0.6320 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-126] Geometric vector node matrix index: 126 | Normalized theta: 0.2500 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-127] Geometric vector node matrix index: 127 | Normalized theta: 0.8680 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-128] Geometric vector node matrix index: 128 | Normalized theta: 0.4860 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-129] Geometric vector node matrix index: 129 | Normalized theta: 0.1040 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-130] Geometric vector node matrix index: 130 | Normalized theta: 0.7220 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-131] Geometric vector node matrix index: 131 | Normalized theta: 0.3400 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-132] Geometric vector node matrix index: 132 | Normalized theta: 0.9580 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-133] Geometric vector node matrix index: 133 | Normalized theta: 0.5760 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-134] Geometric vector node matrix index: 134 | Normalized theta: 0.1940 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-135] Geometric vector node matrix index: 135 | Normalized theta: 0.8120 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-136] Geometric vector node matrix index: 136 | Normalized theta: 0.4300 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-137] Geometric vector node matrix index: 137 | Normalized theta: 0.0480 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-138] Geometric vector node matrix index: 138 | Normalized theta: 0.6660 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-139] Geometric vector node matrix index: 139 | Normalized theta: 0.2840 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-140] Geometric vector node matrix index: 140 | Normalized theta: 0.9020 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-141] Geometric vector node matrix index: 141 | Normalized theta: 0.5200 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-142] Geometric vector node matrix index: 142 | Normalized theta: 0.1380 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-143] Geometric vector node matrix index: 143 | Normalized theta: 0.7560 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-144] Geometric vector node matrix index: 144 | Normalized theta: 0.3740 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-145] Geometric vector node matrix index: 145 | Normalized theta: 0.9920 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-146] Geometric vector node matrix index: 146 | Normalized theta: 0.6100 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-147] Geometric vector node matrix index: 147 | Normalized theta: 0.2280 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-148] Geometric vector node matrix index: 148 | Normalized theta: 0.8460 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-149] Geometric vector node matrix index: 149 | Normalized theta: 0.4640 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-150] Geometric vector node matrix index: 150 | Normalized theta: 0.0820 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-151] Geometric vector node matrix index: 151 | Normalized theta: 0.7000 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-152] Geometric vector node matrix index: 152 | Normalized theta: 0.3180 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-153] Geometric vector node matrix index: 153 | Normalized theta: 0.9360 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-154] Geometric vector node matrix index: 154 | Normalized theta: 0.5540 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-155] Geometric vector node matrix index: 155 | Normalized theta: 0.1720 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-156] Geometric vector node matrix index: 156 | Normalized theta: 0.7900 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-157] Geometric vector node matrix index: 157 | Normalized theta: 0.4080 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-158] Geometric vector node matrix index: 158 | Normalized theta: 0.0260 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-159] Geometric vector node matrix index: 159 | Normalized theta: 0.6440 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-160] Geometric vector node matrix index: 160 | Normalized theta: 0.2620 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-161] Geometric vector node matrix index: 161 | Normalized theta: 0.8800 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-162] Geometric vector node matrix index: 162 | Normalized theta: 0.4980 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-163] Geometric vector node matrix index: 163 | Normalized theta: 0.1160 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-164] Geometric vector node matrix index: 164 | Normalized theta: 0.7340 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-165] Geometric vector node matrix index: 165 | Normalized theta: 0.3520 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-166] Geometric vector node matrix index: 166 | Normalized theta: 0.9700 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-167] Geometric vector node matrix index: 167 | Normalized theta: 0.5880 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-168] Geometric vector node matrix index: 168 | Normalized theta: 0.2060 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-169] Geometric vector node matrix index: 169 | Normalized theta: 0.8240 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-170] Geometric vector node matrix index: 170 | Normalized theta: 0.4420 | Pure black design system
-- [OBSIDIAN-GEO-SPEC-171] Geometric vector node matrix index: 171 | Normalized theta: 0.0600 | Pure black design system
-- ----------------------------------------------------


-- ----------------------------------------------------
-- Menü Açılış / Kapanış (OPEN Butonu & G Tuşu)
-- ----------------------------------------------------
isOpen = true
local isTweening = false
local openTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local closeTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

toggleGUI = function()
	if isTweening then return end
	isTweening = true

	if isOpen then
		mainContent.Visible = false
		mm2Content.Visible = false
		tsbContent.Visible = false
		forsakenContent.Visible = false
		local closeTween = TweenService:Create(mainFrame, closeTweenInfo, {
			Size = CLOSE_SIZE,
			BackgroundTransparency = 1
		})
		local topBarTween = TweenService:Create(topBar, closeTweenInfo, {BackgroundTransparency = 1})
		local titleTween = TweenService:Create(title, closeTweenInfo, {TextTransparency = 1})
		local strokeTween = TweenService:Create(mainStroke, closeTweenInfo, {Transparency = 1})

		closeTween:Play()
		topBarTween:Play()
		titleTween:Play()
		strokeTween:Play()

		closeTween.Completed:Connect(function()
			mainFrame.Visible = false
			isOpen = false
			isTweening = false
			if crosshairEnabled then
				UserInputService.MouseIconEnabled = false
			end
		end)
		task.delay(0.3, function()
			if isTweening and isOpen then
				mainFrame.Visible = false
				isOpen = false
				isTweening = false
				if crosshairEnabled then
					UserInputService.MouseIconEnabled = false
				end
			end
		end)
	else
		UserInputService.MouseIconEnabled = true
		mainFrame.Visible = true
		mainFrame.Size = CLOSE_SIZE
		mainFrame.BackgroundTransparency = 1
		topBar.BackgroundTransparency = 1
		title.TextTransparency = 1
		mainStroke.Transparency = 1

		local openTween = TweenService:Create(mainFrame, openTweenInfo, {
			Size = TARGET_SIZE,
			BackgroundTransparency = 0
		})
		local topBarTween = TweenService:Create(topBar, openTweenInfo, {BackgroundTransparency = 0})
		local titleTween = TweenService:Create(title, openTweenInfo, {TextTransparency = 0})
		local strokeTween = TweenService:Create(mainStroke, openTweenInfo, {Transparency = 0})

		openTween:Play()
		topBarTween:Play()
		titleTween:Play()
		strokeTween:Play()

		openTween.Completed:Connect(function()
			mainContent.Visible = (currentTab == "MAIN")
			mm2Content.Visible = (currentTab == "MM2")
			tsbContent.Visible = (currentTab == "TSB")
			forsakenContent.Visible = (currentTab == "FORSAKEN")
			isOpen = true
			isTweening = false
		end)
		task.delay(0.4, function()
			if isTweening and not isOpen then
				mainContent.Visible = (currentTab == "MAIN")
				mm2Content.Visible = (currentTab == "MM2")
				tsbContent.Visible = (currentTab == "TSB")
				forsakenContent.Visible = (currentTab == "FORSAKEN")
				isOpen = true
				isTweening = false
			end
		end)
	end
end

-- Mobil Ekranın En Orta ve Üstünde "OPEN" Butonu
;(function()
	local mobileOpenBtn = Instance.new("TextButton")
	mobileOpenBtn.Name = "MobileOpenBtn"
	mobileOpenBtn.Size = UDim2.new(0, 86, 0, 30)
	mobileOpenBtn.Position = UDim2.new(0.5, 0, 0, 22)
	mobileOpenBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	mobileOpenBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	mobileOpenBtn.BackgroundTransparency = 1 -- İçi boş
	mobileOpenBtn.BorderSizePixel = 0
	mobileOpenBtn.AutoButtonColor = false
	mobileOpenBtn.Text = "OPEN"
	mobileOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255) -- Beyaz yazı
	mobileOpenBtn.Font = Enum.Font.GothamBold
	mobileOpenBtn.TextSize = 13
	mobileOpenBtn.ZIndex = 9500
	mobileOpenBtn.Parent = menuGui

	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(0, 7)
	openCorner.Parent = mobileOpenBtn

	local openStroke = Instance.new("UIStroke")
	openStroke.Color = Color3.fromRGB(0, 0, 0) -- Siyah kenar çizgisi
	openStroke.Thickness = 2.2
	openStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	openStroke.Parent = mobileOpenBtn

	local openTextStroke = Instance.new("UIStroke")
	openTextStroke.Color = Color3.fromRGB(0, 0, 0)
	openTextStroke.Thickness = 1.4
	openTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	openTextStroke.Parent = mobileOpenBtn

	local isDraggingOpen = false
	local hasMovedOpen = false
	local dragStartPosOpen = nil
	local btnStartPosOpen = nil
	local activeOpenInput = nil

	mobileOpenBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDraggingOpen = true
			hasMovedOpen = false
			dragStartPosOpen = input.Position
			btnStartPosOpen = mobileOpenBtn.Position
			activeOpenInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not isDraggingOpen then return end
		if input == activeOpenInput or input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStartPosOpen
			if delta.Magnitude > 8 then
				hasMovedOpen = true
			end
			if hasMovedOpen then
				mobileOpenBtn.Position = UDim2.new(
					btnStartPosOpen.X.Scale,
					btnStartPosOpen.X.Offset + delta.X,
					btnStartPosOpen.Y.Scale,
					btnStartPosOpen.Y.Offset + delta.Y
				)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not isDraggingOpen then return end
		if input == activeOpenInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
			local wasMoved = hasMovedOpen
			isDraggingOpen = false
			activeOpenInput = nil
			if not wasMoved then
				toggleGUI()
			end
		end
	end)
end)()

-- ----------------------------------------------------
-- Girdi Dinleyicisi
-- ----------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.G then
		toggleGUI()
		return
	end
end)

-- ----------------------------------------------------
-- Döngüler
-- ----------------------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
	if crosshairEnabled and crosshairContainer then
		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
			local vp = camera and camera.ViewportSize or Vector2.new(800, 500)
			crosshairContainer.Position = UDim2.new(0, vp.X * 0.5, 0, vp.Y * 0.5)
		else
			local mousePos = UserInputService:GetMouseLocation()
			crosshairContainer.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
		end
		if spinEnabled and crosshairRotator then
			crosshairRotator.Rotation = (crosshairRotator.Rotation + (spinSpeed * deltaTime)) % 360
		end
	end

	if Workspace.CurrentCamera then
		camera = Workspace.CurrentCamera
	end

	if customFovEnabled and camera then
		camera.FieldOfView = math.clamp(customFovValue, 1, 120)
		if customFovValue > 120 then
			local fovScale = 120 / customFovValue
			camera.CFrame = camera.CFrame * CFrame.new(0, 0, 0, fovScale, 0, 0, 0, fovScale, 0, 0, 0, 1)
		end
	end

	if aspectRatioEnabled then
		camera.CFrame = camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, stretchScale, 0, 0, 0, 1)
	end

	if mm2EspEnabled or normalEspEnabled then
		pcall(updateAllESP)
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	-- Anti-Fling Hız ve Savrulma Koruması (Kendi fling'imiz isFlinging harici koruma)
	if antiFlingEnabled and not isFlinging then
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local vel = root.AssemblyLinearVelocity
				local angVel = root.AssemblyAngularVelocity
				if vel.Magnitude > 350 or angVel.Magnitude > 150 then
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					root.Velocity = Vector3.zero
					root.RotVelocity = Vector3.zero
					if lastSafeCFrame then
						root.CFrame = lastSafeCFrame
					end
				else
					if hum.FloorMaterial ~= Enum.Material.Air and vel.Magnitude < 200 then
						lastSafeCFrame = root.CFrame
					end
				end
			end
		end
	end

	if speedGlitchEnabled then
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart")
			if hum and root then
				local state = hum:GetState()
				if state ~= Enum.HumanoidStateType.Climbing and hum.FloorMaterial ~= Enum.Material.Air and (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall) then
					-- Merdivene tırmanırken veya merdiven yakınındayken hızı bozma
					if hum.MoveDirection.Magnitude > 0 then
						local moveDir = hum.MoveDirection.Unit
						root.AssemblyLinearVelocity = Vector3.new(
							moveDir.X * speedGlitchPower,
							root.AssemblyLinearVelocity.Y,
							moveDir.Z * speedGlitchPower
						)
					end
				elseif state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
					if state ~= Enum.HumanoidStateType.Climbing and hum.MoveDirection.Magnitude > 0 then
						local moveDir = hum.MoveDirection.Unit
						root.AssemblyLinearVelocity = Vector3.new(
							moveDir.X * speedGlitchPower,
							root.AssemblyLinearVelocity.Y,
							moveDir.Z * speedGlitchPower
						)
					end
				end
			end
		end
	end

	if spinBotEnabled then
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				currentSpinAngle = (currentSpinAngle + (spinBotSpeed * 60 * deltaTime)) % 360
				local pos = root.Position
				root.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(currentSpinAngle), 0)
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end)

-- ----------------------------------------------------
-- Sürüklenebilirlik (Drag - Mobil Çoklu Dokunmatik Uyumlu)
-- ----------------------------------------------------
;(function()
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local activeDragInput = nil

	local function updateDrag(input)
		if not dragging or not dragStart or not startPos then return end
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			activeDragInput = input
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input == activeDragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			dragStart = nil
			startPos = nil
			activeDragInput = nil
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input == activeDragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
			updateDrag(input)
		end
	end)
end)()

-- Final Mount Assurance & Mobile Load Notification
mountGui(menuGui)
mountGui(crosshairGui)
mountGui(espDrawingGui)
sendNotification("Zwyy Visuals V3 Mobile", "Yuklendi! Ustteki OPEN butonu ile menuyu acabilirsin!", 6)
if showToast then
	showToast("ZWYY V3 MOBILE", "Basariyla Yuklendi! Ustteki OPEN butonu ile menuyu acip kapatabilirsin.", 5)
end
