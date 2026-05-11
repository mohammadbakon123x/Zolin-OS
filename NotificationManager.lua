-- NotificationManager.lua (Complete Rework)
local NotificationManager = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

-- ================================
-- REFERENCES
-- ================================
local MainUI = script:FindFirstAncestorOfClass("ScreenGui")
local __ScreenFrame = MainUI:WaitForChild("__ScreenFrame")
local __NotificationFrame = __ScreenFrame:WaitForChild("__NotificationFrame")
local __NotificationScrollFrame = __NotificationFrame:WaitForChild("ScrollingFrame")
local __BtnNotificationReplicaFullScreen = __NotificationScrollFrame:WaitForChild("__NotificationReplicaFullScreen")
local ReplicatedNotifications = MainUI:WaitForChild("ReplicatedNotifications")
local __NotificationReplicaWindow = ReplicatedNotifications:WaitForChild("__NotificationReplicaWindow_2")
local __NoNotificationsLabel = __NotificationScrollFrame:WaitForChild("NoNotificationLabel");
local __NotificationBar = __ScreenFrame:WaitForChild("NotificationBar");
-- ================================
-- DEPENDENCIES
-- ================================
local CooldownManager = require(script.Parent.CooldownManager)

-- ================================
-- CONSTANTS
-- ================================
local CONSTANTS = {
	NOTIFICATION_COOLDOWN = 0.5,
	PANEL_TOP_THRESHOLD = 50,
	PANEL_SWIPE_THRESHOLD = 80,
	NOTIFICATION_DURATION = 4,
	NOTIFICATION_SOUND_ID = "rbxassetid://131390520971848",
	SWIPE_THRESHOLD = 100,
	NOTIFICATION_HEIGHT = 80,

	TWEEN = {
		POPUP = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		FADE_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		PANEL_OPEN = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		PANEL_CLOSE = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		BG_OPEN = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		BG_CLOSE = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	}
}

-- ================================
-- STATE
-- ================================
local state = {
	doNotDisturb = false,
	isPanelOpen = false,
	activeNotifications = {},
	activePopups = {},
	panelTween = nil,
	dndButton = nil,
	noNotificationLabel = nil  -- Store reference to the label
}

-- ================================
-- HELPER FUNCTIONS
-- ================================
local function getPanelHeight()
	return __NotificationScrollFrame.AbsoluteSize.Y
end

local function isPointInsidePanel(x, y)
	local absPos = __NotificationScrollFrame.AbsolutePosition
	local absSize = __NotificationScrollFrame.AbsoluteSize
	return x >= absPos.X and x <= absPos.X + absSize.X
		and y >= absPos.Y and y <= absPos.Y + absSize.Y
end

local function updateNoNotificationLabel()
	local notificationCount = #state.activeNotifications
	if notificationCount == 0 then
		if not state.noNotificationLabel then
			local NewNoNotificationLabel = __NoNotificationsLabel:Clone();
			NewNoNotificationLabel.Parent = __BtnNotificationReplicaFullScreen
			NewNoNotificationLabel.Visible = true
			NewNoNotificationLabel.Position = UDim2.new(0.5, 0, 1.25, 0)
			NewNoNotificationLabel.TextScaled = false
			NewNoNotificationLabel.TextSize = 46
			state.noNotificationLabel = NewNoNotificationLabel
		end
		state.noNotificationLabel.Visible = true
	else
		if state.noNotificationLabel then
			state.noNotificationLabel.Visible = false
		end
	end
end

local function updateCanvasSize()
	local notificationCount = #state.activeNotifications

	if notificationCount == 0 then
		__NotificationScrollFrame.CanvasSize = UDim2.new(0, 0, 1, 0)
		updateNoNotificationLabel()
		return
	end

	local canvasScale = 1.5 + (math.max(0, notificationCount - 1) * 0.5)
	canvasScale = math.max(1.5, canvasScale)
	__NotificationScrollFrame.CanvasSize = UDim2.new(0, 0, canvasScale, 0)
	updateNoNotificationLabel()
end

