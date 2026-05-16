-- VolumeStyleOptions ModuleScript (System Popup App)
local VolumeStyleOptions = {}

-- ============================================
-- SERVICES
-- ============================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ============================================
-- REFERENCES
-- ============================================
local MainUI = script:FindFirstAncestor("ZolinOS") and script:FindFirstAncestorOfClass("ScreenGui");
local __ScreenFrame = MainUI and MainUI:WaitForChild("__ScreenFrame")
local VolumeFrame = __ScreenFrame and __ScreenFrame:WaitForChild("VolumeFrame")
local VolumeStyleOptionsFrame = __ScreenFrame and __ScreenFrame:WaitForChild("VolumeStyleOptionsFrame")
local Assets = VolumeStyleOptionsFrame and VolumeStyleOptionsFrame:FindFirstChild("Assets")
local FrameTemplate = Assets and Assets:FindFirstChild("FrameTemplate")
local DoneButton = VolumeStyleOptionsFrame and VolumeStyleOptionsFrame:FindFirstChild("DoneButton")

-- Volume Manager
local VolumeManager = require(script.Parent.Parent.__Zolin.VolumeManager)

-- ============================================
-- STATE
-- ============================================
local state = {
	isOpen = false,
	mediaVolume = 0.5,
	notificationVolume = 0.5,
	mediaSlider = nil,
	notificationSlider = nil,
	openTween = nil,
	closeTween = nil,
	activeRow = nil,  -- Track which row is being hovered for keyboard control
	keyboardConnections = nil
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
local function formatVolume(value)
	return math.floor(value * 100) .. "%"
end

-- ============================================
-- KEYBOARD CONTROL FOR HOVERED ROW
-- ============================================
local function setupKeyboardControls(slider, row, optionName)
	local function onKeyPress(input, gameProcessed)
		if gameProcessed then return end
		if state.activeRow ~= row then return end

		local currentValue = (optionName == "Media") and state.mediaVolume or state.notificationVolume
		local newValue = currentValue

		if input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then
			newValue = math.max(0, currentValue - 0.05)
		elseif input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.KeypadPlus then
			newValue = math.min(1, currentValue + 0.05)
		else
			return
		end

		slider.setValue(newValue)
		if slider._onValueChanged then
			slider._onValueChanged(newValue)
		end
	end

	row.MouseEnter:Connect(function()
		state.activeRow = row
	end)

	row.MouseLeave:Connect(function()
		if state.activeRow == row then
			state.activeRow = nil
		end
	end)

	-- Connect keyboard handler
	local keyboardConnection = UserInputService.InputBegan:Connect(onKeyPress)

	return keyboardConnection
end

-- ============================================
-- CREATE HORIZONTAL SLIDER FROM TEMPLATE
-- ============================================
local function createSliderFromTemplate(parent, initialValue, optionName, iconId)
	-- Clone the template
	local row = FrameTemplate:Clone()
	row.Name = optionName .. "Row"
	row.Parent = parent
	row.Visible = true

	-- Set icon
	local icon = row:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		icon.Image = iconId
	end

	-- Find Fill frame (this will be the clickable TextButton)
	local fill = row:FindFirstChild("Fill")
	if not fill then
		warn("Fill not found in FrameTemplate")
		return nil
	end

	-- Convert Fill to TextButton if needed
	local clickArea = fill
	if not clickArea:IsA("TextButton") then
		local textButton = Instance.new("TextButton")
		textButton.Name = "Fill"
		textButton.Size = fill.Size
		textButton.Position = fill.Position
		textButton.BackgroundColor3 = fill.BackgroundColor3
		textButton.BackgroundTransparency = fill.BackgroundTransparency
		textButton.Text = ""
		textButton.ZIndex = fill.ZIndex
		textButton.Parent = row
		fill:Destroy()
		clickArea = textButton
	end

	-- Find OutlineStyle for bounds
	local outlineStyle = row:FindFirstChild("OutlineStyle")
	if not outlineStyle then
		warn("OutlineStyle not found in FrameTemplate")
		return nil
	end

	-- Make OutlineStyle visible as track background
	outlineStyle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	outlineStyle.BorderSizePixel = 0

	-- Position fill INSIDE OutlineStyle (as a child)
	clickArea.Parent = outlineStyle
	clickArea.Position = UDim2.new(0, 0, outlineStyle.Position.Y.Scale, 5)
	clickArea.Size = UDim2.new(initialValue, 0, outlineStyle.Size.Y.Scale, 0)
	clickArea.BackgroundColor3 = optionName == "Media" and Color3.fromRGB(34, 255, 255) or Color3.fromRGB(255, 200, 50)
	clickArea.BackgroundTransparency = 0
	clickArea.Text = ""

	-- Add corner to fill
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = clickArea

	-- Add corner to outline if not exists
	local outlineCorner = outlineStyle:FindFirstChild("UICorner")
	if not outlineCorner then
		outlineCorner = Instance.new("UICorner")
		outlineCorner.CornerRadius = UDim.new(1, 0)
		outlineCorner.Parent = outlineStyle
	end

	-- Create slider button (circle) - also parent to outline
	local sliderButton = Instance.new("ImageButton")
	sliderButton.Name = "SliderButton"
	sliderButton.Size = UDim2.new(0, 18, 0, 18)
	sliderButton.Position = UDim2.new(initialValue, -9, 0.5, -9)
	sliderButton.BackgroundColor3 = optionName == "Media" and Color3.fromRGB(34, 255, 255) or Color3.fromRGB(255, 200, 50)
	sliderButton.BackgroundTransparency = 0
	sliderButton.BorderSizePixel = 0
	sliderButton.Image = "rbxassetid://0"
	sliderButton.ZIndex = 14
	sliderButton.Parent = outlineStyle

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(1, 0)
	buttonCorner.Parent = sliderButton

	-- Glow effect
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.Size = UDim2.new(1.5, 0, 1.5, 0)
	glow.Position = UDim2.new(-0.25, 0, -0.25, 0)
	glow.BackgroundColor3 = optionName == "Media" and Color3.fromRGB(34, 255, 255) or Color3.fromRGB(255, 200, 50)
	glow.BackgroundTransparency = 0.6
	glow.BorderSizePixel = 0
	glow.ZIndex = 13
	glow.Parent = sliderButton

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glow

	-- Value label (stay in row, not in outline)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0, 50, 1, 0)
	valueLabel.Position = UDim2.new(1, 10, 0, 0)
	valueLabel.Text = formatVolume(initialValue)
	valueLabel.ZIndex = 14
	valueLabel.TextColor3 = Color3.new(1, 1, 1)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.Gotham
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.Parent = row

	-- Callback storage
	local onValueChanged = nil

	-- Drag logic
	local dragging = false

	local function getMaxWidth()
		return outlineStyle.AbsoluteSize.X
	end

	local function updateFromPosition(mouseX)
		local outlineAbsPos = outlineStyle.AbsolutePosition
		local maxWidth = getMaxWidth()

		if maxWidth <= 0 then return initialValue end

		-- Clamp mouse position to outline bounds
		local relativeX = math.clamp(mouseX - outlineAbsPos.X, 0, maxWidth)
		local newValue = relativeX / maxWidth
		newValue = math.clamp(newValue, 0, 1)

		-- Update fill width (based on OutlineStyle bounds)
		clickArea.Size = UDim2.new(newValue, 0, outlineStyle.Size.Y.Scale, 0)

		-- Update button position (based on OutlineStyle bounds)
		local buttonX = (newValue * maxWidth) - (sliderButton.AbsoluteSize.X / 2)
		local buttonMinX = -sliderButton.AbsoluteSize.X / 2
		local buttonMaxX = maxWidth - (sliderButton.AbsoluteSize.X / 2)
		buttonX = math.clamp(buttonX, buttonMinX, buttonMaxX)
		sliderButton.Position = UDim2.new(0, buttonX, 0.5, -9)

		-- Update label
		valueLabel.Text = formatVolume(newValue)

		return newValue
	end

	local function triggerValueChange(newValue)
		if onValueChanged then
			onValueChanged(newValue)
		end
	end

	-- Click/Drag on fill button
	clickArea.MouseButton1Down:Connect(function()
		dragging = true
		sliderButton.BackgroundColor3 = Color3.fromRGB(80, 255, 255)
		if glow then glow.BackgroundColor3 = Color3.fromRGB(80, 255, 255) end
	end)

	-- Click/Drag on slider button
	sliderButton.MouseButton1Down:Connect(function()
		dragging = true
		sliderButton.BackgroundColor3 = Color3.fromRGB(80, 255, 255)
		if glow then glow.BackgroundColor3 = Color3.fromRGB(80, 255, 255) end
	end)

	local inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = UserInputService:GetMouseLocation()
			local newValue = updateFromPosition(mousePos.X)
			triggerValueChange(newValue)
		end
	end)

	local inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			local buttonColor = optionName == "Media" and Color3.fromRGB(34, 255, 255) or Color3.fromRGB(255, 200, 50)
			sliderButton.BackgroundColor3 = buttonColor
			if glow then glow.BackgroundColor3 = buttonColor end
		end
	end)

	-- Click on OutlineStyle to jump
	local outlineClickConnection = outlineStyle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mousePos = UserInputService:GetMouseLocation()
			local newValue = updateFromPosition(mousePos.X)
			triggerValueChange(newValue)
		end
	end)

	-- Create slider object
	local slider = {
		row = row,
		fill = clickArea,
		button = sliderButton,
		valueLabel = valueLabel,
		outlineStyle = outlineStyle,
		_onValueChanged = onValueChanged,
		setValue = function(value)
			value = math.clamp(value, 0, 1)
			local maxWidth = getMaxWidth()

			-- Update fill size (capped to outline bounds)
			clickArea.Size = UDim2.new(value, 0, outlineStyle.Size.Y.Scale, 0)

			-- Update button position (capped to outline bounds)
			if maxWidth > 0 then
				local buttonX = (value * maxWidth) - (sliderButton.AbsoluteSize.X / 2)
				local buttonMinX = -sliderButton.AbsoluteSize.X / 2
				local buttonMaxX = maxWidth - (sliderButton.AbsoluteSize.X / 2)
				buttonX = math.clamp(buttonX, buttonMinX, buttonMaxX)
				sliderButton.Position = UDim2.new(0, buttonX, 0.5, -9)
			end

			valueLabel.Text = formatVolume(value)
		end
	}

	-- Initialize fill position
	slider.setValue(initialValue)

	-- Add setOnValueChanged method separately
	slider.setOnValueChanged = function(callback)
		onValueChanged = callback
		slider._onValueChanged = callback
	end

	-- Setup keyboard controls for this row
	local keyboardConn = setupKeyboardControls(slider, row, optionName)

	-- Store connections for cleanup
	slider._connections = {
		inputChangedConnection,
		inputEndedConnection,
		outlineClickConnection,
		keyboardConn
	}

	return slider, keyboardConn
