local ZolinApp = {};

function ZolinApp.Init()
-- ============================================================
-- Install "Play as AI" App for ZolinOS (Enhanced Version)
-- ============================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainUI = playerGui:WaitForChild("ZolinOS")
local replicatedWindow = mainUI:WaitForChild("ReplicatedWindow")

if not replicatedWindow:FindFirstChild("PlayAsAI") then
	-- ======== BUILD APP FRAME (unchanged) ========
	local app = Instance.new("Frame")
	app.Name = "PlayAsAI"
	app.AnchorPoint = Vector2.new(0.5, 0.5)
	app.BackgroundTransparency = 0
	app.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	app.Size = UDim2.new(1, 0, 1, 0)
	app.Position = UDim2.new(0.5, 0, 0.5, 0)
	app.ZIndex = 6
	app.Parent = replicatedWindow

	local dataFolder = Instance.new("Folder")
	dataFolder.Name = "Data"
	dataFolder.Parent = app

	local desc = Instance.new("StringValue", dataFolder)
	desc.Name = "Description"
	desc.Value = "Play as AI – intelligent bot controller"

	local ver = Instance.new("StringValue", dataFolder)
	ver.Name = "Version"
	ver.Value = "2.0"

	local ui = Instance.new("Frame")
	ui.Name = "UI"
	ui.AnchorPoint = Vector2.new(0.5, 0.5)
	ui.Position = UDim2.new(0.5, 0, 0.495, 0)
	ui.Size = UDim2.new(1, 0, 0.89, 0)
	ui.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
	ui.BackgroundTransparency = 0.65
	ui.ZIndex = app.ZIndex - 1
	ui.Parent = app

	local preview = Instance.new("Frame")
	preview.Name = "PreviewAppInfoZL"
	preview.AnchorPoint = Vector2.new(0.5, 0.5)
	preview.AutomaticSize = Enum.AutomaticSize.XY
	preview.BackgroundColor3 = Color3.fromRGB(59, 232, 189)
	preview.BackgroundTransparency = 0.35
	preview.Position = UDim2.new(0.082, 0, 0.031, 0)
	preview.Size = UDim2.new(0.165, 0, 0.061, 0)
	preview.ZIndex = 8
	preview.Visible = false
	preview.Parent = app

	local previewLabel = Instance.new("TextLabel")
	previewLabel.Name = "AppNameLabel"
	previewLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	previewLabel.Position = UDim2.new(0.409, 0, 0.5, 0)
	previewLabel.Size = UDim2.new(0, 150, 0, 25)
	previewLabel.BackgroundTransparency = 1
	previewLabel.TextScaled = true
	previewLabel.Font = Enum.Font.Oswald
	previewLabel.Text = "Play as AI"
	previewLabel.Parent = preview

	local previewIcon = Instance.new("ImageLabel")
	previewIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	previewIcon.AutomaticSize = Enum.AutomaticSize.XY
	previewIcon.BackgroundTransparency = 1
	previewIcon.Position = UDim2.new(0.9, 0, 0.5, 0)
	previewIcon.Size = UDim2.new(0, 39, 0, 39)
	previewIcon.Image = "rbxassetid://13458988525"
	previewIcon.ScaleType = Enum.ScaleType.Fit
	previewIcon.Parent = preview

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.08, 0)
	title.Position = UDim2.new(0, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "Play as AI"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = ui

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0.5, 0, 0.1, 0)
	toggleBtn.Position = UDim2.new(0.25, 0, 0.12, 0)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
	toggleBtn.Text = "Enable AI"
	toggleBtn.TextColor3 = Color3.new(0, 0, 0)
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 14
	toggleBtn.Parent = ui

	local settingsFrame = Instance.new("ScrollingFrame")
	settingsFrame.Size = UDim2.new(1, -10, 0.65, 0)
	settingsFrame.Position = UDim2.new(0, 5, 0.25, 0)
	settingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	settingsFrame.BackgroundTransparency = 0.5
	settingsFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
	settingsFrame.ScrollBarThickness = 5
	settingsFrame.Parent = ui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = settingsFrame

	local function addSettingRow(text, options)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 40)
		row.BackgroundTransparency = 1
		row.Parent = settingsFrame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.5, 0, 1, 0)
		label.Position = UDim2.new(0, 5, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.Gotham
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local cycleBtn = Instance.new("TextButton")
		cycleBtn.Size = UDim2.new(0.5, 0, 1, 0)
		cycleBtn.Position = UDim2.new(0.5, 0, 0, 0)
		cycleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		cycleBtn.Text = options[1]
		cycleBtn.TextColor3 = Color3.new(1, 1, 1)
		cycleBtn.Font = Enum.Font.Gotham
		cycleBtn.TextSize = 14
		cycleBtn.Parent = row

		local idx = 1
		cycleBtn.MouseButton1Click:Connect(function()
			idx = idx % #options + 1
			cycleBtn.Text = options[idx]
		end)
		return cycleBtn
	end

	local friendlyBtn = addSettingRow("Friendly:", {"All", "Friends Only", "None"})
	local wanderBtn = addSettingRow("Wander:", {"Off", "Sometimes", "Always"})
	local escapeBtn = addSettingRow("Escaping:", {"None", "Run from enemy", "When low health"})

	local controlsRow = Instance.new("Frame")
	controlsRow.Size = UDim2.new(1, -10, 0, 40)
	controlsRow.BackgroundTransparency = 1
	controlsRow.Parent = settingsFrame

	local controlsLabel = Instance.new("TextLabel")
	controlsLabel.Size = UDim2.new(0.5, 0, 1, 0)
	controlsLabel.Position = UDim2.new(0, 5, 0, 0)
	controlsLabel.BackgroundTransparency = 1
	controlsLabel.Text = "Player Controls:"
	controlsLabel.TextColor3 = Color3.new(1, 1, 1)
	controlsLabel.Font = Enum.Font.Gotham
	controlsLabel.TextSize = 14
	controlsLabel.TextXAlignment = Enum.TextXAlignment.Left
	controlsLabel.Parent = controlsRow

	local controlsDisabled = Instance.new("TextLabel")
	controlsDisabled.Size = UDim2.new(0.5, 0, 1, 0)
	controlsDisabled.Position = UDim2.new(0.5, 0, 0, 0)
	controlsDisabled.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	controlsDisabled.Text = "Disabled (AI Active)"
	controlsDisabled.TextColor3 = Color3.fromRGB(150, 150, 150)
	controlsDisabled.Font = Enum.Font.Gotham
	controlsDisabled.TextSize = 14
	controlsDisabled.Parent = controlsRow

	local diffBtn = addSettingRow("Difficulty:", {"Easy", "Normal", "Hard", "Insane"})

	-- ======== AI LOGIC (ENHANCED) ========
	local aiActive = false
	local aiConnection = nil
	local aiThread = nil

	local diffParams = {
		Easy   = {detectRange = 30, fightChance = 0.2, abilityChance = 0.1, runHealth = 0.3, fakeMoveChance = 0.1, spinChance = 0.1, behindChance = 0.1, jumpAttackChance = 0.1},
		Normal = {detectRange = 60, fightChance = 0.5, abilityChance = 0.3, runHealth = 0.4, fakeMoveChance = 0.3, spinChance = 0.3, behindChance = 0.3, jumpAttackChance = 0.3},
		Hard   = {detectRange = 100, fightChance = 0.8, abilityChance = 0.6, runHealth = 0.5, fakeMoveChance = 0.6, spinChance = 0.6, behindChance = 0.6, jumpAttackChance = 0.6},
		Insane = {detectRange = 200, fightChance = 1.0, abilityChance = 0.9, runHealth = 0.7, fakeMoveChance = 0.9, spinChance = 0.9, behindChance = 0.9, jumpAttackChance = 0.9},
	}

	local function getParams()
		return diffParams[diffBtn.Text] or diffParams.Normal
	end

	local function getCharacter()
		return player.Character or player.CharacterAdded:Wait()
	end

	local function isFriend(otherPlayer)
		return player.Team and otherPlayer.Team and player.Team == otherPlayer.Team
	end

	local function getNearestEnemy(character, friendlySetting)
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return nil, math.huge end
		local myPos = root.Position
		local nearest = nil
		local nearestDist = math.huge
		local params = getParams()

		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player then
				local otherChar = otherPlayer.Character
				if otherChar then
					local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
					local otherHum = otherChar:FindFirstChild("Humanoid")
					if otherRoot and otherHum and otherHum.Health > 0 then
						if friendlySetting == "Friends Only" and isFriend(otherPlayer) then
							continue
						elseif friendlySetting == "All" then
							continue
						end
						local dist = (otherRoot.Position - myPos).Magnitude
						if dist < params.detectRange and dist < nearestDist then
							nearestDist = dist
							nearest = otherRoot
						end
					end
				end
			end
		end
		return nearest, nearestDist
	end

	-- Improved edge detection with ground check
	local function nearEdge(character, direction)
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return false end
		local rayOrigin = root.Position + Vector3.new(0, 2, 0) + direction * 10
		local ray = Ray.new(rayOrigin, Vector3.new(0, -20, 0))
		local hit = Workspace:Raycast(ray, {character})
		return hit == nil  -- no ground 20 studs below
	end

	local function safePosition(character, targetPos)
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return false end
		local rayOrigin = targetPos + Vector3.new(0, 5, 0)
		local ray = Ray.new(rayOrigin, Vector3.new(0, -15, 0))
		local hit = Workspace:Raycast(ray, {character})
		return hit ~= nil
	end

	local function rotateCharacter(character, angleDeg, speed)
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local hum = character:FindFirstChild("Humanoid")
		if hum then
			hum.AutoRotate = false  -- we take control
		end
		local startTime = tick()
		local duration = 0.5 / speed
		local startCF = root.CFrame
		local endCF = startCF * CFrame.Angles(0, math.rad(angleDeg), 0)
		while tick() - startTime < duration do
			root.CFrame = startCF:Lerp(endCF, (tick() - startTime) / duration)
			RunService.Heartbeat:Wait()
		end
		root.CFrame = endCF
		if hum then
			hum.AutoRotate = true
		end
	end

	local function jumpIfSafe(character)
		local root = character:FindFirstChild("HumanoidRootPart")
		local hum = character:FindFirstChild("Humanoid")
		if not root or not hum then return false end
		if nearEdge(character, root.CFrame.LookVector) then
			return false  -- don't jump into void
		end
		hum.Jump = true
		return true
	end

	local function getBehindPosition(enemyRoot, offset)
		local behind = enemyRoot.CFrame * CFrame.new(0, 0, offset) -- behind = negative Z in local space? Actually, lookVector is forward, so behind is -lookVector.
		local pos = enemyRoot.Position - enemyRoot.CFrame.LookVector * offset
		pos = Vector3.new(pos.X, enemyRoot.Position.Y, pos.Z)  -- keep same Y
		return pos
	end

	local function equipAndAttack()
		local char = getCharacter()
		if not char then return end
		local tools = char:FindChildrenOfClass("Tool")
		local glove = nil
		for _, tool in ipairs(tools) do
			if tool.Name:lower():find("glove") then
				glove = tool
				break
			end
		end
		if not glove and #tools > 0 then
			glove = tools[1]
		end
		if glove then
			player.Character.Humanoid:EquipTool(glove)
			glove:Activate()
		end
	end

	local function useAbilityE()
		pcall(function()
			VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			wait(0.05)
			VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end)
	end

	local function aiLoop()
		while aiActive do
			local character = getCharacter()
			local hum = character and character:FindFirstChild("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not hum or hum.Health <= 0 or not root then
				wait(0.5)
				continue
			end

			local params = getParams()
			local friendly = friendlyBtn.Text
			local wanderSetting = wanderBtn.Text
			local escapeSetting = escapeBtn.Text

			local enemy, enemyDist = getNearestEnemy(character, friendly)
			local healthPercent = hum.Health / hum.MaxHealth

			local shouldRun = false
			local shouldFight = false

			if enemy then
				if escapeSetting == "Run from enemy" then
					shouldRun = true
				elseif escapeSetting == "When low health" and healthPercent <= params.runHealth then
					shouldRun = true
				end
			end

			if not shouldRun and enemy and enemyDist <= params.detectRange then
				if math.random() < params.fightChance then
					shouldFight = true
				end
			end

			-- Wander
			if not enemy and wanderSetting ~= "Off" then
				if wanderSetting == "Always" or (wanderSetting == "Sometimes" and math.random() < 0.05) then
					local wanderPoint = root.Position + Vector3.new(math.random(-30,30), 0, math.random(-30,30))
					if safePosition(character, wanderPoint) then
						hum:MoveTo(wanderPoint)
					end
				end
			end

			-- Combat / Escape movement with enhancements
			if shouldRun then
				local awayDir = (root.Position - enemy.Position).Unit * 50
				local runPoint = root.Position + awayDir
				if safePosition(character, runPoint) and not nearEdge(character, awayDir) then
					hum:MoveTo(runPoint)
				end
			elseif shouldFight then
				-- Normal approach
				hum:MoveTo(enemy.Position)
				equipAndAttack()
				if math.random() < params.abilityChance then useAbilityE() end

				-- Jump attack
				if math.random() < params.jumpAttackChance then
					if jumpIfSafe(character) then
						wait(0.1)  -- brief delay
						equipAndAttack()  -- attack mid-air
					end
				end

				-- 180/360 spin (shift-lock style)
				if math.random() < params.spinChance then
					local angle = math.random() < 0.5 and 180 or 360
					rotateCharacter(character, angle, 0.5)
				end

				-- Move behind enemy
				if math.random() < params.behindChance then
					local behindPos = getBehindPosition(enemy, 8) -- 8 studs behind
					if safePosition(character, behindPos) then
						hum:MoveTo(behindPos)
						wait(0.2)
						equipAndAttack()
					end
				end

				-- Fake moves near edges (already present)
				if math.random() < params.fakeMoveChance and nearEdge(character, root.CFrame.LookVector) then
					ZolinApp.performFakeMove(character)
				end
			else
				hum:MoveTo(root.Position)
			end

			wait(0.2)
		end
	end

	-- performFakeMove kept as is but we'll reuse it
	function ZolinApp.performFakeMove(character)
		local hum = character:FindFirstChild("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return end
		local right = root.CFrame.RightVector * 15
		local left = -right
		local targetPos = root.Position + (math.random() < 0.5 and right or left)
		if safePosition(character, targetPos) then
			hum:MoveTo(targetPos)
			wait(0.2)
		end
	end

	local function stopAI()
		aiActive = false
		toggleBtn.Text = "Enable AI"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
		if aiConnection then
			aiConnection:Disconnect()
			aiConnection = nil
		end
		if aiThread then
			task.cancel(aiThread)
			aiThread = nil
		end
		-- Restore character control if any
		local char = getCharacter()
		if char then
			local hum = char:FindFirstChild("Humanoid")
			if hum then hum.AutoRotate = true end
		end
	end

	local function startAI()
		if aiActive then return end
		aiActive = true
		toggleBtn.Text = "Disable AI"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 34, 34)

		aiConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and aiActive then
				if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					stopAI()
				end
			end
		end)

		aiThread = task.spawn(aiLoop)
	end

	toggleBtn.MouseButton1Click:Connect(function()
		if aiActive then stopAI() else startAI() end
	end)

	print("Play as AI enhanced installed successfully.")
end

-- Refresh home screen
local zolin = mainUI:FindFirstChild("__Zolin")
local remotes = zolin and zolin:FindFirstChild("Remotes")
local refreshEvent = remotes and remotes:FindFirstChild("updateZolinLauncher")
if refreshEvent then
	refreshEvent:Fire()
end
	return ZolinApp
end

ZolinApp.Init();
