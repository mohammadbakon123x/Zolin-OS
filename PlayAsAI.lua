-- ============================================================
-- PlayAsAI – AI Logic (returned as a module for AppManager)
-- Enhanced with Beatdown Combo
-- ============================================================
local ZolinApp = {}

function ZolinApp.Init(ui, launchArgs, appFolder)
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local VIM = game:GetService("VirtualInputManager")

	local player = Players.LocalPlayer

	local toggleBtn = ui:WaitForChild("ToggleButton")
	local settingsFrame = ui:WaitForChild("SettingsFrame")
	local friendlyBtn = settingsFrame:WaitForChild("Friendly:"):FindFirstChild("FriendlyBtn")
	local wanderBtn = settingsFrame:WaitForChild("Wander:"):FindFirstChild("WanderBtn")
	local escapeBtn = settingsFrame:WaitForChild("Escape:"):FindFirstChild("EscapingBtn")
	local diffBtn = settingsFrame:WaitForChild("Difficulty:"):FindFirstChild("DifficultyBtn")

	if not (toggleBtn and friendlyBtn and wanderBtn and escapeBtn and diffBtn) then
		warn("PlayAsAI: UI elements missing.")
		return
	end

	local aiActive = false
	local aiConnection = nil
	local aiThread = nil

	local diffParams = {
		Easy   = {detectRange = 30, fightChance = 0.2, abilityChance = 0.1, runHealth = 0.3, fakeMoveChance = 0.1, spinChance = 0.1, behindChance = 0.1, jumpAttackChance = 0.1, beatdownChance = 0.1},
		Normal = {detectRange = 60, fightChance = 0.5, abilityChance = 0.3, runHealth = 0.4, fakeMoveChance = 0.3, spinChance = 0.3, behindChance = 0.3, jumpAttackChance = 0.3, beatdownChance = 0.4},
		Hard   = {detectRange = 100, fightChance = 0.8, abilityChance = 0.6, runHealth = 0.5, fakeMoveChance = 0.6, spinChance = 0.6, behindChance = 0.6, jumpAttackChance = 0.6, beatdownChance = 0.7},
		Insane = {detectRange = 200, fightChance = 1.0, abilityChance = 0.9, runHealth = 0.7, fakeMoveChance = 0.9, spinChance = 0.9, behindChance = 0.9, jumpAttackChance = 0.9, beatdownChance = 0.9},
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

	local function nearEdge(character, direction)
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return false end
		local rayOrigin = root.Position + Vector3.new(0, 2, 0) + direction * 10
		local ray = Ray.new(rayOrigin, Vector3.new(0, -20, 0))
		local hit = Workspace:Raycast(ray, {character})
		return hit == nil
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
		if hum then hum.AutoRotate = false end
		local startTime = tick()
		local duration = 0.5 / speed
		local startCF = root.CFrame
		local endCF = startCF * CFrame.Angles(0, math.rad(angleDeg), 0)
		while tick() - startTime < duration do
			root.CFrame = startCF:Lerp(endCF, (tick() - startTime) / duration)
			RunService.Heartbeat:Wait()
		end
		root.CFrame = endCF
		if hum then hum.AutoRotate = true end
	end

	local function jumpIfSafe(character)
		local root = character:FindFirstChild("HumanoidRootPart")
		local hum = character:FindFirstChild("Humanoid")
		if not root or not hum then return false end
		if nearEdge(character, root.CFrame.LookVector) then return false end
		hum.Jump = true
		return true
	end

	local function getBehindPosition(enemyRoot, offset)
		local pos = enemyRoot.Position - enemyRoot.CFrame.LookVector * offset
		pos = Vector3.new(pos.X, enemyRoot.Position.Y, pos.Z)
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

	local function performFakeMove(character)
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

	-- ===== NEW: Beatdown Combo =====
	local function isBeatdownGlove()
		local char = getCharacter()
		if not char then return false end
		local tools = char:FindChildrenOfClass("Tool")
		for _, tool in ipairs(tools) do
			if tool.Name:lower():find("beatdown") then
				return tool
			end
		end
		return nil
	end

	local function performBeatdownCombo(character, enemyRoot)
		local hum = character:FindFirstChild("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return end

		useAbilityE()
		wait(0.1)

		local targetPos = enemyRoot.Position
		hum:MoveTo(targetPos)
		local startTime = tick()
		while tick() - startTime < 0.7 and aiActive do
			if (root.Position - targetPos).Magnitude > 1 then
				hum:MoveTo(targetPos)
			end
			RunService.Heartbeat:Wait()
		end

		equipAndAttack()
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

			-- Combat / Escape
			if shouldRun then
				local awayDir = (root.Position - enemy.Position).Unit * 50
				local runPoint = root.Position + awayDir
				if safePosition(character, runPoint) and not nearEdge(character, awayDir) then
					hum:MoveTo(runPoint)
				end
			elseif shouldFight then
				local beatdownGlove = isBeatdownGlove()
				-- Try Beatdown combo if close and glove detected
				if beatdownGlove and enemyDist < 6 and math.random() < params.beatdownChance then
					performBeatdownCombo(character, enemy)
				else
					-- Normal fight routine
					hum:MoveTo(enemy.Position)
					equipAndAttack()
					if math.random() < params.abilityChance then useAbilityE() end

					if math.random() < params.jumpAttackChance then
						if jumpIfSafe(character) then
							wait(0.1)
							equipAndAttack()
						end
					end

					if math.random() < params.spinChance then
						local angle = math.random() < 0.5 and 180 or 360
						rotateCharacter(character, angle, 0.5)
					end

					if math.random() < params.behindChance then
						local behindPos = getBehindPosition(enemy, 8)
						if safePosition(character, behindPos) then
							hum:MoveTo(behindPos)
							wait(0.2)
							equipAndAttack()
						end
					end

					if math.random() < params.fakeMoveChance and nearEdge(character, root.CFrame.LookVector) then
						performFakeMove(character)
					end
				end
			else
				hum:MoveTo(root.Position)
			end

			wait(0.2)
		end
	end

	local function stopAI()
		aiActive = false
		toggleBtn.Text = "Enable AI"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
		if aiConnection then aiConnection:Disconnect(); aiConnection = nil end
		if aiThread then task.cancel(aiThread); aiThread = nil end
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
end

return ZolinApp
