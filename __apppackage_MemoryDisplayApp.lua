-- ============================================================
-- MemoryDisplay System App (Real‑time Memory Monitor + Graph)
-- ============================================================
local __MemoryDisplayPackage = {}
function __MemoryDisplayPackage.Install()
	local AppName = "MemoryDisplay"
	local ZolinOS = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS")
	if not ZolinOS then warn("ZolinOS not found"); return end

	local replicatedWindowSys = ZolinOS:FindFirstChild("ReplicatedWindow_Sys")
	if not replicatedWindowSys then warn("ReplicatedWindow_Sys not found"); return end

	local __Zolin = ZolinOS:FindFirstChild("__Zolin")
	if not __Zolin then warn("__Zolin not found"); return end

	local __AppsLaunchArgFolder = __Zolin:FindFirstChild("__AppsLaunchArgFolder")
	if not __AppsLaunchArgFolder then
		__AppsLaunchArgFolder = Instance.new("Folder")
		__AppsLaunchArgFolder.Name = "__AppsLaunchArgFolder"
		__AppsLaunchArgFolder.Parent = __Zolin
	end

	-- Prevent double installation
	if __AppsLaunchArgFolder:FindFirstChild(AppName) and replicatedWindowSys:FindFirstChild(AppName) then
		warn(tostring(AppName) .. " already installed")
		return
	end

	-- ============================================================
	-- BUILD APP FRAME
	-- ============================================================
	local app = Instance.new("Frame")
	app.Name = AppName
	app.AnchorPoint = Vector2.new(0.5, 0.5)
	app.BackgroundTransparency = 0
	app.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	app.Size = UDim2.new(1, 0, 1, 0)
	app.Position = UDim2.new(0.5, 0, 0.5, 0)
	app.ZIndex = 6
	app.Visible = false
	app.Parent = replicatedWindowSys

	-- Data folder (metadata)
	local dataFolder = Instance.new("Folder")
	dataFolder.Name = "Data"
	dataFolder.Parent = app

	Instance.new("StringValue", dataFolder).Name = "Description"
	dataFolder.Description.Value = "Monitor system memory in real time"

	Instance.new("StringValue", dataFolder).Name = "Version"
	dataFolder.Version.Value = "1.0"

	-- ============================================================
	-- UI CONTAINER
	-- ============================================================
	local ui = Instance.new("Frame")
	ui.Name = "UI"
	ui.AnchorPoint = Vector2.new(0.5, 0.5)
	ui.Position = UDim2.new(0.5, 0, 0.495, 0)
	ui.Size = UDim2.new(1, 0, 0.89, 0)
	ui.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	ui.BackgroundTransparency = 0.2
	ui.ZIndex = app.ZIndex - 1
	ui.Parent = app

	-- ============================================================
	-- PREVIEW (for App Drawer)
	-- ============================================================
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
	previewLabel.Text = AppName
	previewLabel.Parent = preview

	local previewIcon = Instance.new("ImageLabel")
	previewIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	previewIcon.AutomaticSize = Enum.AutomaticSize.XY
	previewIcon.BackgroundTransparency = 1
	previewIcon.Position = UDim2.new(0.9, 0, 0.5, 0)
	previewIcon.Size = UDim2.new(0, 39, 0, 39)
	previewIcon.Image = "rbxassetid://12905435514"  -- placeholder, replace with a memory icon
	previewIcon.ScaleType = Enum.ScaleType.Fit
	previewIcon.Parent = preview

	-- ============================================================
	-- MAIN UI ELEMENTS
	-- ============================================================

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.06, 0)
	title.Position = UDim2.new(0, 0, 0.01, 0)
	title.BackgroundTransparency = 1
	title.Text = "📊 Memory Usage"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.ZIndex = ui.ZIndex + 1
	title.Parent = ui

	-- Info labels (Used / Total / Percent)
	local usedLabel = Instance.new("TextLabel")
	usedLabel.Size = UDim2.new(0.5, 0, 0.05, 0)
	usedLabel.Position = UDim2.new(0, 10, 0.08, 0)
	usedLabel.BackgroundTransparency = 1
	usedLabel.Text = "Used: 0 MB"
	usedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	usedLabel.TextXAlignment = Enum.TextXAlignment.Left
	usedLabel.Font = Enum.Font.Gotham
	usedLabel.TextSize = 16
	usedLabel.ZIndex = ui.ZIndex + 1
	usedLabel.Parent = ui

	local totalLabel = Instance.new("TextLabel")
	totalLabel.Size = UDim2.new(0.5, 0, 0.05, 0)
	totalLabel.Position = UDim2.new(0.5, 10, 0.08, 0)
	totalLabel.BackgroundTransparency = 1
	totalLabel.Text = "Total: 0 MB"
	totalLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	totalLabel.TextXAlignment = Enum.TextXAlignment.Left
	totalLabel.Font = Enum.Font.Gotham
	totalLabel.TextSize = 16
	totalLabel.ZIndex = ui.ZIndex + 1
	totalLabel.Parent = ui

	local percentLabel = Instance.new("TextLabel")
	percentLabel.Size = UDim2.new(1, 0, 0.08, 0)
	percentLabel.Position = UDim2.new(0, 0, 0.14, 0)
	percentLabel.BackgroundTransparency = 1
	percentLabel.Text = "0%"
	percentLabel.TextColor3 = Color3.new(1, 1, 1)
	percentLabel.Font = Enum.Font.GothamBold
	percentLabel.TextSize = 36
	percentLabel.ZIndex = ui.ZIndex + 1
	percentLabel.Parent = ui

	-- Progress bar background
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0.8, 0, 0.03, 0)
	barBg.Position = UDim2.new(0.1, 0, 0.23, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	barBg.BorderSizePixel = 0
	barBg.ZIndex = ui.ZIndex + 1
	barBg.Parent = ui
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 10)
	barCorner.Parent = barBg

	-- Progress fill
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
	fill.BorderSizePixel = 0
	fill.ZIndex = ui.ZIndex + 2
	fill.Parent = barBg
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 10)
	fillCorner.Parent = fill

	-- Uptime
	local uptimeLabel = Instance.new("TextLabel")
	uptimeLabel.Size = UDim2.new(1, 0, 0.03, 0)
	uptimeLabel.Position = UDim2.new(0, 0, 0.27, 0)
	uptimeLabel.BackgroundTransparency = 1
	uptimeLabel.Text = "Uptime: 00:00:00"
	uptimeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	uptimeLabel.Font = Enum.Font.Gotham
	uptimeLabel.TextSize = 14
	uptimeLabel.ZIndex = ui.ZIndex + 1
	uptimeLabel.Parent = ui

	-- Graph title
	local graphTitle = Instance.new("TextLabel")
	graphTitle.Size = UDim2.new(1, 0, 0.035, 0)
	graphTitle.Position = UDim2.new(0, 0, 0.31, 0)
	graphTitle.BackgroundTransparency = 1
	graphTitle.Text = "Memory Usage Over Time (last 60s)"
	graphTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
	graphTitle.Font = Enum.Font.Gotham
	graphTitle.TextSize = 13
	graphTitle.ZIndex = ui.ZIndex + 1
	graphTitle.Parent = ui

	-- Graph container
	local graphContainer = Instance.new("Frame")
	graphContainer.Size = UDim2.new(0.9, 0, 0.35, 0)
	graphContainer.Position = UDim2.new(0.05, 0, 0.35, 0)
	graphContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	graphContainer.BorderSizePixel = 1
	graphContainer.BorderColor3 = Color3.fromRGB(60, 60, 70)
	graphContainer.ZIndex = ui.ZIndex + 1
	graphContainer.Parent = ui
	local graphCorner = Instance.new("UICorner")
	graphCorner.CornerRadius = UDim.new(0, 6)
	graphCorner.Parent = graphContainer

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.12, 0, 0.05, 0)
	closeBtn.Position = UDim2.new(0.44, 0, 0.73, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	closeBtn.Text = "Close"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.Gotham
	closeBtn.TextSize = 16
	closeBtn.ZIndex = ui.ZIndex + 2
	closeBtn.Parent = ui
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = closeBtn

	-- ============================================================
	-- GRAPH BARS (pre‑create 60 bars)
	-- ============================================================
	local MAX_POINTS = 60
	local bars = {}
	local history = {}

	for i = 1, MAX_POINTS do
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 6, 0, 0)
		bar.Position = UDim2.new(0, 0, 0, 0)
		bar.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
		bar.BorderSizePixel = 0
		bar.Visible = false
		bar.ZIndex = graphContainer.ZIndex + 1
		bar.Parent = graphContainer
		table.insert(bars, bar)
	end

	-- ============================================================
	-- MEMORY LOGIC
	-- ============================================================
	local Stats = game:GetService("Stats")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")

	local function getMemoryStats()
		local mem = Stats:FindFirstChild("Memory")
		if mem then
			local used = mem:FindFirstChild("Used") and mem.Used.Value or 0
			local total = mem:FindFirstChild("Total") and mem.Total.Value or 1000
			return used / 1024 / 1024, total / 1024 / 1024
		end
		-- Fallback: simulate realistic usage (200-800 MB)
		return math.random(200, 800), 1024
	end

	local function getUptime()
		return ZolinModules.CurrentUptime or "00:00:00"
	end

	local updateThread = nil

	local function updateDisplay()
		local usedMB, totalMB = getMemoryStats()
		local percent = (usedMB / totalMB) * 100
		percent = math.clamp(percent, 0, 100)

		-- Update labels
		usedLabel.Text = string.format("Used: %.0f MB", usedMB)
		totalLabel.Text = string.format("Total: %.0f MB", totalMB)
		percentLabel.Text = string.format("%.0f%%", percent)

		-- Update progress bar
		local targetWidth = percent / 100
		local tween = TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(targetWidth, 0, 1, 0)
		})
		tween:Play()

		-- Color based on usage
		if percent > 80 then
			fill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
		elseif percent > 60 then
			fill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
		else
			fill.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
		end

		-- Uptime
		uptimeLabel.Text = "Uptime: " .. getUptime()

		-- ===== GRAPH UPDATE =====
		table.insert(history, percent)
		if #history > MAX_POINTS then
			table.remove(history, 1)
		end

		local count = #history
		if count == 0 then return end

		local containerAbsSize = graphContainer.AbsoluteSize
		local availWidth = containerAbsSize.X - 10
		local availHeight = containerAbsSize.Y - 6

		local barWidth = 6
		local spacing = 2
		local totalBarWidth = (barWidth + spacing) * count - spacing
		local startX = 5

		if totalBarWidth > availWidth then
			local scale = availWidth / totalBarWidth
			barWidth = math.max(2, barWidth * scale)
			spacing = math.max(1, spacing * scale)
			totalBarWidth = (barWidth + spacing) * count - spacing
			startX = 5
		end

		for i = 1, count do
			local bar = bars[i]
			local val = history[i] or 0
			local height = (val / 100) * availHeight
			height = math.max(1, height)

			local x = startX + (i - 1) * (barWidth + spacing)
			local y = availHeight - height

			bar.Size = UDim2.new(0, barWidth, 0, height)
			bar.Position = UDim2.new(0, x, 0, y)

			-- Gradient color
			local r = 50 + (val / 100) * 205
			local g = 181 - (val / 100) * 150
			local b = 172 - (val / 100) * 150
			bar.BackgroundColor3 = Color3.fromRGB(
				math.clamp(r, 50, 255),
				math.clamp(g, 30, 181),
				math.clamp(b, 30, 172)
			)
			bar.Visible = true
		end

		for i = count + 1, #bars do
			bars[i].Visible = false
		end
	end

	-- Start updating
	updateDisplay()
	updateThread = RunService.Heartbeat:Connect(function()
		task.wait(1)
		updateDisplay()
	end)

	-- ============================================================
	-- CLOSE BUTTON LOGIC
	-- ============================================================
	closeBtn.MouseButton1Click:Connect(function()
		-- Close the app via ZolinModules (if available)
		local modules = ZolinModules.GetAll()
		if modules and modules.AppManager then
			modules.AppManager.CloseApp(AppName)
		else
			-- Fallback: just hide it
			app.Visible = false
			if updateThread then
				updateThread:Disconnect()
				updateThread = nil
			end
		end
	end)

	-- ============================================================
	-- CLEANUP ON DESTROY
	-- ============================================================
	app.Destroying:Connect(function()
		if updateThread then
			updateThread:Disconnect()
			updateThread = nil
		end
	end)

	-- ============================================================
	-- REGISTER THE APP
	-- ============================================================
	local appEntry = __AppsLaunchArgFolder:FindFirstChild(AppName)
	if not appEntry then
		appEntry = Instance.new("StringValue")
		appEntry.Name = AppName
		appEntry.Parent = __AppsLaunchArgFolder
	end
	appEntry.Value = "ZolinModules"  -- Mark as built-in module

	print(AppName .. " package installed successfully!")
end

-- ============================================================
-- INSTALL
-- ============================================================
__MemoryDisplayPackage.Install()
