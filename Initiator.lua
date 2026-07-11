local v1 = {};
v1.ver = "1.3.3" -- versionOS

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
local function createUIStroke(parent, name, color, thickness, transparency, zIndex)
	local stroke = Instance.new("UIStroke")
	stroke.Name = name
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	stroke.ZIndex = zIndex
	stroke.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

local function createUICorner(parent, name, radius)
	local corner = Instance.new("UICorner")
	corner.Name = name
	corner.CornerRadius = radius
	corner.Parent = parent
	return corner
end

local function createUIScale(parent, name, scale)
	local uiScale = Instance.new("UIScale")
	uiScale.Name = name
	uiScale.Scale = scale
	uiScale.Parent = parent
	return uiScale
end

-- Global references to be used across chunks
local MainUI = nil
local __ScreenFrame = nil
local __ZolinDesktop = nil
local __DesktopScreenFrame = nil
local BuildVersion = nil

-- ============================================
-- CHUNK 1: __ScreenFrame & Basic UI
-- ============================================
local function createChunk1()
	-- UIStroke
	createUIStroke(__ScreenFrame, "UIStroke", Color3.fromRGB(33, 33, 33), 14.8, 0.67, 3)

	-- UICorner
	createUICorner(__ScreenFrame, "UICorner", UDim.new(0, 8))

	-- UIScale
	createUIScale(__ScreenFrame, "UIScale", 1)

	-- Applications Folder
	local Applications = Instance.new("Folder")
	Applications.Name = "Applications"
	Applications.Parent = __ScreenFrame

	-- Wallpaper
	local Wallpaper = Instance.new("ImageLabel")
	Wallpaper.Name = "Wallpaper"
	Wallpaper.AnchorPoint = Vector2.new(0.5, 0.5)
	Wallpaper.Position = UDim2.new(0.5, 0, 0.5, 0)
	Wallpaper.Size = UDim2.new(1, 0, 1, 0)
	Wallpaper.BackgroundTransparency = 0
	Wallpaper.Image = "rbxassetid://2387794684"
	Wallpaper.ScaleType = Enum.ScaleType.Stretch
	Wallpaper.ZIndex = 2
	Wallpaper.ClipsDescendants = false
	Wallpaper.Parent = __ScreenFrame
	Wallpaper.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end

-- ============================================
-- CHUNK 2: BackgroundPage
-- ============================================
local function createChunk2()
	local BackgroundPage = Instance.new("Frame")
	BackgroundPage.Name = "BackgroundPage"
	BackgroundPage.AnchorPoint = Vector2.new(0.5, 0.5)
	BackgroundPage.Position = UDim2.new(0.5, 0, 0.47, 0)
	BackgroundPage.Size = UDim2.new(1, 0, 0.94, 0)
	BackgroundPage.BackgroundTransparency = 0.15
	BackgroundPage.BackgroundColor3 = Color3.fromRGB(48, 87, 126)
	BackgroundPage.ZIndex = 5
	BackgroundPage.ClipsDescendants = true
	BackgroundPage.Visible = false
	BackgroundPage.Parent = __ScreenFrame

	createUICorner(BackgroundPage, "UICorner2", UDim.new(0, 8))

	local FrameNote = Instance.new("Frame")
	FrameNote.Name = "FrameNote"
	FrameNote.AnchorPoint = Vector2.new(0.5, 0.5)
	FrameNote.Position = UDim2.new(0.5, 0, 0.48, 0)
	FrameNote.Size = UDim2.new(0.35, 0, 0.5, 0)
	FrameNote.BackgroundTransparency = 1
	FrameNote.ZIndex = 6
	FrameNote.ClipsDescendants = false
	FrameNote.Visible = true
	FrameNote.Parent = BackgroundPage

	createUICorner(FrameNote, "UICorner3", UDim.new(0, 15))

	local ImageLabel = Instance.new("ImageLabel")
	ImageLabel.Name = "ImageLabel"
	ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	ImageLabel.Position = UDim2.new(0.5, 0, 0.3, 0)
	ImageLabel.Size = UDim2.new(0.35, 0, 0.5, 0)
	ImageLabel.BackgroundTransparency = 1
	ImageLabel.ZIndex = 6
	ImageLabel.Image = "rbxassetid://99708222755000"
	ImageLabel.ScaleType = Enum.ScaleType.Fit
	ImageLabel.ClipsDescendants = false
	ImageLabel.Visible = true
	ImageLabel.Parent = FrameNote

	createUICorner(ImageLabel, "UICorner4", UDim.new(0, 11))

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Name = "TextLabel"
	TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	TextLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
	TextLabel.Size = UDim2.new(0.3, 0, 0.1, 0)
	TextLabel.BackgroundTransparency = 1
	TextLabel.ZIndex = 6
	TextLabel.Font = Enum.Font.SourceSansBold
	TextLabel.Text = "No recent Items"
	TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.TextSize = 14
	TextLabel.TextWrapped = true
	TextLabel.TextXAlignment = Enum.TextXAlignment.Center
	TextLabel.TextYAlignment = Enum.TextYAlignment.Center
	TextLabel.RichText = true
	TextLabel.TextScaled = true
	TextLabel.ClipsDescendants = false
	TextLabel.Visible = true
	TextLabel.Parent = FrameNote

	local ScrollingApps = Instance.new("ScrollingFrame")
	ScrollingApps.Name = "ScrollingApps"
	ScrollingApps.AnchorPoint = Vector2.new(0.5, 0.5)
	ScrollingApps.Position = UDim2.new(0.5, 0, 0.5, 0)
	ScrollingApps.Size = UDim2.new(1, 0, 1, 0)
	ScrollingApps.BackgroundTransparency = 0.85
	ScrollingApps.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ScrollingApps.ZIndex = 6
	ScrollingApps.ClipsDescendants = true
	ScrollingApps.Visible = false
	ScrollingApps.AutomaticCanvasSize = Enum.AutomaticSize.XY
	ScrollingApps.ScrollBarThickness = 12
	ScrollingApps.CanvasPosition = Vector2.new(0, 0)
	ScrollingApps.CanvasSize = UDim2.new(1, 0, 1, 0)
	ScrollingApps.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	ScrollingApps.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	ScrollingApps.ScrollingDirection = Enum.ScrollingDirection.X
	ScrollingApps.ScrollingEnabled = true
	ScrollingApps.VerticalScrollBarInset = Enum.ScrollBarInset.None
	ScrollingApps.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
	ScrollingApps.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	ScrollingApps.Parent = BackgroundPage

	createUICorner(ScrollingApps, "UICorner5", UDim.new(0, 7))

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.SortOrder = Enum.SortOrder.Name
	UIListLayout.Padding = UDim.new(0.2, 0)
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
	UIListLayout.VerticalFlex = Enum.UIFlexAlignment.None
	UIListLayout.Parent = ScrollingApps

	local BackUI = Instance.new("TextButton")
	BackUI.Name = "BackUI"
	BackUI.AnchorPoint = Vector2.new(0.5, 0.5)
	BackUI.Position = UDim2.new(0.5, 0, 0.5, 0)
	BackUI.Size = UDim2.new(1, 0, 0.95, 0)
	BackUI.BackgroundTransparency = 0.9
	BackUI.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BackUI.ZIndex = 4
	BackUI.Visible = true
	BackUI.Text = ""
	BackUI.AutoButtonColor = false
	BackUI.Parent = BackgroundPage

	local ClearAll_Button = Instance.new("TextButton")
	ClearAll_Button.Name = "ClearAll_Button"
	ClearAll_Button.AnchorPoint = Vector2.new(0.5, 0.5)
	ClearAll_Button.Position = UDim2.new(0.5, 0, 0.94, 0)
	ClearAll_Button.Size = UDim2.new(0.07, 0, 0.05, 0)
	ClearAll_Button.BackgroundTransparency = 0
	ClearAll_Button.BackgroundColor3 = Color3.fromRGB(66, 122, 173)
	ClearAll_Button.ZIndex = 7
	ClearAll_Button.Visible = true
	ClearAll_Button.Font = Enum.Font.Oswald
	ClearAll_Button.Text = "Clear All"
	ClearAll_Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	ClearAll_Button.TextScaled = true
	ClearAll_Button.TextWrapped = true
	ClearAll_Button.TextYAlignment = Enum.TextYAlignment.Center
	ClearAll_Button.TextXAlignment = Enum.TextXAlignment.Center
	ClearAll_Button.AutoButtonColor = true
	ClearAll_Button.Parent = BackgroundPage

	createUICorner(ClearAll_Button, "UICorner6", UDim.new(0.35, 0))
end

-- ============================================
-- CHUNK 3: HomeScreenScroller
-- ============================================
local function createChunk3()
	local HomeScreenScroller = Instance.new("ScrollingFrame")
	HomeScreenScroller.Name = "HomeScreenScroller"
	HomeScreenScroller.AnchorPoint = Vector2.new(0.5, 0.5)
	HomeScreenScroller.Position = UDim2.new(0.5, 0, 0.486, 0)
	HomeScreenScroller.Size = UDim2.new(1, 0, 0.873, 0)
	HomeScreenScroller.BackgroundTransparency = 1
	HomeScreenScroller.ZIndex = 3
	HomeScreenScroller.Visible = true
	HomeScreenScroller.ScrollingDirection = Enum.ScrollingDirection.X
	HomeScreenScroller.AutomaticCanvasSize = Enum.AutomaticSize.XY
	HomeScreenScroller.CanvasSize = UDim2.new(1, 1, 0, 0)
	HomeScreenScroller.ScrollBarImageTransparency = 1
	HomeScreenScroller.ScrollBarThickness = 0
	HomeScreenScroller.ScrollingEnabled = true
	HomeScreenScroller.Active = true
	HomeScreenScroller.VerticalScrollBarInset = Enum.ScrollBarInset.None
	HomeScreenScroller.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	HomeScreenScroller.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	HomeScreenScroller.ElasticBehavior = Enum.ElasticBehavior.Always
	HomeScreenScroller.Parent = __ScreenFrame

	local UIListLayout2 = Instance.new("UIListLayout")
	UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout2.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout2.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout2.HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly
	UIListLayout2.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	UIListLayout2.VerticalFlex = Enum.UIFlexAlignment.None
	UIListLayout2.Padding = UDim.new(0.05, 0)
	UIListLayout2.Wraps = true
	UIListLayout2.Parent = HomeScreenScroller
end

-- ============================================
-- CHUNK 4: NavigationBar
-- ============================================
local function createChunk4()
	local NavigationBar = Instance.new("Frame")
	NavigationBar.Name = "NavigationBar"
	NavigationBar.AnchorPoint = Vector2.new(0.5, 0.5)
	NavigationBar.Position = UDim2.new(0.5, 0, 0.97, 0)
	NavigationBar.Size = UDim2.new(1, 0, 0.06, 0)
	NavigationBar.BackgroundTransparency = 0.87
	NavigationBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NavigationBar.ZIndex = 9996
	NavigationBar.Visible = true
	NavigationBar.Parent = __ScreenFrame

	local UIListLayout3 = Instance.new("UIListLayout")
	UIListLayout3.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout3.FillDirection = Enum.FillDirection.Vertical
	UIListLayout3.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout3.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout3.HorizontalFlex = Enum.UIFlexAlignment.None
	UIListLayout3.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	UIListLayout3.VerticalFlex = Enum.UIFlexAlignment.None
	UIListLayout3.Padding = UDim.new(0.4, 0)
	UIListLayout3.Wraps = true
	UIListLayout3.Parent = NavigationBar

	local Background = Instance.new("ImageButton")
	Background.Name = "Background"
	Background.AnchorPoint = Vector2.new(0.5, 0.5)
	Background.Size = UDim2.new(0.08, 0, 0.9, 0)
	Background.Image = "rbxassetid://14657415531"
	Background.ImageTransparency = 0.1
	Background.BackgroundColor3 = Color3.fromRGB(231, 231, 231)
	Background.BackgroundTransparency = 1
	Background.ScaleType = Enum.ScaleType.Fit
	Background.LayoutOrder = -1
	Background.ZIndex = 9997
	Background.Visible = true
	Background.Parent = NavigationBar

	createUICorner(Background, "UICorner7", UDim.new(1, 0))

	local Exit = Instance.new("ImageButton")
	Exit.Name = "Exit"
	Exit.AnchorPoint = Vector2.new(0.5, 0.5)
	Exit.Size = UDim2.new(0.08, 0, 0.9, 0)
	Exit.Image = "rbxassetid://99851851"
	Exit.ImageTransparency = 0.1
	Exit.BackgroundColor3 = Color3.fromRGB(231, 231, 231)
	Exit.BackgroundTransparency = 1
	Exit.ScaleType = Enum.ScaleType.Fit
	Exit.LayoutOrder = -2
	Exit.ZIndex = 9997
	Exit.Visible = true
	Exit.Parent = NavigationBar

	createUICorner(Exit, "UICorner8", UDim.new(1, 0))
end

-- ============================================
-- CHUNK 5: NotificationBar
-- ============================================
local function createChunk5()
	local NotificationBar = Instance.new("Frame")
	NotificationBar.Name = "NotificationBar"
	NotificationBar.AnchorPoint = Vector2.new(0.5, 0.5)
	NotificationBar.Position = UDim2.new(0.5, 0, 0.03, -5)
	NotificationBar.Size = UDim2.new(1, 0, 0.05, 0)
	NotificationBar.BackgroundTransparency = 0.5
	NotificationBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	NotificationBar.ZIndex = 9996
	NotificationBar.Visible = true
	NotificationBar.Parent = __ScreenFrame

	local NotificationRankList = Instance.new("Frame")
	NotificationRankList.Name = "NotificationRankList"
	NotificationRankList.AnchorPoint = Vector2.new(0, 0.5)
	NotificationRankList.Position = UDim2.new(0, 0, 0.5, 0)
	NotificationRankList.Size = UDim2.new(0.6, 0, 1, 0)
	NotificationRankList.BackgroundTransparency = 1
	NotificationRankList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NotificationRankList.ZIndex = 9998
	NotificationRankList.Visible = true
	NotificationRankList.Parent = NotificationBar

	local UIListLayout4 = Instance.new("UIListLayout")
	UIListLayout4.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout4.Padding = UDim.new(0.01, 0)
	UIListLayout4.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout4.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout4.HorizontalAlignment = Enum.HorizontalAlignment.Left
	UIListLayout4.VerticalFlex = Enum.UIFlexAlignment.None
	UIListLayout4.HorizontalFlex = Enum.UIFlexAlignment.None
	UIListLayout4.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	UIListLayout4.Parent = NotificationRankList

	local TimeLabel = Instance.new("TextLabel")
	TimeLabel.Name = "TimeLabel"
	TimeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	TimeLabel.Size = UDim2.new(0.1, 0, 1, 0)
	TimeLabel.BackgroundTransparency = 1
	TimeLabel.ZIndex = 9997
	TimeLabel.TextScaled = true
	TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TimeLabel.Text = "00:00 AM"
	TimeLabel.RichText = true
	TimeLabel.Font = Enum.Font.Kalam
	TimeLabel.TextWrapped = true
	TimeLabel.TextSize = 14
	TimeLabel.Visible = true
	TimeLabel.Parent = NotificationRankList
	TimeLabel:SetAttribute("Clock", true)
end

-- ============================================
-- CHUNK 6: VolumeFrame
-- ============================================
local function createChunk6()
	local VolumeFrame = Instance.new("Frame")
	VolumeFrame.Name = "VolumeFrame"
	VolumeFrame.AnchorPoint = Vector2.new(1, 0.5)
	VolumeFrame.Position = UDim2.new(1, -5, 0.465, 0)
	VolumeFrame.Size = UDim2.new(0.028, 0, 0.617, 0)
	VolumeFrame.BackgroundColor3 = Color3.fromRGB(31, 35, 35)
	VolumeFrame.BackgroundTransparency = 0.06
	VolumeFrame.Visible = false
	VolumeFrame.ZIndex = 100
	VolumeFrame.Parent = __ScreenFrame

	createUICorner(VolumeFrame, "UICorner9", UDim.new(0.25, 0))

	local Fill = Instance.new("Frame")
	Fill.Name = "Fill"
	Fill.AnchorPoint = Vector2.new(0.5, 0)
	Fill.Position = UDim2.new(0.493, 0, 0.75, 0)
	Fill.Size = UDim2.new(0.602, 0, 0, 0)
	Fill.ZIndex = 102
	Fill.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
	Fill.Parent = VolumeFrame

	createUICorner(Fill, "UICorner10", UDim.new(0.1, 0))

	local OutlineStyle = Instance.new("Frame")
	OutlineStyle.Name = "OutlineStyle"
	OutlineStyle.AnchorPoint = Vector2.new(0.5, 0.5)
	OutlineStyle.Position = UDim2.new(0.493, 0, 0.395, 0)
	OutlineStyle.Size = UDim2.new(0.602, 0, 0.709, 0)
	OutlineStyle.ZIndex = 101
	OutlineStyle.BackgroundColor3 = Color3.fromRGB(78, 100, 98)
	OutlineStyle.Parent = VolumeFrame

	createUICorner(OutlineStyle, "UICorner11", UDim.new(0.25, 0))

	local MoreOptions = Instance.new("ImageButton")
	MoreOptions.Name = "MoreOptions"
	MoreOptions.AnchorPoint = Vector2.new(0.5, 0.5)
	MoreOptions.Position = UDim2.new(0.5, 0, 0.962, 0)
	MoreOptions.Size = UDim2.new(0, 59, 0, 40)
	MoreOptions.ZIndex = 100
	MoreOptions.BackgroundColor3 = Color3.fromRGB(31, 35, 35)
	MoreOptions.ImageColor3 = Color3.fromRGB(59, 214, 201)
	MoreOptions.BackgroundTransparency = 1
	MoreOptions.Visible = true
	MoreOptions.Image = "rbxassetid://127075876244307"
	MoreOptions.ScaleType = Enum.ScaleType.Stretch
	MoreOptions.Parent = VolumeFrame

	createUICorner(MoreOptions, "UICorner12", UDim.new(0.3, 0))

	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint.Parent = MoreOptions
	UIAspectRatioConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint.AspectRatio = 1

	local VolumeIconButton = Instance.new("ImageButton")
	VolumeIconButton.Name = "VolumeIconButton"
	VolumeIconButton.AnchorPoint = Vector2.new(0.5, 0.5)
	VolumeIconButton.Position = UDim2.new(0.5, 0, 0.854, 0)
	VolumeIconButton.Size = UDim2.new(0.688, 0, 0.121, 0)
	VolumeIconButton.ZIndex = 100
	VolumeIconButton.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
	VolumeIconButton.BackgroundTransparency = 0.24
	VolumeIconButton.Image = "rbxassetid://470648244"
	VolumeIconButton.ScaleType = Enum.ScaleType.Fit
	VolumeIconButton.Visible = true
	VolumeIconButton.Parent = VolumeFrame

	createUICorner(VolumeIconButton, "UICorner13", UDim.new(0.3, 0))

	local UIAspectRatioConstraint2 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint2.Parent = VolumeIconButton
	UIAspectRatioConstraint2.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint2.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint2.AspectRatio = 1
