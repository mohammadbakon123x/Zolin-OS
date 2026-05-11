local VolumeManager = {}

-- Assets
local UNMUTED_ICON = "rbxassetid://14840403306"
local MUTED_ICON = "http://www.roblox.com/asset/?id=470648244"

-- References
local MainUI = script:FindFirstAncestorOfClass("ScreenGui")
local __ScreenFrame = MainUI and MainUI:WaitForChild("__ScreenFrame")
local VolumeFrame = __ScreenFrame and __ScreenFrame:WaitForChild("VolumeFrame")
local FillFrame = VolumeFrame and VolumeFrame:WaitForChild("Fill")
local OutlineStyle = VolumeFrame and VolumeFrame:FindFirstChild("OutlineStyle")
local VolumeIconButton = VolumeFrame and VolumeFrame:FindFirstChild("VolumeIconButton")
local AnimationManager = require(script.Parent.AnimationManager)
local MainSoundUI = MainUI and MainUI:FindFirstChild("MediaSoundUI");
local NotificationSoundUI = MainUI and MainUI:FindFirstChild("NotificationsSoundUI");
local VolumeOptionsFrame = __ScreenFrame and __ScreenFrame:FindFirstChild("VolumeStyleOptionsFrame");
local MoreOptionsButton = VolumeFrame and VolumeFrame:FindFirstChild("MoreOptions");
local __Zolin = script.Parent and MainUI:FindFirstChild("__Zolin");
local Remotes = __Zolin and __Zolin:FindFirstChild("Remotes");
local moreOptionsVolStyleEvent = Remotes and Remotes:FindFirstChild("moreOptionsVolStyle");

-- State
local currentVolume = 0.5
local currentNotificationVolume = 0.5
local isMuted = false
local isNotificationsMuted = false
local dragging = false
local isOpen = false
local lastInteraction = 0
local inactivityThread = nil
local minusHeld = false
local plusHeld = false
local adjusting = false
local inVolumeOptionsFrameUI = false
local SliderButton = nil

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
local function getTrackSize()
	if OutlineStyle then
		return OutlineStyle.AbsoluteSize
	else
		return (FillFrame and FillFrame.AbsoluteSize) or VolumeFrame.AbsoluteSize
	end
end

local function getTrackPosition()
	if OutlineStyle then
		return OutlineStyle.AbsolutePosition
	else
		return (FillFrame and FillFrame.AbsolutePosition) or VolumeFrame.AbsolutePosition
	end
end

-- ============================================
-- CREATE CIRCLE DOT BUTTON
-- ============================================
local function createSliderButton()
	SliderButton = VolumeFrame:FindFirstChild("SliderButton")
	if SliderButton then return SliderButton end

	SliderButton = Instance.new("ImageButton")
	SliderButton.Name = "SliderButton"
	SliderButton.Size = UDim2.new(0.5, 20, 0, 25)
	SliderButton.Position = UDim2.new(0.5, -10, 0, 0)
	SliderButton.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
	SliderButton.BackgroundTransparency = 0
	SliderButton.BorderSizePixel = 0
	SliderButton.Image = "rbxassetid://0"
	SliderButton.ZIndex = 103
	SliderButton.Parent = VolumeFrame
	SliderButton.BackgroundTransparency = 1

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = SliderButton

	return SliderButton
end

-- ============================================
-- UPDATE UI (with circle dot positioning)
-- ============================================
local function updateUI()
	if not (FillFrame and VolumeIconButton) then return end

	local volume = isMuted and 0 or currentVolume

	if OutlineStyle then
		local trackHeight = OutlineStyle.AbsoluteSize.Y
		if trackHeight > 0 then
			local fillHeight = trackHeight * volume
			FillFrame.Size = UDim2.new(0.602, 0, 0, -fillHeight)
		end
	else
		FillFrame.Size = UDim2.new(0.602, 0, volume, 0)
	end

	if SliderButton then
		local trackHeight = getTrackSize().Y
		local trackPos = getTrackPosition()
		if trackHeight > 0 then
			local buttonOffset = ((1 - volume) * trackHeight) - (SliderButton.AbsoluteSize.Y / 2)
			buttonOffset = math.clamp(buttonOffset, -SliderButton.AbsoluteSize.Y / 2, trackHeight - SliderButton.AbsoluteSize.Y / 2)
			SliderButton.Position = UDim2.new(0.5, -SliderButton.AbsoluteSize.X / 2, 0, trackPos.Y + buttonOffset - VolumeFrame.AbsolutePosition.Y)
		end
	end

	if volume == 0 then
		if SliderButton then
			SliderButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
			local glow = SliderButton:FindFirstChild("Glow")
			if glow then glow.BackgroundColor3 = Color3.fromRGB(150, 150, 150) end
		end
		FillFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		VolumeIconButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		VolumeIconButton.Image = MUTED_ICON
	else
		if SliderButton then
			SliderButton.BackgroundColor3 = Color3.fromRGB(34, 255, 255)
			local glow = SliderButton:FindFirstChild("Glow")
			if glow then glow.BackgroundColor3 = Color3.fromRGB(34, 255, 255) end
		end
		FillFrame.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
		VolumeIconButton.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
		VolumeIconButton.Image = UNMUTED_ICON
	end
