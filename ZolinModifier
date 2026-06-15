-- ============================================================
-- Zolin Modifier – Logic Script - Client
-- ============================================================
local ZolinApp = {}

function ZolinApp.Init(ui, launchArgs, appFolder)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	local TweenService = game:GetService("TweenService")
	local Workspace = game:GetService("Workspace")

	local player = Players.LocalPlayer
	local camera = Workspace.CurrentCamera

	-- UI References
	local settingsFrame = ui:WaitForChild("SettingsFrame")
	local espBtn = settingsFrame:WaitForChild("ESPButton")
	local cameraBtn = settingsFrame:WaitForChild("CameraButton")
	local fullBrightBtn = settingsFrame:WaitForChild("FullBrightButton")
	local speedRow = settingsFrame:WaitForChild("SpeedRow")
	local jumpRow = settingsFrame:WaitForChild("JumpRow")
	local aimBtn = settingsFrame:WaitForChild("AimButton")
	local safeModeBtn = settingsFrame:WaitForChild("SafeModeButton")

	-- Extract sub‑elements from number rows
	local speedSliderBg = speedRow:FindFirstChild("Frame")
	local speedFill = speedSliderBg and speedSliderBg:FindFirstChild("SliderFill")
	local speedBox = speedRow:FindFirstChild("ValueBox")

	local jumpSliderBg = jumpRow:FindFirstChild("Frame")
	local jumpFill = jumpSliderBg and jumpSliderBg:FindFirstChild("SliderFill")
	local jumpBox = jumpRow:FindFirstChild("ValueBox")

	-- Default values (mirror the installer)
	local walkSpeed = 16
	local jumpPower = 50
	local safeMode = true

	-- ================== HELPER: Slider interaction ==================
	local function setupSlider(sliderBg, fill, box, min, max, setter)
		local current = tonumber(box.Text) or min
		local function updateVisual(value)
			value = math.clamp(value, min, max)
			fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
			box.Text = tostring(math.floor(value * 10) / 10)
			setter(value)
		end
		updateVisual(current)

		box.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				local num = tonumber(box.Text)
				if num then
					updateVisual(num)
				else
					box.Text = tostring(math.floor(current * 10) / 10)
				end
			end
		end)

		sliderBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local connection
				connection = RunService.Heartbeat:Connect(function()
					local mousePos = UserInputService:GetMouseLocation()
					local barPos = sliderBg.AbsolutePosition
					local barSize = sliderBg.AbsoluteSize
					local relX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
					local val = min + relX * (max - min)
					updateVisual(val)
					current = val
				end)
				local endConn
				endConn = UserInputService.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then
						connection:Disconnect()
						endConn:Disconnect()
					end
				end)
			end
		end)
		return updateVisual
	end

	local setSpeed = setupSlider(speedSliderBg, speedFill, speedBox, 0, 1990, function(v)
		walkSpeed = v
		if not safeMode then
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.WalkSpeed = v
			end
		end
	end)

	local setJump = setupSlider(jumpSliderBg, jumpFill, jumpBox, 0, 1990, function(v)
		jumpPower = v
		if not safeMode then
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.JumpPower = v
			end
		end
	end)

	-- ================== SAFE MODE ==================
	local function applySafeMode()
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") then
			if safeMode then
				char.Humanoid.WalkSpeed = math.clamp(walkSpeed, 16, 19.6)
				char.Humanoid.JumpPower = math.clamp(jumpPower, 50, 70)
			else
				char.Humanoid.WalkSpeed = walkSpeed
				char.Humanoid.JumpPower = jumpPower
			end
		end
	end

	safeModeBtn.MouseButton1Click:Connect(function()
		safeMode = not safeMode
		safeModeBtn.Text = safeMode and "Enabled" or "Disabled"
		safeModeBtn.BackgroundColor3 = safeMode and Color3.fromRGB(0,130,0) or Color3.fromRGB(130,0,0)
		applySafeMode()
	end)

	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		applySafeMode()
	end)
	if player.Character then
		applySafeMode()
	end

	-- ================== CAMERA TYPE ==================
	local cameraModes = {"Default", "First Person"}
	cameraBtn.MouseButton1Click:Connect(function()
		local current = table.find(cameraModes, cameraBtn.Text) or 1
		local nextMode = current % #cameraModes + 1
		cameraBtn.Text = cameraModes[nextMode]
		if cameraModes[nextMode] == "First Person" then
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			player.CameraMaxZoomDistance = 0
		else
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMaxZoomDistance = 400
		end
	end)

	-- ================== FULL BRIGHT (with restore) ==================
	local defaultLighting = {
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		FogEnd = Lighting.FogEnd,
		GlobalShadows = Lighting.GlobalShadows,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient
	}
	local fullBrightActive = false

	fullBrightBtn.MouseButton1Click:Connect(function()
		fullBrightActive = not fullBrightActive
		fullBrightBtn.Text = fullBrightActive and "Enabled" or "Disabled"
		fullBrightBtn.BackgroundColor3 = fullBrightActive and Color3.fromRGB(0,130,0) or Color3.fromRGB(130,0,0)
		if fullBrightActive then
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.FogEnd = 100000
			Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.fromRGB(255,255,255)
			Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
		else
			Lighting.Brightness = defaultLighting.Brightness
			Lighting.ClockTime = defaultLighting.ClockTime
			Lighting.FogEnd = defaultLighting.FogEnd
			Lighting.GlobalShadows = defaultLighting.GlobalShadows
			Lighting.Ambient = defaultLighting.Ambient
			Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
		end
	end)

	-- ================== ESP ==================
	local highlights = {}
	local espMode = "None"

	local function updateESP()
		for plr, hl in pairs(highlights) do
			hl.Enabled = false
			hl:Destroy()
			highlights[plr] = nil
		end
		if espMode == "None" then return end

		for _, other in ipairs(Players:GetPlayers()) do
			if other == player then continue end
			local char = other.Character
			if char and not char:FindFirstChild("Highlight") then
				local hl = Instance.new("Highlight")
				hl.Name = "ESP_Highlight"
				hl.Adornee = char
				hl.FillTransparency = 0.5
				hl.OutlineTransparency = 0
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = char
				highlights[other] = hl
				local color
				if espMode == "All" then
					color = Color3.fromRGB(255, 0, 0)
				elseif espMode == "Friends Only" then
					if other:IsFriendsWithAsync(player.UserId) then
						color = Color3.fromRGB(255, 255, 0)
					else
						hl.Enabled = false
						continue
					end
				elseif espMode == "All + Friends (Green)" then
					if other:IsFriendsWithAsync(player.UserId) then
						color = Color3.fromRGB(0, 255, 0)
					else
						color = Color3.fromRGB(255, 0, 0)
					end
				end
				hl.FillColor = color
				hl.OutlineColor = color
				hl.Enabled = true
			end
		end
	end

	local espModes = {"None", "All", "Friends Only", "All + Friends (Green)"}
	espBtn.MouseButton1Click:Connect(function()
		local current = table.find(espModes, espBtn.Text) or 1
		local nextMode = current % #espModes + 1
		espBtn.Text = espModes[nextMode]
		espMode = espModes[nextMode]
		updateESP()
	end)

	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(updateESP)
	end)
	Players.PlayerRemoving:Connect(function(p)
		if highlights[p] then
			highlights[p]:Destroy()
			highlights[p] = nil
		end
	end)
	updateESP()

	-- ================== AIM ASSIST ==================
	local aimEnabled = false
	local aimToggle = false
	local rightClickHeld = false

	local function isOnScreen(targetPos)
		local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
		if not onScreen then return false end
		return screenPos.X >= 0 and screenPos.X <= 1 and screenPos.Y >= 0 and screenPos.Y <= 1 and screenPos.Z > 0
	end

	local function isVisible(targetChar)
		local head = targetChar:FindFirstChild("Head")
		if not head then return false end
		if not isOnScreen(head.Position) then return false end
		local ray = Ray.new(camera.CFrame.Position, (head.Position - camera.CFrame.Position).Unit * 1000)
		local hit = Workspace:Raycast(ray, {player.Character})
		return hit and hit.Instance:IsDescendantOf(targetChar)
	end

	local function getNearestVisibleEnemy()
		local bestDist = math.huge
		local bestChar = nil
		local aimFilter = aimBtn.Text
		if aimFilter == "Disabled" then return nil end

		for _, other in ipairs(Players:GetPlayers()) do
			if other == player then continue end
			local char = other.Character
			if char and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				if aimFilter == "OnlyNoneFriends" and other:IsFriendsWithAsync(player.UserId) then
					continue
				end
				if isVisible(char) then
					local dist = (char.Head.Position - camera.CFrame.Position).Magnitude
					if dist < bestDist then
						bestDist = dist
						bestChar = char
					end
				end
			end
		end
		return bestChar
	end

	local aimConnection = nil
	local function updateAim()
		if not aimEnabled then return end
		local target = getNearestVisibleEnemy()
		if target and target.Head then
			local lookAt = target.Head.Position
			local newCFrame = CFrame.lookAt(camera.CFrame.Position, lookAt)
			camera.CFrame = camera.CFrame:Lerp(newCFrame, 0.2)
		end
	end

	local function setAimEnabled(state)
		if state ~= aimEnabled then
			aimEnabled = state
			if aimEnabled then
				aimConnection = RunService.Heartbeat:Connect(updateAim)
			else
				if aimConnection then
					aimConnection:Disconnect()
					aimConnection = nil
				end
			end
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.X then
			aimToggle = not aimToggle
			setAimEnabled(aimToggle or rightClickHeld)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			rightClickHeld = true
			setAimEnabled(aimToggle or rightClickHeld)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			rightClickHeld = false
			setAimEnabled(aimToggle or rightClickHeld)
		end
	end)

	-- ================== CLEAN UP (RESTORE LIGHTING) ==================
	ui.Destroying:Connect(function()
		-- Stop AIM
		if aimConnection then
			aimConnection:Disconnect()
		end
		-- Restore original lighting if Full Bright was toggled on
		if fullBrightActive then
			Lighting.Brightness = defaultLighting.Brightness
			Lighting.ClockTime = defaultLighting.ClockTime
			Lighting.FogEnd = defaultLighting.FogEnd
			Lighting.GlobalShadows = defaultLighting.GlobalShadows
			Lighting.Ambient = defaultLighting.Ambient
			Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
		end
		-- Remove ESP highlights
		for _, hl in pairs(highlights) do
			hl:Destroy()
		end
		highlights = {}
	end)

	print("Zolin Modifier logic initialized!")
end

return ZolinApp
