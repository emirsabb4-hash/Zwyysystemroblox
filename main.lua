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
local crosshairGradientEnabled = false
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

-- ----------------------------------------------------
-- Aspect Ratio Hedefleme & Fare Duzeltme Motoru
-- (Stretched Resolution acikken merminin asagiya/baska yere gitmesini onler)
-- ----------------------------------------------------
local rawMouse = player and player:GetMouse()
local isCalculatingHit = false

local function getCorrectedMouseRay(customX, customY)
	local cam = Workspace.CurrentCamera or camera
	if not cam then return nil end
	local vp = cam.ViewportSize
	local mLoc = UserInputService:GetMouseLocation()
	local x = customX or mLoc.X
	local y = customY or mLoc.Y

	if aspectRatioEnabled and stretchScale and stretchScale > 0 and stretchScale ~= 1 then
		local cY = vp.Y / 2
		local dy = y - cY
		y = cY + (dy / stretchScale)
	end

	return cam:ScreenPointToRay(x, y)
end

local function getCorrectedMouseHit()
	if isCalculatingHit then
		return rawMouse and rawMouse.Hit, rawMouse and rawMouse.Target
	end
	isCalculatingHit = true

	local success, hitCF, hitPart = pcall(function()
		local ray = getCorrectedMouseRay()
		if not ray then
			return rawMouse and rawMouse.Hit, rawMouse and rawMouse.Target
		end

		local char = player and player.Character
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ignoreList = {}
		if char then
			table.insert(ignoreList, char)
		end
		params.FilterDescendantsInstances = ignoreList
		params.IgnoreWater = true

		local result = Workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
		if result then
			return CFrame.new(result.Position, result.Position + ray.Direction), result.Instance
		else
			return CFrame.new(ray.Origin + ray.Direction * 3000), nil
		end
	end)

	isCalculatingHit = false

	if success and hitCF then
		return hitCF, hitPart
	end
	return rawMouse and rawMouse.Hit, rawMouse and rawMouse.Target
end

pcall(function()
	if hookmetamethod then
		local oldIndex
		oldIndex = hookmetamethod(game, "__index", function(self, key)
			if aspectRatioEnabled and not isCalculatingHit then
				if typeof(self) == "Instance" and self:IsA("Mouse") then
					if key == "Hit" then
						local hitCF = getCorrectedMouseHit()
						if hitCF then return hitCF end
					elseif key == "Target" then
						local _, hitPart = getCorrectedMouseHit()
						return hitPart
					elseif key == "UnitRay" then
						local ray = getCorrectedMouseRay()
						if ray then return ray end
					end
				end
			end
			return oldIndex(self, key)
		end)

		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			if aspectRatioEnabled and (method == "ScreenPointToRay" or method == "ViewportPointToRay") then
				if typeof(self) == "Instance" and self:IsA("Camera") then
					local args = {...}
					local x = args[1]
					local y = args[2]
					if type(x) == "number" and type(y) == "number" and stretchScale and stretchScale > 0 and stretchScale ~= 1 then
						local cY = self.ViewportSize.Y / 2
						local dy = y - cY
						args[2] = cY + (dy / stretchScale)
						return oldNamecall(self, unpack(args))
					end
				end
			end
			return oldNamecall(self, ...)
		end)
	else
		local gmt = getrawmetatable and getrawmetatable(game)
		local setro = setreadonly or make_writeable
		if gmt and setro then
			setro(gmt, false)
			local oldIndex = gmt.__index
			local oldNamecall = gmt.__namecall

			gmt.__index = (newcclosure and newcclosure(function(self, key)
				if aspectRatioEnabled and not isCalculatingHit then
					if typeof(self) == "Instance" and self:IsA("Mouse") then
						if key == "Hit" then
							local hitCF = getCorrectedMouseHit()
							if hitCF then return hitCF end
						elseif key == "Target" then
							local _, hitPart = getCorrectedMouseHit()
							return hitPart
						elseif key == "UnitRay" then
							local ray = getCorrectedMouseRay()
							if ray then return ray end
						end
					end
				end
				return oldIndex(self, key)
			end)) or function(self, key)
				if aspectRatioEnabled and not isCalculatingHit then
					if typeof(self) == "Instance" and self:IsA("Mouse") then
						if key == "Hit" then
							local hitCF = getCorrectedMouseHit()
							if hitCF then return hitCF end
						elseif key == "Target" then
							local _, hitPart = getCorrectedMouseHit()
							return hitPart
						elseif key == "UnitRay" then
							local ray = getCorrectedMouseRay()
							if ray then return ray end
						end
					end
				end
				return oldIndex(self, key)
			end

			if oldNamecall then
				gmt.__namecall = (newcclosure and newcclosure(function(self, ...)
					local method = getnamecallmethod()
					if aspectRatioEnabled and (method == "ScreenPointToRay" or method == "ViewportPointToRay") then
						if typeof(self) == "Instance" and self:IsA("Camera") then
							local args = {...}
							local x = args[1]
							local y = args[2]
							if type(x) == "number" and type(y) == "number" and stretchScale and stretchScale > 0 and stretchScale ~= 1 then
								local cY = self.ViewportSize.Y / 2
								local dy = y - cY
								args[2] = cY + (dy / stretchScale)
								return oldNamecall(self, unpack(args))
							end
						end
					end
					return oldNamecall(self, ...)
				end)) or function(self, ...)
					local method = getnamecallmethod()
					if aspectRatioEnabled and (method == "ScreenPointToRay" or method == "ViewportPointToRay") then
						if typeof(self) == "Instance" and self:IsA("Camera") then
							local args = {...}
							local x = args[1]
							local y = args[2]
							if type(x) == "number" and type(y) == "number" and stretchScale and stretchScale > 0 and stretchScale ~= 1 then
								local cY = self.ViewportSize.Y / 2
								local dy = y - cY
								args[2] = cY + (dy / stretchScale)
								return oldNamecall(self, unpack(args))
							end
						end
					end
					return oldNamecall(self, ...)
				end
			end
			setro(gmt, true)
		end
	end
end)

-- TP Drop Gun Tuş Ataması
local tpGunKey = nil
local tpKeybindBtn = nil
local shootKeybindBtn = nil
local isBindingTpGun = false

-- Shoot & Wallbang
local shootKey = nil
local isBindingShoot = false
local isShooting = false
local currentAimTorsoPos = nil
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

-- TSB (The Strongest Battlegrounds) Auto Block Ayarları
local autoBlockEnabled = false
-- TSB Counter ESP
local tsbCounterEspEnabled = false
local tsbCounterNotifyEnded = true
local activeCounters = {}
local tsbSettings = {
	Range = 25,
	Delay = 0,
	Fov = 180,
	Facing = false,
	Aimhelper = false
}


-- ----------------------------------------------------
-- Katman Yönetimi
local menuGui = Instance.new("ScreenGui")
menuGui.Name = "ZwyyVisual_Menu"
menuGui.DisplayOrder = 999999
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
-- R15'ten R6'ya Doğrudan Resetli Dönüştürücü (Animasyonsuz)
-- ----------------------------------------------------
local function convertR15ToR6WithReset()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local savedCFrame = root and root.CFrame

	-- Karakteri resetle
	if hum then
		hum.Health = 0
	end

	-- Respawn olduğunda R6 rigine dönüştür
	local conn
	conn = player.CharacterAdded:Connect(function(newChar)
		conn:Disconnect()
		task.wait(0.2)
		pcall(function()
			local newHum = newChar:WaitForChild("Humanoid", 8)
			local newRoot = newChar:WaitForChild("HumanoidRootPart", 8)
			if savedCFrame and newRoot then
				newRoot.CFrame = savedCFrame
			end

			-- Eğer oyun R15 olarak doğurduysa, gerçek R6 modeline çevir
			if newHum and newHum.RigType == Enum.HumanoidRigType.R15 then
				local desc = nil
				pcall(function()
					desc = Players:GetHumanoidDescriptionFromUserId(player.UserId)
				end)
				if not desc and newHum:FindFirstChildOfClass("HumanoidDescription") then
					desc = newHum:FindFirstChildOfClass("HumanoidDescription")
				end
				if desc then
					local r6Model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
					if r6Model then
						r6Model.Name = player.Name
						if newRoot then
							r6Model:SetPrimaryPartCFrame(newRoot.CFrame)
						end
						player.Character = r6Model
						r6Model.Parent = Workspace
						newChar:Destroy()
					end
				end
			end
		end)
	end)
end

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

local function hideNativeShiftLockCursor()
	pcall(function()
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and (gui.Name:lower():find("mouselock") or gui.Name:lower():find("shiftlock")) then
				local label = gui:FindFirstChildWhichIsA("ImageLabel", true)
				if label and label.Visible then
					label.Visible = false
				end
			end
		end
		local tg = playerGui:FindFirstChild("TouchGui")
		if tg then
			local label = tg:FindFirstChild("MouseLockLabel", true)
			if label and label.Visible then
				label.Visible = false
			end
		end
	end)
end