local function playNotificationSound()
	if state.doNotDisturb then return end

	local sound = Instance.new("Sound")
	sound.SoundId = CONSTANTS.NOTIFICATION_SOUND_ID
	sound.Volume = 1
	sound.Parent = MainUI
	sound.SoundGroup = MainUI.NotificationsSoundUI
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(2, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

-- ================================
-- PANEL CONTROL
-- ================================
function NotificationManager.OpenPanel()
	if state.isPanelOpen then return end
	if state.panelTween then state.panelTween:Cancel() end

	local targetPos = UDim2.new(0, 0, 0, 0)
	state.panelTween = TweenService:Create(__NotificationScrollFrame, CONSTANTS.TWEEN.PANEL_OPEN, {Position = targetPos})
	state.panelTween:Play()
	-- force notificationsFrame to not visible
	__NotificationBar.Visible = false
	local backgroundTween = TweenService:Create(__NotificationFrame, CONSTANTS.TWEEN.BG_OPEN, {BackgroundTransparency = 0.1})
	backgroundTween:Play()
	__NotificationFrame.Active = false
	state.isPanelOpen = true

	-- Update no notification label visibility when panel opens
	updateNoNotificationLabel()
end

function NotificationManager.ClosePanel()
	if not state.isPanelOpen then return end
	if state.panelTween then state.panelTween:Cancel() end

	local targetPos = UDim2.new(0, 0, 0, -getPanelHeight())
	state.panelTween = TweenService:Create(__NotificationScrollFrame, CONSTANTS.TWEEN.PANEL_CLOSE, {Position = targetPos})
	state.panelTween:Play()

	local backgroundTween = TweenService:Create(__NotificationFrame, CONSTANTS.TWEEN.BG_CLOSE, {BackgroundTransparency = 1})
	backgroundTween:Play()
	spawn(function()
	task.wait(0.32);
	__NotificationBar.Visible = true
	end)
	__NotificationFrame.Active = true
	state.isPanelOpen = false
end

function NotificationManager.TogglePanel()
	if state.isPanelOpen then
		NotificationManager.ClosePanel()
	else
		NotificationManager.OpenPanel()
	end
end

-- ================================
-- FADE OUT AND DESTROY POPUP (FIXED)
-- ================================
local function fadeOutAndDestroyPopup(popup, popupData)
	if not popup or not popup.Parent then return end

	-- Cancel auto dismiss timer safely
	if popupData and popupData.autoDismissTask then
		local success, err = pcall(function()
			task.cancel(popupData.autoDismissTask)
		end)
		if not success then
			-- If cancel fails, just clear the reference
		end
		popupData.autoDismissTask = nil
	end

	-- Disconnect swipe connections
	if popupData and popupData.dragConnection then
		pcall(function() popupData.dragConnection:Disconnect() end)
		popupData.dragConnection = nil
	end
	if popupData and popupData.endConnection then
		pcall(function() popupData.endConnection:Disconnect() end)
		popupData.endConnection = nil
	end

	-- Fade out animation
	local fadeTween = TweenService:Create(popup, CONSTANTS.TWEEN.FADE_OUT, {Position = UDim2.new(0.5, -250, -1, 0)})
	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		if popup and popup.Parent then
			popup:Destroy()
		end
		-- Remove from active list
		for i, p in ipairs(state.activePopups) do
			if p.instance == popup then
				table.remove(state.activePopups, i)
				break
			end
		end
	end)
end

-- ================================
-- SWIPE HANDLER FOR POPUP
-- ================================
local function setupPopupSwipe(popup, popupData, fadeOutCallback)
	local dragStartX = 0
	local dragStartPos = 0
	local isDragging = false
	local dragConnection = nil
	local endConnection = nil

	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			dragStartX = input.Position.X
			dragStartPos = popup.Position.X.Offset
		end
	end

	local function onInputChanged(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local deltaX = input.Position.X - dragStartX
			local newX = dragStartPos + deltaX
			popup.Position = UDim2.new(0.5, newX - 250, popup.Position.Y.Scale, popup.Position.Y.Offset)

			-- Calculate transparency based on swipe distance
			local alpha = math.clamp(1 - (math.abs(deltaX) / CONSTANTS.SWIPE_THRESHOLD), 0, 1)

			-- Apply transparency to all UI elements in popup
			for _, child in ipairs(popup:GetDescendants()) do
				if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") or child:IsA("ImageButton") then
					if child:IsA("TextLabel") or child:IsA("TextButton") then
						child.TextTransparency = 1 - alpha
					end
					if child:IsA("ImageLabel") or child:IsA("ImageButton") then
						child.ImageTransparency = 1 - alpha
					end
					if child:IsA("Frame") or child:IsA("ScrollingFrame") then
						child.BackgroundTransparency = 1 - alpha
					end
				end
			end
		end
	end

	local function onInputEnded(input)
		if isDragging then
			isDragging = false
			local deltaX = input.Position.X - dragStartX

			if math.abs(deltaX) > CONSTANTS.SWIPE_THRESHOLD then
				-- Dismiss the popup
				if fadeOutCallback then
					fadeOutCallback(popup, popupData)
				end
			else
				-- Snap back to original position
				local snapTween = TweenService:Create(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(0.5, -250, 0.05, 0)
				})
				snapTween:Play()

				-- Reset transparency
				for _, child in ipairs(popup:GetDescendants()) do
					if child:IsA("TextLabel") or child:IsA("TextButton") then
						child.TextTransparency = 0
					end
					if child:IsA("ImageLabel") or child:IsA("ImageButton") then
						child.ImageTransparency = 0
					end
					if child:IsA("Frame") or child:IsA("ScrollingFrame") then
						child.BackgroundTransparency = 0
					end
				end
			end
		end
	end

	popup.InputBegan:Connect(onInputBegan)
	dragConnection = UserInputService.InputChanged:Connect(onInputChanged)
	endConnection = UserInputService.InputEnded:Connect(onInputEnded)

	return dragConnection, endConnection
