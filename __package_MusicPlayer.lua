-- ============================================================
-- ZolinMusic Package Installer
-- ============================================================
local __AppPackage = {}
function __AppPackage.Install()
	local AppName = "ZolinMusic"
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
		warn(AppName .. " already installed")
		return
	end

	-- ======== BUILD APP FRAME ========
	local app = Instance.new("Frame")
	app.Name = AppName
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

	Instance.new("StringValue", dataFolder).Name = "Description"
	dataFolder.Description.Value = "Music Player with upload, search, loop, and seek"

	Instance.new("StringValue", dataFolder).Name = "Version"
	dataFolder.Version.Value = "1.1"
	
	Instance.new("StringValue", dataFolder).Name = "Author"
	dataFolder.Author.Value = "Sky_Attacker"

	local ui = Instance.new("Frame")
	ui.Name = "UI"
	ui.AnchorPoint = Vector2.new(0.5, 0.5)
	ui.Position = UDim2.new(0.5, 0, 0.495, 0)
	ui.Size = UDim2.new(1, 0, 0.89, 0)
	ui.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	ui.BackgroundTransparency = 0.3
	ui.ZIndex = app.ZIndex - 1
	ui.Parent = app

	-- Preview
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

	local previewLabel = Instance.new("TextLabel", preview)
	previewLabel.Name = "AppNameLabel"
	previewLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	previewLabel.Position = UDim2.new(0.409, 0, 0.5, 0)
	previewLabel.Size = UDim2.new(0, 150, 0, 25)
	previewLabel.BackgroundTransparency = 1
	previewLabel.TextScaled = true
	previewLabel.Font = Enum.Font.Oswald
	previewLabel.Text = "ZolinMusic"

	local previewIcon = Instance.new("ImageLabel", preview)
	previewIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	previewIcon.AutomaticSize = Enum.AutomaticSize.XY
	previewIcon.BackgroundTransparency = 1
	previewIcon.Position = UDim2.new(0.9, 0, 0.5, 0)
	previewIcon.Size = UDim2.new(0, 39, 0, 39)
	previewIcon.Image = "rbxassetid://16737376245"
	previewIcon.ScaleType = Enum.ScaleType.Fit

	-- ===== UI ELEMENTS =====

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.06, 0)
	title.Position = UDim2.new(0, 0, 0.01, 0)
	title.BackgroundTransparency = 1
	title.Text = "Music Player"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.ZIndex = ui.ZIndex + 1
	title.Parent = ui

	-- Now Playing Label
	local nowPlayingLabel = Instance.new("TextLabel")
	nowPlayingLabel.Name = "NowPlayingLabel"
	nowPlayingLabel.Size = UDim2.new(1, 0, 0.04, 0)
	nowPlayingLabel.Position = UDim2.new(0, 0, 0.08, 0)
	nowPlayingLabel.BackgroundTransparency = 1
	nowPlayingLabel.Text = "Now Playing: None"
	nowPlayingLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	nowPlayingLabel.Font = Enum.Font.Gotham
	nowPlayingLabel.TextSize = 12
	nowPlayingLabel.TextXAlignment = Enum.TextXAlignment.Left
	nowPlayingLabel.ZIndex = ui.ZIndex + 1
	nowPlayingLabel.Parent = ui

	-- Time label
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, 0, 0.03, 0)
	timeLabel.Position = UDim2.new(0, 0, 0.125, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "0:00 / 0:00"
	timeLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextSize = 10
	timeLabel.TextXAlignment = Enum.TextXAlignment.Center
	timeLabel.ZIndex = ui.ZIndex + 1
	timeLabel.Parent = ui

	-- Seek Bar (Progress)
	local seekBarBg = Instance.new("Frame")
	seekBarBg.Name = "SeekBarBg"
	seekBarBg.Size = UDim2.new(0.9, 0, 0.015, 0)
	seekBarBg.Position = UDim2.new(0.05, 0, 0.16, 0)
	seekBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	seekBarBg.ZIndex = ui.ZIndex + 1
	seekBarBg.Parent = ui

	local seekBarCorner = Instance.new("UICorner")
	seekBarCorner.CornerRadius = UDim.new(1, 0)
	seekBarCorner.Parent = seekBarBg

	local seekBarFill = Instance.new("Frame")
	seekBarFill.Name = "SeekBarFill"
	seekBarFill.Size = UDim2.new(0, 0, 1, 0)
	seekBarFill.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
	seekBarFill.ZIndex = ui.ZIndex + 2
	seekBarFill.Parent = seekBarBg

	local seekBarFillCorner = Instance.new("UICorner")
	seekBarFillCorner.CornerRadius = UDim.new(1, 0)
	seekBarFillCorner.Parent = seekBarFill

	-- Control Buttons
	local controlsFrame = Instance.new("Frame")
	controlsFrame.Name = "ControlsFrame"
	controlsFrame.Size = UDim2.new(1, 0, 0.08, 0)
	controlsFrame.Position = UDim2.new(0, 0, 0.185, 0)
	controlsFrame.BackgroundTransparency = 1
	controlsFrame.ZIndex = ui.ZIndex + 1
	controlsFrame.Parent = ui

	-- Previous Button
	local prevBtn = Instance.new("TextButton")
	prevBtn.Name = "PrevButton"
	prevBtn.Size = UDim2.new(0, 40, 0, 40)
	prevBtn.Position = UDim2.new(0.28, 0, 0.5, -20)
	prevBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	prevBtn.Text = "⏮"
	prevBtn.TextColor3 = Color3.new(1, 1, 1)
	prevBtn.Font = Enum.Font.GothamBold
	prevBtn.TextSize = 18
	prevBtn.ZIndex = ui.ZIndex + 2
	prevBtn.Parent = controlsFrame

	local prevCorner = Instance.new("UICorner")
	prevCorner.CornerRadius = UDim.new(1, 0)
	prevCorner.Parent = prevBtn

	-- Play/Pause Button
	local playBtn = Instance.new("TextButton")
	playBtn.Name = "PlayButton"
	playBtn.Size = UDim2.new(0, 50, 0, 50)
	playBtn.Position = UDim2.new(0.5, -25, 0.5, -25)
	playBtn.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
	playBtn.Text = "▶"
	playBtn.TextColor3 = Color3.new(0, 0, 0)
	playBtn.Font = Enum.Font.GothamBold
	playBtn.TextSize = 22
	playBtn.ZIndex = ui.ZIndex + 2
	playBtn.Parent = controlsFrame

	local playCorner = Instance.new("UICorner")
	playCorner.CornerRadius = UDim.new(1, 0)
	playCorner.Parent = playBtn

	-- Next Button
	local nextBtn = Instance.new("TextButton")
	nextBtn.Name = "NextButton"
	nextBtn.Size = UDim2.new(0, 40, 0, 40)
	nextBtn.Position = UDim2.new(0.72, 0, 0.5, -20)
	nextBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	nextBtn.Text = "⏭"
	nextBtn.TextColor3 = Color3.new(1, 1, 1)
	nextBtn.Font = Enum.Font.GothamBold
	nextBtn.TextSize = 18
	nextBtn.ZIndex = ui.ZIndex + 2
	nextBtn.Parent = controlsFrame

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(1, 0)
	nextCorner.Parent = nextBtn

	-- Loop Toggle
	local loopBtn = Instance.new("TextButton")
	loopBtn.Name = "LoopButton"
	loopBtn.Size = UDim2.new(0, 60, 0, 25)
	loopBtn.Position = UDim2.new(0.85, 0, 0.5, -12)
	loopBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	loopBtn.Text = "🔁 Off"
	loopBtn.TextColor3 = Color3.new(1, 1, 1)
	loopBtn.Font = Enum.Font.GothamBold
	loopBtn.TextSize = 10
	loopBtn.ZIndex = ui.ZIndex + 2
	loopBtn.Parent = controlsFrame

	local loopCorner = Instance.new("UICorner")
	loopCorner.CornerRadius = UDim.new(0, 6)
	loopCorner.Parent = loopBtn

	-- Search Bar
	local searchFrame = Instance.new("Frame")
	searchFrame.Size = UDim2.new(0.8, 0, 0.06, 0)
	searchFrame.Position = UDim2.new(0.1, 0, 0.28, 0)
	searchFrame.BackgroundTransparency = 1
	searchFrame.ZIndex = ui.ZIndex + 1
	searchFrame.Parent = ui

	local searchBar = Instance.new("TextBox")
	searchBar.Name = "SearchBar"
	searchBar.Size = UDim2.new(1, -45, 1, 0)
	searchBar.Position = UDim2.new(0, 0, 0, 0)
	searchBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	searchBar.TextColor3 = Color3.new(1, 1, 1)
	searchBar.PlaceholderText = "Search or enter Asset ID..."
	searchBar.Font = Enum.Font.Gotham
	searchBar.TextSize = 12
	searchBar.TextXAlignment = Enum.TextXAlignment.Left
	searchBar.ZIndex = ui.ZIndex + 2
	searchBar.Parent = searchFrame

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 8)
	searchCorner.Parent = searchBar

	-- Add Button (+)
	local addBtn = Instance.new("TextButton")
	addBtn.Name = "AddButton"
	addBtn.Size = UDim2.new(0, 35, 0, 35)
	addBtn.Position = UDim2.new(1, -35, 0.5, -17)
	addBtn.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
	addBtn.Text = "+"
	addBtn.TextColor3 = Color3.new(0, 0, 0)
	addBtn.Font = Enum.Font.GothamBold
	addBtn.TextSize = 20
	addBtn.ZIndex = ui.ZIndex + 2
	addBtn.Parent = searchFrame

	local addCorner = Instance.new("UICorner")
	addCorner.CornerRadius = UDim.new(1, 0)
	addCorner.Parent = addBtn

	-- Playlist
	local playlistLabel = Instance.new("TextLabel")
	playlistLabel.Size = UDim2.new(1, 0, 0.03, 0)
	playlistLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
	playlistLabel.BackgroundTransparency = 1
	playlistLabel.Text = "Playlist"
	playlistLabel.TextColor3 = Color3.new(1, 1, 1)
	playlistLabel.Font = Enum.Font.GothamBold
	playlistLabel.TextSize = 12
	playlistLabel.TextXAlignment = Enum.TextXAlignment.Left
	playlistLabel.ZIndex = ui.ZIndex + 1
	playlistLabel.Parent = ui

	local playlist = Instance.new("ScrollingFrame")
	playlist.Name = "Playlist"
	playlist.Size = UDim2.new(0.9, 0, 0.55, 0)
	playlist.Position = UDim2.new(0.05, 0, 0.39, 0)
	playlist.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	playlist.BackgroundTransparency = 0.3
	playlist.CanvasSize = UDim2.new(0, 0, 0, 0)
	playlist.ScrollBarThickness = 5
	playlist.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
	playlist.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playlist.ZIndex = ui.ZIndex + 1
	playlist.Parent = ui

	local playlistCorner = Instance.new("UICorner")
	playlistCorner.CornerRadius = UDim.new(0, 8)
	playlistCorner.Parent = playlist

	local playlistLayout = Instance.new("UIListLayout")
	playlistLayout.Padding = UDim.new(0, 3)
	playlistLayout.SortOrder = Enum.SortOrder.Name
	playlistLayout.Parent = playlist

	-- Volume Control
	local volumeLabel = Instance.new("TextLabel")
	volumeLabel.Size = UDim2.new(0.1, 0, 0.03, 0)
	volumeLabel.Position = UDim2.new(0.05, 0, 0.95, 0)
	volumeLabel.BackgroundTransparency = 1
	volumeLabel.Text = "🔊"
	volumeLabel.TextColor3 = Color3.new(1, 1, 1)
	volumeLabel.Font = Enum.Font.Gotham
	volumeLabel.TextSize = 14
	volumeLabel.TextXAlignment = Enum.TextXAlignment.Left
	volumeLabel.ZIndex = ui.ZIndex + 1
	volumeLabel.Parent = ui

	local volumeBarBg = Instance.new("Frame")
	volumeBarBg.Name = "VolumeBarBg"
	volumeBarBg.Size = UDim2.new(0.3, 0, 0.015, 0)
	volumeBarBg.Position = UDim2.new(0.15, 0, 0.957, 0)
	volumeBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	volumeBarBg.ZIndex = ui.ZIndex + 1
	volumeBarBg.Parent = ui

	local volCorner = Instance.new("UICorner")
	volCorner.CornerRadius = UDim.new(1, 0)
	volCorner.Parent = volumeBarBg

	local volumeBarFill = Instance.new("Frame")
	volumeBarFill.Name = "VolumeBarFill"
	volumeBarFill.Size = UDim2.new(0.5, 0, 1, 0)
	volumeBarFill.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
	volumeBarFill.ZIndex = ui.ZIndex + 2
	volumeBarFill.Parent = volumeBarBg

	local volFillCorner = Instance.new("UICorner")
	volFillCorner.CornerRadius = UDim.new(1, 0)
	volFillCorner.Parent = volumeBarFill

	-- Store references for AI logic
	local musicData = Instance.new("Folder")
	musicData.Name = "MusicData"
	musicData.Parent = app

	-- ======== REGISTER THE APP ========
	local appEntry = __AppsLaunchArgFolder:FindFirstChild(AppName)
	if not appEntry then
		appEntry = Instance.new("StringValue")
		appEntry.Name = AppName
		appEntry.Parent = __AppsLaunchArgFolder
	end
	appEntry.Value = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/ZolinMusic.lua"

	print(AppName .. " package installed successfully!")
end

__AppPackage.Install()