local function isShiftLocked()
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		return true
	end

	local locked = false
	pcall(function()
		local tg = playerGui and playerGui:FindFirstChild("TouchGui")
		local tcf = tg and tg:FindFirstChild("TouchControlFrame")
		local sl = tcf and (tcf:FindFirstChild("ShiftLock") or tcf:FindFirstChild("ShiftLockButton"))
		if not sl and playerGui then
			for _, g in ipairs(playerGui:GetChildren()) do
				if g:IsA("ScreenGui") then
					local btn = g:FindFirstChild("ShiftLock", true) or g:FindFirstChild("ShiftLockButton", true)
					if btn and btn:IsA("ImageButton") then
						sl = btn
						break
					end
				end
			end
		end
		if sl and sl:IsA("ImageButton") then
			local img = tostring(sl.Image):lower()
			if (img:find("on") or img:find("active") or img:find("selected") or img:find("enabled")) and not (img:find("off") or img:find("disabled")) then
				locked = true
			end
		end
	end)
	return locked
end

local crosshairContainer = Instance.new("Frame")
crosshairContainer.Name = "CrosshairContainer"
crosshairContainer.Size = UDim2.new(0, 100, 0, 100)
crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
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

local armBars, armStrokes, armGradients = {}, {}, {}
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

	local barGrad = Instance.new("UIGradient")
	barGrad.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255))
	barGrad.Rotation = 0
	barGrad.Enabled = false
	barGrad.Parent = bar

	table.insert(armBars, bar)
	table.insert(armStrokes, glowStroke)
	table.insert(armGradients, barGrad)
end

local function updateCrosshairAppearance()
	local coreColor, glowColor, glowAlpha, glowThickness = getNeonColors()
	for i, bar in ipairs(armBars) do
		bar.Size = UDim2.new(0, crosshairThickness, 0, crosshairLength)
		bar.Position = UDim2.new(0.5, 0, 0, -crosshairGap)
		local stroke = armStrokes[i]
		local grad = armGradients[i]
		if crosshairGradientEnabled then
			if grad then grad.Enabled = true end
			bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			if stroke then
				stroke.Color = Color3.fromRGB(255, 255, 255)
				stroke.Transparency = 0.55
				stroke.Thickness = 1
			end
		else
			if grad then grad.Enabled = false end
			bar.BackgroundColor3 = coreColor
			if stroke then
				stroke.Color = glowColor
				stroke.Transparency = glowAlpha
				stroke.Thickness = glowThickness
			end
		end
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
	if highlights[targetPlr] then
		pcall(function() highlights[targetPlr]:Destroy() end)
		highlights[targetPlr] = nil
	end
	if nameLabels[targetPlr] then
		pcall(function()
			nameLabels[targetPlr].Visible = false
			nameLabels[targetPlr]:Destroy()
		end)
		nameLabels[targetPlr] = nil
	end
	if tracerLines[targetPlr] then
		pcall(function()
			tracerLines[targetPlr].Visible = false
			tracerLines[targetPlr]:Destroy()
		end)
		tracerLines[targetPlr] = nil
	end
end

local function hookPlayerCleanup(targetPlr)
	local function onChar(char)
		removePlayerVisuals(targetPlr)
		local hum = char:WaitForChild("Humanoid", 4)
		if hum then
			hum.Died:Connect(function()
				removePlayerVisuals(targetPlr)
			end)
		end
	end
	if targetPlr.Character then
		onChar(targetPlr.Character)
	end
	targetPlr.CharacterAdded:Connect(onChar)
	targetPlr.CharacterRemoving:Connect(function()
		removePlayerVisuals(targetPlr)
	end)
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
	if not char or not char:IsDescendantOf(Workspace) then
		removePlayerVisuals(targetPlr)
		return
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	local head = char:FindFirstChild("Head")

	if not root or not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead or not root:IsDescendantOf(Workspace) then
		removePlayerVisuals(targetPlr)
		return
	end

	if char:GetAttribute("Dead") == true or char:GetAttribute("KO") == true then
		removePlayerVisuals(targetPlr)
		return
	end

	local hl = highlights[targetPlr]
	if not hl or hl.Adornee ~= char or hl.Parent ~= espDrawingGui then
		if hl then pcall(function() hl:Destroy() end) end
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

	local posForTag = head and (head.Position + Vector3.new(0, 1.4, 0)) or (root.Position + Vector3.new(0, 2.4, 0))
	local screenPos, onScreen = camera:WorldToViewportPoint(posForTag)

	if showName and onScreen and screenPos.Z > 0 then
		local lbl = nameLabels[targetPlr]
		if not lbl or lbl.Parent ~= espDrawingGui then
			if lbl then pcall(function() lbl:Destroy() end) end
			lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0, 180, 0, 22)
			lbl.AnchorPoint = Vector2.new(0.5, 1)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 13
			lbl.ZIndex = 50
			lbl.Parent = espDrawingGui
			nameLabels[targetPlr] = lbl
		end
		lbl.Visible = true
		lbl.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
		lbl.TextColor3 = color
		lbl.Text = string.format("%s [%s]", targetPlr.DisplayName, tagText)
	else
		if nameLabels[targetPlr] then
			nameLabels[targetPlr].Visible = false
		end
	end

	if showTracer and onScreen and screenPos.Z > 0 then
		local line = tracerLines[targetPlr]
		if not line or line.Parent ~= espDrawingGui then
			if line then pcall(function() line:Destroy() end) end
			line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.BorderSizePixel = 0
			line.ZIndex = 49
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
		line.BackgroundTransparency = 0.2
	else
		if tracerLines[targetPlr] then
			tracerLines[targetPlr].Visible = false
		end
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
-- Gelişmiş Balistik Tahmin & Silent Aim Motoru (Jumper & Zig-Zag Koruma)
-- ----------------------------------------------------
local function getPredictedPosition(targetPlayer, offset)
	local targetChar = targetPlayer and targetPlayer.Character
	if not targetChar then return nil end

	local torso = targetChar:FindFirstChild("UpperTorso")
		or targetChar:FindFirstChild("Torso")
		or targetChar:FindFirstChild("LowerTorso")
		or targetChar:FindFirstChild("HumanoidRootPart")
	local playerHum = targetChar:FindFirstChildOfClass("Humanoid")
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or torso
	if not torso or not playerHum then return nil end

	local myChar = player.Character
	local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Head"))
	local gunPos = myRoot and myRoot.Position or Vector3.zero

	local dist = (torso.Position - gunPos).Magnitude
	local bulletSpeed = 280

	-- Ping gecikmesini dinamik hesapla
	local ping = 0.05
	pcall(function()
		local stat = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
		if stat then
			ping = math.clamp(stat:GetValue() / 1000, 0.02, 0.20)
		end
	end)

	local travelTime = (dist / bulletSpeed) + ping

	local vel = (targetRoot and (targetRoot.AssemblyLinearVelocity or targetRoot.Velocity)) or Vector3.zero
	local horizontalVel = Vector3.new(vel.X, 0, vel.Z)

	-- 1. Yatay Tahmin: Hızlı koşan veya zig-zag çizen hedefin varış noktasını hesapla
	local predictedPos = torso.Position + (horizontalVel * travelTime)

	-- 2. Dikey Tahmin (Anti-Jumper): Zıplayan oyuncunun yerçekimi parabolünü simüle et
	local isAirborne = (playerHum.FloorMaterial == Enum.Material.Air)
		or (playerHum:GetState() == Enum.HumanoidStateType.Jumping)
		or (playerHum:GetState() == Enum.HumanoidStateType.Freefall)

	if isAirborne then
		local grav = Workspace.Gravity > 0 and Workspace.Gravity or 196.2
		local vertDisplacement = (vel.Y * travelTime) - (0.5 * grav * (travelTime ^ 2))
		local predictedY = torso.Position.Y + vertDisplacement
		local minFloorY = torso.Position.Y - 2.8
		if predictedY < minFloorY then
			predictedY = minFloorY
		end
		predictedPos = Vector3.new(predictedPos.X, predictedY, predictedPos.Z)
	else
		predictedPos = Vector3.new(predictedPos.X, torso.Position.Y, predictedPos.Z)
	end

	return predictedPos
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
	local mHum = murderer.Character:FindFirstChildOfClass("Humanoid")
	if not mHum or mHum.Health <= 0 then return end

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

		-- Gelişmiş Balistik Tahmin Konumu (Jumper ve zig-zag yapan katili kaçırmaz)
		local aimPos = getPredictedPosition(murderer, shootOffset)
		if not aimPos then
			local liveTorso = murderer.Character:FindFirstChild("UpperTorso") or murderer.Character:FindFirstChild("Torso") or murderer.Character:FindFirstChild("HumanoidRootPart")
			aimPos = liveTorso and liveTorso.Position or root.Position
		end
		currentAimTorsoPos = aimPos

		-- Anında katilin tahmini pozisyonuna gövde yönelimi yap
		pcall(function()
			root.CFrame = CFrame.new(root.Position, Vector3.new(aimPos.X, root.Position.Y, aimPos.Z))
			root.AssemblyAngularVelocity = Vector3.zero
		end)

		local shootRemote, remoteType = getShootRemote(gunTool)
		if shootRemote then
			if remoteType == "CreateBeam" then
				pcall(function()
					shootRemote:InvokeServer(1, aimPos, "AH2")
				end)
				-- Zig-zag yapan hedefler için anlık mikro-garanti vuruşu
				task.delay(0.04, function()
					pcall(function()
						local freshAim = getPredictedPosition(murderer, shootOffset) or aimPos
						shootRemote:InvokeServer(1, freshAim, "AH2")
					end)
				end)
			elseif remoteType == "ShootEvent" then
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

		currentAimTorsoPos = nil
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