end

-- ================================
-- POPUP NOTIFICATION
-- ================================
local function createPopupNotification(data)
	if state.doNotDisturb then return nil end

	local popup = __NotificationReplicaWindow:Clone()
	popup.Name = "Popup_" .. tostring(#state.activePopups + 1)
	popup.Parent = __ScreenFrame
	popup.Visible = true
	popup.Position = UDim2.new(0.5, -250, -1, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0)

	-- Set content
	local titleLabel = popup:FindFirstChild("Title") or popup:FindFirstChildOfClass("TextLabel")
	if titleLabel then titleLabel.Text = data.title end

	local descLabel = popup:FindFirstChild("Description")
	if descLabel and data.description then descLabel.Text = data.description end

	local icon = popup:FindFirstChild("Icon")
	if icon and data.icon then icon.Image = data.icon end

	local dismissButton = popup:FindFirstChild("Dismiss")

	local popupData = {
		instance = popup,
		data = data,
		dismissButton = dismissButton,
		autoDismissTask = nil,
		dragConnection = nil,
		endConnection = nil
	}

	-- Animate in
	local tween = TweenService:Create(popup, CONSTANTS.TWEEN.POPUP, {Position = UDim2.new(0.5, -250, 0.05, 0)})
	tween:Play()

	-- Auto dismiss timer (using task.spawn to avoid cancel issues)
	local autoDismissTask = nil
	autoDismissTask = task.spawn(function()
		task.wait(CONSTANTS.NOTIFICATION_DURATION)
		if popup and popup.Parent and popupData and popupData.autoDismissTask == autoDismissTask then
			fadeOutAndDestroyPopup(popup, popupData)
		end
	end)
	popupData.autoDismissTask = autoDismissTask

	-- Setup swipe gestures
	local dragConn, endConn = setupPopupSwipe(popup, popupData, fadeOutAndDestroyPopup)
	popupData.dragConnection = dragConn
	popupData.endConnection = endConn

	-- Setup dismiss button
	if dismissButton then
		dismissButton.MouseButton1Click:Connect(function()
			fadeOutAndDestroyPopup(popup, popupData)
		end)
	end

	-- Setup click area for opening app
	local notificationArea = Instance.new("TextButton")
	notificationArea.Size = UDim2.new(1, -50, 1, 0)
	notificationArea.Position = UDim2.new(0, 0, 0, 0)
	notificationArea.BackgroundTransparency = 1
	notificationArea.Text = ""
	notificationArea.Parent = popup
	notificationArea.ZIndex = 9997

	if dismissButton then
		notificationArea.Size = UDim2.new(1, -60, 1, 0)
		dismissButton.ZIndex = 9997
		notificationArea.ZIndex = 9997
	end

	notificationArea.MouseButton1Click:Connect(function()
		if data.onClick then
			data.onClick()
		end

		NotificationManager.OpenPanel()
		fadeOutAndDestroyPopup(popup, popupData)
	end)

	table.insert(state.activePopups, popupData)
	return popupData
end

-- ================================
-- PANEL NOTIFICATION
-- ================================
local function createPanelNotification(data)
	local notification = __NotificationReplicaWindow:Clone()
	notification.Name = "Notification_" .. tostring(#state.activeNotifications + 1)
	notification.Parent = __NotificationScrollFrame
	notification.Visible = true
	notification.Position = UDim2.new(0, 0, 0, 0)

	local titleLabel = notification:FindFirstChild("Title") or notification:FindFirstChildOfClass("TextLabel")
	if titleLabel then titleLabel.Text = data.title end

	local descLabel = notification:FindFirstChild("Description")
	if descLabel and data.description then descLabel.Text = data.description end

	local icon = notification:FindFirstChild("Icon")
	if icon and data.icon then icon.Image = data.icon end

	local dismissButton = notification:FindFirstChild("Dismiss")

	if dismissButton then
		dismissButton.MouseButton1Click:Connect(function()
			NotificationManager.DismissPanelNotification(notification)
		end)
	end

	local notificationArea = Instance.new("TextButton")
	notificationArea.Size = UDim2.new(0.9, 0, 1, 0)
	notificationArea.Position = UDim2.new(0, 0, 0, 0)
	notificationArea.BackgroundTransparency = 1
	notificationArea.Text = ""
	notificationArea.Parent = notification
	notificationArea.ZIndex = 9997

	if dismissButton then
		dismissButton.ZIndex = 9998
		notificationArea.ZIndex = 9998
	end

	notificationArea.MouseButton1Click:Connect(function()
		if data.onClick then
			data.onClick()
		end
	end)

	return notification
end

function NotificationManager.DismissPanelNotification(notification)
	if not notification or not notification.Parent then return end

	local fadeTween = TweenService:Create(notification, CONSTANTS.TWEEN.FADE_OUT, {Position = UDim2.new(0, -500, 0, 0)})
	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		if notification and notification.Parent then
			notification:Destroy()
		end
		for i, n in ipairs(state.activeNotifications) do
			if n == notification then
				table.remove(state.activeNotifications, i)
				break
			end
		end
		updateCanvasSize()
	end)
end

-- ================================
-- MAIN SHOW NOTIFICATION FUNCTION
-- ================================
function NotificationManager.ShowNotification(data)
	if not data or not data.title then
		warn("NotificationManager: Invalid notification data")
		return
	end

	if not CooldownManager.CanFire("notification", CONSTANTS.NOTIFICATION_COOLDOWN) then
		return
	end

	local panelNotif = createPanelNotification(data)
	table.insert(state.activeNotifications, panelNotif)
	spawn(function()
		playNotificationSound()
	end)
	updateCanvasSize()
	if state.doNotDisturb then
		return
	end
	createPopupNotification(data)
end

-- ================================
-- DO NOT DISTURB
-- ================================
function NotificationManager.SetDoNotDisturb(enabled)
	state.doNotDisturb = enabled

	if state.dndButton then
		state.dndButton.BackgroundColor3 = enabled and Color3.fromRGB(85, 132, 141) or Color3.fromRGB(50, 77, 83)
	end
end

function NotificationManager.GetDoNotDisturb()
	return state.doNotDisturb
end

-- ================================
-- CLEANUP
-- ================================
function NotificationManager.DismissAllPopups()
	for _, popupData in ipairs(state.activePopups) do
		if popupData.instance and popupData.instance.Parent then
			fadeOutAndDestroyPopup(popupData.instance, popupData)
		end
	end
	state.activePopups = {}
end

function NotificationManager.DismissAllPanelNotifications()
	for _, notification in ipairs(state.activeNotifications) do
		if notification and notification.Parent then
			NotificationManager.DismissPanelNotification(notification)
		end
	end
	state.activeNotifications = {}
	updateCanvasSize()
end

-- ================================
-- INITIALIZATION
-- ================================
function NotificationManager.Initialize()
	local height = getPanelHeight()
	__NotificationScrollFrame.Position = UDim2.new(0, 0, 0, -height)
	__NotificationScrollFrame.Visible = true
	__NotificationFrame.BackgroundTransparency = 1
	state.isPanelOpen = false
	updateCanvasSize()

	local dndButton = __BtnNotificationReplicaFullScreen:FindFirstChild("DoNotDisturb", true)
	if dndButton then
		state.dndButton = dndButton
		dndButton.MouseButton1Click:Connect(function()
			NotificationManager.SetDoNotDisturb(not state.doNotDisturb)
		end)
		dndButton.BackgroundColor3 = state.doNotDisturb and Color3.fromRGB(85, 132, 141) or Color3.fromRGB(50, 77, 83)
	end

	local swipeStartY = nil
	local swipeStartTime = nil

	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local pos = input.Position
		if pos.Y <= CONSTANTS.PANEL_TOP_THRESHOLD and not state.isPanelOpen then
			swipeStartY = pos.Y
			swipeStartTime = tick()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if swipeStartY and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
			local endY = input.Position.Y
			local deltaY = endY - swipeStartY
			local duration = tick() - swipeStartTime
			if deltaY >= CONSTANTS.PANEL_SWIPE_THRESHOLD and duration < 0.5 then
				NotificationManager.OpenPanel()
			end
			swipeStartY = nil
		end
	end)

	__ScreenFrame.InputBegan:Connect(function(input)
		if state.isPanelOpen and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
			local mousePos = UserInputService:GetMouseLocation()
			if not isPointInsidePanel(mousePos.X, mousePos.Y) then
				NotificationManager.ClosePanel()
			end
		end
	end)
end

return NotificationManager