end

-- ============================================
-- CHUNK 7: VolumeStyleOptionsFrame
-- ============================================
local function createChunk7()
	local VolumeStyleOptionsFrame = Instance.new("Frame")
	VolumeStyleOptionsFrame.Name = "VolumeStyleOptionsFrame"
	VolumeStyleOptionsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	VolumeStyleOptionsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	VolumeStyleOptionsFrame.Size = UDim2.new(1, 0, 1, 0)
	VolumeStyleOptionsFrame.ZIndex = 11
	VolumeStyleOptionsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	VolumeStyleOptionsFrame.BackgroundTransparency = 1
	VolumeStyleOptionsFrame.Visible = false
	VolumeStyleOptionsFrame.Parent = __ScreenFrame

	local Assets = Instance.new("Folder")
	Assets.Name = "Assets"
	Assets.Parent = VolumeStyleOptionsFrame

	local FrameTemplate = Instance.new("Frame")
	FrameTemplate.Name = "FrameTemplate"
	FrameTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	FrameTemplate.Position = UDim2.new(0.5, 0, 0.349, 0)
	FrameTemplate.Size = UDim2.new(0.9, 0, 0.207, 0)
	FrameTemplate.ZIndex = 12
	FrameTemplate.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	FrameTemplate.BackgroundTransparency = 0
	FrameTemplate.Visible = false
	FrameTemplate.Parent = Assets

	createUICorner(FrameTemplate, "UICorner14", UDim.new(0, 15))

	local UIStroke2 = Instance.new("UIStroke")
	UIStroke2.Name = "UIStroke"
	UIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke2.Color = Color3.fromRGB(255, 255, 255)
	UIStroke2.Thickness = 1.3
	UIStroke2.Transparency = 0
	UIStroke2.LineJoinMode = Enum.LineJoinMode.Round
	UIStroke2.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	UIStroke2.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	UIStroke2.ZIndex = 1
	UIStroke2.Parent = FrameTemplate

	local UIAspectRatioConstraint3 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint3.Parent = FrameTemplate
	UIAspectRatioConstraint3.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint3.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint3.AspectRatio = 13.263

	local OutlineStyle2 = Instance.new("Frame")
	OutlineStyle2.Name = "OutlineStyle"
	OutlineStyle2.AnchorPoint = Vector2.new(0, 0)
	OutlineStyle2.Position = UDim2.new(0.073, 0, 0.34, 0)
	OutlineStyle2.Size = UDim2.new(0.914, 0, 0.32, 0)
	OutlineStyle2.ZIndex = 13
	OutlineStyle2.BackgroundColor3 = Color3.fromRGB(61, 61, 61)
	OutlineStyle2.BackgroundTransparency = 0
	OutlineStyle2.Visible = true
	OutlineStyle2.Parent = FrameTemplate

	createUICorner(OutlineStyle2, "UICorner15", UDim.new(0, 15))

	local UIAspectRatioConstraint4 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint4.Parent = OutlineStyle2
	UIAspectRatioConstraint4.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint4.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint4.AspectRatio = 37.935

	local Icon = Instance.new("ImageButton")
	Icon.Name = "Icon"
	Icon.AnchorPoint = Vector2.new(0, 0)
	Icon.Position = UDim2.new(0.007, 0, 0.134, 0)
	Icon.Size = UDim2.new(0.055, 0, 0.732, 0)
	Icon.ZIndex = 13
	Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Icon.BackgroundTransparency = 1
	Icon.Visible = true
	Icon.Parent = FrameTemplate

	createUICorner(Icon, "UICorner16", UDim.new(0, 15))

	local UIAspectRatioConstraint5 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint5.Parent = Icon
	UIAspectRatioConstraint5.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint5.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint5.AspectRatio = 1

	local Fill2 = Instance.new("Frame")
	Fill2.Name = "Fill"
	Fill2.AnchorPoint = Vector2.new(0, 0.5)
	Fill2.Position = UDim2.new(0.073, 0, 0.499, 0)
	Fill2.Size = UDim2.new(0, 0, 0, 30)
	Fill2.ZIndex = 14
	Fill2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Fill2.BackgroundTransparency = 0
	Fill2.Visible = true
	Fill2.Parent = FrameTemplate

	createUICorner(Fill2, "UICorner17", UDim.new(0, 15))

	local UI = Instance.new("Frame")
	UI.Name = "UI"
	UI.AnchorPoint = Vector2.new(0.5, 1)
	UI.Position = UDim2.new(0.5, 0, 0.94, 0)
	UI.Size = UDim2.new(0.7, 0, 0.536, 0)
	UI.ZIndex = 11
	UI.BackgroundColor3 = Color3.fromRGB(88, 88, 88)
	UI.BackgroundTransparency = 0
	UI.Visible = true
	UI.Parent = VolumeStyleOptionsFrame

	createUICorner(UI, "UICorner18", UDim.new(0.05, 0))

	local UIAspectRatioConstraint6 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint6.Parent = UI
	UIAspectRatioConstraint6.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint6.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint6.AspectRatio = 3.044

	local Media_Notif = Instance.new("TextLabel")
	Media_Notif.Name = "Media_Notif"
	Media_Notif.AnchorPoint = Vector2.new(0, 0)
	Media_Notif.Position = UDim2.new(0, 0, 0, 0)
	Media_Notif.Size = UDim2.new(1, 0, 0.143, 0)
	Media_Notif.ZIndex = 12
	Media_Notif.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Media_Notif.BackgroundTransparency = 1
	Media_Notif.LayoutOrder = -2
	Media_Notif.Visible = true
	Media_Notif.Font = Enum.Font.SourceSans
	Media_Notif.Text = "Media & Media & Notifications"
	Media_Notif.TextColor3 = Color3.fromRGB(255, 255, 255)
	Media_Notif.TextSize = 14
	Media_Notif.TextWrapped = true
	Media_Notif.TextXAlignment = Enum.TextXAlignment.Center
	Media_Notif.TextYAlignment = Enum.TextYAlignment.Bottom
	Media_Notif.RichText = true
	Media_Notif.TextScaled = true
	Media_Notif.Parent = UI

	local UIAspectRatioConstraint7 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint7.Parent = Media_Notif
	UIAspectRatioConstraint7.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint7.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint7.AspectRatio = 28.589

	createUICorner(Media_Notif, "UICorner19", UDim.new(0.3, 0))

	local UIListLayout2 = Instance.new("UIListLayout")
	UIListLayout2.Parent = UI
	UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout2.VerticalFlex = Enum.UIFlexAlignment.None
	UIListLayout2.Padding = UDim.new(0, 10)
	UIListLayout2.VerticalAlignment = Enum.VerticalAlignment.Top
	UIListLayout2.FillDirection = Enum.FillDirection.Vertical
	UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local blankFrame = Instance.new("Frame")
	blankFrame.Name = "BlankFrame"
	blankFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	blankFrame.Size = UDim2.new(1, 0, 0.063, 0)
	blankFrame.Position = UDim2.new(0.5, 0, 0.191, 0)
	blankFrame.ZIndex = 12
	blankFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	blankFrame.BackgroundTransparency = 1
	blankFrame.LayoutOrder = 0
	blankFrame.Visible = true
	blankFrame.Parent = UI

	local UIAspectRatioConstraint8 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint8.Parent = blankFrame
	UIAspectRatioConstraint8.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint8.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint8.AspectRatio = 18.095

	local underline = Instance.new("Frame")
	underline.Name = "underline"
	underline.AnchorPoint = Vector2.new(0.5, 0.5)
	underline.Size = UDim2.new(0.9, 0, 0.017, 0)
	underline.Position = UDim2.new(0.5, 0, 0.151, 0)
	underline.ZIndex = 12
	underline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	underline.BackgroundTransparency = 0
	underline.LayoutOrder = -1
	underline.Visible = true
	underline.Parent = UI

	createUICorner(underline, "UICorner20", UDim.new(1, 0))

	local UIAspectRatioConstraint9 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint9.Parent = underline
	UIAspectRatioConstraint9.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint9.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint9.AspectRatio = 213.408

	local DoneButton = Instance.new("TextButton")
	DoneButton.Name = "DoneButton"
	DoneButton.AnchorPoint = Vector2.new(0.5, 0.5)
	DoneButton.Size = UDim2.new(0.056, 0, 0.044, 0)
	DoneButton.Position = UDim2.new(0.808, 0, 1.889, 0)
	DoneButton.ZIndex = 13
	DoneButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	DoneButton.BackgroundTransparency = 0.25
	DoneButton.Visible = true
	DoneButton.Font = Enum.Font.SourceSans
	DoneButton.Text = "Done"
	DoneButton.TextColor3 = Color3.fromRGB(173, 222, 212)
	DoneButton.TextSize = 14
	DoneButton.TextScaled = true
	DoneButton.TextWrapped = true
	DoneButton.Parent = VolumeStyleOptionsFrame

	createUICorner(DoneButton, "UICorner21", UDim.new(0.1, 0))

	local UIAspectRatioConstraint10 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint10.Parent = DoneButton
	UIAspectRatioConstraint10.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint10.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint10.AspectRatio = 2.923

	local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	UITextSizeConstraint.Parent = DoneButton
	UITextSizeConstraint.MaxTextSize = 39
	UITextSizeConstraint.MinTextSize = 1
end

-- ============================================
-- CHUNK 8: __NotificationFrame
-- ============================================
local function createChunk8()
	local __NotificationFrame = Instance.new("Frame")
	__NotificationFrame.Name = "__NotificationFrame"
	__NotificationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	__NotificationFrame.Size = UDim2.new(1, 0, 0.943, 0)
	__NotificationFrame.Position = UDim2.new(0.5, 0, 0.472, 0)
	__NotificationFrame.ZIndex = 9995
	__NotificationFrame.BackgroundColor3 = Color3.fromRGB(16, 27, 45)
	__NotificationFrame.BackgroundTransparency = 1
	__NotificationFrame.Visible = true
	__NotificationFrame.Parent = __ScreenFrame

	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Name = "ScrollingFrame"
	ScrollFrame.AnchorPoint = Vector2.new(0, 0)
	ScrollFrame.Size = UDim2.new(1, 0, 0.997, 0)
	ScrollFrame.Position = UDim2.new(0, 0, 0, 0)
	ScrollFrame.ZIndex = 9996
	ScrollFrame.BackgroundTransparency = 0.25
	ScrollFrame.BackgroundColor3 = Color3.fromRGB(24, 35, 33)
	ScrollFrame.ClipsDescendants = true
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 1.5, 0)
	ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollFrame.ScrollBarThickness = 0
	ScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	ScrollFrame.ScrollBarImageTransparency = 1
	ScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	ScrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.None
	ScrollFrame.ElasticBehavior = Enum.ElasticBehavior.Always
	ScrollFrame.Parent = __NotificationFrame

	local UIListLayout5 = Instance.new("UIListLayout")
	UIListLayout5.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout5.Padding = UDim.new(0.03, 0)
	UIListLayout5.Wraps = true
	UIListLayout5.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout5.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout5.Parent = ScrollFrame

	local __CurrentNotificationSwipe = Instance.new("Frame")
	__CurrentNotificationSwipe.Name = "__CurrentNotificationSwipe"
	__CurrentNotificationSwipe.AnchorPoint = Vector2.new(0, 0)
	__CurrentNotificationSwipe.Size = UDim2.new(1, 0, 0.5, 0)
	__CurrentNotificationSwipe.Position = UDim2.new(0, 0, 0, 0)
	__CurrentNotificationSwipe.ZIndex = 9996
	__CurrentNotificationSwipe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	__CurrentNotificationSwipe.BackgroundTransparency = 1
	__CurrentNotificationSwipe.Visible = true
	__CurrentNotificationSwipe.LayoutOrder = 9999
	__CurrentNotificationSwipe.Parent = ScrollFrame

	local UIAspectRatioConstraint11 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint11.Parent = __CurrentNotificationSwipe
	UIAspectRatioConstraint11.AspectRatio = 4.957
	UIAspectRatioConstraint11.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint11.AspectType = Enum.AspectType.ScaleWithParentSize

	local __NotificationReplicaFullScreen = Instance.new("TextButton")
	__NotificationReplicaFullScreen.Name = "__NotificationReplicaFullScreen"
	__NotificationReplicaFullScreen.AnchorPoint = Vector2.new(0.5, 0.5)
	__NotificationReplicaFullScreen.Size = UDim2.new(1, 0, 0.7, 0)
	__NotificationReplicaFullScreen.Position = UDim2.new(0.5, 0, 0.4, 0)
	__NotificationReplicaFullScreen.ZIndex = 9999
	__NotificationReplicaFullScreen.BackgroundColor3 = Color3.fromRGB(35, 42, 48)
	__NotificationReplicaFullScreen.BackgroundTransparency = 0
	__NotificationReplicaFullScreen.Visible = true
	__NotificationReplicaFullScreen.LayoutOrder = -2
	__NotificationReplicaFullScreen.AutoButtonColor = false
	__NotificationReplicaFullScreen.Parent = ScrollFrame
	__NotificationReplicaFullScreen.TextScaled = true
	__NotificationReplicaFullScreen.Text = ""
	__NotificationReplicaFullScreen.TextColor3 = Color3.fromRGB(255, 255, 255)

	local UIAspectRatioConstraint12 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint12.Parent = __NotificationReplicaFullScreen
	UIAspectRatioConstraint12.AspectRatio = 3.54
	UIAspectRatioConstraint12.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint12.AspectType = Enum.AspectType.ScaleWithParentSize

	createUICorner(__NotificationReplicaFullScreen, "UICorner11", UDim.new(0.05, 0))

	local UI2 = Instance.new("Frame")
	UI2.Name = "UI"
	UI2.AnchorPoint = Vector2.new(0.5, 0.5)
	UI2.Size = UDim2.new(0.99, 0, 0.98, 0)
	UI2.Position = UDim2.new(0.5, 0, 0.5, 0)
	UI2.ZIndex = 9999
	UI2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	UI2.BackgroundTransparency = 1
	UI2.Visible = true
	UI2.Parent = __NotificationReplicaFullScreen

	local UIAspectRatioConstraint13 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint13.Parent = UI2
	UIAspectRatioConstraint13.AspectRatio = 3.577
	UIAspectRatioConstraint13.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint13.AspectType = Enum.AspectType.ScaleWithParentSize

	local UIListLayout6 = Instance.new("UIListLayout")
	UIListLayout6.Parent = UI2
	UIListLayout6.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout6.Padding = UDim.new(0.04, 0)
	UIListLayout6.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout6.VerticalAlignment = Enum.VerticalAlignment.Top
	UIListLayout6.HorizontalAlignment = Enum.HorizontalAlignment.Right
	UIListLayout6.VerticalFlex = Enum.UIFlexAlignment.SpaceBetween
	UIListLayout6.HorizontalFlex = Enum.UIFlexAlignment.None

	local DoNotDisturb = Instance.new("TextButton")
	DoNotDisturb.Name = "DoNotDisturb"
	DoNotDisturb.AnchorPoint = Vector2.new(0.5, 0.5)
	DoNotDisturb.Size = UDim2.new(0.099, 0, 0.115, 0)
	DoNotDisturb.Position = UDim2.new(0.446, 0, 0.399, 0)
	DoNotDisturb.ZIndex = 9999
	DoNotDisturb.BackgroundColor3 = Color3.fromRGB(50, 77, 83)
	DoNotDisturb.BackgroundTransparency = 0
	DoNotDisturb.TextScaled = true
	DoNotDisturb.Text = "Do Not Disturb"
	DoNotDisturb.Font = Enum.Font.SourceSansBold
	DoNotDisturb.TextColor3 = Color3.fromRGB(255, 255, 255)
	DoNotDisturb.RichText = true
	DoNotDisturb.Visible = true
	DoNotDisturb.Parent = UI2

	local UIAspectRatioConstraint14 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint14.Parent = DoNotDisturb
	UIAspectRatioConstraint14.AspectRatio = 3.077
	UIAspectRatioConstraint14.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatioConstraint14.AspectType = Enum.AspectType.ScaleWithParentSize

	createUICorner(DoNotDisturb, "UICorner12", UDim.new(0.25, 0))

	local UIStroke3 = Instance.new("UIStroke")
	UIStroke3.Parent = DoNotDisturb
	UIStroke3.Color = Color3.fromRGB(107, 173, 180)
	UIStroke3.Thickness = 1.6
	UIStroke3.LineJoinMode = Enum.LineJoinMode.Round
	UIStroke3.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	UIStroke3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke3.ZIndex = 1

	local UITextSizeConstraint1 = Instance.new("UITextSizeConstraint")
	UITextSizeConstraint1.Parent = DoNotDisturb
	UITextSizeConstraint1.MaxTextSize = 18
	UITextSizeConstraint1.MinTextSize = 1

	local NoNotificationLabel = Instance.new("TextLabel")
	NoNotificationLabel.Name = "NoNotificationLabel"
	NoNotificationLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	NoNotificationLabel.Size = UDim2.new(1, 0, 1, 0)
	NoNotificationLabel.Position = UDim2.new(0, 0, 0, 0)
	NoNotificationLabel.ZIndex = 9997
	NoNotificationLabel.LayoutOrder = 0
	NoNotificationLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NoNotificationLabel.BackgroundTransparency = 1
	NoNotificationLabel.TextScaled = true
	NoNotificationLabel.TextWrapped = true
	NoNotificationLabel.TextTransparency = 0.53
	NoNotificationLabel.Text = "No Notification"
	NoNotificationLabel.FontFace = Font.fromEnum(Enum.Font.Oswald, Enum.FontWeight.Bold)
	NoNotificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	NoNotificationLabel.RichText = true
	NoNotificationLabel.Visible = false
	NoNotificationLabel.Parent = ScrollFrame

	local UITextSizeConstraint2 = Instance.new("UITextSizeConstraint")
	UITextSizeConstraint2.Parent = NoNotificationLabel
	UITextSizeConstraint2.MaxTextSize = 44
	UITextSizeConstraint2.MinTextSize = 1

	local Unknown = Instance.new("TextLabel")
	Unknown.Name = "Unknown"
	Unknown.AnchorPoint = Vector2.new(0.5, 0.5)
	Unknown.Size = UDim2.new(1, 0, 1, 0)
	Unknown.Position = UDim2.new(0, 0, 0, 0)
	Unknown.ZIndex = 9997
	Unknown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Unknown.BackgroundTransparency = 1
	Unknown.TextScaled = true
	Unknown.TextWrapped = true
	Unknown.TextTransparency = 0.53
	Unknown.Text = ""
	Unknown.TextColor3 = Color3.fromRGB(255, 255, 255)
	Unknown.RichText = true
	Unknown.Visible = false
	Unknown.LayoutOrder = 1
	Unknown.Parent = ScrollFrame

	local UITextSizeConstraint3 = Instance.new("UITextSizeConstraint")
	UITextSizeConstraint3.Parent = Unknown
	UITextSizeConstraint3.MaxTextSize = 44
	UITextSizeConstraint3.MinTextSize = 1

	local UIAspectRatioConstraint15 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint15.Parent = Unknown
	UIAspectRatioConstraint15.AspectRatio = 179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368
	UIAspectRatioConstraint15.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint15.DominantAxis = Enum.DominantAxis.Width