-- ----------------------------------------------------
-- TSB Karakter ve Form Tespiti
-- ----------------------------------------------------
local function detectTSBCharacter(char)
	if not char then return "Unknown" end

	if char:FindFirstChild("Katana") or char:FindFirstChild("Sheath") or char:FindFirstChild("Saya") or char:FindFirstChild("AtomicBlade") then
		return "Atomic"
	end
	if char:FindFirstChild("Bat") or char:FindFirstChild("MetalBat") or char:FindFirstChild("FoulBat") then
		return "Bat"
	end
	if char:FindFirstChild("NinjaScarf") or char:FindFirstChild("NinjaBlade") or char:FindFirstChild("SonicScarf") then
		return "Sonic"
	end
	if char:FindFirstChild("CyborgArm") or char:FindFirstChild("Core") or char:FindFirstChild("GenosCore") then
		return "Genos"
	end
	if char:FindFirstChild("Bandages") or char:FindFirstChild("HunterHair") or char:FindFirstChild("HunterRobe") then
		return "Garou"
	end
	if char:FindFirstChild("Cape") or char:FindFirstChild("BaldHead") or char:FindFirstChild("HeroSuit") then
		return "Saitama"
	end

	local charName = char:GetAttribute("Character") or char:GetAttribute("Char") or char:GetAttribute("Class")
	if charName and type(charName) == "string" then
		local cLower = charName:lower()
		if cLower:find("hunter") or cLower:find("garou") then return "Garou" end
		if cLower:find("hero") or cLower:find("saitama") or cLower:find("bald") then return "Saitama" end
		if cLower:find("blade") or cLower:find("atomic") or cLower:find("samurai") then return "Atomic" end
		if cLower:find("bat") or cLower:find("brutal") or cLower:find("foul") then return "Bat" end
		if cLower:find("ninja") or cLower:find("sonic") then return "Sonic" end
		if cLower:find("cyborg") or cLower:find("genos") then return "Genos" end
		if cLower:find("void") or cLower:find("suiryu") or cLower:find("fist") then return "Suiryu" end
	end

	return "Unknown"
end