end

-- Apply volume to sound
local function applyVolume()
	if MainSoundUI then
		MainSoundUI.Volume = isMuted and 0 or currentVolume
	end
end

-- Apply notification volume (NO UI VISUALS)
local function applyNotificationVolume()
	if NotificationSoundUI then
		NotificationSoundUI.Volume = isNotificationsMuted and 0 or currentNotificationVolume
	end
end

-- ============================================
-- PUBLIC FUNCTIONS - MEDIA VOLUME
-- ============================================
function VolumeManager.GetVolume()
	return currentVolume
end

function VolumeManager.SetVolume(value)
	value = math.clamp(value, 0, 1)
	currentVolume = value
	if isMuted then
		updateUI()
	else
		applyVolume()
		updateUI()
	end
end

function VolumeManager.GetMuted()
	return isMuted
end

function VolumeManager.SetMuted(muted)
	isMuted = muted
	applyVolume()
	updateUI()
end

function VolumeManager.ToggleMute()
	VolumeManager.SetMuted(not isMuted)
end

-- ============================================
-- PUBLIC FUNCTIONS - NOTIFICATION VOLUME (NO UI)
-- ============================================
function VolumeManager.GetNotificationVolume()
	return currentNotificationVolume
end

function VolumeManager.SetNotificationVolume(value)
	value = math.clamp(value, 0, 1)
	currentNotificationVolume = value
	applyNotificationVolume()
	-- NO UI UPDATE - this doesn't affect the visual volume bar
end

function VolumeManager.GetNotificationsMuted()
	return isNotificationsMuted
end

function VolumeManager.SetNotificationsMuted(muted)
	isNotificationsMuted = muted
	applyNotificationVolume()
	-- NO UI UPDATE - this doesn't affect the visual volume bar
end

function VolumeManager.ToggleNotificationsMute()
	VolumeManager.SetNotificationsMuted(not isNotificationsMuted)
end

-- ============================================
-- OPEN/CLOSE ANIMATIONS
-- ============================================
local function openVolumeFrame()
	if (isOpen and inVolumeOptionsFrameUI) then return end
	isOpen = true
	VolumeFrame.Visible = true
	AnimationManager.AnimateVolumeFrame(VolumeFrame, "Open")
end

local function closeVolumeFrame()
	if not isOpen then return end
	isOpen = false
	AnimationManager.AnimateVolumeFrame(VolumeFrame, "Close")
	VolumeFrame.Visible = false
end

-- Reset inactivity timer
local function resetInactivityTimer()
	lastInteraction = tick()
	if not isOpen then
		openVolumeFrame()
	end
end

-- Inactivity monitoring loop
local function startInactivityMonitor()
	if inactivityThread then return end
	inactivityThread = task.spawn(function()
		while true do
			task.wait(1)
			if isOpen and tick() - lastInteraction > 3 then
				closeVolumeFrame()
			end
		end
	end)
end

-- Keyboard adjustment loop
local function startAdjusting()
	if adjusting or inVolumeOptionsFrameUI then return end
	adjusting = true
	task.spawn(function()
		while (minusHeld or plusHeld) and not inVolumeOptionsFrameUI do
			local delta = 0
			if plusHeld then delta = delta + 0.02 end
			if minusHeld then delta = delta - 0.02 end
			if delta ~= 0 then
				local newVol = math.clamp(currentVolume + delta, 0, 1)
				VolumeManager.SetVolume(newVol)
			end
			task.wait(0.05)
		end
		adjusting = false
	end)