end

-- ============================================
-- CHUNK 9: ReplicatedIcons & Notification Templates
-- ============================================
local function createChunk9()
	local ReplicatedIcons = Instance.new("Folder")
	ReplicatedIcons.Name = "ReplicatedIcons"
	ReplicatedIcons.Parent = MainUI

	local AppIconTemplate = Instance.new("ImageButton")
	AppIconTemplate.Name = "AppIconTemplate"
	AppIconTemplate.Visible = false
	AppIconTemplate.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	AppIconTemplate.Size = UDim2.new(0.037, 0, 0.087, 0)
	AppIconTemplate.Position = UDim2.new(0.5, 0, 0.5, 0)
	AppIconTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	AppIconTemplate.BackgroundTransparency = 0
	AppIconTemplate.ImageTransparency = 0
	AppIconTemplate.Visible = false
	AppIconTemplate.ScaleType = Enum.ScaleType.Fit
	AppIconTemplate.ZIndex = 4
	AppIconTemplate.Parent = ReplicatedIcons

	local UIAspectRatioConstraint16 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint16.Parent = AppIconTemplate
	UIAspectRatioConstraint16.AspectRatio = 1
	UIAspectRatioConstraint16.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint16.DominantAxis = Enum.DominantAxis.Width

	local UIStroke1 = Instance.new("UIStroke")
	UIStroke1.Parent = AppIconTemplate
	UIStroke1.Color = Color3.fromRGB(65, 64, 64)
	UIStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	UIStroke1.Thickness = 7.3
	UIStroke1.Transparency = 0.58

	createUICorner(AppIconTemplate, "UICorner1", UDim.new(0.4, 0))

	local AppName = Instance.new("TextLabel")
	AppName.Name = "AppName"
	AppName.Parent = AppIconTemplate
	AppName.AnchorPoint = Vector2.new(0.5, 0.5)
	AppName.Position = UDim2.new(0.5, 0, 1.294, 0)
	AppName.Size = UDim2.new(1.882, 0, 0.353, 0)
	AppName.BackgroundTransparency = 1
	AppName.Text = "App Name"
	AppName.TextColor3 = Color3.fromRGB(255, 251, 251)
	AppName.TextScaled = true
	AppName.TextSize = 14
	AppName.TextWrapped = true
	AppName.RichText = true
	AppName.Font = Enum.Font.SourceSansBold
	AppName.TextXAlignment = Enum.TextXAlignment.Center
	AppName.TextYAlignment = Enum.TextYAlignment.Center
	AppName.TextStrokeTransparency = 0.5
	AppName.ZIndex = 4
	AppName.Visible = true

	local UIAspectRatioConstraint17 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint17.Parent = AppName
	UIAspectRatioConstraint17.AspectRatio = 5.333
	UIAspectRatioConstraint17.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint17.DominantAxis = Enum.DominantAxis.Width

	local UITextSizeConstraint_AppName = Instance.new("UITextSizeConstraint")
	UITextSizeConstraint_AppName.Parent = AppName
	UITextSizeConstraint_AppName.MaxTextSize = 30
	UITextSizeConstraint_AppName.MinTextSize = 1

	local ReplicatedNotifications = Instance.new("Folder")
	ReplicatedNotifications.Name = "ReplicatedNotifications"
	ReplicatedNotifications.Parent = MainUI

	local __NotificationReplicaWindow_2 = Instance.new("TextButton")
	__NotificationReplicaWindow_2.Name = "__NotificationReplicaWindow_2"
	__NotificationReplicaWindow_2.Visible = false
	__NotificationReplicaWindow_2.BackgroundColor3 = Color3.fromRGB(35, 42, 48)
	__NotificationReplicaWindow_2.BackgroundTransparency = 0
	__NotificationReplicaWindow_2.Size = UDim2.new(0.5, 0, 0.3, 0)
	__NotificationReplicaWindow_2.Text = ""
	__NotificationReplicaWindow_2.TextTransparency = 1
	__NotificationReplicaWindow_2.ZIndex = 9997
	__NotificationReplicaWindow_2.Parent = ReplicatedNotifications

	local UIAspectRatioConstraint18 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint18.Parent = __NotificationReplicaWindow_2
	UIAspectRatioConstraint18.AspectRatio = 4.13
	UIAspectRatioConstraint18.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint18.DominantAxis = Enum.DominantAxis.Width

	createUICorner(__NotificationReplicaWindow_2, "UICorner_NotificationReplicaWindow_2", UDim.new(0.1, 0))

	local Dismiss = Instance.new("TextButton")
	Dismiss.Name = "Dismiss"
	Dismiss.Parent = __NotificationReplicaWindow_2
	Dismiss.AnchorPoint = Vector2.new(0.5, 0.5)
	Dismiss.Position = UDim2.new(1, 0, 0.5, 0)
	Dismiss.Size = UDim2.new(0.15, 0, 1, 0)
	Dismiss.BackgroundColor3 = Color3.fromRGB(61, 73, 84)
	Dismiss.ZIndex = 9998
	Dismiss.Text = ">"
	Dismiss.TextColor3 = Color3.fromRGB(166, 255, 237)
	Dismiss.TextScaled = true
	Dismiss.TextSize = 14
	Dismiss.TextWrapped = true
	Dismiss.Font = Enum.Font.Oswald
	Dismiss.TextXAlignment = Enum.TextXAlignment.Center

	createUICorner(Dismiss, "UICorner_Dismiss", UDim.new(0.15, 0))

	local Icon__NotificationReplicaWindow_2 = Instance.new("ImageLabel")
	Icon__NotificationReplicaWindow_2.Name = "Icon"
	Icon__NotificationReplicaWindow_2.Parent = __NotificationReplicaWindow_2
	Icon__NotificationReplicaWindow_2.AnchorPoint = Vector2.new(0.5, 0.5)
	Icon__NotificationReplicaWindow_2.Position = UDim2.new(0.088, 0, 0.17, 0)
	Icon__NotificationReplicaWindow_2.Size = UDim2.new(0.087, 0, 0.22, 2)
	Icon__NotificationReplicaWindow_2.ZIndex = 9997
	Icon__NotificationReplicaWindow_2.BackgroundTransparency = 1
	Icon__NotificationReplicaWindow_2.ScaleType = Enum.ScaleType.Fit

	createUICorner(Icon__NotificationReplicaWindow_2, "UICorner_Icon__NotificationReplicaWindow_2", UDim.new(1, 0))

	local Title__NotificationReplicaWindow_2 = Instance.new("TextLabel")
	Title__NotificationReplicaWindow_2.Name = "Title"
	Title__NotificationReplicaWindow_2.Parent = __NotificationReplicaWindow_2
	Title__NotificationReplicaWindow_2.Position = UDim2.new(0.209, 0, 0.096, 0)
	Title__NotificationReplicaWindow_2.Size = UDim2.new(0, 127, 0, 26)
	Title__NotificationReplicaWindow_2.BackgroundTransparency = 1
	Title__NotificationReplicaWindow_2.ZIndex = 9997
	Title__NotificationReplicaWindow_2.Font = Enum.Font.SourceSansBold
	Title__NotificationReplicaWindow_2.Text = "Title"
	Title__NotificationReplicaWindow_2.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title__NotificationReplicaWindow_2.TextScaled = true
	Title__NotificationReplicaWindow_2.TextSize = 14
	Title__NotificationReplicaWindow_2.TextWrapped = true

	local Description__NotificationReplicaWindow_2 = Instance.new("TextLabel")
	Description__NotificationReplicaWindow_2.Name = "Description"
	Description__NotificationReplicaWindow_2.Parent = __NotificationReplicaWindow_2
	Description__NotificationReplicaWindow_2.Position = UDim2.new(0.502, 0, 0.567, 0)
	Description__NotificationReplicaWindow_2.AnchorPoint = Vector2.new(0.5, 0.5)
	Description__NotificationReplicaWindow_2.Size = UDim2.new(0.742, 0, 0.568, 0)
	Description__NotificationReplicaWindow_2.BackgroundTransparency = 1
	Description__NotificationReplicaWindow_2.ZIndex = 9997
	Description__NotificationReplicaWindow_2.Font = Enum.Font.SourceSans
	Description__NotificationReplicaWindow_2.Text = "Description"
	Description__NotificationReplicaWindow_2.TextColor3 = Color3.fromRGB(255, 255, 255)
	Description__NotificationReplicaWindow_2.TextScaled = false
	Description__NotificationReplicaWindow_2.TextSize = 21
	Description__NotificationReplicaWindow_2.TextWrapped = true
	Description__NotificationReplicaWindow_2.RichText = true
	Description__NotificationReplicaWindow_2.TextXAlignment = Enum.TextXAlignment.Left
	Description__NotificationReplicaWindow_2.TextYAlignment = Enum.TextYAlignment.Top
end

-- ============================================
-- CHUNK 10: System Folders & Settings
-- ============================================
local function createChunk10()
	local MediaSoundUI = Instance.new("SoundGroup")
	MediaSoundUI.Name = "MediaSoundUI"
	MediaSoundUI.Volume = 0.5
	MediaSoundUI.Parent = MainUI

	local NotificationsSoundUI = Instance.new("SoundGroup")
	NotificationsSoundUI.Name = "NotificationsSoundUI"
	NotificationsSoundUI.Volume = 0.5
	NotificationsSoundUI.Parent = MainUI

	local __Zolin = Instance.new("Folder")
	__Zolin.Name = "__Zolin"
	__Zolin.Parent = MainUI

	local Runtime = Instance.new("Folder")
	Runtime.Name = "Runtime"
	Runtime.Parent = __Zolin

	local Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = __Zolin

	local Data = Instance.new("Folder")
	Data.Name = "Data"
	Data.Parent = __Zolin

	local ReplicatedWindow = Instance.new("Folder")
	ReplicatedWindow.Name = "ReplicatedWindow"
	ReplicatedWindow.Parent = MainUI

	local DeviceTree = Instance.new("Folder")
	DeviceTree.Name = "DeviceTree"
	DeviceTree.Parent = MainUI

	local DeviceName = Instance.new("StringValue")
	DeviceName.Name = "DeviceName"
	DeviceName.Value = "ZolinOS"
	DeviceName.Parent = DeviceTree

	local DevicePlatform = Instance.new("StringValue")
	DevicePlatform.Name = "DevicePlatform"
	DevicePlatform.Value = "mobile"
	DevicePlatform.Parent = DeviceTree

	local ZolinVersion = Instance.new("StringValue")
	ZolinVersion.Name = "ZolinVersion"
	ZolinVersion.Value = v1.ver;
	BuildVersion = ZolinVersion.Value
	ZolinVersion.Parent = DeviceTree

	local AnimationUI = Instance.new("BoolValue")
	AnimationUI.Name = "AnimationUI"
	AnimationUI.Value = true
	AnimationUI.Parent = Data

	local TransitionSpeed = Instance.new("NumberValue")
	TransitionSpeed.Name = "TransitionSpeed"
	TransitionSpeed.Value = 1.5
	TransitionSpeed.Parent = Data

	local CloseAllApps = Instance.new("BindableEvent")
	CloseAllApps.Name = "CloseAllApps"
	CloseAllApps.Parent = Remotes

	local moreOptionsVolStyle = Instance.new("BindableEvent")
	moreOptionsVolStyle.Name = "moreOptionsVolStyle"
	moreOptionsVolStyle.Parent = Remotes

	local updateZolinLauncher = Instance.new("BindableEvent")
	updateZolinLauncher.Name = "updateZolinLauncher"
	updateZolinLauncher.Parent = Remotes

	local contactDirHWupdateEvent = Instance.new("BindableEvent")
	contactDirHWupdateEvent.Name = "contactDirHWupdateEvent"
	contactDirHWupdateEvent.Parent = Remotes

	local ContextMenuEvent = Instance.new("BindableEvent")
	ContextMenuEvent.Name = "ContextMenuEvent"
	ContextMenuEvent.Parent = Remotes

	local sendnotificationEvent = Instance.new("BindableEvent")
	sendnotificationEvent.Name = "SendNotificationEvent"
	sendnotificationEvent.Parent = Remotes
end

-- ============================================
-- CHUNK 11: ReplicatedWindow_Sys & ExampleWindow
-- ============================================
local function createChunk11()
	local ReplicatedWindow_Sys = Instance.new("Folder")
	ReplicatedWindow_Sys.Name = "ReplicatedWindow_Sys"
	ReplicatedWindow_Sys.Parent = MainUI

	local ExampleWindow = Instance.new("Frame")
	ExampleWindow.Name = "ExampleWindow"
	ExampleWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	ExampleWindow.BackgroundTransparency = 0
	ExampleWindow.BackgroundColor3 = Color3.fromRGB(66, 119, 171)
	ExampleWindow.Size = UDim2.new(0.67, 0, 0.8, 0)
	ExampleWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	ExampleWindow.Visible = false
	ExampleWindow.ZIndex = 6
	ExampleWindow.Parent = ReplicatedWindow_Sys

	createUICorner(ExampleWindow, "UICorner_ExampleWindow", UDim.new(0, 25))

	local ExampleWindow_UI = Instance.new("TextButton")
	ExampleWindow_UI.Name = "UI"
	ExampleWindow_UI.AnchorPoint = Vector2.new(0.5, 0.5)
	ExampleWindow_UI.BackgroundTransparency = 0.6
	ExampleWindow_UI.BackgroundColor3 = Color3.fromRGB(70, 255, 255)
	ExampleWindow_UI.Size = UDim2.new(1, 0, 1, 0)
	ExampleWindow_UI.Position = UDim2.new(0.5, 0, 0.5, 0)
	ExampleWindow_UI.Text = ""
	ExampleWindow_UI.ZIndex = ExampleWindow.ZIndex
	ExampleWindow_UI.Visible = true
	ExampleWindow_UI.Active = true
	ExampleWindow_UI.Parent = ExampleWindow

	createUICorner(ExampleWindow_UI, "UICorner_ExampleWindow_UI", UDim.new(0, 25))

	local PreviewAppInfoZL_ExampleWindow = Instance.new("Frame")
	PreviewAppInfoZL_ExampleWindow.Name = "PreviewAppInfoZL"
	PreviewAppInfoZL_ExampleWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	PreviewAppInfoZL_ExampleWindow.AutomaticSize = Enum.AutomaticSize.XY
	PreviewAppInfoZL_ExampleWindow.BackgroundColor3 = Color3.fromRGB(59, 232, 189)
	PreviewAppInfoZL_ExampleWindow.BackgroundTransparency = 0.35
	PreviewAppInfoZL_ExampleWindow.Position = UDim2.new(0.082, 0, 0.031, 0)
	PreviewAppInfoZL_ExampleWindow.Size = UDim2.new(0.165, 0, 0.061, 0)
	PreviewAppInfoZL_ExampleWindow.ZIndex = 10
	PreviewAppInfoZL_ExampleWindow.Visible = true
	PreviewAppInfoZL_ExampleWindow.Parent = ExampleWindow

	createUICorner(PreviewAppInfoZL_ExampleWindow, "UICorner_PreviewAppInfoZL", UDim.new(0.5, 0))

	local TextLabel_PreviewAppInfoZL = Instance.new("TextLabel")
	TextLabel_PreviewAppInfoZL.Name = "AppNameLabel"
	TextLabel_PreviewAppInfoZL.AnchorPoint = Vector2.new(0.5, 0.5)
	TextLabel_PreviewAppInfoZL.Position = UDim2.new(0.409, 0, 0.5, 0)
	TextLabel_PreviewAppInfoZL.Size = UDim2.new(0, 150, 0, 25)
	TextLabel_PreviewAppInfoZL.BackgroundTransparency = 1
	TextLabel_PreviewAppInfoZL.TextScaled = true
	TextLabel_PreviewAppInfoZL.Font = Enum.Font.Oswald
	TextLabel_PreviewAppInfoZL.RichText = true
	TextLabel_PreviewAppInfoZL.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel_PreviewAppInfoZL.ZIndex = PreviewAppInfoZL_ExampleWindow.ZIndex
	TextLabel_PreviewAppInfoZL.Text = "<b>ZolinUI</b>"
	TextLabel_PreviewAppInfoZL.Parent = PreviewAppInfoZL_ExampleWindow

	local ImageLabel_PreviewAppInfoZL = Instance.new("ImageLabel")
	ImageLabel_PreviewAppInfoZL.AnchorPoint = Vector2.new(0.5, 0.5)
	ImageLabel_PreviewAppInfoZL.AutomaticSize = Enum.AutomaticSize.XY
	ImageLabel_PreviewAppInfoZL.BackgroundTransparency = 1
	ImageLabel_PreviewAppInfoZL.Position = UDim2.new(0.9, 0, 0.5, 0)
	ImageLabel_PreviewAppInfoZL.Size = UDim2.new(0, 39, 0, 39)
	ImageLabel_PreviewAppInfoZL.ZIndex = PreviewAppInfoZL_ExampleWindow.ZIndex
	ImageLabel_PreviewAppInfoZL.Image = "rbxassetid://3459878578"
	ImageLabel_PreviewAppInfoZL.ScaleType = Enum.ScaleType.Fit
	ImageLabel_PreviewAppInfoZL.Parent = PreviewAppInfoZL_ExampleWindow

	createUICorner(ImageLabel_PreviewAppInfoZL, "UICorner_ImageLabel_PreviewAppInfoZL", UDim.new(0.5, 0))