local function getCounterState(targetPlr)
	local char = targetPlr.Character
	if not char or not char:IsDescendantOf(Workspace) then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return nil end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then return nil end

	local charType = detectTSBCharacter(char)

	-- Ulti / Awakened Modu Kontrolü
	local isUltMode = false
	pcall(function()
		if char:GetAttribute("Awakened") == true or char:GetAttribute("Ultimate") == true or char:GetAttribute("Mode") == "Awakened" or char:FindFirstChild("Awakening") or char:FindFirstChild("UltimateAura") then
			isUltMode = true
		end
		if char:FindFirstChild("RedEyes") or char:FindFirstChild("AwakenedAura") or char:FindFirstChild("Aura") then
			isUltMode = true
		end
	end)

	local tracks = animator:GetPlayingAnimationTracks()
	for _, track in ipairs(tracks) do
		if track.IsPlaying then
			local anim = track.Animation
			local animId = anim and anim.AnimationId or ""
			local animIdClean = animId:match("%d+") or ""
			local trackName = track.Name:lower()

			-- 1. DEATH COUNTER (Saitama Ulti Counter)
			if animIdClean == "11343318134" or animIdClean == "13927612951" or trackName:find("deathcounter") or (trackName:find("death") and trackName:find("counter")) then
				return {
					isUlt = true,
					label = "Death Counter",
					color = Color3.fromRGB(255, 30, 30),
					characterName = "Death Counter"
				}
			end

			-- 2. GAROU (Flowing Water / Prey's Peril)
			if animIdClean == "12272894215" or animIdClean == "12351854556" or animIdClean == "12273188754" or animIdClean == "14374357351" or (trackName:find("flowing") and trackName:find("water")) or trackName:find("prey") then
				if isUltMode then
					return {
						isUlt = true,
						label = "Garou Ulti counter",
						color = Color3.fromRGB(180, 0, 255),
						characterName = "Garou"
					}
				else
					return {
						isUlt = false,
						label = "Garou counter",
						color = Color3.fromRGB(0, 160, 255),
						characterName = "Garou"
					}
				end
			end

			-- 3. ATOMIC SAMURAI (Pinpoint Cut / Split Second Counter)
			if trackName:find("pinpoint") or trackName:find("splitsecond") or trackName:find("split_second") or (charType == "Atomic" and trackName:find("counter")) or animIdClean == "12447707844" then
				if isUltMode then
					return {
						isUlt = true,
						label = "Atomic Ulti counter",
						color = Color3.fromRGB(255, 75, 0),
						characterName = "Atomic"
					}
				else
					return {
						isUlt = false,
						label = "Atomic counter",
						color = Color3.fromRGB(255, 170, 0),
						characterName = "Atomic"
					}
				end
			end

			-- 4. METAL BAT (Foul Counter / Grand Slam)
			if trackName:find("foul") or (charType == "Bat" and trackName:find("counter")) or (trackName:find("grand") and trackName:find("slam")) then
				if isUltMode then
					return {
						isUlt = true,
						label = "Bat Ulti counter",
						color = Color3.fromRGB(255, 0, 90),
						characterName = "Bat"
					}
				else
					return {
						isUlt = false,
						label = "Bat counter",
						color = Color3.fromRGB(220, 20, 60),
						characterName = "Bat"
					}
				end
			end

			-- 5. SONIC (Flash Counter)
			if (charType == "Sonic" and trackName:find("counter")) or trackName:find("flashcounter") then
				if isUltMode then
					return {
						isUlt = true,
						label = "Sonic Ulti counter",
						color = Color3.fromRGB(220, 80, 255),
						characterName = "Sonic"
					}
				else
					return {
						isUlt = false,
						label = "Sonic counter",
						color = Color3.fromRGB(150, 40, 255),
						characterName = "Sonic"
					}
				end
			end

			-- 6. GENEL / DİĞER (Diğer karakterlerin gerçek counter hareketleri)
			if trackName:find("counter") and not trackName:find("run") and not trackName:find("walk") and not trackName:find("idle") then
				local charLabel = (charType ~= "Unknown" and charType) or "Ulti"
				if isUltMode then
					return {
						isUlt = true,
						label = charLabel .. " Ulti counter",
						color = Color3.fromRGB(255, 50, 150),
						characterName = charLabel
					}
				else
					return {
						isUlt = false,
						label = charLabel .. " counter",
						color = Color3.fromRGB(0, 210, 255),
						characterName = charLabel
					}
				end
			end
		end
	end

	-- 7. Karakterde özel FlowingWater nesnesi varsa
	if char:FindFirstChild("FlowingWater") then
		if isUltMode then
			return {
				isUlt = true,
				label = "Garou Ulti counter",
				color = Color3.fromRGB(180, 0, 255),
				characterName = "Garou"
			}
		else
			return {
				isUlt = false,
				label = "Garou counter",
				color = Color3.fromRGB(0, 160, 255),
				characterName = "Garou"
			}
		end
	end

	return nil
end

local function updateAllESP()
	if not mm2EspEnabled and not normalEspEnabled and not tsbCounterEspEnabled then
		for p, _ in pairs(highlights) do removePlayerVisuals(p) end
		if gunHighlight then gunHighlight.Enabled = false end
		activeCounters = {}
		return
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local counterInfo = nil
			if tsbCounterEspEnabled then
				counterInfo = getCounterState(p)
			end

			if counterInfo then
				-- TSB Counter Aktif! Normal ESP'nin önüne geçer
				activeCounters[p] = counterInfo
				local espColor
				if counterInfo.isUlt then
					-- Rainbow (Chroma) Parlama
					local hue = (tick() * 1.5) % 1
					espColor = Color3.fromHSV(hue, 1, 1)
				else
					espColor = counterInfo.color or Color3.fromRGB(0, 160, 255)
				end
				createOrUpdateVisuals(p, espColor, counterInfo.label, false, true, 0.15)
			else
				-- Counter az önce aktifti ve şimdi bittiyse:
				if activeCounters[p] then
					activeCounters[p] = nil
					if tsbCounterNotifyEnded and showToast then
						local pName = p.DisplayName or p.Name
						showToast("TSB COUNTER", string.format("%s Counter ended", pName), 3.5)
					end
				end

				-- Normal ESP / MM2 ESP Mantığı
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
-- TSB Auto Block / Parry Motoru (Gelişmiş Animasyon & Yetenek Tespiti)
-- ----------------------------------------------------
;(function()
	local vimService = nil
	pcall(function() vimService = game:GetService("VirtualInputManager") end)

	local anims = {
		-- Saitama
		["rbxassetid://10469493270"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://10469630950"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://10469639222"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://10469643643"] = { [1] = 0, [2] = 0.30 },
		-- Hunter (Garou)
		["rbxassetid://13532562418"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://13532600125"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://13532604085"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://13294471966"] = { [1] = 0, [2] = 0.30 },
		-- Cyborg (Genos)
		["rbxassetid://13491635433"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://13296577783"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://13295919399"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://13295936866"] = { [1] = 0, [2] = 0.30 },
		-- Ninja (Sonic)
		["rbxassetid://13370310513"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://13390230973"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://13378751717"] = { [1] = 0, [2] = 0.30 },
		["rbxassetid://13378708199"] = { [1] = 0, [2] = 0.30 }
	}

	local dodges = {
		["rbxassetid://10479335397"] = { [1] = 0, [2] = 0.50 },
		["rbxassetid://13380255751"] = { [1] = 0, [2] = 0.50 }
	}

	local barrages = {
		["rbxassetid://10466974800"] = { [1] = 0.20, [2] = 1.80 },
		["rbxassetid://12534735382"] = { [1] = 0.20, [2] = 1.80 }
	}

	local abilities = {
		["rbxassetid://10468665991"] = { [1] = 0.15, [2] = 0.60 },
		["rbxassetid://13376869471"] = { [1] = 0.05, [2] = 1 },
		["rbxassetid://13376962659"] = { [1] = 0, [2] = 2 },
		["rbxassetid://12296882427"] = { [1] = 0.05, [2] = 1 },
		["rbxassetid://13309500827"] = { [1] = 0.05, [2] = 1 },
		["rbxassetid://13365849295"] = { [1] = 0, [2] = 1 },
		["rbxassetid://13377153603"] = { [1] = 0, [2] = 1 },
		["rbxassetid://12509505723"] = { [1] = 0.09, [2] = 2 }
	}

	local durations = {
		["anim"] = 0.3,
		["dodge"] = 0.9,
		["barrage"] = 0.9,
		["ability"] = 0.6
	}

	local cd = false

	local function def(action)
		if cd then return end
		cd = true
		if tsbSettings.Delay > 0 then
			task.wait(tsbSettings.Delay)
		end
		pcall(function()
			local myChar = player.Character
			if myChar then
				local comm = myChar:FindFirstChild("Communicate")
				if comm and comm:IsA("RemoteEvent") then
					comm:FireServer({["Goal"] = "KeyPress", ["Key"] = Enum.KeyCode.F})
				end
			end
		end)
		pcall(function()
			if vimService then
				vimService:SendKeyEvent(true, Enum.KeyCode.F, false, game)
			end
		end)
		task.wait(durations[action] or 0.3)
		pcall(function()
			local myChar = player.Character
			if myChar then
				local comm = myChar:FindFirstChild("Communicate")
				if comm and comm:IsA("RemoteEvent") then
					comm:FireServer({["Goal"] = "KeyRelease", ["Key"] = Enum.KeyCode.F})
				end
			end
		end)
		pcall(function()
			if vimService then
				vimService:SendKeyEvent(false, Enum.KeyCode.F, false, game)
			end
		end)
		cd = false
	end

	local function closest()
		local closestplr = {}
		local myChar = player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myRoot then return closestplr end

		for _, v in ipairs(Players:GetPlayers()) do
			if v ~= player and v.Character and v.Character ~= myChar then
				local eRoot = v.Character:FindFirstChild("HumanoidRootPart")
				if eRoot and (eRoot.Position - myRoot.Position).Magnitude < tsbSettings.Range then
					table.insert(closestplr, v)
				end
			end
		end
		return closestplr
	end

	local function attackchecker()
		local myChar = player.Character
		if not myChar then return false end
		local hum = myChar:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if not animator then return false end

		for _, Anim in ipairs(animator:GetPlayingAnimationTracks()) do
			local id = Anim.Animation and Anim.Animation.AnimationId
			if id and (anims[id] or dodges[id] or abilities[id] or barrages[id]) then
				return true
			end
		end
		return false
	end

	local function isfacing(enemyChar)
		if not tsbSettings.Facing then return true end
		local myChar = player.Character
		local myHead = myChar and myChar:FindFirstChild("Head")
		local eHead = enemyChar and enemyChar:FindFirstChild("Head")
		if not myHead or not eHead then return true end

		local plrDirection = myHead.CFrame.LookVector
		local unit = (eHead.CFrame.Position - myHead.CFrame.Position).Unit
		local value = math.pow((plrDirection - unit).Magnitude / 2, 2)
		if value >= tsbSettings.Fov / 360 then
			return false
		else
			return true
		end
	end

	local function allowed(enemyChar)
		local myChar = player.Character
		if not myChar then return false end
		if myChar:FindFirstChild("M1ing") then return false end
		if attackchecker() then return false end
		if not isfacing(enemyChar) then return false end
		return true
	end

	local function lookat(enemyChar)
		if not tsbSettings.Aimhelper then return end
		local myChar = player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local eRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
		if myRoot and eRoot then
			local targetPos = Vector3.new(eRoot.Position.X, myRoot.Position.Y, eRoot.Position.Z)
			myRoot.CFrame = CFrame.lookAt(myRoot.Position, targetPos)
			local cam = workspace.CurrentCamera
			if cam and isShiftLocked and isShiftLocked() then
				local camPos = cam.CFrame.Position
				local focusPos = eRoot.Position + Vector3.new(0, 1.5, 0)
				cam.CFrame = CFrame.lookAt(camPos, focusPos)
			end
		end
	end

	local function parry()
		if not autoBlockEnabled then return end
		local myChar = player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myRoot then return end

		for _, c in ipairs(closest()) do
			local eChar = c.Character
			local eHum = eChar and eChar:FindFirstChildOfClass("Humanoid")
			local animator = eHum and eHum:FindFirstChildOfClass("Animator")
			if animator and allowed(eChar) then
				for _, v in ipairs(animator:GetPlayingAnimationTracks()) do
					local animId = v.Animation and v.Animation.AnimationId
					if animId then
						local anim = anims[animId]
						local dodge = dodges[animId]
						local ability = abilities[animId]
						local barrage = barrages[animId]
						local pos = v.TimePosition

						if anim and pos >= anim[1] and pos <= anim[2] then
							task.spawn(function()
								lookat(eChar)
								def("anim")
							end)
							break
						elseif dodge and pos > dodge[1] and pos < dodge[2] then
							task.spawn(function()
								lookat(eChar)
								def("dodge")
							end)
							break
						elseif barrage and pos > barrage[1] and pos < barrage[2] then
							task.spawn(function()
								lookat(eChar)
								def("barrage")
							end)
							break
						elseif ability and pos > ability[1] and pos < ability[2] then
							task.spawn(function()
								lookat(eChar)
								def("ability")
							end)
							break
						end
					end
				end
			end
		end
	end

	RunService.RenderStepped:Connect(function()
		if autoBlockEnabled then
			parry()
		end
	end)
end)()

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

-- Sekme Değiştirici Konteyner (Tab Selector - 3 Sekme: MAIN, MM2, TSB)
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
tabIndicator.Size = UDim2.new(1/3, -4, 1, -4)
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

-- Sekme Düğmeleri (MAIN, MM2, TSB)
local mainTabBtn = Instance.new("TextButton")
mainTabBtn.Text = "MAIN"
mainTabBtn.Font = Enum.Font.GothamBold
mainTabBtn.TextSize = 10
mainTabBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
mainTabBtn.Size = UDim2.new(1/3, 0, 1, 0)
mainTabBtn.Position = UDim2.new(0, 0, 0, 0)
mainTabBtn.BackgroundTransparency = 1
mainTabBtn.ZIndex = 8
mainTabBtn.Parent = tabNavContainer

local mm2TabBtn = Instance.new("TextButton")
mm2TabBtn.Text = "MM2"
mm2TabBtn.Font = Enum.Font.GothamBold
mm2TabBtn.TextSize = 10
mm2TabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
mm2TabBtn.Size = UDim2.new(1/3, 0, 1, 0)
mm2TabBtn.Position = UDim2.new(1/3, 0, 0, 0)
mm2TabBtn.BackgroundTransparency = 1
mm2TabBtn.ZIndex = 8
mm2TabBtn.Parent = tabNavContainer

local tsbTabBtn = Instance.new("TextButton")
tsbTabBtn.Text = "TSB"
tsbTabBtn.Font = Enum.Font.GothamBold
tsbTabBtn.TextSize = 10
tsbTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
tsbTabBtn.Size = UDim2.new(1/3, 0, 1, 0)
tsbTabBtn.Position = UDim2.new(2/3, 0, 0, 0)
tsbTabBtn.BackgroundTransparency = 1
tsbTabBtn.ZIndex = 8
tsbTabBtn.Parent = tabNavContainer

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


mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	mainContent.CanvasSize = UDim2.new(0, 0, 0, mainLayout.AbsoluteContentSize.Y + 20)
end)

mm2Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	mm2Content.CanvasSize = UDim2.new(0, 0, 0, mm2Layout.AbsoluteContentSize.Y + 20)
end)

tsbLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	tsbContent.CanvasSize = UDim2.new(0, 0, 0, tsbLayout.AbsoluteContentSize.Y + 20)
end)


-- Sekme Değiştirme Animasyonu (Quart Interpolation)
currentTab = "MAIN"
mainTabBtn.MouseButton1Click:Connect(function()
	if currentTab == "MAIN" then return end
	currentTab = "MAIN"
	mainContent.Visible = true
	mm2Content.Visible = false
	tsbContent.Visible = false
	TweenService:Create(tabIndicator, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 2, 0, 2)
	}):Play()
	mainTabBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
	mm2TabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	tsbTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
end)