end

-- ============================================
-- ANIMATIONS
-- ============================================
local function openPopup()
	if state.isOpen then return end

	VolumeStyleOptionsFrame.Visible = true
	DoneButton.Visible = true
	state.isOpen = true

	-- Animate in
	local targetPos = UDim2.new(0.5, 0, 0.94, 0)
	local targetPos2 = UDim2.new(0.808, 0, 0.889, 0)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	state.openTween = TweenService:Create(VolumeStyleOptionsFrame.UI, tweenInfo, {Position = targetPos})
	state.openTween:Play()
	local DoneButtonPos = TweenService:Create(DoneButton, tweenInfo, {Position = targetPos2})
	DoneButtonPos:Play()
	local DoneButtonTweenAndBackground = TweenService:Create(DoneButton, tweenInfo, {BackgroundTransparency = 0})
	DoneButtonTweenAndBackground:Play()
	local DoneButtonTween = TweenService:Create(DoneButton, tweenInfo, {TextTransparency = 0})
	DoneButtonTween:Play()
	-- Fade in background
	local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	local BG_Tween = TweenService:Create(VolumeStyleOptionsFrame, tweenInfo, {BackgroundTransparency = 0.5})
	BG_Tween:Play()
end

local function closePopup()
	if not state.isOpen then return end

	-- Animate out
	local targetPos = UDim2.new(0.5, 0, 1.5, 0)
	local targetPos2 = UDim2.new(0.808, 0, 1.889, 0)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	state.closeTween = TweenService:Create(VolumeStyleOptionsFrame.UI, tweenInfo, {Position = targetPos})
	state.closeTween:Play()
	local DoneButtonPos = TweenService:Create(DoneButton, tweenInfo, {Position = targetPos2})
	DoneButtonPos:Play()
	local DoneButtonTweenAndBackground = TweenService:Create(DoneButton, tweenInfo, {BackgroundTransparency = 1})
	DoneButtonTweenAndBackground:Play()
	local DoneButtonTween = TweenService:Create(DoneButton, tweenInfo, {TextTransparency = 1})
	DoneButtonTween:Play()
	
	state.closeTween.Completed:Connect(function()
		VolumeStyleOptionsFrame.Visible = false
		DoneButton.Visible = false
		state.isOpen = false
	end)

	-- Fade out background
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local BG_Tween = TweenService:Create(VolumeStyleOptionsFrame, tweenInfo, {BackgroundTransparency = 1})
	BG_Tween:Play()