end

-- ============================================
-- CHUNK 12: WallpaperSys App (Part 1)
-- ============================================
local function createChunk12()
	local ReplicatedWindow_Sys = MainUI:FindFirstChild("ReplicatedWindow_Sys")

	local WallpaperSys = Instance.new("Frame")
	WallpaperSys.Name = "WallpaperSys"
	WallpaperSys.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys.BackgroundTransparency = 0
	WallpaperSys.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	WallpaperSys.Size = UDim2.new(1, 0, 1, 0)
	WallpaperSys.Position = UDim2.new(0.5, 0, 0.5, 0)
	WallpaperSys.ZIndex = 6
	WallpaperSys.Visible = false
	WallpaperSys.Parent = ReplicatedWindow_Sys

	local Assets_WallpaperSys = Instance.new("Folder")
	Assets_WallpaperSys.Name = "Assets"
	Assets_WallpaperSys.Parent = WallpaperSys

	local HighlightSelection = Instance.new("UIStroke")
	HighlightSelection.Name = "HighlightSelection"
	HighlightSelection.Thickness = 7
	HighlightSelection.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	HighlightSelection.Color = Color3.fromRGB(47, 255, 0)
	HighlightSelection.ZIndex = 7
	HighlightSelection.Enabled = false
	HighlightSelection.Parent = Assets_WallpaperSys

	local WallpaperPickerTemplate = Instance.new("ImageButton")
	WallpaperPickerTemplate.Name = "WallpaperPickerTemplate"
	WallpaperPickerTemplate.BackgroundTransparency = 1
	WallpaperPickerTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperPickerTemplate.Size = UDim2.new(0.088, 0, 0.2, 0)
	WallpaperPickerTemplate.Position = UDim2.new(0.962, 0, 0.1, 0)
	WallpaperPickerTemplate.Active = true
	WallpaperPickerTemplate.ZIndex = 6
	WallpaperPickerTemplate.Visible = false
	WallpaperPickerTemplate.Parent = Assets_WallpaperSys

	createUICorner(WallpaperPickerTemplate, "WallpaperPickerTemplate_UI", UDim.new(0, 11))

	local UIAspectRatio_WallpaperPickerTemplate = Instance.new("UIAspectRatioConstraint")
	UIAspectRatio_WallpaperPickerTemplate.AspectRatio = 1.155
	UIAspectRatio_WallpaperPickerTemplate.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatio_WallpaperPickerTemplate.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatio_WallpaperPickerTemplate.Parent = WallpaperPickerTemplate

	local WallpaperNameLabel = Instance.new("TextLabel")
	WallpaperNameLabel.Name = "WallpaperNameLabel"
	WallpaperNameLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	WallpaperNameLabel.BackgroundTransparency = 0.35
	WallpaperNameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperNameLabel.Position = UDim2.new(0.5, 0, 0.9, 0)
	WallpaperNameLabel.Size = UDim2.new(1, 0, 0.2, 0)
	WallpaperNameLabel.ZIndex = 7
	WallpaperNameLabel.Text = "Colorful"
	WallpaperNameLabel.TextColor3 = Color3.fromRGB(109, 168, 173)
	WallpaperNameLabel.TextSize = 25
	WallpaperNameLabel.TextScaled = true
	WallpaperNameLabel.TextWrapped = true
	WallpaperNameLabel.RichText = true
	WallpaperNameLabel.Font = Enum.Font.SourceSansBold
	WallpaperNameLabel.Parent = WallpaperPickerTemplate

	createUICorner(WallpaperNameLabel, "UICorner_WallpaperNameLabel", UDim.new(0, 11))

	local UITextSizeConstraint_WallpaperNameLabel = Instance.new("UITextSizeConstraint")
	UITextSizeConstraint_WallpaperNameLabel.MaxTextSize = 25
	UITextSizeConstraint_WallpaperNameLabel.MinTextSize = 1
	UITextSizeConstraint_WallpaperNameLabel.Parent = WallpaperNameLabel

	local Data_WallpaperSys = Instance.new("Folder")
	Data_WallpaperSys.Name = "Data"
	Data_WallpaperSys.Parent = WallpaperSys

	local Desc_WallpaperSys = Instance.new("StringValue")
	Desc_WallpaperSys.Name = "Description"
	Desc_WallpaperSys.Value = "Wallpaper Style"
	Desc_WallpaperSys.Parent = Data_WallpaperSys

	local Version_WallpaperSys = Instance.new("StringValue")
	Version_WallpaperSys.Name = "Version"
	Version_WallpaperSys.Value = "1.0"
	Version_WallpaperSys.Parent = Data_WallpaperSys

	createUICorner(WallpaperSys, "UICorner_WallpaperSys", UDim.new(0, 10))

	local UIScale_WallpaperSys = Instance.new("UIScale")
	UIScale_WallpaperSys.Parent = WallpaperSys
	UIScale_WallpaperSys.Scale = 0

	local PreviewAppInfoZL_WallpaperSys = Instance.new("Frame")
	PreviewAppInfoZL_WallpaperSys.Name = "PreviewAppInfoZL"
	PreviewAppInfoZL_WallpaperSys.AnchorPoint = Vector2.new(0.5, 0.5)
	PreviewAppInfoZL_WallpaperSys.AutomaticSize = Enum.AutomaticSize.XY
	PreviewAppInfoZL_WallpaperSys.BackgroundColor3 = Color3.fromRGB(59, 232, 189)
	PreviewAppInfoZL_WallpaperSys.BackgroundTransparency = 0.35
	PreviewAppInfoZL_WallpaperSys.Position = UDim2.new(0.082, 0, 0.031, 0)
	PreviewAppInfoZL_WallpaperSys.Size = UDim2.new(0.165, 0, 0.061, 0)
	PreviewAppInfoZL_WallpaperSys.ZIndex = 8
	PreviewAppInfoZL_WallpaperSys.Visible = false
	PreviewAppInfoZL_WallpaperSys.Parent = WallpaperSys

	createUICorner(PreviewAppInfoZL_WallpaperSys, "UICorner_PreviewAppInfoZL", UDim.new(0.5, 0))

	local TextLabel_PreviewAppInfoZL = Instance.new("TextLabel")
	TextLabel_PreviewAppInfoZL.Name = "AppNameLabel"
	TextLabel_PreviewAppInfoZL.AnchorPoint = Vector2.new(0.5, 0.5)
	TextLabel_PreviewAppInfoZL.Position = UDim2.new(0.409, 0, 0.5, 0)
	TextLabel_PreviewAppInfoZL.Size = UDim2.new(0, 150, 0, 25)
	TextLabel_PreviewAppInfoZL.BackgroundTransparency = 1
	TextLabel_PreviewAppInfoZL.TextScaled = true
	TextLabel_PreviewAppInfoZL.Font = Enum.Font.Oswald
	TextLabel_PreviewAppInfoZL.RichText = true
	TextLabel_PreviewAppInfoZL.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel_PreviewAppInfoZL.ZIndex = PreviewAppInfoZL_WallpaperSys.ZIndex

	local ImageLabel_PreviewAppInfoZL = Instance.new("ImageLabel")
	ImageLabel_PreviewAppInfoZL.AnchorPoint = Vector2.new(0.5, 0.5)
	ImageLabel_PreviewAppInfoZL.AutomaticSize = Enum.AutomaticSize.XY
	ImageLabel_PreviewAppInfoZL.BackgroundTransparency = 1
	ImageLabel_PreviewAppInfoZL.Position = UDim2.new(0.9, 0, 0.5, 0)
	ImageLabel_PreviewAppInfoZL.Size = UDim2.new(0, 39, 0, 39)
	ImageLabel_PreviewAppInfoZL.ZIndex = PreviewAppInfoZL_WallpaperSys.ZIndex
	ImageLabel_PreviewAppInfoZL.Image = "rbxassetid://128691285053548"
	ImageLabel_PreviewAppInfoZL.ScaleType = Enum.ScaleType.Fit
	ImageLabel_PreviewAppInfoZL.Parent = PreviewAppInfoZL_WallpaperSys

	createUICorner(ImageLabel_PreviewAppInfoZL, "UICorner_ImageLabel_PreviewAppInfoZL", UDim.new(0.5, 0))

	local WallpaperSys_UI = Instance.new("Frame")
	WallpaperSys_UI.Name = "UI"
	WallpaperSys_UI.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys_UI.Position = UDim2.new(0.5, 0, 0.495, 0)
	WallpaperSys_UI.Size = UDim2.new(1, 0, 0.89, 0)
	WallpaperSys_UI.ZIndex = WallpaperSys.ZIndex - 1
	WallpaperSys_UI.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
	WallpaperSys_UI.BackgroundTransparency = 0.65
	WallpaperSys_UI.Visible = true
	WallpaperSys_UI.Parent = WallpaperSys

	createUICorner(WallpaperSys_UI, "WallpaperSys_UI_UICorner", UDim.new(0, 10))

	local WallpaperSys_UI_UIListLayout = Instance.new("UIListLayout")
	WallpaperSys_UI_UIListLayout.SortOrder = Enum.SortOrder.Name
	WallpaperSys_UI_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	WallpaperSys_UI_UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	WallpaperSys_UI_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	WallpaperSys_UI_UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
	WallpaperSys_UI_UIListLayout.VerticalFlex = Enum.UIFlexAlignment.None
	WallpaperSys_UI_UIListLayout.Parent = WallpaperSys_UI
end

-- ============================================
-- CHUNK 13: WallpaperSys ApplyWallpaperUI (Part 2)
-- ============================================
local function createChunk13()
	local ReplicatedWindow_Sys = MainUI:FindFirstChild("ReplicatedWindow_Sys")
	local WallpaperSys = ReplicatedWindow_Sys and ReplicatedWindow_Sys:FindFirstChild("WallpaperSys")
	local WallpaperSys_UI = WallpaperSys and WallpaperSys:FindFirstChild("UI")

	if not WallpaperSys_UI then return end

	local WallpaperSys_UI_ApplyWallpaperUI = Instance.new("Frame")
	WallpaperSys_UI_ApplyWallpaperUI.Name = "ApplyWallpaperUI"
	WallpaperSys_UI_ApplyWallpaperUI.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys_UI_ApplyWallpaperUI.BackgroundTransparency = 1
	WallpaperSys_UI_ApplyWallpaperUI.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	WallpaperSys_UI_ApplyWallpaperUI.Size = UDim2.new(1, 0, 1, 0)
	WallpaperSys_UI_ApplyWallpaperUI.Position = UDim2.new(0.5, 0, 0.5, 0)
	WallpaperSys_UI_ApplyWallpaperUI.ZIndex = WallpaperSys_UI.ZIndex + 1
	WallpaperSys_UI_ApplyWallpaperUI.Visible = false
	WallpaperSys_UI_ApplyWallpaperUI.Parent = WallpaperSys_UI

	local WallpaperSys_UI_ApplyWallpaperUI_Setting = Instance.new("Frame")
	WallpaperSys_UI_ApplyWallpaperUI_Setting.Name = "Setting"
	WallpaperSys_UI_ApplyWallpaperUI_Setting.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys_UI_ApplyWallpaperUI_Setting.Size = UDim2.new(0.1, 0, 0.35, 0)
	WallpaperSys_UI_ApplyWallpaperUI_Setting.Position = UDim2.new(0.07, 0, 0.2, 0)
	WallpaperSys_UI_ApplyWallpaperUI_Setting.ZIndex = WallpaperSys_UI_ApplyWallpaperUI.ZIndex + 1
	WallpaperSys_UI_ApplyWallpaperUI_Setting.BackgroundColor3 = Color3.fromRGB(141, 167, 161)
	WallpaperSys_UI_ApplyWallpaperUI_Setting.BackgroundTransparency = 0.2
	WallpaperSys_UI_ApplyWallpaperUI_Setting.Parent = WallpaperSys_UI_ApplyWallpaperUI

	createUICorner(WallpaperSys_UI_ApplyWallpaperUI_Setting, "WallpaperSys_UI_ApplyWallpaperUI_Setting_UICorner", UDim.new(0, 15))

	local WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout = Instance.new("UIListLayout")
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout.Padding = UDim.new(0.05, 0)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout.FillDirection = Enum.FillDirection.Vertical
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout.VerticalFlex = Enum.UIFlexAlignment.None
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIListLayout.Parent = WallpaperSys_UI_ApplyWallpaperUI_Setting

	local WallpaperSys_UI_ApplyWallpaperUI_Setting_UIAspectRatio = Instance.new("UIAspectRatioConstraint")
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIAspectRatio.Parent = WallpaperSys_UI_ApplyWallpaperUI_Setting
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIAspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIAspectRatio.AspectRatio = 0.748
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIAspectRatio.DominantAxis = Enum.DominantAxis.Width

	local WallpaperSys_UI_ApplyWallpaperUI_Setting_UIStroke = Instance.new("UIStroke")
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIStroke.Name = "UIStroke"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIStroke.Parent = WallpaperSys_UI_ApplyWallpaperUI_Setting
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIStroke.Thickness = 3.9
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIStroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIStroke.Color = Color3.fromRGB(119, 189, 142)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIStroke.Transparency = 0.3
	WallpaperSys_UI_ApplyWallpaperUI_Setting_UIStroke.ZIndex = WallpaperSys_UI_ApplyWallpaperUI_Setting.ZIndex + 1

	local WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop = Instance.new("TextButton")
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.Name = "Crop"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.Active = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.Size = UDim2.new(1, 0, 0.15, 0)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.BackgroundColor3 = Color3.fromRGB(115, 194, 168)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.LayoutOrder = 2
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.Text = "Crop"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.TextColor3 = Color3.fromRGB(210, 255, 248)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.TextScaled = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.TextWrapped = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.TextSize = 14
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.ZIndex = WallpaperSys_UI_ApplyWallpaperUI_Setting.ZIndex
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.Parent = WallpaperSys_UI_ApplyWallpaperUI_Setting

	createUICorner(WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop, "WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop_UICorner", UDim.new(0, 5))

	local WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit = Instance.new("TextButton")
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.Name = "Fit"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.Active = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.Size = UDim2.new(1, 0, 0.15, 0)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.BackgroundColor3 = Color3.fromRGB(115, 194, 168)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.LayoutOrder = WallpaperSys_UI_ApplyWallpaperUI_Setting_Crop.LayoutOrder + 1
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.Text = "Fit"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.TextColor3 = Color3.fromRGB(210, 255, 248)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.TextScaled = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.TextWrapped = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.TextSize = 14
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.ZIndex = WallpaperSys_UI_ApplyWallpaperUI_Setting.ZIndex
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.Parent = WallpaperSys_UI_ApplyWallpaperUI_Setting

	createUICorner(WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit, "WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit_UICorner", UDim.new(0, 5))

	local WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch = Instance.new("TextButton")
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.Name = "Stretch"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.Active = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.Size = UDim2.new(1, 0, 0.15, 0)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.BackgroundColor3 = Color3.fromRGB(115, 194, 168)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.LayoutOrder = WallpaperSys_UI_ApplyWallpaperUI_Setting_Fit.LayoutOrder - 2
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.Text = "Stretch"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.TextColor3 = Color3.fromRGB(210, 255, 248)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.TextScaled = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.TextWrapped = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.TextSize = 14
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.ZIndex = WallpaperSys_UI_ApplyWallpaperUI_Setting.ZIndex
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.Parent = WallpaperSys_UI_ApplyWallpaperUI_Setting

	createUICorner(WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch, "WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch_UICorner", UDim.new(0, 5))

	local WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit = Instance.new("TextButton")
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.Name = "Submit"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.Active = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.Size = UDim2.new(1, 0, 0.15, 0)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.BackgroundColor3 = Color3.fromRGB(140, 255, 134)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.BackgroundTransparency = 0.2
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.LayoutOrder = WallpaperSys_UI_ApplyWallpaperUI_Setting_Stretch.LayoutOrder + 3
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.Text = "Apply"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.TextColor3 = Color3.fromRGB(101, 127, 102)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.TextScaled = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.TextWrapped = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.TextSize = 14
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.ZIndex = WallpaperSys_UI_ApplyWallpaperUI_Setting.ZIndex
	WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit.Parent = WallpaperSys_UI_ApplyWallpaperUI_Setting

	createUICorner(WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit, "WallpaperSys_UI_ApplyWallpaperUI_Setting_Submit_UICorner", UDim.new(0, 5))

	local WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne = Instance.new("TextLabel")
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.Name = "OrderOne"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.AnchorPoint = Vector2.new(0, 0)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.Size = UDim2.new(1, 0, 0.1, 0)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.BackgroundTransparency = 0.2
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.BackgroundColor3 = Color3.fromRGB(65, 131, 97)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.LayoutOrder = 0
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.Text = "Wallpaper Scale"
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.TextColor3 = Color3.fromRGB(224, 255, 243)
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.TextScaled = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.TextWrapped = true
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.TextSize = 14
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.ZIndex = WallpaperSys_UI_ApplyWallpaperUI_Setting.ZIndex
	WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne.Parent = WallpaperSys_UI_ApplyWallpaperUI_Setting

	createUICorner(WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne, "WallpaperSys_UI_ApplyWallpaperUI_Setting_OrderOne_UICorner", UDim.new(0, 15))

	local WallpaperSys_UI_ApplyWallpaperUI_BackButton = Instance.new("ImageButton")
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.Name = "BackButton"
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.BackgroundColor3 = Color3.fromRGB(119, 176, 165)
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.BackgroundTransparency = 0.3
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.Position = UDim2.new(0.983, 0, 0.044, 0)
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.Size = UDim2.new(0.034, 0, 0.089, 0)
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.ZIndex = WallpaperSys_UI_ApplyWallpaperUI.ZIndex + 2
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.Image = "rbxassetid://6302778252"
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.ScaleType = Enum.ScaleType.Stretch
	WallpaperSys_UI_ApplyWallpaperUI_BackButton.Parent = WallpaperSys_UI_ApplyWallpaperUI

	local WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper = Instance.new("ImageLabel")
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.Name = "TempWallpaper"
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.AnchorPoint = Vector2.new(0.5, 0.5)
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.BackgroundColor3 = Color3.fromRGB(119, 176, 165)
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.BackgroundTransparency = 1
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.Position = UDim2.new(0.5, 0, 0.5, 0)
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.Size = UDim2.new(1, 0, 1, 0)
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.ZIndex = WallpaperSys_UI_ApplyWallpaperUI.ZIndex
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.ScaleType = Enum.ScaleType.Stretch
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.Visible = true
	WallpaperSys_UI_ApplyWallpaperUI_TempWallpaper.Parent = WallpaperSys_UI_ApplyWallpaperUI

	local WallpaperSys_UI_WallpaperList = Instance.new("ScrollingFrame")
	WallpaperSys_UI_WallpaperList.Name = "WallpaperList"
	WallpaperSys_UI_WallpaperList.AnchorPoint = Vector2.new(0, 0.5)
	WallpaperSys_UI_WallpaperList.Size = UDim2.new(1, 0, 1, 0)
	WallpaperSys_UI_WallpaperList.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
	WallpaperSys_UI_WallpaperList.BackgroundTransparency = 0
	WallpaperSys_UI_WallpaperList.ClipsDescendants = true
	WallpaperSys_UI_WallpaperList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	WallpaperSys_UI_WallpaperList.CanvasSize = UDim2.new(0, 0, 1, 0)
	WallpaperSys_UI_WallpaperList.ZIndex = WallpaperSys_UI.ZIndex
	WallpaperSys_UI_WallpaperList.ScrollBarThickness = 13
	WallpaperSys_UI_WallpaperList.ScrollBarImageColor3 = Color3.fromRGB(185, 185, 185)
	WallpaperSys_UI_WallpaperList.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	WallpaperSys_UI_WallpaperList.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	WallpaperSys_UI_WallpaperList.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	WallpaperSys_UI_WallpaperList.Visible = true
	WallpaperSys_UI_WallpaperList.Parent = WallpaperSys_UI

	local WallpaperSys_UI_WallpaperList_ButtonsContainer = Instance.new("UIListLayout")
	WallpaperSys_UI_WallpaperList_ButtonsContainer.Name = "ButtonsContainer"
	WallpaperSys_UI_WallpaperList_ButtonsContainer.SortOrder = Enum.SortOrder.Name
	WallpaperSys_UI_WallpaperList_ButtonsContainer.Padding = UDim.new(0.001, 0)
	WallpaperSys_UI_WallpaperList_ButtonsContainer.FillDirection = Enum.FillDirection.Horizontal
	WallpaperSys_UI_WallpaperList_ButtonsContainer.Wraps = true
	WallpaperSys_UI_WallpaperList_ButtonsContainer.HorizontalAlignment = Enum.HorizontalAlignment.Right
	WallpaperSys_UI_WallpaperList_ButtonsContainer.HorizontalFlex = Enum.UIFlexAlignment.None
	WallpaperSys_UI_WallpaperList_ButtonsContainer.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	WallpaperSys_UI_WallpaperList_ButtonsContainer.VerticalAlignment = Enum.VerticalAlignment.Top
	WallpaperSys_UI_WallpaperList_ButtonsContainer.VerticalFlex = Enum.UIFlexAlignment.None
	WallpaperSys_UI_WallpaperList_ButtonsContainer.Parent = WallpaperSys_UI_WallpaperList