mm2TabBtn.MouseButton1Click:Connect(function()
	if currentTab == "MM2" then return end
	currentTab = "MM2"
	mainContent.Visible = false
	mm2Content.Visible = true
	tsbContent.Visible = false
	TweenService:Create(tabIndicator, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(1/3, 2, 0, 2)
	}):Play()
	mm2TabBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
	mainTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	tsbTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
end)

tsbTabBtn.MouseButton1Click:Connect(function()
	if currentTab == "TSB" then return end
	currentTab = "TSB"
	mainContent.Visible = false
	mm2Content.Visible = false
	tsbContent.Visible = true
	TweenService:Create(tabIndicator, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(2/3, 2, 0, 2)
	}):Play()
	tsbTabBtn.TextColor3 = Color3.fromRGB(250, 250, 250)
	mainTabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	mm2TabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
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
	local r6Card, r6ToggleBtn, setR6Visual = createModuleCard(mainContent, "R15 to R6 (Resetli)")
	r6ToggleBtn.MouseButton1Click:Connect(function()
		convertR15ToR6WithReset()
		sendNotification("R6 Dönüştürücü", "Karakter resetlendi, R6 olarak yükleniyor...", 3)
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
	local chPanel = createSettingsPanel(mainContent, 260)
	local gradBtnStroke = nil

	addColorPaletteRow(chPanel, "Nişangah Rengi", baseColor, function(newCol)
		baseColor = newCol
		crosshairGradientEnabled = false
		if gradBtnStroke then
			gradBtnStroke.Color = Color3.fromRGB(50, 50, 50)
		end
		updateCrosshairAppearance()
	end)

	-- Gradient Renk Modu: background: linear-gradient(to right, #000000, #ffffff);
	local gradRow = Instance.new("Frame")
	gradRow.Size = UDim2.new(1, 0, 0, 36)
	gradRow.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
	gradRow.BorderSizePixel = 0
	gradRow.ZIndex = 5
	gradRow.Parent = chPanel

	local grCorner = Instance.new("UICorner") grCorner.CornerRadius = UDim.new(0, 4) grCorner.Parent = gradRow
	local grStroke = Instance.new("UIStroke") grStroke.Color = Color3.fromRGB(24, 24, 24) grStroke.Thickness = 1 grStroke.Parent = gradRow

	local grLabel = Instance.new("TextLabel")
	grLabel.Text = "Gradient (Siyah -> Beyaz)"
	grLabel.Size = UDim2.new(0, 160, 1, 0)
	grLabel.Position = UDim2.new(0, 10, 0, 0)
	grLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
	grLabel.Font = Enum.Font.Gotham
	grLabel.TextSize = 12
	grLabel.BackgroundTransparency = 1
	grLabel.TextXAlignment = Enum.TextXAlignment.Left
	grLabel.ZIndex = 6
	grLabel.Parent = gradRow

	local gradBtn = Instance.new("TextButton")
	gradBtn.Text = ""
	gradBtn.Size = UDim2.new(0, 48, 0, 20)
	gradBtn.Position = UDim2.new(1, -58, 0.5, -10)
	gradBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	gradBtn.BorderSizePixel = 0
	gradBtn.ZIndex = 6
	gradBtn.Parent = gradRow

	local gbCorner = Instance.new("UICorner") gbCorner.CornerRadius = UDim.new(0, 4) gbCorner.Parent = gradBtn
	local gbGrad = Instance.new("UIGradient")
	gbGrad.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255))
	gbGrad.Rotation = 0
	gbGrad.Parent = gradBtn

	gradBtnStroke = Instance.new("UIStroke")
	gradBtnStroke.Color = crosshairGradientEnabled and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(50, 50, 50)
	gradBtnStroke.Thickness = 1.5
	gradBtnStroke.Parent = gradBtn

	gradBtn.MouseButton1Click:Connect(function()
		crosshairGradientEnabled = not crosshairGradientEnabled
		gradBtnStroke.Color = crosshairGradientEnabled and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(50, 50, 50)
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

		if crosshairEnabled then
			if crosshairContainer then
				crosshairContainer.Visible = true
				if isShiftLocked() then
					crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
					hideNativeShiftLockCursor()
				else
					local mousePos = UserInputService:GetMouseLocation()
					if mousePos and mousePos.X > 0 and mousePos.Y > 0 then
						crosshairContainer.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
					else
						crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
					end
				end
			end
			if not isOpen then
				UserInputService.MouseIconEnabled = false
			end
		else
			if crosshairContainer then
				crosshairContainer.Visible = false
				if crosshairRotator then
					crosshairRotator.Rotation = 0
				end
			end
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
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and not spinBotEnabled then
			hum.AutoRotate = true
		end
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
-- MAIN SEKTMESI MODULLERI - BOLUM 5 (FULLBRIGHT & FLY GUI)
-- =========================================================================
;(function() -- Main Tab Scope 5 (Luau 200 Register Limit Protection)

	local Lighting = game:GetService("Lighting")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")

	-- =====================================================================
	-- 13. FULLBRIGHT (AYDINLATMA - SOFT & DENGELI)
	-- =====================================================================
	local fullBrightEnabled = false
	local fbConnection = nil
	local origLighting = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		GlobalShadows = Lighting.GlobalShadows,
		ClockTime = Lighting.ClockTime,
		FogEnd = Lighting.FogEnd
	}

	local function applyFullBright()
		Lighting.Ambient = Color3.fromRGB(135, 135, 135)
		Lighting.OutdoorAmbient = Color3.fromRGB(135, 135, 135)
		Lighting.Brightness = 2.0
		Lighting.GlobalShadows = false
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
	end

	local function restoreLighting()
		Lighting.Ambient = origLighting.Ambient
		Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
		Lighting.Brightness = origLighting.Brightness
		Lighting.GlobalShadows = origLighting.GlobalShadows
		Lighting.ClockTime = origLighting.ClockTime
		Lighting.FogEnd = origLighting.FogEnd
	end

	local function toggleFullBright(state)
		fullBrightEnabled = state
		if fullBrightEnabled then
			origLighting.Ambient = Lighting.Ambient
			origLighting.OutdoorAmbient = Lighting.OutdoorAmbient
			origLighting.Brightness = Lighting.Brightness
			origLighting.GlobalShadows = Lighting.GlobalShadows
			origLighting.ClockTime = Lighting.ClockTime
			origLighting.FogEnd = Lighting.FogEnd

			applyFullBright()
			if fbConnection then fbConnection:Disconnect() end
			fbConnection = Lighting.Changed:Connect(function(prop)
				if fullBrightEnabled and (prop == "Ambient" or prop == "OutdoorAmbient" or prop == "Brightness" or prop == "GlobalShadows" or prop == "ClockTime" or prop == "FogEnd") then
					applyFullBright()
				end
			end)
			if showToast then showToast("AYDINLATMA", "FullBright aktif edildi.", 2) end
		else
			if fbConnection then
				fbConnection:Disconnect()
				fbConnection = nil
			end
			restoreLighting()
			if showToast then showToast("AYDINLATMA", "FullBright kapatıldı.", 2) end
		end
	end

	local fbCard, fbToggleBtn, setFbVisual = createModuleCard(mainContent, "FullBright (Aydınlatma)")
	fbToggleBtn.MouseButton1Click:Connect(function()
		toggleFullBright(not fullBrightEnabled)
		setFbVisual(fullBrightEnabled)
	end)

	-- =====================================================================
	-- 14. FLY GUI (V4/V3 MOTORU - SIYAH / BEYAZ OBSIDIAN TEMA)
	-- =====================================================================
	local flyGuiActive = false
	local flyGuiScreen = nil
	local flyEnabled = false
	local flying = false
	local flySpeed = 50
	local speeds = 1
	local currentKeybind = Enum.KeyCode.F
	local settingKeybind = false
	local keybindDisabled = false
	local keybindHidden = false
	local rotationSpeed = 1
	local originalCollisionStates = {}
	local nowe = false
	local tpwalking = false
	local verticalDir = 0
	local lastLookDirection = Vector3.new(0, 0, -1)

	local bodyVelocity, bodyGyro, flyConnection, stateChangedConnection, animationConnection, noclipConnection, keybindConnection
	local setFlyVisualRef = nil

	local function getCharacter()
		return player.Character or (player.CharacterAdded and player.CharacterAdded:Wait())
	end

	local function getRootPart()
		local char = getCharacter()
		return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
	end

	local function waitForControlModule()
		local success, controlModule = pcall(function()
			return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
		end)
		if success then return controlModule else return nil end
	end

	local function isMovementAnimation(animationId)
		if not animationId then return false end
		local movementAnimIds = {
			"180436334", "180436148", "125750702", "180435571", "180435792"
		}
		for _, id in ipairs(movementAnimIds) do
			if animationId:find(id) then return true end
		end
		return false
	end

	local function isCharacterAnchored()
		local char = getCharacter()
		local root = getRootPart()
		if not char or not root then return false end
		if root.Anchored then return true end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Sit then return true end
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") and part.Anchored then return true end
		end
		return false
	end

	local function storeOriginalCollisions()
		originalCollisionStates = {}
		local char = player.Character
		if char then
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
					originalCollisionStates[v] = v.CanCollide
				end
			end
		end
	end

	local function enableNoclip()
		if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
		local env = (getgenv and getgenv()) or _G
		if env.noclipfly == false then return end
		storeOriginalCollisions()
		noclipConnection = RunService.Stepped:Connect(function()
			if not flyEnabled or not flying then return end
			local char = player.Character
			if char then
				for _, v in ipairs(char:GetDescendants()) do
					if v:IsA("BasePart") and v.CanCollide then
						v.CanCollide = false
					end
				end
			end
		end)
	end

	local function disableNoclip()
		if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
		local char = player.Character
		if char then
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
					if originalCollisionStates[v] ~= nil then
						v.CanCollide = originalCollisionStates[v]
					else
						if v.Name == "Head" or v.Name == "HumanoidRootPart" or v.Name == "Torso" or v.Name == "UpperTorso" or v.Name == "LowerTorso" then
							v.CanCollide = false
						else
							v.CanCollide = true
						end
					end
				end
			end
		end
		task.wait(0.05)
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end
		originalCollisionStates = {}
	end

	local function stopFly()
		flying = false
		nowe = false
		tpwalking = false
		verticalDir = 0
		if flyConnection then flyConnection:Disconnect() flyConnection = nil end
		if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
		if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
		if stateChangedConnection then stateChangedConnection:Disconnect() stateChangedConnection = nil end
		if animationConnection then animationConnection:Disconnect() animationConnection = nil end
		disableNoclip()
		local char = getCharacter()
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		local root = getRootPart()
		if humanoid and root then
			root.AssemblyAngularVelocity = Vector3.zero
			root.AssemblyLinearVelocity = Vector3.zero
			humanoid.PlatformStand = false
			for _, state in ipairs({
				Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Flying,
				Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
				Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Physics, Enum.HumanoidStateType.PlatformStanding,
				Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics,
				Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.StrafingNoPhysics, Enum.HumanoidStateType.Swimming
			}) do
				humanoid:SetStateEnabled(state, true)
			end
			task.wait(0.05)
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
			if char:FindFirstChild("Animate") then
				char.Animate.Disabled = false
			end
		end
	end

	local function startFlyV4()
		local char = getCharacter()
		local root = getRootPart()
		if not char or not root or not flyEnabled then return end
		flying = true
		if bodyVelocity then bodyVelocity:Destroy() end
		if bodyGyro then bodyGyro:Destroy() end
		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.zero
		bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		bodyVelocity.Parent = root
		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		bodyGyro.P = 1e4
		bodyGyro.CFrame = root.CFrame
		bodyGyro.Parent = root

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
				if track.Animation and track.Animation.AnimationId and isMovementAnimation(track.Animation.AnimationId) then
					track:Stop()
				end
			end
			task.wait(0.05)
			humanoid.PlatformStand = true
		end

		local controlModule = waitForControlModule()
		local camera = workspace.CurrentCamera
		lastLookDirection = camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)

		if flyConnection then flyConnection:Disconnect() end
		flyConnection = RunService.Heartbeat:Connect(function()
			if not flyEnabled or not flying or not root or not root.Parent then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and not hum.PlatformStand then
				hum.PlatformStand = true
			end

			local moveVec = Vector3.zero
			if controlModule then
				pcall(function() moveVec = controlModule:GetMoveVector() end)
			end
			if moveVec.Magnitude == 0 and hum and hum.MoveDirection.Magnitude > 0 and camera then
				moveVec = camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
			end

			local targetVelocity = Vector3.zero
			if moveVec.Magnitude > 0 and camera then
				local direction = camera.CFrame:VectorToWorldSpace(moveVec)
				targetVelocity = direction.Unit * flySpeed
			end

			if verticalDir ~= 0 then
				targetVelocity = targetVelocity + Vector3.new(0, verticalDir * flySpeed, 0)
			end

			if bodyVelocity then
				bodyVelocity.Velocity = bodyVelocity.Velocity:Lerp(targetVelocity, 0.25)
			end

			if flyEnabled and flying and bodyGyro and not isCharacterAnchored() and camera then
				local currentLookDirection = camera.CFrame.LookVector
				local env = (getgenv and getgenv()) or _G
				local rSpeed = tonumber(env.rotationSpeed) or rotationSpeed
				local smoothedLookDirection = lastLookDirection:Lerp(currentLookDirection, math.clamp(rSpeed * 0.05 + 0.02, 0.02, 1))
				lastLookDirection = smoothedLookDirection
				bodyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + smoothedLookDirection)
			end

			if targetVelocity.Magnitude == 0 and bodyVelocity then
				bodyVelocity.Velocity = Vector3.zero
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end)
		enableNoclip()
	end

	local function startFlyV3()
		if not flyEnabled then return end
		flying = true
		nowe = true
		local char = getCharacter()
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			for _, state in ipairs({
				Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Flying,
				Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
				Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Physics, Enum.HumanoidStateType.PlatformStanding,
				Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics,
				Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.StrafingNoPhysics, Enum.HumanoidStateType.Swimming
			}) do
				hum:SetStateEnabled(state, false)
			end
			hum:ChangeState(Enum.HumanoidStateType.Swimming)
			hum.PlatformStand = true
		end

		local root = getRootPart()
		if root then
			if bodyGyro then bodyGyro:Destroy() end
			if bodyVelocity then bodyVelocity:Destroy() end
			bodyGyro = Instance.new("BodyGyro", root)
			bodyGyro.P = 9e4
			bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
			bodyGyro.cframe = root.CFrame

			bodyVelocity = Instance.new("BodyVelocity", root)
			bodyVelocity.velocity = Vector3.new(0, 0.1, 0)
			bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)

			task.spawn(function()
				local ctrl = {f = 0, b = 0, l = 0, r = 0}
				local speed_v3 = 0
				local maxspeed = 50 * speeds
				local camera = workspace.CurrentCamera
				while nowe and root and root.Parent do
					RunService.Heartbeat:Wait()
					local moveVec = hum and hum.MoveDirection or Vector3.zero
					if moveVec.Magnitude > 0 and camera then
						speed_v3 = math.clamp(speed_v3 + 1, 0, maxspeed)
						bodyVelocity.velocity = moveVec * speed_v3 + Vector3.new(0, verticalDir * maxspeed, 0)
						bodyGyro.cframe = camera.CFrame
					else
						speed_v3 = 0
						bodyVelocity.velocity = Vector3.new(0, verticalDir * maxspeed, 0)
						if camera then bodyGyro.cframe = camera.CFrame end
					end
				end
				if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
				if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
				if hum then hum.PlatformStand = false end
			end)
		end
		enableNoclip()
	end

	local function startFly()
		local env = (getgenv and getgenv()) or _G
		if env.useV3Method then
			startFlyV3()
		else
			startFlyV4()
		end
	end

	local function closeFlyGui()
		flyGuiActive = false
		flyEnabled = false
		stopFly()
		if keybindConnection then
			keybindConnection:Disconnect()
			keybindConnection = nil
		end
		if flyGuiScreen and flyGuiScreen.Parent then
			flyGuiScreen:Destroy()
			flyGuiScreen = nil
		end
		if setFlyVisualRef then
			setFlyVisualRef(false)
		end
		if showToast then showToast("FLY GUI", "Fly GUI kapatıldı.", 2) end
	end

	local function openFlyGui()
		if flyGuiScreen and flyGuiScreen.Parent then
			flyGuiScreen.Enabled = true
			return
		end

		local env = (getgenv and getgenv()) or _G
		rotationSpeed = tonumber(env.rotationSpeed) or 1
		keybindHidden = (env.hideKeybind == true) or UserInputService.TouchEnabled
		keybindDisabled = keybindHidden

		local main = Instance.new("ScreenGui")
		main.Name = "FlyGuiV4_Dark"
		main.ResetOnSpawn = false
		main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local targetParent = (gethui and gethui()) or (playerGui:FindFirstChild("RobloxGui") or playerGui)
		main.Parent = targetParent
		flyGuiScreen = main

		local Frame = Instance.new("Frame")
		Frame.Name = "FlyFrame"
		Frame.Parent = main
		Frame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
		Frame.BorderColor3 = Color3.fromRGB(36, 36, 36)
		Frame.BorderSizePixel = 1
		Frame.Position = UDim2.new(0.12, 0, 0.38, 0)
		Frame.Size = UDim2.new(0, 192, 0, keybindHidden and 58 or 88)
		Frame.Active = true
		Frame.Draggable = true

		local frameCorner = Instance.new("UICorner", Frame)
		frameCorner.CornerRadius = UDim.new(0, 8)
		local frameStroke = Instance.new("UIStroke", Frame)
		frameStroke.Color = Color3.fromRGB(42, 42, 42)
		frameStroke.Thickness = 1

		local function styleButton(btn, text, size, pos)
			btn.Parent = Frame
			btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			btn.BorderSizePixel = 0
			btn.Size = size
			btn.Position = pos
			btn.Font = Enum.Font.GothamBold
			btn.Text = text
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 13
			btn.AutoButtonColor = false

			local c = Instance.new("UICorner", btn)
			c.CornerRadius = UDim.new(0, 5)
			local s = Instance.new("UIStroke", btn)
			s.Color = Color3.fromRGB(40, 40, 40)
			s.Thickness = 1

			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(32, 32, 32)}):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(22, 22, 22)}):Play()
			end)
			return btn
		end

		local up = styleButton(Instance.new("TextButton"), "UP", UDim2.new(0, 44, 0, 26), UDim2.new(0, 4, 0, 4))
		local down = styleButton(Instance.new("TextButton"), "DOWN", UDim2.new(0, 44, 0, 26), UDim2.new(0, 4, 0, 32))
		local mine = styleButton(Instance.new("TextButton"), "-", UDim2.new(0, 44, 0, 26), UDim2.new(0, 50, 0, 32))
		local plus = styleButton(Instance.new("TextButton"), "+", UDim2.new(0, 44, 0, 26), UDim2.new(0, 50, 0, 4))

		local speed = Instance.new("TextLabel", Frame)
		speed.Name = "speed"
		speed.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
		speed.BorderSizePixel = 0
		speed.Position = UDim2.new(0, 96, 0, 32)
		speed.Size = UDim2.new(0, 44, 0, 26)
		speed.Font = Enum.Font.GothamBold
		speed.Text = tostring(env.useV3Method and speeds or flySpeed)
		speed.TextColor3 = Color3.fromRGB(255, 255, 255)
		speed.TextSize = 12
		local sc = Instance.new("UICorner", speed)
		sc.CornerRadius = UDim.new(0, 5)
		local ss = Instance.new("UIStroke", speed)
		ss.Color = Color3.fromRGB(36, 36, 36)

		local titleLabel = Instance.new("TextLabel", Frame)
		titleLabel.Name = "titleLabel"
		titleLabel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		titleLabel.BorderSizePixel = 0
		titleLabel.Position = UDim2.new(0, 96, 0, 4)
		titleLabel.Size = UDim2.new(0, 92, 0, 26)
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.Text = "FLY GUI"
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextSize = 12
		local tc = Instance.new("UICorner", titleLabel)
		tc.CornerRadius = UDim.new(0, 5)
		local ts = Instance.new("UIStroke", titleLabel)
		ts.Color = Color3.fromRGB(36, 36, 36)

		local onof = styleButton(Instance.new("TextButton"), "fly", UDim2.new(0, 46, 0, 26), UDim2.new(0, 142, 0, 32))

		local keybindLabel = Instance.new("TextLabel", Frame)
		keybindLabel.Name = "keybindLabel"
		keybindLabel.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
		keybindLabel.BorderSizePixel = 0
		keybindLabel.Position = UDim2.new(0, 4, 0, 60)
		keybindLabel.Size = UDim2.new(0, 44, 0, 24)
		keybindLabel.Font = Enum.Font.GothamBold
		keybindLabel.Text = tostring(currentKeybind):gsub("Enum.KeyCode.", "")
		keybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		keybindLabel.TextSize = 12
		local klc = Instance.new("UICorner", keybindLabel)
		klc.CornerRadius = UDim.new(0, 5)
		local kls = Instance.new("UIStroke", keybindLabel)
		kls.Color = Color3.fromRGB(36, 36, 36)

		local keybindBtn = styleButton(Instance.new("TextButton"), "Set Keybind", UDim2.new(0, 88, 0, 24), UDim2.new(0, 50, 0, 60))
		local resetKeybindBtn = styleButton(Instance.new("TextButton"), "Reset", UDim2.new(0, 48, 0, 24), UDim2.new(0, 140, 0, 60))

		local closebutton = Instance.new("TextButton", Frame)
		closebutton.Name = "Close"
		closebutton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		closebutton.BorderSizePixel = 0
		closebutton.Size = UDim2.new(0, 26, 0, 22)
		closebutton.Position = UDim2.new(0, 0, 0, -24)
		closebutton.Font = Enum.Font.GothamBold
		closebutton.Text = "X"
		closebutton.TextColor3 = Color3.fromRGB(255, 255, 255)
		closebutton.TextSize = 13
		local cbc = Instance.new("UICorner", closebutton)
		cbc.CornerRadius = UDim.new(0, 5)
		local cbs = Instance.new("UIStroke", closebutton)
		cbs.Color = Color3.fromRGB(40, 40, 40)

		local mini = Instance.new("TextButton", Frame)
		mini.Name = "mini"
		mini.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		mini.BorderSizePixel = 0
		mini.Size = UDim2.new(0, 26, 0, 22)
		mini.Position = UDim2.new(0, 28, 0, -24)
		mini.Font = Enum.Font.GothamBold
		mini.Text = "-"
		mini.TextColor3 = Color3.fromRGB(255, 255, 255)
		mini.TextSize = 16
		local mc = Instance.new("UICorner", mini)
		mc.CornerRadius = UDim.new(0, 5)
		local ms = Instance.new("UIStroke", mini)
		ms.Color = Color3.fromRGB(40, 40, 40)

		local mini2 = Instance.new("TextButton", Frame)
		mini2.Name = "mini2"
		mini2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		mini2.BorderSizePixel = 0
		mini2.Size = UDim2.new(0, 26, 0, 22)
		mini2.Position = UDim2.new(0, 28, 0, -24)
		mini2.Font = Enum.Font.GothamBold
		mini2.Text = "+"
		mini2.TextColor3 = Color3.fromRGB(255, 255, 255)
		mini2.TextSize = 16
		mini2.Visible = false
		local m2c = Instance.new("UICorner", mini2)
		m2c.CornerRadius = UDim.new(0, 5)
		local m2s = Instance.new("UIStroke", mini2)
		m2s.Color = Color3.fromRGB(40, 40, 40)

		if keybindHidden then
			keybindLabel.Visible = false
			keybindBtn.Visible = false
			resetKeybindBtn.Visible = false
		end

		local function toggleFlightState()
			flyEnabled = not flyEnabled
			if flyEnabled then
				onof.Text = "off"
				onof.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				startFly()
			else
				onof.Text = "fly"
				onof.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
				stopFly()
			end
		end

		onof.MouseButton1Click:Connect(toggleFlightState)

		plus.MouseButton1Click:Connect(function()
			local e = (getgenv and getgenv()) or _G
			if e.useV3Method then
				speeds = speeds + 1
				speed.Text = tostring(speeds)
			else
				flySpeed = math.clamp(flySpeed + 50, 50, 1000)
				speed.Text = tostring(flySpeed)
			end
		end)

		mine.MouseButton1Click:Connect(function()
			local e = (getgenv and getgenv()) or _G
			if e.useV3Method then
				speeds = math.max(1, speeds - 1)
				speed.Text = tostring(speeds)
			else
				flySpeed = math.max(50, flySpeed - 50)
				speed.Text = tostring(flySpeed)
			end
		end)

		local function bindHold(btn, dir)
			btn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					verticalDir = dir
				end
			end)
			btn.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if verticalDir == dir then verticalDir = 0 end
				end
			end)
		end
		bindHold(up, 1)
		bindHold(down, -1)

		keybindBtn.MouseButton1Click:Connect(function()
			if keybindDisabled then return end
			if not settingKeybind then
				settingKeybind = true
				keybindBtn.Text = "Press key..."
			else
				settingKeybind = false
				keybindBtn.Text = "Set Keybind"
			end
		end)

		resetKeybindBtn.MouseButton1Click:Connect(function()
			if keybindDisabled then return end
			currentKeybind = Enum.KeyCode.F
			keybindLabel.Text = "F"
			settingKeybind = false
			keybindBtn.Text = "Set Keybind"
		end)

		if keybindConnection then keybindConnection:Disconnect() end
		keybindConnection = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe or keybindDisabled then return end
			if settingKeybind then
				if input.KeyCode ~= Enum.KeyCode.Unknown then
					currentKeybind = input.KeyCode
					keybindLabel.Text = tostring(currentKeybind):gsub("Enum.KeyCode.", "")
					settingKeybind = false
					keybindBtn.Text = "Set Keybind"
				end
			else
				if input.KeyCode == currentKeybind then
					toggleFlightState()
				end
			end
		end)

		mini.MouseButton1Click:Connect(function()
			for _, child in ipairs(Frame:GetChildren()) do
				if child:IsA("GuiObject") and child ~= closebutton and child ~= mini and child ~= mini2 then
					child.Visible = false
				end
			end
			mini.Visible = false
			mini2.Visible = true
			Frame.BackgroundTransparency = 1
			frameStroke.Transparency = 1
			closebutton.Position = UDim2.new(0, 0, 0, 0)
			mini2.Position = UDim2.new(0, 28, 0, 0)
		end)

		mini2.MouseButton1Click:Connect(function()
			for _, child in ipairs(Frame:GetChildren()) do
				if child:IsA("GuiObject") and child ~= mini2 and child ~= closebutton then
					if not keybindHidden or (child ~= keybindLabel and child ~= keybindBtn and child ~= resetKeybindBtn) then
						child.Visible = true
					end
				end
			end
			mini.Visible = true
			mini2.Visible = false
			Frame.BackgroundTransparency = 0
			frameStroke.Transparency = 0
			closebutton.Position = UDim2.new(0, 0, 0, -24)
			mini.Position = UDim2.new(0, 28, 0, -24)
		end)

		closebutton.MouseButton1Click:Connect(function()
			closeFlyGui()
		end)
	end

	local function toggleFlyGui(state)
		flyGuiActive = state
		if flyGuiActive then
			openFlyGui()
			if showToast then showToast("FLY GUI", "Fly GUI açıldı.", 2) end
		else
			closeFlyGui()
		end
	end

	local flyCard, flyToggleBtn, setFlyVisual = createModuleCard(mainContent, "Fly GUI")
	setFlyVisualRef = setFlyVisual
	flyToggleBtn.MouseButton1Click:Connect(function()
		toggleFlyGui(not flyGuiActive)
		setFlyVisual(flyGuiActive)
	end)

