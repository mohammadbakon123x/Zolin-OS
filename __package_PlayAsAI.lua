-- ============================================================
-- PlayAsAI Package Installer
-- Paste this entire block into the ZolinInstaller "URL" box,
-- give the app the name "PlayAsAI", then click Install.
-- ============================================================
local __AppPackage = {}
function __AppPackage.Install()
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
	if __AppsLaunchArgFolder:FindFirstChild("PlayAsAI") and replicatedWindow:FindFirstChild("PlayAsAI") then
		warn("PlayAsAI already installed")
		return
	end

	-- ======== BUILD APP FRAME (static UI skeleton) ========
	local app = Instance.new("Frame")
	app.Name = "PlayAsAI"
	app.AnchorPoint = Vector2.new(0.5, 0.5)
	app.BackgroundTransparency = 0
	app.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	app.Size = UDim2.new(1, 0, 1, 0)
	app.Position = UDim2.new(0.5, 0, 0.5, 0)
	app.ZIndex = 6
	app.Parent = replicatedWindow
	app.Visible = false

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

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.08, 0)
	title.Position = UDim2.new(0, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "Play as AI"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = ui

	-- Toggle Button (placeholder – AI logic will replace its functionality)
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleButton"
	toggleBtn.Size = UDim2.new(0.5, 0, 0.1, 0)
	toggleBtn.Position = UDim2.new(0.25, 0, 0.12, 0)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
	toggleBtn.Text = "Enable AI"
	toggleBtn.TextColor3 = Color3.new(0, 0, 0)
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 14
	toggleBtn.Parent = ui

	-- Settings ScrollingFrame
	local settingsFrame = Instance.new("ScrollingFrame")
	settingsFrame.Name = "SettingsFrame"
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

	-- Helper to create setting rows (will be reused in AI logic)
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

	-- Create setting rows (they will be named so AI logic can find them)
	addSettingRow("Friendly:", {"All", "Friends Only", "None"}).Name = "FriendlyBtn"
	addSettingRow("Wander:", {"Off", "Sometimes", "Always"}).Name = "WanderBtn"
	addSettingRow("Escaping:", {"None", "Run from enemy", "When low health"}).Name = "EscapeBtn"

	-- Player Controls (greyed out)
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

	addSettingRow("Difficulty:", {"Easy", "Normal", "Hard", "Insane"}).Name = "DifficultyBtn"

	-- ======== REGISTER THE APP ========
	local appEntry = __AppsLaunchArgFolder:FindFirstChild("PlayAsAI") or Instance.new("StringValue")
	appEntry.Name = "PlayAsAI"
	appEntry.Value = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/PlayAsAI.lua"
	appEntry.Parent = __AppsLaunchArgFolder

	print("PlayAsAI package installed successfully!")
end

__AppPackage.Install()