end

-- ============================================
-- CHUNK 14: Settings App
-- ============================================
local function createChunk14()
	local ReplicatedWindow = MainUI:FindFirstChild("ReplicatedWindow")

	local SettingsApp = Instance.new("Frame")
	SettingsApp.Name = "Settings"
	SettingsApp.AnchorPoint = Vector2.new(0.5, 0.5)
	SettingsApp.BackgroundTransparency = 0
	SettingsApp.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	SettingsApp.Size = UDim2.new(1, 0, 1, 0)
	SettingsApp.Position = UDim2.new(0.5, 0, 0.5, 0)
	SettingsApp.ZIndex = 6
	SettingsApp.Visible = false
	SettingsApp.Parent = ReplicatedWindow

	local Data_SettingsApp = Instance.new("Folder")
	Data_SettingsApp.Name = "Data"
	Data_SettingsApp.Parent = SettingsApp

	local Desc_SettingsApp = Instance.new("StringValue")
	Desc_SettingsApp.Name = "Description"
	Desc_SettingsApp.Value = "Settings Applicaton "
	Desc_SettingsApp.Parent = Data_SettingsApp

	local Version_SettingsApp = Instance.new("StringValue")
	Version_SettingsApp.Name = "Version"
	Version_SettingsApp.Value = "1.3"
	Version_SettingsApp.Parent = Data_SettingsApp

	createUICorner(SettingsApp, "UICorner_SettingsApp", UDim.new(0, 10))

	local UIScale_SettingsApp = Instance.new("UIScale")
	UIScale_SettingsApp.Parent = SettingsApp
	UIScale_SettingsApp.Scale = 0

	local PreviewAppInfoZL_SettingsApp = Instance.new("Frame")
	PreviewAppInfoZL_SettingsApp.Name = "PreviewAppInfoZL"
	PreviewAppInfoZL_SettingsApp.AnchorPoint = Vector2.new(0.5, 0.5)
	PreviewAppInfoZL_SettingsApp.AutomaticSize = Enum.AutomaticSize.XY
	PreviewAppInfoZL_SettingsApp.BackgroundColor3 = Color3.fromRGB(59, 232, 189)
	PreviewAppInfoZL_SettingsApp.BackgroundTransparency = 0.35
	PreviewAppInfoZL_SettingsApp.Position = UDim2.new(0.082, 0, 0.031, 0)
	PreviewAppInfoZL_SettingsApp.Size = UDim2.new(0.165, 0, 0.061, 0)
	PreviewAppInfoZL_SettingsApp.ZIndex = 8
	PreviewAppInfoZL_SettingsApp.Visible = false
	PreviewAppInfoZL_SettingsApp.Parent = SettingsApp

	createUICorner(PreviewAppInfoZL_SettingsApp, "UICorner_PreviewAppInfoZL_SettingsApp", UDim.new(0.5, 0))

	local TextLabel_PreviewAppInfoZL_SettingsApp = Instance.new("TextLabel")
	TextLabel_PreviewAppInfoZL_SettingsApp.Name = "AppNameLabel"
	TextLabel_PreviewAppInfoZL_SettingsApp.AnchorPoint = Vector2.new(0.5, 0.5)
	TextLabel_PreviewAppInfoZL_SettingsApp.Position = UDim2.new(0.409, 0, 0.5, 0)
	TextLabel_PreviewAppInfoZL_SettingsApp.Size = UDim2.new(0, 150, 0, 25)
	TextLabel_PreviewAppInfoZL_SettingsApp.BackgroundTransparency = 1
	TextLabel_PreviewAppInfoZL_SettingsApp.TextScaled = true
	TextLabel_PreviewAppInfoZL_SettingsApp.Font = Enum.Font.Oswald
	TextLabel_PreviewAppInfoZL_SettingsApp.RichText = true
	TextLabel_PreviewAppInfoZL_SettingsApp.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel_PreviewAppInfoZL_SettingsApp.ZIndex = PreviewAppInfoZL_SettingsApp.ZIndex

	local ImageLabel_PreviewAppInfoZL_SettingsApp = Instance.new("ImageLabel")
	ImageLabel_PreviewAppInfoZL_SettingsApp.AnchorPoint = Vector2.new(0.5, 0.5)
	ImageLabel_PreviewAppInfoZL_SettingsApp.AutomaticSize = Enum.AutomaticSize.XY
	ImageLabel_PreviewAppInfoZL_SettingsApp.BackgroundTransparency = 1
	ImageLabel_PreviewAppInfoZL_SettingsApp.Position = UDim2.new(0.9, 0, 0.5, 0)
	ImageLabel_PreviewAppInfoZL_SettingsApp.Size = UDim2.new(0, 39, 0, 39)
	ImageLabel_PreviewAppInfoZL_SettingsApp.ZIndex = PreviewAppInfoZL_SettingsApp.ZIndex
	ImageLabel_PreviewAppInfoZL_SettingsApp.Image = "rbxassetid://115730300615716"
	ImageLabel_PreviewAppInfoZL_SettingsApp.ScaleType = Enum.ScaleType.Fit
	ImageLabel_PreviewAppInfoZL_SettingsApp.Parent = PreviewAppInfoZL_SettingsApp

	createUICorner(ImageLabel_PreviewAppInfoZL_SettingsApp, "UICorner_ImageLabel_SettingsApp_PreviewAppInfoZL", UDim.new(0.5, 0))

	local SettingsApp_UI = Instance.new("Frame")
	SettingsApp_UI.Name = "UI"
	SettingsApp_UI.AnchorPoint = Vector2.new(0.5, 0.5)
	SettingsApp_UI.Position = UDim2.new(0.5, 0, 0.495, 0)
	SettingsApp_UI.Size = UDim2.new(1, 0, 0.89, 0)
	SettingsApp_UI.ZIndex = SettingsApp.ZIndex - 1
	SettingsApp_UI.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
	SettingsApp_UI.BackgroundTransparency = 0.65
	SettingsApp_UI.Visible = true
	SettingsApp_UI.Parent = SettingsApp

	createUICorner(SettingsApp_UI, "SettingsApp_UI_UICorner", UDim.new(0, 10))

	local SettingsApp_UI_UIListLayout = Instance.new("UIListLayout")
	SettingsApp_UI_UIListLayout.SortOrder = Enum.SortOrder.Name
	SettingsApp_UI_UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	SettingsApp_UI_UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	SettingsApp_UI_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	SettingsApp_UI_UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
	SettingsApp_UI_UIListLayout.VerticalFlex = Enum.UIFlexAlignment.None
	SettingsApp_UI_UIListLayout.Parent = SettingsApp_UI

	local SettingsApp_UI_SettingsList = Instance.new("ScrollingFrame")
	SettingsApp_UI_SettingsList.Name = "SettingsList"
	SettingsApp_UI_SettingsList.AnchorPoint = Vector2.new(0, 0.5)
	SettingsApp_UI_SettingsList.Size = UDim2.new(1, 0, 1, 0)
	SettingsApp_UI_SettingsList.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
	SettingsApp_UI_SettingsList.BackgroundTransparency = 0
	SettingsApp_UI_SettingsList.ClipsDescendants = true
	SettingsApp_UI_SettingsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	SettingsApp_UI_SettingsList.CanvasSize = UDim2.new(0, 0, 1.25, 0)
	SettingsApp_UI_SettingsList.ZIndex = SettingsApp_UI.ZIndex + 1
	SettingsApp_UI_SettingsList.ScrollBarThickness = 12
	SettingsApp_UI_SettingsList.ScrollBarImageColor3 = Color3.fromRGB(76, 176, 185)
	SettingsApp_UI_SettingsList.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	SettingsApp_UI_SettingsList.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	SettingsApp_UI_SettingsList.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	SettingsApp_UI_SettingsList.Visible = true
	SettingsApp_UI_SettingsList.Active = true
	SettingsApp_UI_SettingsList.ClipsDescendants = true
	SettingsApp_UI_SettingsList.Parent = SettingsApp_UI

	local SettingsApp_UI_SettingsList_ButtonContainer = Instance.new("UIListLayout")
	SettingsApp_UI_SettingsList_ButtonContainer.Name = "ButtonsContainer"
	SettingsApp_UI_SettingsList_ButtonContainer.SortOrder = Enum.SortOrder.LayoutOrder
	SettingsApp_UI_SettingsList_ButtonContainer.FillDirection = Enum.FillDirection.Vertical
	SettingsApp_UI_SettingsList_ButtonContainer.HorizontalAlignment = Enum.HorizontalAlignment.Center
	SettingsApp_UI_SettingsList_ButtonContainer.VerticalAlignment = Enum.VerticalAlignment.Top
	SettingsApp_UI_SettingsList_ButtonContainer.HorizontalFlex = Enum.UIFlexAlignment.None
	SettingsApp_UI_SettingsList_ButtonContainer.VerticalFlex = Enum.UIFlexAlignment.None
	SettingsApp_UI_SettingsList_ButtonContainer.Parent = SettingsApp_UI_SettingsList
end

-- ============================================
-- CHUNK 15: Translation App
-- ============================================
local function createChunk15()
	local ReplicatedWindow = MainUI:FindFirstChild("ReplicatedWindow")

	local TranslationApp = Instance.new("Frame")
	TranslationApp.Name = "Library Stands"
	TranslationApp.AnchorPoint = Vector2.new(0.5, 0.5)
	TranslationApp.BackgroundTransparency = 0
	TranslationApp.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TranslationApp.Size = UDim2.new(1, 0, 1, 0)
	TranslationApp.Position = UDim2.new(0.5, 0, 0.5, 0)
	TranslationApp.ZIndex = 6
	TranslationApp.Visible = false
	TranslationApp.Parent = ReplicatedWindow

	local Data_TranslationApp = Instance.new("Folder")
	Data_TranslationApp.Name = "Data"
	Data_TranslationApp.Parent = TranslationApp

	local Desc_TranslationApp = Instance.new("StringValue")
	Desc_TranslationApp.Name = "Description"
	Desc_TranslationApp.Value = "Library Stands has been created for modifying Slap Battles's rule game by Sky Attacker !"
	Desc_TranslationApp.Parent = Data_TranslationApp

	local Version_TranslationApp = Instance.new("StringValue")
	Version_TranslationApp.Name = "Version"
	Version_TranslationApp.Value = "3.21.8"
	Version_TranslationApp.Parent = Data_TranslationApp

	createUICorner(TranslationApp, "UICorner_Translation", UDim.new(0, 10))

	local UIScale_Translation = Instance.new("UIScale")
	UIScale_Translation.Parent = TranslationApp
	UIScale_Translation.Scale = 0

	local PreviewAppInfoZL_Translation = Instance.new("Frame")
	PreviewAppInfoZL_Translation.Name = "PreviewAppInfoZL"
	PreviewAppInfoZL_Translation.AnchorPoint = Vector2.new(0.5, 0.5)
	PreviewAppInfoZL_Translation.AutomaticSize = Enum.AutomaticSize.XY
	PreviewAppInfoZL_Translation.BackgroundColor3 = Color3.fromRGB(59, 232, 189)
	PreviewAppInfoZL_Translation.BackgroundTransparency = 0.35
	PreviewAppInfoZL_Translation.Position = UDim2.new(0.082, 0, 0.031, 0)
	PreviewAppInfoZL_Translation.Size = UDim2.new(0.165, 0, 0.061, 0)
	PreviewAppInfoZL_Translation.ZIndex = 8
	PreviewAppInfoZL_Translation.Visible = false
	PreviewAppInfoZL_Translation.Parent = TranslationApp

	createUICorner(PreviewAppInfoZL_Translation, "UICorner_PreviewAppInfoZL_Translation", UDim.new(0.5, 0))

	local TextLabel_PreviewAppInfoZL_Translation = Instance.new("TextLabel")
	TextLabel_PreviewAppInfoZL_Translation.Name = "AppNameLabel"
	TextLabel_PreviewAppInfoZL_Translation.AnchorPoint = Vector2.new(0.5, 0.5)
	TextLabel_PreviewAppInfoZL_Translation.Position = UDim2.new(0.409, 0, 0.5, 0)
	TextLabel_PreviewAppInfoZL_Translation.Size = UDim2.new(0, 150, 0, 25)
	TextLabel_PreviewAppInfoZL_Translation.BackgroundTransparency = 1
	TextLabel_PreviewAppInfoZL_Translation.TextScaled = true
	TextLabel_PreviewAppInfoZL_Translation.Font = Enum.Font.Oswald
	TextLabel_PreviewAppInfoZL_Translation.RichText = true
	TextLabel_PreviewAppInfoZL_Translation.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel_PreviewAppInfoZL_Translation.ZIndex = PreviewAppInfoZL_Translation.ZIndex

	local ImageLabel_PreviewAppInfoZL_Translation = Instance.new("ImageLabel")
	ImageLabel_PreviewAppInfoZL_Translation.AnchorPoint = Vector2.new(0.5, 0.5)
	ImageLabel_PreviewAppInfoZL_Translation.AutomaticSize = Enum.AutomaticSize.XY
	ImageLabel_PreviewAppInfoZL_Translation.BackgroundTransparency = 1
	ImageLabel_PreviewAppInfoZL_Translation.Position = UDim2.new(0.9, 0, 0.5, 0)
	ImageLabel_PreviewAppInfoZL_Translation.Size = UDim2.new(0, 39, 0, 39)
	ImageLabel_PreviewAppInfoZL_Translation.ZIndex = PreviewAppInfoZL_Translation.ZIndex
	ImageLabel_PreviewAppInfoZL_Translation.Image = "rbxassetid://93494988440239"
	ImageLabel_PreviewAppInfoZL_Translation.ScaleType = Enum.ScaleType.Fit
	ImageLabel_PreviewAppInfoZL_Translation.Parent = PreviewAppInfoZL_Translation

	createUICorner(ImageLabel_PreviewAppInfoZL_Translation, "UICorner_ImageLabel_Translation_PreviewAppInfoZL", UDim.new(0.5, 0))

	local TranslationApp_UI = Instance.new("Frame")
	TranslationApp_UI.Name = "UI"
	TranslationApp_UI.AnchorPoint = Vector2.new(0.5, 0.5)
	TranslationApp_UI.Position = UDim2.new(0.5, 0, 0.495, 0)
	TranslationApp_UI.Size = UDim2.new(1, 0, 0.89, 0)
	TranslationApp_UI.ZIndex = TranslationApp.ZIndex - 1
	TranslationApp_UI.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
	TranslationApp_UI.BackgroundTransparency = 0.65
	TranslationApp_UI.Visible = true
	TranslationApp_UI.Parent = TranslationApp

	createUICorner(TranslationApp_UI, "TranslationApp_UI_UICorner", UDim.new(0, 10))

	local SideButtonsMenuUI = Instance.new("Frame")
	SideButtonsMenuUI.Name = "SideButtonsMenuUI"
	SideButtonsMenuUI.AnchorPoint = Vector2.new(0, 0.5)
	SideButtonsMenuUI.Position = UDim2.new(0, 0, 0.2, 50)
	SideButtonsMenuUI.Size = UDim2.new(0.088, 50, 0.27, 0)
	SideButtonsMenuUI.BackgroundTransparency = 1
	SideButtonsMenuUI.Parent = TranslationApp

	local SideButtonsMenuUI_UIAspectRatio = Instance.new("UIAspectRatioConstraint")
	SideButtonsMenuUI_UIAspectRatio.Parent = SideButtonsMenuUI
	SideButtonsMenuUI_UIAspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
	SideButtonsMenuUI_UIAspectRatio.AspectRatio = 1
	SideButtonsMenuUI_UIAspectRatio.DominantAxis = Enum.DominantAxis.Width

	local SideButtonsMenuUI_UIListLayout = Instance.new("UIListLayout")
	SideButtonsMenuUI_UIListLayout.Parent = SideButtonsMenuUI
	SideButtonsMenuUI_UIListLayout.Padding = UDim.new(0, 8)
	SideButtonsMenuUI_UIListLayout.FillDirection = Enum.FillDirection.Vertical
	SideButtonsMenuUI_UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SideButtonsMenuUI_UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	SideButtonsMenuUI_UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	SideButtonsMenuUI_UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
	SideButtonsMenuUI_UIListLayout.VerticalFlex = Enum.UIFlexAlignment.None
	SideButtonsMenuUI_UIListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic

	local MainFrame_UI = Instance.new("Frame")
	MainFrame_UI.Name = "MainFrame"
	MainFrame_UI.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame_UI.Position = UDim2.new(0.5, 0, 0.496, 0)
	MainFrame_UI.Size = UDim2.new(1, 0, 0.893, 0)
	MainFrame_UI.ZIndex = 6
	MainFrame_UI.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainFrame_UI.BackgroundTransparency = 1
	MainFrame_UI.Parent = TranslationApp