end)() -- End Main Tab Scope 5


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
	local abPanel = createSettingsPanel(tsbContent, 210)

	addStepperRow(abPanel, "Algılama Menzili (Studs)", tsbSettings.Range, 5, 5, 60, function(newVal)
		tsbSettings.Range = newVal
	end)

	addStepperRow(abPanel, "Blok Gecikmesi (ms)", math.floor(tsbSettings.Delay * 1000), 25, 0, 500, function(newVal)
		tsbSettings.Delay = newVal / 1000
	end)

	addStepperRow(abPanel, "Görüş Açısı (FOV)", tsbSettings.Fov, 15, 30, 360, function(newVal)
		tsbSettings.Fov = newVal
	end)

	addSubToggle(abPanel, "Sadece Karşımdakileri Koru (Facing)", tsbSettings.Facing, function(s)
		tsbSettings.Facing = s
	end)

	addSubToggle(abPanel, "Saldırana Dön (Aim Helper)", tsbSettings.Aimhelper, function(s)
		tsbSettings.Aimhelper = s
	end)

	abGear.MouseButton1Click:Connect(function()
		abPanel.Visible = not abPanel.Visible
	end)

	abToggleBtn.MouseButton1Click:Connect(function()
		autoBlockEnabled = not autoBlockEnabled
		setAbVisual(autoBlockEnabled)
	end)


	-- 2. Counter ESP (TSB)
	local cEspCard, cEspToggleBtn, setCEspVisual = createModuleCard(tsbContent, "Counter ESP (TSB)")
	local cEspGear = createGearButton(cEspCard)
	local cEspPanel = createSettingsPanel(tsbContent, 50)

	addSubToggle(cEspPanel, "Death Counter Bildirimi", tsbCounterNotifyEnded, function(s)
		tsbCounterNotifyEnded = s
	end)

	cEspGear.MouseButton1Click:Connect(function()
		cEspPanel.Visible = not cEspPanel.Visible
	end)

	cEspToggleBtn.MouseButton1Click:Connect(function()
		tsbCounterEspEnabled = not tsbCounterEspEnabled
		setCEspVisual(tsbCounterEspEnabled)
		if not tsbCounterEspEnabled then
			for p, _ in pairs(activeCounters) do
				activeCounters[p] = nil
				if not normalEspEnabled and not mm2EspEnabled then
					removePlayerVisuals(p)
				end
			end
		end
	end)
