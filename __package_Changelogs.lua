-- ============================================================
-- Changelogs Package Installer
-- ============================================================
local __AppPackage = {}
function __AppPackage.Install()
	local AppName = "Changelogs"
	local ZolinOS = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS")
	if not ZolinOS then warn("ZolinOS not found"); return end
	local replicatedWindow = ZolinOS:FindFirstChild("ReplicatedWindow_Sys")
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
		warn(tostring(AppName) .." already installed")
		return
	end

	-- ======== BUILD APP FRAME ========
	local app = Instance.new("Frame")
	app.Name = AppName
	app.AnchorPoint = Vector2.new(0.5, 0.5)
	app.BackgroundTransparency = 0
	app.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	app.Size = UDim2.new(1, 0, 1, 0)
	app.Position = UDim2.new(0.5, 0, 0.5, 0)
	app.ZIndex = 6
	app.Parent = replicatedWindow
	app.Visible = false

	local dataFolder = Instance.new("Folder")
	dataFolder.Name = "Data"
	dataFolder.Parent = app

	Instance.new("StringValue", dataFolder).Name = "Description"
	dataFolder.Description.Value = "See what's new in ZolinOS"

	Instance.new("StringValue", dataFolder).Name = "Version"
	dataFolder.Version.Value = "1.1"

	local ui = Instance.new("Frame")
	ui.Name = "UI"
	ui.AnchorPoint = Vector2.new(0.5, 0.5)
	ui.Position = UDim2.new(0.5, 0, 0.495, 0)
	ui.Size = UDim2.new(1, 0, 0.89, 0)
	ui.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	ui.BackgroundTransparency = 0.2
	ui.ZIndex = app.ZIndex - 1
	ui.Parent = app

	-- Preview (recent apps)
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
	previewLabel.Text = "Changelogs"
	previewLabel.Parent = preview

	local previewIcon = Instance.new("ImageLabel")
	previewIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	previewIcon.AutomaticSize = Enum.AutomaticSize.XY
	previewIcon.BackgroundTransparency = 1
	previewIcon.Position = UDim2.new(0.9, 0, 0.5, 0)
	previewIcon.Size = UDim2.new(0, 39, 0, 39)
	previewIcon.Image = "rbxassetid://12905435514" -- a generic info icon
	previewIcon.ScaleType = Enum.ScaleType.Fit
	previewIcon.Parent = preview

	-- ====== Changelog Content ======
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.06, 0)
	title.Position = UDim2.new(0, 0, 0.01, 0)
	title.BackgroundTransparency = 1
	title.Text = "📜 "..tostring(AppName);
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.ZIndex = ui.ZIndex + 1
	title.Parent = ui

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ChangelogScroll"
	scrollFrame.Size = UDim2.new(1, -10, 0.85, 0)
	scrollFrame.Position = UDim2.new(0, 5, 0.08, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)  -- will be auto-sized later
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ZIndex = ui.ZIndex + 1
	scrollFrame.Parent = ui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scrollFrame

	-- We'll store the changelog data as a StringValue inside the app, so it's easy to edit.
	local changelogData = Instance.new("StringValue")
	changelogData.Name = "ChangelogText"
	changelogData.Value = [[
v1.12 (Current Version | 06/17/2026):
• Added ZolinInstaller
• Fixed bugs and improved performance
• New Zolin Modifier app

v1.11 (06/15/2026):
• Added Music Player
• Improved AI in PlayAsAI

v1.10 (06/10/2026):
• Initial release of ZolinOS
• System apps: Settings, Wallpaper
]]
	changelogData.Parent = dataFolder

	-- ======== REGISTER THE APP ========
	local appEntry = __AppsLaunchArgFolder:FindFirstChild(AppName)
	if not appEntry then
		appEntry = Instance.new("StringValue")
		appEntry.Name = AppName
		appEntry.Parent = __AppsLaunchArgFolder
	end
	-- The logic script URL (we'll provide the logic separately)
	appEntry.Value = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/main/ChangelogsLogic.lua"

	print(AppName .. " package installed successfully!")
end

__AppPackage.Install()
