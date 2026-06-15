-- ============================================================
-- Zolin Modifier Package Installer
-- ============================================================
local __AppPackage = {}
function __AppPackage.Install()
	local AppName = "Zolin Modifier"
	local ZolinOS = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS")
	if not ZolinOS then warn("ZolinOS not found"); return end
	local replicatedWindow = ZolinOS:FindFirstChild("ReplicatedWindow")
	if not replicatedWindow then warn("ReplicatedWindow not found"); return end
	local __Zolin = ZolinOS:FindFirstChild("__Zolin")
	if not __Zolin then warn("__Zolin not found"); return end
	local __AppsLaunchArgFolder = __Zolin:FindFirstChild("__AppsLaunchArgFolder")
	if not __AppsLaunchArgFolder then
		__AppsLaunchArgFolder = Instance.new("Folder")
		__AppsLaunchArgFolder.Name = "__AppsLaunchArgFolder"
		__AppsLaunchArgFolder.Parent = __Zolin
	end
	if __AppsLaunchArgFolder:FindFirstChild(AppName) and replicatedWindow:FindFirstChild(AppName) then
		warn("Zolin Modifier already installed")
		return
	end

	-- ======== BUILD APP FRAME ========
	local app = Instance.new("Frame")
	app.Name = AppName
	app.AnchorPoint = Vector2.new(0.5, 0.5)
	app.BackgroundTransparency = 0
	app.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
	app.Size = UDim2.new(1, 0, 1, 0)
	app.Position = UDim2.new(0.5, 0, 0.5, 0)
	app.ZIndex = 6
	app.Parent = replicatedWindow
	app.Visible = false

	local dataFolder = Instance.new("Folder")
	dataFolder.Name = "Data"
	dataFolder.Parent = app

	Instance.new("StringValue", dataFolder).Name = "Description"
	dataFolder.Description.Value = "Zolin Modifier – advanced game tweaks. Made by Zolin."

	Instance.new("StringValue", dataFolder).Name = "Version"
	dataFolder.Version.Value = "1.0.0"

	local ui = Instance.new("Frame")
	ui.Name = "UI"
	ui.AnchorPoint = Vector2.new(0.5, 0.5)
	ui.Position = UDim2.new(0.5, 0, 0.495, 0)
	ui.Size = UDim2.new(1, 0, 0.89, 0)
	ui.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
	ui.BackgroundTransparency = 0.2
	ui.ZIndex = app.ZIndex - 1
	ui.Parent = app

	-- Preview
	local preview = Instance.new("Frame")
	preview.Name = "PreviewAppInfoZL"
	preview.AnchorPoint = Vector2.new(0.5, 0.5)
	preview.AutomaticSize = Enum.AutomaticSize.XY
	preview.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
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
	previewLabel.Text = "Zolin Modifier"
	previewLabel.Parent = preview

	local previewIcon = Instance.new("ImageLabel")
	previewIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	previewIcon.AutomaticSize = Enum.AutomaticSize.XY
	previewIcon.BackgroundTransparency = 1
	previewIcon.Position = UDim2.new(0.9, 0, 0.5, 0)
	previewIcon.Size = UDim2.new(0, 39, 0, 39)
	previewIcon.Image = "rbxassetid://108965213161366"
	previewIcon.ScaleType = Enum.ScaleType.Fit
	previewIcon.Parent = preview

	-- ===== UI CONTENT =====

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.06, 0)
	title.Position = UDim2.new(0, 0, 0.01, 0)
	title.BackgroundTransparency = 1
	title.Text = "Zolin Modifier"
	title.TextColor3 = Color3.fromRGB(255, 50, 50)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.ZIndex = ui.ZIndex + 1
	title.Parent = ui

	-- Version label
	local versionLabel = Instance.new("TextLabel")
	versionLabel.Size = UDim2.new(1, 0, 0.03, 0)
	versionLabel.Position = UDim2.new(0, 0, 0.08, 0)
	versionLabel.BackgroundTransparency = 1
	versionLabel.Text = "v1.0.0 | by Zolin"
	versionLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
	versionLabel.TextSize = 10
	versionLabel.Font = Enum.Font.Gotham
	versionLabel.TextXAlignment = Enum.TextXAlignment.Center
	versionLabel.ZIndex = ui.ZIndex + 1
	versionLabel.Parent = ui

	-- 📁 Buttons folder (all main control buttons go here for easy access)
	local buttonsFolder = Instance.new("Folder")
	buttonsFolder.Name = "Buttons"
	buttonsFolder.Parent = ui

	-- Settings scroll area
	local settingsFrame = Instance.new("ScrollingFrame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.Size = UDim2.new(1, -10, 0.78, 0)
	settingsFrame.Position = UDim2.new(0, 5, 0.12, 0)
	settingsFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
	settingsFrame.BackgroundTransparency = 0.4
	settingsFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
	settingsFrame.ScrollBarThickness = 5
	settingsFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
	settingsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	settingsFrame.Parent = ui
	settingsFrame.ZIndex = ui.ZIndex + 2

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = settingsFrame

	-- Helper: add a cycle setting and ALSO store the button in Buttons folder
	local function addCycleSetting(name, options)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 40)
		row.BackgroundTransparency = 1
		row.Parent = settingsFrame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.45, 0, 1, 0)
		label.Position = UDim2.new(0, 5, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local cycleBtn = Instance.new("TextButton")
		cycleBtn.Size = UDim2.new(0.5, 0, 1, 0)
		cycleBtn.Position = UDim2.new(0.5, 0, 0, 0)
		cycleBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
		cycleBtn.Text = options[1]
		cycleBtn.TextColor3 = Color3.new(1, 1, 1)
		cycleBtn.Font = Enum.Font.Gotham
		cycleBtn.TextSize = 12
		cycleBtn.Parent = row

		local idx = 1
		cycleBtn.MouseButton1Click:Connect(function()
			idx = idx % #options + 1
			cycleBtn.Text = options[idx]
		end)
		return cycleBtn
	end

	-- Helper: add a toggle setting and store in Buttons folder
	local function addToggleSetting(name, defaultState)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 40)
		row.BackgroundTransparency = 1
		row.Parent = settingsFrame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.45, 0, 1, 0)
		label.Position = UDim2.new(0, 5, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local toggleBtn = Instance.new("TextButton")
		toggleBtn.Size = UDim2.new(0.5, 0, 1, 0)
		toggleBtn.Position = UDim2.new(0.5, 0, 0, 0)
		toggleBtn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(130, 0, 0)
		toggleBtn.Text = defaultState and "Enabled" or "Disabled"
		toggleBtn.TextColor3 = Color3.new(1, 1, 1)
		toggleBtn.Font = Enum.Font.Gotham
		toggleBtn.TextSize = 12
		toggleBtn.Parent = row

		local state = defaultState
		toggleBtn.MouseButton1Click:Connect(function()
			state = not state
			toggleBtn.Text = state and "Enabled" or "Disabled"
			toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(130, 0, 0)
		end)
		return toggleBtn
	end

	-- Helper: add a slider + textbox row
	local function addNumberSetting(name, minVal, maxVal, defaultVal)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 55)
		row.BackgroundTransparency = 1
		row.Parent = settingsFrame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.45, 0, 0.4, 0)
		label.Position = UDim2.new(0, 5, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local sliderBg = Instance.new("Frame")
		sliderBg.Size = UDim2.new(0.45, 0, 0.25, 0)
		sliderBg.Position = UDim2.new(0, 5, 0.45, 0)
		sliderBg.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
		sliderBg.Parent = row

		local sliderFill = Instance.new("Frame")
		sliderFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
		sliderFill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
		sliderFill.Name = "SliderFill"
		sliderFill.Parent = sliderBg

		local sliderCorner = Instance.new("UICorner")
		sliderCorner.CornerRadius = UDim.new(1, 0)
		sliderCorner.Parent = sliderBg

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = sliderFill

		local valueBox = Instance.new("TextBox")
		valueBox.Size = UDim2.new(0.5, -10, 0.35, 0)
		valueBox.Position = UDim2.new(0.5, 5, 0.65, 0)
		valueBox.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
		valueBox.TextColor3 = Color3.new(1, 1, 1)
		valueBox.Text = tostring(defaultVal)
		valueBox.Font = Enum.Font.Gotham
		valueBox.TextSize = 12
		valueBox.Name = "ValueBox"
		valueBox.Parent = row

		return row
	end

	-- === CREATE ALL SETTINGS (buttons stored in Buttons folder) ===

	-- ESP
	local espBtn = addCycleSetting("ESP:", {"None", "All", "Friends Only", "All + Friends (Green)"})
	espBtn.Name = "ESPButton"
	espBtn.Parent = buttonsFolder   -- 🔥 move to Buttons folder

	-- Camera Type
	local cameraBtn = addCycleSetting("Camera Type:", {"Default", "First Person"})
	cameraBtn.Name = "CameraButton"
	cameraBtn.Parent = buttonsFolder

	-- Full Bright Light
	local fullBrightBtn = addToggleSetting("Full Bright Light:", false)
	fullBrightBtn.Name = "FullBrightButton"
	fullBrightBtn.Parent = buttonsFolder

	-- Player Speed
	local speedRow = addNumberSetting("Player Speed (Not Recommended):", 0, 1990, 16)
	speedRow.Name = "SpeedRow"

	-- Player Jump
	local jumpRow = addNumberSetting("Player Jump (Not Recommended):", 0, 1990, 50)
	jumpRow.Name = "JumpRow"

	-- Aim Asset
	local aimBtn = addCycleSetting("Aim Asset:", {"Disabled", "Enabled", "OnlyNoneFriends"})  -- simplified name
	aimBtn.Name = "AimButton"
	aimBtn.Parent = buttonsFolder

	-- Safe Mode
	local safeModeBtn = addToggleSetting("Safe Mode:", true)
	safeModeBtn.Name = "SafeModeButton"
	safeModeBtn.Parent = buttonsFolder

	-- ======== REGISTER THE APP ========
	local appEntry = __AppsLaunchArgFolder:FindFirstChild(AppName)
	if not appEntry then
		appEntry = Instance.new("StringValue")
		appEntry.Name = AppName
		appEntry.Parent = __AppsLaunchArgFolder
	end
	appEntry.Value = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/ZolinModifier.lua"

	print(AppName .. " package installed successfully!")
end

__AppPackage.Install()