end)() -- End TSB Tab Scope


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
		local duration = displayDuration or 3.5

		local toast = Instance.new("Frame")
		toast.Size = UDim2.new(1, 0, 0, 44)
		toast.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		toast.BorderSizePixel = 0
		toast.ClipsDescendants = true
		toast.ZIndex = 16
		toast.Parent = toastContainer

		local tCorner = Instance.new("UICorner")
		tCorner.CornerRadius = UDim.new(0, 7)
		tCorner.Parent = toast

		local tStroke = Instance.new("UIStroke")
		tStroke.Color = Color3.fromRGB(36, 36, 36)
		tStroke.Thickness = 1.2
		tStroke.Parent = toast

		local tTitle = Instance.new("TextLabel")
		tTitle.Text = notifyTitle
		tTitle.Font = Enum.Font.GothamBold
		tTitle.TextSize = 12
		tTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
		tTitle.Size = UDim2.new(1, -20, 0, 16)
		tTitle.Position = UDim2.new(0, 14, 0, 6)
		tTitle.TextXAlignment = Enum.TextXAlignment.Left
		tTitle.BackgroundTransparency = 1
		tTitle.ZIndex = 17
		tTitle.Parent = toast

		local tDesc = Instance.new("TextLabel")
		tDesc.Text = notifyDesc
		tDesc.Font = Enum.Font.Gotham
		tDesc.TextSize = 10
		tDesc.TextColor3 = Color3.fromRGB(160, 160, 160)
		tDesc.Size = UDim2.new(1, -20, 0, 14)
		tDesc.Position = UDim2.new(0, 14, 0, 24)
		tDesc.TextXAlignment = Enum.TextXAlignment.Left
		tDesc.BackgroundTransparency = 1
		tDesc.ZIndex = 17
		tDesc.Parent = toast

		-- Alt kısımdaki beyaz çizgi (En altta yer alır, sağdan sola doğru kısalır)
		local progressBar = Instance.new("Frame")
		progressBar.Name = "ProgressBar"
		progressBar.Size = UDim2.new(1, 0, 0, 2)
		progressBar.Position = UDim2.new(0, 0, 1, -2)
		progressBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		progressBar.BorderSizePixel = 0
		progressBar.ZIndex = 18
		progressBar.Parent = toast

		-- Giriş Animasyonu (Sağdan içeri kayarak girer ve belirir)
		toast.Position = UDim2.new(1, 40, 0, 0)
		toast.BackgroundTransparency = 0.5
		TweenService:Create(toast, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 0
		}):Play()

		-- Beyaz çizginin sağdan sola doğru kısalma animasyonu
		TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 0, 2)
		}):Play()

		-- Süre bittiğinde sağa doğru kayarak kaybolur
		task.delay(duration, function()
			if toast and toast.Parent then
				local slideOut = TweenService:Create(toast, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					Position = UDim2.new(1, 60, 0, 0),
					BackgroundTransparency = 1
				})
				slideOut:Play()
				slideOut.Completed:Connect(function()
					toast:Destroy()
				end)
			end
		end)
	end

	showToast = showToastNotification
	showToastNotification("ZWYY SYSTEM", "Obsidian arayüz başarıyla yüklendi.", 3)

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
			else
				UserInputService.MouseIconEnabled = true
			end
		end)
		task.delay(0.3, function()
			if isTweening and isOpen then
				mainFrame.Visible = false
				isOpen = false
				isTweening = false
				if crosshairEnabled then
				UserInputService.MouseIconEnabled = false
			else
				UserInputService.MouseIconEnabled = true
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
			isOpen = true
			isTweening = false
		end)
		task.delay(0.4, function()
			if isTweening and not isOpen then
				mainContent.Visible = (currentTab == "MAIN")
				mm2Content.Visible = (currentTab == "MM2")
				tsbContent.Visible = (currentTab == "TSB")
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
	if UserInputService:GetFocusedTextBox() then return end

	if input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.RightShift then
		toggleGUI()
		return
	end
end)