end

-- ============================================
-- GET VOLUME FROM POSITION
-- ============================================
local function getVolumeFromPosition(mouseY)
	local trackPos = getTrackPosition()
	local trackSize = getTrackSize()

	local topY = trackPos.Y
	local bottomY = trackPos.Y + trackSize.Y
	local distanceFromBottom = bottomY - mouseY
	local newVolume = math.clamp(distanceFromBottom / trackSize.Y, 0, 1)
	return newVolume
end

-- ============================================
-- INITIALIZATION
-- ============================================
function VolumeManager.Initialize()
	if not (VolumeFrame and FillFrame and VolumeIconButton) then
		warn("VolumeManager: UI elements missing")
		return
	end

	-- Create the circle slider button
	SliderButton = createSliderButton()

	-- Start with frame closed
	VolumeFrame.Position = UDim2.new(1.1, -5, 0.465, 0)
	isOpen = false

	updateUI()
	applyVolume()
	applyNotificationVolume()
	startInactivityMonitor()

	local UserInputService = game:GetService("UserInputService")

	-- ========== HOVER DETECTION ==========
	VolumeFrame.MouseEnter:Connect(function()
		resetInactivityTimer()
	end)

	VolumeFrame.MouseLeave:Connect(function()
		dragging = false
	end)

	if VolumeOptionsFrame then
		VolumeOptionsFrame.MouseEnter:Connect(function()
			inVolumeOptionsFrameUI = true
		end)

		VolumeOptionsFrame.MouseLeave:Connect(function()
			inVolumeOptionsFrameUI = false
		end)
	end

	-- ========== MUTE TOGGLE ==========
	VolumeIconButton.MouseButton1Click:Connect(function()
		resetInactivityTimer()
		VolumeManager.ToggleMute()
	end)

	-- ========== SLIDER DRAG (Vertical) ==========
	if SliderButton then
		SliderButton.MouseButton1Down:Connect(function()
			resetInactivityTimer()
			dragging = true

			SliderButton.BackgroundColor3 = Color3.fromRGB(80, 255, 255)
			local glow = SliderButton:FindFirstChild("Glow")
			if glow then glow.BackgroundColor3 = Color3.fromRGB(80, 255, 255) end
		end)
	end

	if MoreOptionsButton and moreOptionsVolStyleEvent then
		MoreOptionsButton.MouseButton1Click:Connect(function()
			closeVolumeFrame()
			moreOptionsVolStyleEvent:Fire("Open")
		end)
	end

	-- Track mouse movement during drag
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			resetInactivityTimer()
			local mousePos = UserInputService:GetMouseLocation()
			local newVolume = getVolumeFromPosition(mousePos.Y)
			VolumeManager.SetVolume(newVolume)
		end
	end)

	-- Handle drag end
	UserInputService.InputEnded:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			local volume = isMuted and 0 or currentVolume
			if volume == 0 then
				if SliderButton then SliderButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150) end
			else
				if SliderButton then SliderButton.BackgroundColor3 = Color3.fromRGB(34, 255, 255) end
			end
		end
	end)

	-- ========== CLICK ON TRACK TO JUMP ==========
	if SliderButton then
		SliderButton.MouseButton1Click:Connect(function()
			resetInactivityTimer()
			local mousePos = UserInputService:GetMouseLocation()
			local newVolume = getVolumeFromPosition(mousePos.Y)
			VolumeManager.SetVolume(newVolume)
		end)
	end

	if OutlineStyle then
		OutlineStyle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				resetInactivityTimer()
				local mousePos = UserInputService:GetMouseLocation()
				local newVolume = getVolumeFromPosition(mousePos.Y)
				VolumeManager.SetVolume(newVolume)
			end
		end)
	end

	-- ========== KEYBOARD CONTROL ==========
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then
			resetInactivityTimer()
			minusHeld = true
			startAdjusting()
		elseif input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.KeypadPlus then
			resetInactivityTimer()
			plusHeld = true
			startAdjusting()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then
			minusHeld = false
		elseif input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.KeypadPlus then
			plusHeld = false
		end
	end)

	print("VolumeManager initialized!")
end

-- ============================================
-- CLEANUP
-- ============================================
function VolumeManager.Cleanup()
	if inactivityThread then
		task.cancel(inactivityThread)
		inactivityThread = nil
	end
end

return VolumeManager