end

-- ============================================
-- CHUNK 16: SideButtons & Connection Events
-- ============================================
local function createChunk16()
	local SideButtons = Instance.new("Frame")
	SideButtons.Name = "SideButtons"
	SideButtons.AnchorPoint = Vector2.new(0.1, 0.5)
	SideButtons.Position = UDim2.new(0, 0, 0.35, 50)
	SideButtons.Size = UDim2.new(0.1, 50, 0.4, 0)
	SideButtons.SizeConstraint = Enum.SizeConstraint.RelativeXY
	SideButtons.ZIndex = 1
	SideButtons.Visible = true
	SideButtons.Transparency = 1
	SideButtons.Parent = MainUI

	local UIAspectRatio = Instance.new("UIAspectRatioConstraint")
	UIAspectRatio.AspectRatio = 1
	UIAspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatio.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatio.Parent = SideButtons

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0, 8)
	UIListLayout.FillDirection = Enum.FillDirection.Vertical
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
	UIListLayout.VerticalFlex = Enum.UIFlexAlignment.None
	UIListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	UIListLayout.Parent = SideButtons

	local ButtonSettings = Instance.new("TextButton")
	ButtonSettings.AnchorPoint = Vector2.new(0.05, 0.5)
	ButtonSettings.AutoButtonColor = true
	ButtonSettings.Active = true
	ButtonSettings.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	ButtonSettings.BackgroundTransparency = 0.3
	ButtonSettings.Name = "ButtonSettings"
	ButtonSettings.Size = UDim2.new(0.42, 0, 0.3, 0)
	ButtonSettings.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ButtonSettings.ZIndex = 1
	ButtonSettings.Visible = true
	ButtonSettings.Font = Enum.Font.Oswald
	ButtonSettings.Text = ""
	ButtonSettings.TextColor3 = Color3.fromRGB(255, 255, 189)
	ButtonSettings.TextScaled = true
	ButtonSettings.TextSize = 14
	ButtonSettings.TextYAlignment = Enum.TextYAlignment.Center
	ButtonSettings.TextXAlignment = Enum.TextXAlignment.Left
	ButtonSettings.TextWrapped = true
	ButtonSettings.Parent = SideButtons

	createUICorner(ButtonSettings, "UICorner_ButtonSettings", UDim.new(0.15, 0))

	local UIPaddding_ButtonSettings = Instance.new("UIPadding")
	UIPaddding_ButtonSettings.PaddingLeft = UDim.new(0.05, 0)
	UIPaddding_ButtonSettings.PaddingRight = UDim.new(0.05, 0)
	UIPaddding_ButtonSettings.PaddingTop = UDim.new(0, 0)
	UIPaddding_ButtonSettings.PaddingBottom = UDim.new(0, 0)
	UIPaddding_ButtonSettings.Parent = ButtonSettings

	local UIStroke_ButtonSettings = Instance.new("UIStroke")
	UIStroke_ButtonSettings.Color = Color3.fromRGB(157, 157, 157)
	UIStroke_ButtonSettings.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke_ButtonSettings.Thickness = 3
	UIStroke_ButtonSettings.LineJoinMode = Enum.LineJoinMode.Round
	UIStroke_ButtonSettings.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	UIStroke_ButtonSettings.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	UIStroke_ButtonSettings.ZIndex = 1
	UIStroke_ButtonSettings.Transparency = 0
	UIStroke_ButtonSettings.Parent = ButtonSettings

	local ImageLabel_ButtonSettings = Instance.new("ImageLabel")
	ImageLabel_ButtonSettings.AnchorPoint = Vector2.new(1, 0.5)
	ImageLabel_ButtonSettings.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageLabel_ButtonSettings.BackgroundTransparency = 1
	ImageLabel_ButtonSettings.BorderColor3 = Color3.fromRGB(27, 42, 53)
	ImageLabel_ButtonSettings.Position = UDim2.new(1, 0, 0.5, 0)
	ImageLabel_ButtonSettings.Size = UDim2.new(1, 0, 0.7, 0)
	ImageLabel_ButtonSettings.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ImageLabel_ButtonSettings.ZIndex = 2
	ImageLabel_ButtonSettings.Visible = true
	ImageLabel_ButtonSettings.Image = "rbxassetid://5912368763"
	ImageLabel_ButtonSettings.ImageColor3 = Color3.fromRGB(48, 48, 48)
	ImageLabel_ButtonSettings.ScaleType = Enum.ScaleType.Fit
	ImageLabel_ButtonSettings.Parent = ButtonSettings
end

-- ============================================
-- CHUNK 17: ZolinInstaller App
-- ============================================
local function createChunk17()
	local ReplicatedWindow_Sys = MainUI:FindFirstChild("ReplicatedWindow")

	local ZolinInstaller = Instance.new("Frame")
	ZolinInstaller.Name = "ZolinInstaller"
	ZolinInstaller.AnchorPoint = Vector2.new(0.5, 0.5)
	ZolinInstaller.BackgroundTransparency = 0
	ZolinInstaller.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ZolinInstaller.Size = UDim2.new(1, 0, 1, 0)
	ZolinInstaller.Position = UDim2.new(0.5, 0, 0.5, 0)
	ZolinInstaller.ZIndex = 6
	ZolinInstaller.Visible = false
	ZolinInstaller.Parent = ReplicatedWindow_Sys

	local Data_ZolinInstaller = Instance.new("Folder")
	Data_ZolinInstaller.Name = "Data"
	Data_ZolinInstaller.Parent = ZolinInstaller

	local Desc_ZolinInstaller = Instance.new("StringValue")
	Desc_ZolinInstaller.Name = "Description"
	Desc_ZolinInstaller.Value = "Install new apps via loadstring"
	Desc_ZolinInstaller.Parent = Data_ZolinInstaller

	local Version_ZolinInstaller = Instance.new("StringValue")
	Version_ZolinInstaller.Name = "Version"
	Version_ZolinInstaller.Value = "1.0"
	Version_ZolinInstaller.Parent = Data_ZolinInstaller

	createUICorner(ZolinInstaller, "UICorner_ZolinInstaller", UDim.new(0, 10))

	local UIScale_ZolinInstaller = Instance.new("UIScale")
	UIScale_ZolinInstaller.Parent = ZolinInstaller
	UIScale_ZolinInstaller.Scale = 0

	local PreviewAppInfoZL_ZolinInstaller = Instance.new("Frame")
	PreviewAppInfoZL_ZolinInstaller.Name = "PreviewAppInfoZL"
	PreviewAppInfoZL_ZolinInstaller.AnchorPoint = Vector2.new(0.5, 0.5)
	PreviewAppInfoZL_ZolinInstaller.AutomaticSize = Enum.AutomaticSize.XY
	PreviewAppInfoZL_ZolinInstaller.BackgroundColor3 = Color3.fromRGB(59, 232, 189)
	PreviewAppInfoZL_ZolinInstaller.BackgroundTransparency = 0.35
	PreviewAppInfoZL_ZolinInstaller.Position = UDim2.new(0.082, 0, 0.031, 0)
	PreviewAppInfoZL_ZolinInstaller.Size = UDim2.new(0.165, 0, 0.061, 0)
	PreviewAppInfoZL_ZolinInstaller.ZIndex = 8
	PreviewAppInfoZL_ZolinInstaller.Visible = false
	PreviewAppInfoZL_ZolinInstaller.Parent = ZolinInstaller

	createUICorner(PreviewAppInfoZL_ZolinInstaller, "UICorner_PreviewAppInfoZL_ZolinInstaller", UDim.new(0.5, 0))

	local TextLabel_PreviewAppInfoZL_ZolinInstaller = Instance.new("TextLabel")
	TextLabel_PreviewAppInfoZL_ZolinInstaller.Name = "AppNameLabel"
	TextLabel_PreviewAppInfoZL_ZolinInstaller.AnchorPoint = Vector2.new(0.5, 0.5)
	TextLabel_PreviewAppInfoZL_ZolinInstaller.Position = UDim2.new(0.409, 0, 0.5, 0)
	TextLabel_PreviewAppInfoZL_ZolinInstaller.Size = UDim2.new(0, 150, 0, 25)
	TextLabel_PreviewAppInfoZL_ZolinInstaller.BackgroundTransparency = 1
	TextLabel_PreviewAppInfoZL_ZolinInstaller.TextScaled = true
	TextLabel_PreviewAppInfoZL_ZolinInstaller.Font = Enum.Font.Oswald
	TextLabel_PreviewAppInfoZL_ZolinInstaller.RichText = true
	TextLabel_PreviewAppInfoZL_ZolinInstaller.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel_PreviewAppInfoZL_ZolinInstaller.ZIndex = PreviewAppInfoZL_ZolinInstaller.ZIndex

	local ImageLabel_PreviewAppInfoZL_ZolinInstaller = Instance.new("ImageLabel")
	ImageLabel_PreviewAppInfoZL_ZolinInstaller.AnchorPoint = Vector2.new(0.5, 0.5)
	ImageLabel_PreviewAppInfoZL_ZolinInstaller.AutomaticSize = Enum.AutomaticSize.XY
	ImageLabel_PreviewAppInfoZL_ZolinInstaller.BackgroundTransparency = 1
	ImageLabel_PreviewAppInfoZL_ZolinInstaller.Position = UDim2.new(0.9, 0, 0.5, 0)
	ImageLabel_PreviewAppInfoZL_ZolinInstaller.Size = UDim2.new(0, 39, 0, 39)
	ImageLabel_PreviewAppInfoZL_ZolinInstaller.ZIndex = PreviewAppInfoZL_ZolinInstaller.ZIndex
	ImageLabel_PreviewAppInfoZL_ZolinInstaller.Image = "rbxassetid://128691285053548"  -- your icon
	ImageLabel_PreviewAppInfoZL_ZolinInstaller.ScaleType = Enum.ScaleType.Fit
	ImageLabel_PreviewAppInfoZL_ZolinInstaller.Parent = PreviewAppInfoZL_ZolinInstaller

	createUICorner(ImageLabel_PreviewAppInfoZL_ZolinInstaller, "UICorner_ImageLabel_ZolinInstaller", UDim.new(0.5, 0))

	local ZolinInstaller_UI = Instance.new("Frame")
	ZolinInstaller_UI.Name = "UI"
	ZolinInstaller_UI.AnchorPoint = Vector2.new(0.5, 0.5)
	ZolinInstaller_UI.Position = UDim2.new(0.5, 0, 0.495, 0)
	ZolinInstaller_UI.Size = UDim2.new(1, 0, 0.89, 0)
	ZolinInstaller_UI.ZIndex = ZolinInstaller.ZIndex - 1
	ZolinInstaller_UI.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
	ZolinInstaller_UI.BackgroundTransparency = 0.65
	ZolinInstaller_UI.Visible = true
	ZolinInstaller_UI.Parent = ZolinInstaller

	createUICorner(ZolinInstaller_UI, "ZolinInstaller_UI_UICorner", UDim.new(0, 10))

	-- URL TEXTBOX
	local urlBar = Instance.new("TextBox")
	urlBar.Name = "URLBar"
	urlBar.AnchorPoint = Vector2.new(0.5, 0.5)
	urlBar.Position = UDim2.new(0.5, 0, 0.38, 0)
	urlBar.Size = UDim2.new(0.8, 0, 0.08, 0)
	urlBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	urlBar.TextColor3 = Color3.new(1, 1, 1)
	urlBar.PlaceholderText = "insert Loadstring URL package"
	urlBar.Text = ""
	urlBar.Font = Enum.Font.Gotham
	urlBar.TextSize = 14
	urlBar.TextXAlignment = Enum.TextXAlignment.Left
	urlBar.ZIndex = ZolinInstaller_UI.ZIndex + 1
	urlBar.Parent = ZolinInstaller_UI
	createUICorner(urlBar, "URLBar_Corner", UDim.new(0, 8))

	-- Install Button (moved a bit down to make space)
	local InstallButton = Instance.new("TextButton")
	InstallButton.Name = "InstallButton"
	InstallButton.AnchorPoint = Vector2.new(0.5, 0.5)
	InstallButton.Position = UDim2.new(0.5, 0, 0.52, 0)
	InstallButton.Size = UDim2.new(0.4, 0, 0.08, 0)
	InstallButton.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
	InstallButton.BackgroundTransparency = 0.2
	InstallButton.Text = "Install"
	InstallButton.TextColor3 = Color3.new(1, 1, 1)
	InstallButton.Font = Enum.Font.GothamBold
	InstallButton.TextSize = 18
	InstallButton.ZIndex = ZolinInstaller_UI.ZIndex + 1
	InstallButton.Parent = ZolinInstaller_UI

	createUICorner(InstallButton, "InstallButton_Corner", UDim.new(0, 8))

	-- Confirmation Popup (hidden)
	local ConfirmationPopup = Instance.new("Frame")
	ConfirmationPopup.Name = "ConfirmationPopup"
	ConfirmationPopup.AnchorPoint = Vector2.new(0.5, 0.5)
	ConfirmationPopup.Position = UDim2.new(0.5, 0, 1.5, 0)   -- off-screen
	ConfirmationPopup.Size = UDim2.new(0.6, 0, 0.25, 0)
	ConfirmationPopup.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	ConfirmationPopup.BackgroundTransparency = 0
	ConfirmationPopup.ZIndex = ZolinInstaller_UI.ZIndex + 2
	ConfirmationPopup.Visible = false
	ConfirmationPopup.Parent = ZolinInstaller_UI

	createUICorner(ConfirmationPopup, "ConfirmationPopup_Corner", UDim.new(0, 12))

	-- Popup text
	local ConfirmText = Instance.new("TextLabel")
	ConfirmText.Name = "ConfirmText"
	ConfirmText.AnchorPoint = Vector2.new(0.5, 0.5)
	ConfirmText.Position = UDim2.new(0.5, 0, 0.25, 0)
	ConfirmText.Size = UDim2.new(0.9, 0, 0.3, 0)
	ConfirmText.BackgroundTransparency = 1
	ConfirmText.Text = "Are you sure you want to install this app?"
	ConfirmText.TextColor3 = Color3.new(1, 1, 1)
	ConfirmText.Font = Enum.Font.GothamBold
	ConfirmText.TextSize = 16
	ConfirmText.TextWrapped = true
	ConfirmText.TextXAlignment = Enum.TextXAlignment.Center
	ConfirmText.ZIndex = ConfirmationPopup.ZIndex + 1
	ConfirmText.Parent = ConfirmationPopup

	-- Yes Button
	local YesButton = Instance.new("TextButton")
	YesButton.Name = "Yes"
	YesButton.AnchorPoint = Vector2.new(0.5, 0.5)
	YesButton.Position = UDim2.new(0.35, 0, 0.65, 0)
	YesButton.Size = UDim2.new(0.25, 0, 0.15, 0)
	YesButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	YesButton.Text = "Yes"
	YesButton.TextColor3 = Color3.new(1, 1, 1)
	YesButton.Font = Enum.Font.GothamBold
	YesButton.TextSize = 14
	YesButton.ZIndex = ConfirmationPopup.ZIndex + 1
	YesButton.Parent = ConfirmationPopup

	createUICorner(YesButton, "YesButton_Corner", UDim.new(0, 6))

	-- Cancel Button
	local CancelButton = Instance.new("TextButton")
	CancelButton.Name = "Cancel"
	CancelButton.AnchorPoint = Vector2.new(0.5, 0.5)
	CancelButton.Position = UDim2.new(0.65, 0, 0.65, 0)
	CancelButton.Size = UDim2.new(0.25, 0, 0.15, 0)
	CancelButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	CancelButton.Text = "Cancel"
	CancelButton.TextColor3 = Color3.new(1, 1, 1)
	CancelButton.Font = Enum.Font.GothamBold
	CancelButton.TextSize = 14
	CancelButton.ZIndex = ConfirmationPopup.ZIndex + 1
	CancelButton.Parent = ConfirmationPopup

	createUICorner(CancelButton, "CancelButton_Corner", UDim.new(0, 6))