end

-- ============================================
-- INITIALIZATION
-- ============================================
function VolumeStyleOptions.Initialize()
	if not (VolumeStyleOptionsFrame and Assets and FrameTemplate) then
		warn("VolumeStyleOptions: Required UI elements missing")
		return
	end

	-- Clear existing rows (keep only the template assets)
	for _, child in ipairs(VolumeStyleOptionsFrame.UI:GetChildren()) do
		if child:IsA("Frame") and child ~= DoneButton then
			child:Destroy()
		end
	end

	-- Get current volumes
	state.mediaVolume = VolumeManager.GetVolume()
	state.notificationVolume = 0.5

	-- Create Media row from template
	local mediaSlider, mediaKeyboard = createSliderFromTemplate(
		VolumeStyleOptionsFrame.UI,
		state.mediaVolume,
		"Media",
		"rbxassetid://470648244"
	)

	mediaSlider.setOnValueChanged(function(value)
		state.mediaVolume = value
		VolumeManager.SetVolume(value)
	end)

	-- Create Notifications row from template
	local notificationSlider, notificationKeyboard = createSliderFromTemplate(
		VolumeStyleOptionsFrame.UI,
		state.notificationVolume,
		"Notifications",
		"rbxassetid://11401835408"
	)

	notificationSlider.setOnValueChanged(function(value)
		state.notificationVolume = value
		local notificationsSoundUI = MainUI and MainUI:FindFirstChild("NotificationsSoundUI")
		if notificationsSoundUI then
			notificationsSoundUI.Volume = value
		end
	end)

	-- Position rows vertically
	local mediaRow = mediaSlider.row
	local notificationRow = notificationSlider.row

	mediaRow.Position = UDim2.new(0.5, -175, 0.2, 0)
	notificationRow.Position = UDim2.new(0.5, -175, 0.45, 0)

	-- Store references
	state.mediaSlider = mediaSlider
	state.notificationSlider = notificationSlider
	state.keyboardConnections = {mediaKeyboard, notificationKeyboard}

	-- Setup Done button
	if DoneButton then
		DoneButton.MouseButton1Click:Connect(function()
			closePopup()
		end)
	end

	-- Click outside to close
	local function onScreenClick(input)
		if state.isOpen then
			local mousePos = UserInputService:GetMouseLocation()
			local absPos = VolumeStyleOptionsFrame.AbsolutePosition
			local absSize = VolumeStyleOptionsFrame.AbsoluteSize
			local isInside = mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
				and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y

			if not isInside then
				DoneButton.Visible = false
				closePopup()
			end
		end
	end

	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			onScreenClick(input)
		end
	end)

	-- Initially hidden
	VolumeStyleOptionsFrame.Visible = false
	VolumeStyleOptionsFrame.UI.Position = UDim2.new(0.5, 0, 1.1, 0)
	VolumeStyleOptionsFrame.BackgroundTransparency = 1

	print("VolumeStyleOptions initialized!")
end

-- ============================================
-- PUBLIC METHODS
-- ============================================
function VolumeStyleOptions.Open()
	openPopup()
	if state.mediaSlider then
		state.mediaSlider.setValue(VolumeManager.GetVolume())
	end
end

function VolumeStyleOptions.Close()
	closePopup()
end

function VolumeStyleOptions.Toggle()
	if state.isOpen then
		closePopup()
	else
		openPopup()
	end
end

function VolumeStyleOptions.IsOpen()
	return state.isOpen
end

return VolumeStyleOptions