-- ----------------------------------------------------
-- Döngüler
-- ----------------------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
	if crosshairEnabled and crosshairContainer then
		crosshairContainer.Visible = true
		local shiftLocked = isShiftLocked()

		if shiftLocked then
			-- ShiftLock acikken: Crosshair ekranin tam ortasina (0.5, 0.5) yerlesip ShiftLock nisangahi olur
			crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
			hideNativeShiftLockCursor()
		else
			-- ShiftLock kapaliyken: Crosshair farenin ucunu takip eder
			local mousePos = UserInputService:GetMouseLocation()
			if mousePos and mousePos.X > 0 and mousePos.Y > 0 then
				crosshairContainer.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
			else
				crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
			end
		end

		-- Crosshair acikken menu kapaliysa fare ok imlecini gizle (boylece imlec yerine crosshair gorunur)
		if not isOpen and UserInputService.MouseIconEnabled then
			UserInputService.MouseIconEnabled = false
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

	if mm2EspEnabled or normalEspEnabled or tsbCounterEspEnabled then
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
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.AutoRotate then
				hum.AutoRotate = false
			end
			if root then
				if isShooting and currentAimTorsoPos then
					root.CFrame = CFrame.new(root.Position, Vector3.new(currentAimTorsoPos.X, root.Position.Y, currentAimTorsoPos.Z))
					root.AssemblyAngularVelocity = Vector3.zero
				elseif not isShooting then
					currentSpinAngle = (currentSpinAngle + (spinBotSpeed * 60 * deltaTime)) % 360
					local pos = root.Position
					root.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(currentSpinAngle), 0)
					root.AssemblyAngularVelocity = Vector3.zero
				end
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