end

-- ============================================
-- CHUNK 18: ZolinInstaller Auto-Install Queue
-- ============================================
local function createChunk18()
	local __Zolin = MainUI:FindFirstChild("__Zolin")
	if not __Zolin then return end
	local zero = __Zolin:FindFirstChild("0")
	if not zero then
		zero = Instance.new("Folder")
		zero.Name = "0"
		zero.Parent = __Zolin
	end
	local ZolinInstaller_UI = zero:FindFirstChild("ZolinInstaller")
	if not ZolinInstaller_UI then
		local newInstaller = Instance.new("Folder", zero);
		newInstaller.Name = "ZolinInstaller"
		ZolinInstaller_UI = newInstaller
	end
	local __autoInstallOnInit = ZolinInstaller_UI:FindFirstChild("__autoInstallOnInit")
	if not __autoInstallOnInit then
		__autoInstallOnInit = Instance.new("Folder")
		__autoInstallOnInit.Name = "__autoInstallOnInit"
		__autoInstallOnInit.Parent = ZolinInstaller_UI
	end

	-- Package queue: [Name] = URL
	local __packageQueue = {
		Changelogs = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/__package_Changelogs.lua",
		MemoryDisplay = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/__package_MemoryDisplayApp.lua",
	}

	-- Create a StringValue for each package
	for appName, appUrl in pairs(__packageQueue) do
		-- Skip if already queued or installed
		if not __autoInstallOnInit:FindFirstChild(appName) then
			local entry = Instance.new("StringValue")
			entry.Name = appName
			entry.Value = appUrl
			entry.Parent = __autoInstallOnInit
			print("Added to auto-install queue:", appName)
		end
	end

	print("Successfully loaded ZolinInstaller | auto installation queue")
end

-- ============================================
-- CHUNK 19: __ZolinDesktop -> __ScreenFrame & Basic UI
-- ============================================
local function createChunk19()
	-- UIStroke
	createUIStroke(__ZolinDesktop, "UIStroke", Color3.fromRGB(33, 33, 33), 14.8, 0.67, 3)

	-- UICorner
	createUICorner(__ZolinDesktop, "UICorner", UDim.new(0, 8))

	-- UIScale
	createUIScale(__ZolinDesktop, "UIScale", 1)

	-- Applications Folder
	local Applications = Instance.new("Folder")
	Applications.Name = "Applications"
	Applications.Parent = __DesktopScreenFrame

	-- Wallpaper
	local Wallpaper = Instance.new("ImageLabel")
	Wallpaper.Name = "Wallpaper"
	Wallpaper.AnchorPoint = Vector2.new(0.5, 0.5)
	Wallpaper.Position = UDim2.new(0.5, 0, 0.5, 0)
	Wallpaper.Size = UDim2.new(1, 0, 1, 0)
	Wallpaper.BackgroundTransparency = 0
	Wallpaper.Image = "rbxassetid://14098940223" --"rbxassetid://2387794684" default
	Wallpaper.ScaleType = Enum.ScaleType.Stretch
	Wallpaper.ZIndex = 2
	Wallpaper.ClipsDescendants = false
	Wallpaper.Parent = __DesktopScreenFrame
	Wallpaper.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end

-- ============================================
-- CHUNK 20: __ZolinDesktop -> __ScreenFrame -> HomeScreenScroller
-- ============================================
local function createChunk20()
	local HomeScreenScroller = Instance.new("ScrollingFrame")
	HomeScreenScroller.Name = "HomeScreenScrollerV2"
	HomeScreenScroller.AnchorPoint = Vector2.new(0.5, 0.5)
	HomeScreenScroller.Position = UDim2.new(0.5, 0, 0.495, 0)
	HomeScreenScroller.Size = UDim2.new(0.99, 0, 0.891, 0)
	HomeScreenScroller.BackgroundTransparency = 1
	HomeScreenScroller.ZIndex = 3
	HomeScreenScroller.Visible = true
	HomeScreenScroller.ScrollingDirection = Enum.ScrollingDirection.X
	HomeScreenScroller.AutomaticCanvasSize = Enum.AutomaticSize.XY
	HomeScreenScroller.CanvasSize = UDim2.new(1, 1, 0, 0)
	HomeScreenScroller.ScrollBarImageTransparency = 1
	HomeScreenScroller.ScrollBarThickness = 0
	HomeScreenScroller.ScrollingEnabled = false
	HomeScreenScroller.Active = true
	HomeScreenScroller.VerticalScrollBarInset = Enum.ScrollBarInset.None
	HomeScreenScroller.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	HomeScreenScroller.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	HomeScreenScroller.ElasticBehavior = Enum.ElasticBehavior.Always
	HomeScreenScroller.Parent = __DesktopScreenFrame

	local UIListLayout2 = Instance.new("UIListLayout")
	UIListLayout2.SortOrder = Enum.SortOrder.Name
	UIListLayout2.FillDirection = Enum.FillDirection.Vertical
	UIListLayout2.VerticalAlignment = Enum.VerticalAlignment.Top
	UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Left
	UIListLayout2.HorizontalFlex = Enum.UIFlexAlignment.None
	UIListLayout2.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	UIListLayout2.VerticalFlex = Enum.UIFlexAlignment.Fill
	UIListLayout2.Padding = UDim.new(0.07, 0)
	UIListLayout2.Wraps = true
	UIListLayout2.Parent = HomeScreenScroller
end

-- ============================================
-- CHUNK 21: __ZolinDesktop -> ReplicatedIcons & Notification Templates
-- ============================================
local function createChunk21()
	local ReplicatedIcons = nil
	if not MainUI:FindFirstChild("ReplicatedIcons") then
		ReplicatedIcons = Instance.new("Folder")
		ReplicatedIcons.Name = "ReplicatedIcons"
		ReplicatedIcons.Parent = MainUI
	else
		ReplicatedIcons = MainUI:FindFirstChild("ReplicatedIcons")
	end

	local AppIconTemplate = Instance.new("ImageButton")
	AppIconTemplate.Name = "AppIconTemplateV2"
	AppIconTemplate.Visible = false
	AppIconTemplate.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	AppIconTemplate.Size = UDim2.new(0.037, 0, 0.087, 0)
	AppIconTemplate.Position = UDim2.new(0.5, 0, 0.5, 0)
	AppIconTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	AppIconTemplate.BackgroundTransparency = 0
	AppIconTemplate.ImageTransparency = 0
	AppIconTemplate.Visible = false
	AppIconTemplate.ScaleType = Enum.ScaleType.Fit
	AppIconTemplate.ZIndex = 4
	AppIconTemplate.Parent = ReplicatedIcons

	local UIAspectRatioConstraint16 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint16.Parent = AppIconTemplate
	UIAspectRatioConstraint16.AspectRatio = 1
	UIAspectRatioConstraint16.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint16.DominantAxis = Enum.DominantAxis.Width

	local UIStroke1 = Instance.new("UIStroke")
	UIStroke1.Parent = AppIconTemplate
	UIStroke1.Color = Color3.fromRGB(65, 64, 64)
	UIStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	UIStroke1.Thickness = 2
	UIStroke1.Transparency = 0.58

	createUICorner(AppIconTemplate, "UICorner1", UDim.new(0.2, 0))

	local AppName = Instance.new("TextLabel")
	AppName.Name = "AppName"
	AppName.Parent = AppIconTemplate
	AppName.AnchorPoint = Vector2.new(0.5, 0.5)
	AppName.Position = UDim2.new(0.5, 0, 1.294, 0)
	AppName.Size = UDim2.new(1.882, 0, 0.353, 0)
	AppName.BackgroundTransparency = 1
	AppName.Text = "App Name"
	AppName.TextColor3 = Color3.fromRGB(255, 251, 251)
	AppName.TextScaled = true
	AppName.TextSize = 14
	AppName.TextWrapped = true
	AppName.RichText = true
	AppName.Font = Enum.Font.SourceSansBold
	AppName.TextXAlignment = Enum.TextXAlignment.Center
	AppName.TextYAlignment = Enum.TextYAlignment.Center
	AppName.TextStrokeTransparency = 0.5
	AppName.ZIndex = 4
	AppName.Visible = true

	local UIAspectRatioConstraint17 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint17.Parent = AppName
	UIAspectRatioConstraint17.AspectRatio = 5.333
	UIAspectRatioConstraint17.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint17.DominantAxis = Enum.DominantAxis.Width

	local UITextSizeConstraint_AppName = Instance.new("UITextSizeConstraint")
	UITextSizeConstraint_AppName.Parent = AppName
	UITextSizeConstraint_AppName.MaxTextSize = 30
	UITextSizeConstraint_AppName.MinTextSize = 1

	local OutlineFrameHighlight = Instance.new("Frame");
	OutlineFrameHighlight.Name = "OutlineFrameHighlight";
	OutlineFrameHighlight.Size = UDim2.new(1.272, 0, 1.439, 0);
	OutlineFrameHighlight.Position = UDim2.new(-0.211, 0, -0.137, 0);
	OutlineFrameHighlight.BackgroundTransparency = 0.45;
	OutlineFrameHighlight.BackgroundColor3 = Color3.fromRGB(49, 49, 49);
	OutlineFrameHighlight.ZIndex = 2;
	OutlineFrameHighlight.Visible = false;
	OutlineFrameHighlight.Parent = AppIconTemplate;
	createUICorner(OutlineFrameHighlight, "UICorner1", UDim.new(0.1, 0));
	createUIStroke(OutlineFrameHighlight, "UIStroke", Color3.fromRGB(0, 112, 231), 5.5, 0.58, 1)

	local UIAspectRatioConstraint18 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint18.Parent = OutlineFrameHighlight
	UIAspectRatioConstraint18.AspectRatio = 0.915
	UIAspectRatioConstraint18.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint18.DominantAxis = Enum.DominantAxis.Width
end

-- ============================================
-- CHUNK 22: ReplicatedWindow_Sys & ExampleWindow | Desktop Mode
-- ============================================
local function createChunk22()
	local ReplicatedWindow_Sys 
	if not MainUI:FindFirstChild("ReplicatedWindow_Sys") then
		ReplicatedWindow_Sys = Instance.new("Folder")
		ReplicatedWindow_Sys.Name = "ReplicatedWindow_Sys"
		ReplicatedWindow_Sys.Parent = MainUI
	else
		ReplicatedWindow_Sys = MainUI:FindFirstChild("ReplicatedWindow_Sys")
	end

	local ExampleWindow = Instance.new("Frame")
	ExampleWindow.Name = "ExampleWindowV2"
	ExampleWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	ExampleWindow.BackgroundTransparency = 0
	ExampleWindow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ExampleWindow.Size = UDim2.new(1, 0, 0.882, 0)
	ExampleWindow.Position = UDim2.new(0.5, 0, 0.499, 0)
	ExampleWindow.Visible = false
	ExampleWindow.ZIndex = 6
	ExampleWindow.Active = true
	ExampleWindow.Parent = ReplicatedWindow_Sys
	createUIScale(ExampleWindow, "UIScale", 0.85);
	createUICorner(ExampleWindow, "UICorner_ExampleWindow", UDim.new(0, 2))

	local ExampleWindow_UI = Instance.new("Frame")
	ExampleWindow_UI.Name = "UI"
	ExampleWindow_UI.AnchorPoint = Vector2.new(0.5, 0.5)
	ExampleWindow_UI.BackgroundTransparency = 1
	ExampleWindow_UI.BackgroundColor3 = Color3.fromRGB(70, 255, 255)
	ExampleWindow_UI.Size = UDim2.new(1, 0, 0.937, 0)
	ExampleWindow_UI.Position = UDim2.new(0.5, 0, 0.531, 0)
	ExampleWindow_UI.ZIndex = ExampleWindow.ZIndex + 1
	ExampleWindow_UI.Visible = true
	ExampleWindow_UI.Active = true
	ExampleWindow_UI.Parent = ExampleWindow

	local TileInfo = Instance.new("Frame")
	TileInfo.Name = "TileInfo"
	TileInfo.AnchorPoint = Vector2.new(0.5, 0.5)
	TileInfo.BackgroundTransparency = 1
	TileInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TileInfo.Size = UDim2.new(1, 0, 0.064, 0)
	TileInfo.Position = UDim2.new(0.5, 0, 0.03, 0)
	TileInfo.ZIndex = ExampleWindow_UI.ZIndex
	TileInfo.Visible = true
	TileInfo.Active = true
	TileInfo.Parent = ExampleWindow

	local UIAspectRatioConstraint19 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint19.Parent = TileInfo
	UIAspectRatioConstraint19.AspectRatio = 41.274
	UIAspectRatioConstraint19.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint19.DominantAxis = Enum.DominantAxis.Width

	createUICorner(TileInfo, "UICorner", UDim.new(0, 2));

	local AppIcon = Instance.new("ImageLabel");
	AppIcon.Name = "AppIcon";
	AppIcon.BackgroundTransparency = 1;
	AppIcon.Position = UDim2.new(0.006, 0, 0, 0);
	AppIcon.Size = UDim2.new(0.03, 0, 1, 0);
	AppIcon.ZIndex = TileInfo.ZIndex + 1;
	AppIcon.ScaleType = Enum.ScaleType.Fit;
	AppIcon.Parent = TileInfo;

	local UIAspectRatioConstraint20 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint20.Parent = AppIcon;
	UIAspectRatioConstraint20.AspectRatio = 1;
	UIAspectRatioConstraint20.AspectType = Enum.AspectType.FitWithinMaxSize;
	UIAspectRatioConstraint20.DominantAxis = Enum.DominantAxis.Width;

	local AppName = Instance.new("TextLabel");
	AppName.Name = "AppName";
	AppName.Parent = TileInfo;
	AppName.Position = UDim2.new(0.042, 0, 0, 0);
	AppName.Size = UDim2.new(0.156, 0, 1, 0);
	AppName.ZIndex = TileInfo.ZIndex + 1;
	AppName.BackgroundTransparency = 1;
	AppName.TextScaled = true;
	AppName.TextSize = 23;
	AppName.TextColor3 = Color3.fromRGB(0, 0, 0);
	AppName.Font = Enum.Font.SourceSansBold;
	AppName.TextXAlignment = Enum.TextXAlignment.Left;

	local UITextSizeConstraint = Instance.new("UITextSizeConstraint");
	UITextSizeConstraint.MaxTextSize = 23;
	UITextSizeConstraint.MinTextSize = 1;
	UITextSizeConstraint.Parent = AppName;

	local UIAspectRatioConstraint2 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint2.Parent = AppName;
	UIAspectRatioConstraint2.AspectRatio = 5.146;
	UIAspectRatioConstraint2.AspectType = Enum.AspectType.FitWithinMaxSize;
	UIAspectRatioConstraint2.DominantAxis = Enum.DominantAxis.Width;

	local TileBar = Instance.new("Frame")
	TileBar.Name = "Tilebar"
	TileBar.AnchorPoint = Vector2.new(0.5, 0.5)
	TileBar.BackgroundTransparency = 0
	TileBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TileBar.Size = UDim2.new(1, 0, 0.064, 0)
	TileBar.Position = UDim2.new(0.5, 0, 0.031, 0)
	TileBar.ZIndex = ExampleWindow_UI.ZIndex
	TileBar.Visible = true
	TileBar.Active = true
	TileBar.Parent = ExampleWindow

	local UIAspectRatioConstraint20 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint20.Parent = TileBar
	UIAspectRatioConstraint20.AspectRatio = 40.989
	UIAspectRatioConstraint20.AspectType = Enum.AspectType.FitWithinMaxSize
	UIAspectRatioConstraint20.DominantAxis = Enum.DominantAxis.Width

	createUICorner(TileBar, "UICorner", UDim.new(0, 2));

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Parent = TileBar
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	UIListLayout.Padding = UDim.new(0, 0)

	local Exit = Instance.new("ImageButton");
	Exit.Name = "Exit";
	Exit.AnchorPoint = Vector2.new(0.5, 0.5)
	Exit.Size = UDim2.new(0.044, 0, 0.951, 0);
	Exit.ZIndex = TileBar.ZIndex + 1;
	Exit.Visible = true
	Exit.Active = true
	Exit.Parent = TileBar;
	Exit.Image = "rbxassetid://18749164740";
	Exit.ScaleType = Enum.ScaleType.Fit;
	Exit.BackgroundColor3 = Color3.fromRGB(255, 0, 0);
	Exit.LayoutOrder = 1;

	local UIAspectRatioConstraint21 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint21.Parent = Exit;
	UIAspectRatioConstraint21.AspectRatio = 1.538;
	UIAspectRatioConstraint21.AspectType = Enum.AspectType.FitWithinMaxSize;
	UIAspectRatioConstraint21.DominantAxis = Enum.DominantAxis.Width;

	local Min = Instance.new("ImageButton");
	Min.Name = "Min";
	Min.AnchorPoint = Vector2.new(0.5, 0.5)
	Min.Size = UDim2.new(0.044, 0, 0.951, 0);
	Min.ZIndex = TileBar.ZIndex + 1;
	Min.Visible = true
	Min.Active = true
	Min.Parent = TileBar;
	Min.Image = "rbxassetid://18786430625";
	Min.ScaleType = Enum.ScaleType.Fit;
	Min.BackgroundColor3 = Color3.fromRGB(255, 0, 0);
	Min.BackgroundTransparency = 1;
	Min.LayoutOrder = -1;

	local UIAspectRatioConstraint22 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint22.Parent = Min;
	UIAspectRatioConstraint22.AspectRatio = 1.538;
	UIAspectRatioConstraint22.AspectType = Enum.AspectType.FitWithinMaxSize;
	UIAspectRatioConstraint22.DominantAxis = Enum.DominantAxis.Width;

	local Max = Instance.new("ImageButton");
	Max.Name = "Max";
	Max.AnchorPoint = Vector2.new(0.5, 0.5)
	Max.Size = UDim2.new(0.044, 0, 0.951, 0);
	Max.ZIndex = TileBar.ZIndex + 1;
	Max.Visible = true
	Max.Active = true
	Max.Parent = TileBar;
	Max.Image = "rbxassetid://85022922514331";
	Max.ScaleType = Enum.ScaleType.Fit;
	Max.BackgroundColor3 = Color3.fromRGB(255, 0, 0);
	Max.BackgroundTransparency = 1;
	Max.LayoutOrder = 0;

	local UIAspectRatioConstraint23 = Instance.new("UIAspectRatioConstraint");
	UIAspectRatioConstraint23.Parent = Max;
	UIAspectRatioConstraint23.AspectRatio = 1.538;
	UIAspectRatioConstraint23.AspectType = Enum.AspectType.FitWithinMaxSize;
	UIAspectRatioConstraint23.DominantAxis = Enum.DominantAxis.Width;

end

local function createChunk23()
	local taskbar = Instance.new("Frame")
	taskbar.Name = "Taskbar"
	taskbar.Size = UDim2.new(1, 0, 0.07, 0);
	taskbar.AnchorPoint = Vector2.new(0.5, 1)
	taskbar.Size = UDim2.new(1, 0, 0.06, 0);
	taskbar.Position = UDim2.new(0.5, 0, 1, 0);
	taskbar.BackgroundTransparency = 1;
	taskbar.ZIndex = 999999998;
	taskbar.Parent = __DesktopScreenFrame;
	local UIListLayout = Instance.new("UIListLayout");
	UIListLayout.Parent = taskbar;
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
	local TaskbarApps = Instance.new("Frame");
	TaskbarApps.Name = "TaskbarApps"
	TaskbarApps.Size = UDim2.new(0.7, 0, 1, 0);
	TaskbarApps.BackgroundTransparency = 0.55;
	TaskbarApps.BackgroundColor3 = Color3.fromRGB(43, 43, 43);
	TaskbarApps.ZIndex = 999999997;
	TaskbarApps.Parent = taskbar;
	local UIListLayout2 = Instance.new("UIListLayout");
	UIListLayout2.Parent = TaskbarApps;
	UIListLayout2.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Left;
	UIListLayout2.VerticalAlignment = Enum.VerticalAlignment.Center;
	UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder;
	local TaskbarWidgets = Instance.new("Frame");
	TaskbarWidgets.Name = "TaskbarWidgets"
	TaskbarWidgets.Size = UDim2.new(0.27, 0, 1, 0);
	TaskbarWidgets.BackgroundTransparency = 0.55;
	TaskbarWidgets.BackgroundColor3 = Color3.fromRGB(43, 43, 43);
	TaskbarWidgets.AnchorPoint = Vector2.new(0, 1);
	TaskbarWidgets.LayoutOrder = 1;
	TaskbarWidgets.ZIndex = TaskbarApps.ZIndex;
	TaskbarWidgets.Parent = taskbar;
	local UIListLayout3 = Instance.new("UIListLayout");
	UIListLayout3.Parent = TaskbarWidgets;
	UIListLayout3.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout3.HorizontalAlignment = Enum.HorizontalAlignment.Right;
	UIListLayout3.VerticalAlignment = Enum.VerticalAlignment.Center;
	UIListLayout3.SortOrder = Enum.SortOrder.LayoutOrder;
	local TimeDateFrame = Instance.new("Frame");
	TimeDateFrame.Name = "TimeDateFrame"
	TimeDateFrame.Size = UDim2.new(0.348, 0, 1, 0);
	TimeDateFrame.BackgroundTransparency = 1;
	TimeDateFrame.ZIndex = 1;
	TimeDateFrame.AnchorPoint = Vector2.new(0.5, 0.5);
	TimeDateFrame.Parent = TaskbarWidgets;
	local UIListLayout4 = Instance.new("UIListLayout");
	UIListLayout4.Parent = TimeDateFrame;
	UIListLayout4.FillDirection = Enum.FillDirection.Vertical;
	UIListLayout4.HorizontalAlignment = Enum.HorizontalAlignment.Right;
	UIListLayout4.VerticalAlignment = Enum.VerticalAlignment.Center;
	UIListLayout4.SortOrder = Enum.SortOrder.LayoutOrder;
	local DateLabel = Instance.new("TextLabel");
	DateLabel.Name = "DateLabel";
	DateLabel.Size = UDim2.new(1, 0, 0.5, 0);
	DateLabel.BackgroundTransparency = 1;
	DateLabel.AnchorPoint = Vector2.new(0.5, 0.5);
	DateLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
	DateLabel.TextScaled = true;
	DateLabel.ZIndex = 999999997;
	DateLabel.Parent = TimeDateFrame;
	DateLabel:SetAttribute("Date", true);
	DateLabel.LayoutOrder = 1;
	local TimeLabel = Instance.new("TextLabel");
	TimeLabel.Name = "TimeLabel";
	TimeLabel.Size = UDim2.new(1, 0, 0.5, 0);
	TimeLabel.BackgroundTransparency = 1;
	TimeLabel.AnchorPoint = Vector2.new(0.5, 0.5);
	TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
	TimeLabel.TextScaled = true;
	TimeLabel.ZIndex = 999999997;
	TimeLabel.Parent = TimeDateFrame;
	TimeLabel:SetAttribute("Clock", true)
	TimeLabel.LayoutOrder = 0;
	local UITextSizeConstraint = Instance.new("UITextSizeConstraint");
	UITextSizeConstraint.MaxTextSize = 28;
	UITextSizeConstraint.Parent = TimeLabel;
	local UITextSizeConstraint2 = Instance.new("UITextSizeConstraint");
	UITextSizeConstraint2.MaxTextSize = 28;
	UITextSizeConstraint2.Parent = DateLabel;
	local StartMenuButton = Instance.new("ImageButton");
	StartMenuButton.Name = "StartMenuButton";
	StartMenuButton.AnchorPoint = Vector2.new(0.5, 0.5);
	StartMenuButton.Size = UDim2.new(0.03, 0, 1, 0);
	StartMenuButton.BackgroundTransparency = 0.55;
	StartMenuButton.BackgroundColor3 = Color3.fromRGB(43, 43, 43);
	StartMenuButton.LayoutOrder = -1;
	StartMenuButton.ZIndex = taskbar.ZIndex -1;
	StartMenuButton.Parent = taskbar;
	StartMenuButton.Image = "rbxassetid://384763834";
	StartMenuButton.ScaleType = Enum.ScaleType.Fit;
end

local function createChunk24()
	local StartMenuFrame = Instance.new("Frame");
	StartMenuFrame.Name = "StartMenu";
	StartMenuFrame.AnchorPoint = Vector2.new(0, 1);
	StartMenuFrame.BackgroundTransparency = 0.05;
	StartMenuFrame.BackgroundColor3 = Color3.fromRGB(0, 61, 0);
	StartMenuFrame.Position = UDim2.new(0, 0, 0.94, 0);
	StartMenuFrame.Size = UDim2.new(0.12, 0, 0.45, 0);
	StartMenuFrame.ZIndex = 999999997;
	StartMenuFrame.Visible = false;
	StartMenuFrame.Parent = __DesktopScreenFrame;
	local UIListLayout = Instance.new("UIListLayout");
	UIListLayout.Parent = StartMenuFrame;
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayout.Padding = UDim.new(0, 0);
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal;
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top;
	local AppsList = Instance.new("Frame");
	AppsList.Name = "AppsList";
	AppsList.BackgroundTransparency = 1;
	AppsList.Size = UDim2.new(0.72, 2, 1, 0);
	AppsList.LayoutOrder = 1;
	AppsList.AnchorPoint = Vector2.new(0, 1);
	AppsList.ZIndex = 999999998;
	AppsList.Parent = StartMenuFrame;
	local UIListLayout2 = Instance.new("UIListLayout");
	UIListLayout2.Parent = AppsList;
	UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayout2.Padding = UDim.new(0, 0);
	UIListLayout2.FillDirection = Enum.FillDirection.Vertical;
	UIListLayout2.VerticalAlignment = Enum.VerticalAlignment.Bottom;
	UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center;
	local ScrollingApps = Instance.new("ScrollingFrame");
	ScrollingApps.AnchorPoint = Vector2.new(0.5, 0.5);
	ScrollingApps.Active = true;
	ScrollingApps.BackgroundTransparency = 1;
	ScrollingApps.Size = UDim2.new(1, 0, 1, 0);
	ScrollingApps.ZIndex = 999999999;
	ScrollingApps.Parent = AppsList;
	ScrollingApps.AutomaticCanvasSize = Enum.AutomaticSize.Y;
	ScrollingApps.CanvasSize = UDim2.new(0, 0, 2, 0);
	ScrollingApps.ScrollBarThickness = 4;
	ScrollingApps.ScrollingDirection = Enum.ScrollingDirection.Y;
	ScrollingApps.ScrollBarImageTransparency = 0;
	ScrollingApps.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255);
	ScrollingApps.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right;
	local PowerList = Instance.new("Frame");
	PowerList.Name = "PowerList";
	PowerList.AnchorPoint = Vector2.new(0, 1);
	PowerList.BackgroundTransparency = 1;
	PowerList.Size = UDim2.new(0.27, 2, 1, 0);
	PowerList.LayoutOrder = 0;
	PowerList.ZIndex = AppsList.ZIndex;
	local UIListLayout3 = Instance.new("UIListLayout");
	UIListLayout3.Parent = PowerList;
	UIListLayout3.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayout3.FillDirection = Enum.FillDirection.Vertical;
	UIListLayout3.VerticalAlignment = Enum.VerticalAlignment.Bottom;
	UIListLayout3.HorizontalAlignment = Enum.HorizontalAlignment.Center;
	PowerList.Parent = StartMenuFrame;

	--AppButtonTemplate
	local AppButtonTemplate = Instance.new("TextButton");
	AppButtonTemplate.Name = "AppButtonTemplate";
	AppButtonTemplate.BackgroundColor3 = Color3.fromRGB(30, 102, 158);
	AppButtonTemplate.AnchorPoint = Vector2.new(0.5, 0.5);
	AppButtonTemplate.Size = UDim2.new(0.05, 0,0.955, 0);
	AppButtonTemplate.ZIndex = 999999998;
	AppButtonTemplate.Visible = false;
	AppButtonTemplate.Parent = MainUI:FindFirstChild("ReplicatedIcons");
	local HighlightFrame = Instance.new("Frame");
	HighlightFrame.Name = "HighlightFrame";
	HighlightFrame.BackgroundColor3 = Color3.fromRGB(30, 146, 199);
	HighlightFrame.AnchorPoint = Vector2.new(0.5, 1);
	HighlightFrame.Size = UDim2.new(0.8, 0, 0.1, 0);
	HighlightFrame.Position = UDim2.new(0.5, 0, 1, 0);
	HighlightFrame.ZIndex = AppButtonTemplate.ZIndex;
	HighlightFrame.Visible = false;
	HighlightFrame.Parent = AppButtonTemplate;
	local HighlightFrameActive = Instance.new("Frame");
	HighlightFrameActive.Name = "HighlightFrameActive";
	HighlightFrameActive.BackgroundColor3 = Color3.fromRGB(36, 182, 244);
	HighlightFrameActive.AnchorPoint = Vector2.new(0.5, 1);
	HighlightFrameActive.Size = UDim2.new(1, 0, 0.1, 0);
	HighlightFrameActive.Position = UDim2.new(0.5, 0, 1, 0);
	HighlightFrameActive.ZIndex = AppButtonTemplate.ZIndex;
	HighlightFrameActive.Visible = false;
	HighlightFrameActive.Parent = AppButtonTemplate;
	local AppIcon = Instance.new("ImageLabel");
	AppIcon.Name = "AppIcon";
	AppIcon.BackgroundTransparency = 1;
	AppIcon.ScaleType = Enum.ScaleType.Fit;
	AppIcon.AnchorPoint = Vector2.new(0.5, 0.5);
	AppIcon.Size = UDim2.new(0.636, 0, 0.911, 0);
	AppIcon.Position = UDim2.new(0.5, 0, 0.5, 0);
	AppIcon.ZIndex = AppButtonTemplate.ZIndex;
	AppIcon.Visible = true;
	AppIcon.Parent = AppButtonTemplate;
end

-- ============================================
-- MAIN INIT FUNCTION
-- ============================================
function v1.Init()
	MainUI = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS") or Instance.new("ScreenGui")
	MainUI.Name = "ZolinOS"
	MainUI.ClipToDeviceSafeArea = true
	MainUI.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
	MainUI.IgnoreGuiInset = true
	MainUI.DisplayOrder = 1
	MainUI.ResetOnSpawn = false
	MainUI.ZIndexBehavior = Enum.ZIndexBehavior.Global

	if MainUI.Parent ~= game.Players.LocalPlayer:FindFirstChild("PlayerGui") then
		print("Initializing ZolinOS...")
		MainUI.Parent = game.Players.LocalPlayer.PlayerGui
	end

	__ScreenFrame = MainUI:FindFirstChild("__ScreenFrame")
	__ZolinDesktop = MainUI:FindFirstChild("__ZolinDesktop")

	if not __ScreenFrame and not __ZolinDesktop then
		__ScreenFrame = Instance.new("Frame")
		__ScreenFrame.Name = "__ScreenFrame"
		__ScreenFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		__ScreenFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		__ScreenFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
		__ScreenFrame.BackgroundTransparency = 1
		__ScreenFrame.ZIndex = 999999999
		__ScreenFrame.ClipsDescendants = true
		__ScreenFrame.Active = true
		__ScreenFrame.Visible = true
		__ScreenFrame.Parent = MainUI

		__ZolinDesktop = Instance.new("Frame")
		__ZolinDesktop.Name = "__ZolinDesktop"
		__ZolinDesktop.AnchorPoint = Vector2.new(0.5, 0.5)
		__ZolinDesktop.Position = UDim2.new(0.5, 0, 0.5, 0)
		__ZolinDesktop.Size = UDim2.new(0.9, 0, 0.9, 0)
		__ZolinDesktop.BackgroundTransparency = 1
		__ZolinDesktop.ZIndex = 999999999
		__ZolinDesktop.ClipsDescendants = true
		__ZolinDesktop.Active = true
		__ZolinDesktop.Visible = false
		__ZolinDesktop.Parent = MainUI


		__DesktopScreenFrame = Instance.new("Frame")
		__DesktopScreenFrame.Name = "__ScreenFrame"
		__DesktopScreenFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		__DesktopScreenFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		__DesktopScreenFrame.Size = UDim2.new(1, 0, 1, 0)
		__DesktopScreenFrame.BackgroundTransparency = 1
		__DesktopScreenFrame.ZIndex = 999999999
		__DesktopScreenFrame.ClipsDescendants = true
		__DesktopScreenFrame.Active = true
		__DesktopScreenFrame.Visible = true
		__DesktopScreenFrame.Parent = __ZolinDesktop

		-- Call all chunk functions with small delays to avoid register limit
		task.spawn(function() createChunk1() end)
		task.wait()
		task.spawn(function() createChunk2() end)
		task.wait()
		task.spawn(function() createChunk3() end)
		task.wait()
		task.spawn(function() createChunk4() end)
		task.wait()
		task.spawn(function() createChunk5() end)
		task.wait()
		task.spawn(function() createChunk6() end)
		task.wait()
		task.spawn(function() createChunk7() end)
		task.wait()
		task.spawn(function() createChunk8() end)
		task.wait()
		task.spawn(function() createChunk9() end)
		task.wait()
		task.spawn(function() createChunk10() end)
		task.wait()
		task.spawn(function() createChunk11() end)
		task.wait()
		task.spawn(function() createChunk12() end)
		task.wait()
		task.spawn(function() createChunk13() end)
		task.wait()
		task.spawn(function() createChunk14() end)
		task.wait()
		task.spawn(function() createChunk15() end)
		task.wait()
		task.spawn(function() createChunk16() end)
		task.wait()
		task.spawn(function() createChunk17() end)
		task.wait()
		task.spawn(function() createChunk18() end)
		task.wait()
		task.spawn(function() createChunk19() end)
		task.wait()
		task.spawn(function() createChunk20() end)
		task.wait()
		task.spawn(function() createChunk21() end)
		task.wait()
		task.spawn(function() createChunk22() end)
		task.wait()
		task.spawn(function() createChunk23() end)
		task.wait()
		task.spawn(function() createChunk24() end)

		print("ZolinOS UI initialized | Version: " ..tostring(BuildVersion));
	end
end

v1.Init()
return v1
