
-- ZolinModules (Complete Combined ModuleScript)
local ZolinModules = {}
ZolinModules.Mode = "Mobile"  --| Mobile | default - | Desktop | beta
--Global Variables | Desktop
ZolinModules.CurrentUptime = nil
ZolinModules.CurrentTime = nil
ZolinModules.AppLaunchType = {
	["Settings"] = "ZolinModules",
	["WallpaperSys"] = "ZolinModules",
	["Library Stands"] = "loadstring",
	["ZolinInstaller"] = "ZolinModules",
	["MemoryDisplay"] = "ZolinModules"
}

ZolinModules.AppUrls = {
	["Library Stands"] = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/TranslationApp.lua",
}
local openBuiltInModules = {}
local RunningApps = {}
local BackgroundApps = {}
local ActiveApp = nil	

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

local touchStarted = false
local startY = 0
local swipeThreshold = 20
local OnBackUIDisableScrollingAnimation = true
local systemApps = {}
local eventListeners = {
	onAppLaunched = {},
	onAppClosed = {},
	onAppBackgrounded = {},
	onAppResumed = {},
	onAppsCleared = {},
	onActiveAppChanged = {}
}

local animatingWindows = {}  -- Track which windows are currently animating

local backButtonConnection = nil

local currentSelectedWallpaper = nil
local currentScaleMode = "Stretch"
local selectedScaleButton = nil
local tempWallpaper = nil

local monitorLoopRunning = false
local backButtonDebounce = false
local BACK_BUTTON_COOLDOWN = 0.3


-- ============================================
-- HELPER: Get MainUI
-- ============================================
local function getMainUI()
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		playerGui = player:WaitForChild("PlayerGui")
	end
	local screenGui = playerGui:FindFirstChild("ZolinOS")
	if screenGui and screenGui:IsA("ScreenGui") then
		return screenGui
	end
	return nil
end
-- ============================================
-- ANIMATION MANAGER
-- ============================================
function ZolinModules.AnimationManager()
	local v2 = {}
	local TweenService = game:GetService("TweenService")

	local MainUI = getMainUI()
	local DataFolder = MainUI and MainUI:FindFirstChild("__Zolin") and MainUI.__Zolin:FindFirstChild("Data")

	local function getTransitionSpeed()
		if DataFolder then
			local speedValue = DataFolder:FindFirstChild("TransitionSpeed")
			if speedValue and speedValue:IsA("NumberValue") then
				return math.max(0.1, speedValue.Value)
			end
		end
		return 1
	end

	local function isAnimationUIEnabled()
		if DataFolder then
			local animationUI = DataFolder:FindFirstChild("AnimationUI")
			if animationUI and animationUI:IsA("BoolValue") then
				return animationUI.Value
			end
		end
		return true
	end

	local BASE_OPEN_TIME = 0.5
	local BASE_CLOSE_TIME = 0.25

	local function createTweenInfo(baseTime, easingStyle, easingDirection)
		local speedMultiplier = getTransitionSpeed()
		local adjustedTime = math.max(0.05, baseTime * speedMultiplier)
		return TweenInfo.new(adjustedTime, easingStyle, easingDirection)
	end

	function v2.AnimateWindow(p0, p1, p2)
		-- Check if animations are disabled
		if not isAnimationUIEnabled() then
			-- Skip animation, just set final state
			local target
			if type(p0) == "string" then
				local mainUI = getMainUI()
				if mainUI then
					local appFolder = mainUI.__ScreenFrame and mainUI.__ScreenFrame.Applications and mainUI.__ScreenFrame.Applications:FindFirstChild(p0)
					if appFolder then
						target = appFolder
					else
						warn("AnimateWindow: No app found with name:", p0)
						return
					end
				else
					warn("AnimateWindow: Could not find ScreenGui ancestor")
					return
				end
			elseif p0:IsA("Instance") then
				target = p0
			else
				warn("AnimateWindow: Invalid p0 type:", type(p0))
				return
			end

			local window = target
			local uiScale = window:FindFirstChildOfClass("UIScale")
			if not uiScale then
				uiScale = Instance.new("UIScale")
				uiScale.Parent = window
			end
			uiScale.Scale = (p1 == "Open") and 1 or 0
			return true
		end

		if p0 == nil or p1 == nil then
			return
		end

		-- Get the target window
		local target
		if type(p0) == "string" then
			local mainUI = getMainUI();
			if mainUI then
				local appFolder = mainUI.__ScreenFrame and mainUI.__ScreenFrame.Applications and mainUI.__ScreenFrame.Applications:FindFirstChild(p0)
				if appFolder then
					target = appFolder
				else
					warn("AnimateWindow: No app found with name:", p0)
					return
				end
			else
				warn("AnimateWindow: Could not find ScreenGui ancestor")
				return
			end
		elseif p0:IsA("Instance") then
			target = p0
		else
			warn("AnimateWindow: Invalid p0 type:", type(p0))
			return
		end

		local window = target
		local windowKey = tostring(window)  -- Unique identifier for the window
		-- Check if this window is already animating
		if animatingWindows[windowKey] then
			-- Already animating, ignore this call
			return false
		end

		-- Mark this window as animating
		animatingWindows[windowKey] = true

		local uiScale = window:FindFirstChildOfClass("UIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Scale = (p1 == "Open") and 1 or 0
			uiScale.Parent = window
		end

		local tweenInfo = (p1 == "Open") and 
			createTweenInfo(BASE_OPEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) or 
			createTweenInfo(BASE_CLOSE_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

		local tween = TweenService:Create(uiScale, tweenInfo, {
			Scale = (p1 == "Open") and 1 or 0
		})

		-- When animation completes, remove from animating list
		tween.Completed:Connect(function()
			animatingWindows[windowKey] = nil
		end)

		tween:Play()
		tween.Completed:Wait()
		if p2 == true and (p1 == "Close" or 0) then
			window.Visible = false
		elseif p2 == "Destroy" and (p1 == "Close" or 0) then
			window:Destroy()
		end
		return true
	end

	function v2.AnimateVolumeFrame(p2, p3)
		if not isAnimationUIEnabled() then
			if p2 == nil or p3 == nil then return end
			local volumeFrame = p2
			volumeFrame.Position = (p3 == "Open") and UDim2.new(1, -5, 0.465, 0) or UDim2.new(1.1, -5, 0.465, 0)
			return true
		end

		if p2 == nil or p3 == nil then return end

		local volumeFrame = p2
		local baseTime = (p3 == "Open") and BASE_OPEN_TIME or BASE_CLOSE_TIME
		local tweenInfo = (p3 == "Open") and 
			createTweenInfo(baseTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) or 
			createTweenInfo(baseTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

		local tween = TweenService:Create(volumeFrame, tweenInfo, {
			Position = (p3 == "Open") and UDim2.new(1, -5, 0.465, 0) or UDim2.new(1.1, -5, 0.465, 0)
		})
		tween:Play()
		tween.Completed:Wait()
		return true
	end

	function v2.AnimateTextTransparency(p4, p5, p6, p7, p8, p9)
		if not isAnimationUIEnabled() then
			if p4 == nil or p5 == nil then return end
			p4.TextTransparency = p5
			return true
		end

		if p4 == nil or p5 == nil or p6 == nil or p7 == nil or p8 == nil or p9 == nil then return end

		local textLabel = p4
		local speedMultiplier = getTransitionSpeed()
		local TweenSpeed = (p6 or 0.5) * speedMultiplier
		local tweenInfo = TweenInfo.new(TweenSpeed, p7, p8)
		local tween = TweenService:Create(textLabel, tweenInfo, { TextTransparency = p5 })
		tween:Play()
		if p9 then
			tween.Completed:Wait()
			return true
		else
			return true
		end
	end
	
	-- ============================================
	-- DESKTOP WINDOW ANIMATION (Open / Close)
	-- ============================================
	function v2.AnimateDesktopWindowOpen(window, action, state)
		if typeof(window) ~= "Instance" then print("Invalid window provided: " .. tostring(window)) return false end
		action = action or "Open"
		local fadeDuration = getTransitionSpeed();

		local TweenService = game:GetService("TweenService")
		local uiScale = window:FindFirstChild("UIScale");
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Parent = window
		end

		-- If animations are disabled, skip all tweens and just set scale
		if not isAnimationUIEnabled() then
			uiScale.Scale = (action == "Open") and 1 or 0.25
			if action == "Close" then
				window.Visible = false
			end
			return true
		end

		local function createTweens()
			local tweens = {}
			local tweenInfo = TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			if action == "Open" then
				-- ---- OPEN: fade in and scale up ----
				local originalScale =  uiScale.Scale or 0.85
				local startScale = math.max(0.2, originalScale - 0.2)

				-- Save original transparencies and set to 1 (fully transparent)
				local transparencies = {}
				local function saveAndFade(instance)
					if not instance:IsA("GuiObject") then return end
					local props = {}
					if instance:IsA("Frame") or instance:IsA("ScrollingFrame") then
						if instance.BackgroundTransparency ~= nil then
							props.BackgroundTransparency = instance.BackgroundTransparency
							if instance:IsA("ScrollingFrame") then
							props.ScrollBarImageTransparency = instance.ScrollBarImageTransparency
							instance.ScrollBarImageTransparency = 1
							end
							instance.BackgroundTransparency = 1
						end
					end
					if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
						if instance.ImageTransparency ~= nil and instance.BackgroundTransparency ~= nil then
							props.ImageTransparency = instance.ImageTransparency
							props.BackgroundTransparency = instance.BackgroundTransparency
							instance.BackgroundTransparency = 1
							instance.ImageTransparency = 1
						end
					end
					if instance:IsA("TextLabel") or instance:IsA("TextButton") then
						if instance.TextTransparency ~= nil and instance.BackgroundTransparency ~= nil then
							props.TextTransparency = instance.TextTransparency
							props.BackgroundTransparency = instance.BackgroundTransparency
							instance.TextTransparency = 1
							instance.BackgroundTransparency = 1
						end
					end
					if instance:IsA("TextBox") then
						if instance.TextTransparency ~= nil and instance.BackgroundTransparency ~= nil then
						props.TextTransparency = instance.TextTransparency
						props.BackgroundTransparency = instance.BackgroundTransparency
						props.TextTransparency = 1
						props.BackgroundTransparency = 1
						end
					end
					if next(props) then transparencies[instance] = props end
					for _, child in ipairs(instance:GetChildren()) do
						saveAndFade(child)
					end
				end
				saveAndFade(window)
				task.wait();
				window.Visible = true;
				
				-- Set starting scale
				uiScale.Scale = startScale

				-- Create tweens to restore original transparencies
				for instance, props in pairs(transparencies) do
					for prop, originalValue in pairs(props) do
						local tween = TweenService:Create(instance, tweenInfo, { [prop] = originalValue })
						table.insert(tweens, tween)
					end
				end
				-- Scale up tween
				table.insert(tweens, TweenService:Create(uiScale, tweenInfo, { Scale = originalScale }))

			elseif action == "Close" then
				-- ---- CLOSE: fade out and scale down ----
				-- Gather all GuiObjects and tween their transparencies to 1
				local function fadeOut(instance)
					if not instance:IsA("GuiObject") then return end
					local props = {}
					if instance:IsA("Frame") or instance:IsA("ScrollingFrame") then
						props.BackgroundTransparency = 1
						if instance:IsA("ScrollingFrame") then
						props.ScrollBarImageTransparency = 1
						end
					end
					if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
						props.ImageTransparency = 1
						props.BackgroundTransparency = 1
					end
					if instance:IsA("TextLabel") or instance:IsA("TextButton") then
						props.TextTransparency = 1
						props.BackgroundTransparency = 1
					end
					if instance:IsA("TextBox") then
						props.TextTransparency = 1
						props.BackgroundTransparency = 1
					end
					if next(props) then
						local tween = TweenService:Create(instance, tweenInfo, props)
						table.insert(tweens, tween)
					end
					for _, child in ipairs(instance:GetChildren()) do
						fadeOut(child)
					end
				end
				fadeOut(window)

				-- Scale down to 0.2
				table.insert(tweens, TweenService:Create(uiScale, tweenInfo, { Scale = 0.75 }))
			end

			return tweens
		end

		local tweens = createTweens()

		-- Play all tweens
		for _, tween in ipairs(tweens) do
			tween:Play()
		end

		-- If closing, hide the window after the animation finishes
		if action == "Close" then
			-- Wait for the longest tween to finish
			if #tweens > 0 then
				local longest = tweens[1]
				for _, t in ipairs(tweens) do
					if t.TweenInfo.Time > longest.TweenInfo.Time then
						longest = t
					end
				end
				longest.Completed:Connect(function()
					window.Visible = false
					if state == "Destroy" then
						window:Destroy();
					end
				end)
			else
				window.Visible = false
				if state == "Destroy" then
					window:Destroy();
				end
			end
		end

		return true
	end
	
	return v2
end


-- ============================================
-- APP LOADER
-- ============================================
function ZolinModules.AppLoader()
	local AppLoader = {}
	local MainUI = getMainUI()
	if not MainUI then
		return AppLoader;
	end
	local AppDataFolder = MainUI:FindFirstChild("AppData") or Instance.new("Folder", MainUI)
	AppDataFolder.Name = "AppData"

	local registeredApps = {}

	function AppLoader.RegisterApp(appName, metadata)
		registeredApps[appName] = metadata

		local appFile = AppDataFolder:FindFirstChild(appName)
		if not appFile then
			if appName == "ExampleWindow" then return false end
			appFile = Instance.new("Folder")
			appFile.Name = appName
			appFile.Parent = AppDataFolder
		end

		for key, value in pairs(metadata) do
			local attr = appFile:FindFirstChild(key)
			if not attr then
				if type(value) == "string" then
					attr = Instance.new("StringValue")
				elseif type(value) == "boolean" then
					attr = Instance.new("BoolValue")
				elseif type(value) == "number" then
					attr = Instance.new("NumberValue")
				end
				attr.Name = key
				attr.Parent = appFile
			end
			attr.Value = value
		end
		return true
	end

	function AppLoader.GetAppMetadata(appName)
		return registeredApps[appName]
	end

	function AppLoader.GetAllApps()
		local apps = {}
		for name, meta in pairs(registeredApps) do
			if meta.enabled ~= false and name ~= "ExampleWindow" then
				table.insert(apps, { name = name, metadata = meta })
			end
		end
		table.sort(apps, function(a, b) return a.name < b.name end)
		return apps
	end

	function AppLoader.LoadAppIcon(appName, iconImageLabel)
		local metadata = registeredApps[appName]
		if metadata and metadata.icon then
			iconImageLabel.Image = metadata.icon
			return true
		end
		return false
	end

	return AppLoader
end

-- ============================================
-- COOLDOWN MANAGER
-- ============================================
function ZolinModules.CooldownManager()
	local CooldownManager = {}
	local cooldowns = {}

	function CooldownManager.CanFire(key, cooldownTime)
		local last = cooldowns[key]
		local now = tick()
		if not last or now - last >= cooldownTime then
			cooldowns[key] = now
			return true
		end
		return false
	end

	function CooldownManager.Reset(key)
		cooldowns[key] = nil
	end

	return CooldownManager
end

-- ============================================
-- NOTIFICATION MANAGER
-- ============================================
function ZolinModules.NotificationManager(dependencies)
	local NotificationManager = {}
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local SoundService = game:GetService("SoundService")

	local MainUI = getMainUI()
	local __ScreenFrame = MainUI and MainUI:WaitForChild("__ScreenFrame")
	local __NotificationFrame = __ScreenFrame and __ScreenFrame:WaitForChild("__NotificationFrame")
	local __NotificationScrollFrame = __NotificationFrame and __NotificationFrame:WaitForChild("ScrollingFrame")
	local __BtnNotificationReplicaFullScreen = __NotificationScrollFrame and __NotificationScrollFrame:WaitForChild("__NotificationReplicaFullScreen")
	local ReplicatedNotifications = MainUI and MainUI:WaitForChild("ReplicatedNotifications")
	local __NotificationReplicaWindow = ReplicatedNotifications and ReplicatedNotifications:WaitForChild("__NotificationReplicaWindow_2")
	local __NoNotificationsLabel = __NotificationScrollFrame and __NotificationScrollFrame:WaitForChild("NoNotificationLabel")
	local __NotificationBar = __ScreenFrame and __ScreenFrame:WaitForChild("NotificationBar")

	local CooldownManager = dependencies and dependencies.CooldownManager or ZolinModules.CooldownManager()

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

	local state = {
		doNotDisturb = false,
		isPanelOpen = false,
		activeNotifications = {},
		activePopups = {},
		panelTween = nil,
		dndButton = nil,
		noNotificationLabel = nil
	}

	local function getPanelHeight()
		return __NotificationScrollFrame and __NotificationScrollFrame.AbsoluteSize.Y or 0
	end

	local function isPointInsidePanel(x, y)
		if not __NotificationScrollFrame then return false end
		local absPos = __NotificationScrollFrame.AbsolutePosition
		local absSize = __NotificationScrollFrame.AbsoluteSize
		return x >= absPos.X and x <= absPos.X + absSize.X and y >= absPos.Y and y <= absPos.Y + absSize.Y
	end

	local function updateNoNotificationLabel()
		local notificationCount = #state.activeNotifications
		if notificationCount == 0 then
			if not state.noNotificationLabel and __NoNotificationsLabel and __BtnNotificationReplicaFullScreen then
				local NewNoNotificationLabel = __NoNotificationsLabel:Clone()
				NewNoNotificationLabel.Parent = __BtnNotificationReplicaFullScreen
				NewNoNotificationLabel.Visible = true
				NewNoNotificationLabel.Position = UDim2.new(0.5, 0, 1.25, 0)
				NewNoNotificationLabel.TextScaled = false
				NewNoNotificationLabel.TextSize = 46
				state.noNotificationLabel = NewNoNotificationLabel
			end
			if state.noNotificationLabel then
				state.noNotificationLabel.Visible = true
			end
		else
			if state.noNotificationLabel then
				state.noNotificationLabel.Visible = false
			end
		end
	end

	local function updateCanvasSize()
		if not __NotificationScrollFrame then return end
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
		if MainUI and MainUI.NotificationsSoundUI then
			sound.SoundGroup = MainUI.NotificationsSoundUI
		end
		sound:Play()
		sound.Ended:Connect(function() sound:Destroy() end)
		task.delay(2, function() if sound and sound.Parent then sound:Destroy() end end)
	end

	function NotificationManager.OpenPanel()
		if state.isPanelOpen or not __NotificationScrollFrame then return end
		if state.panelTween then state.panelTween:Cancel() end
		local targetPos = UDim2.new(0, 0, 0, 0)
		state.panelTween = TweenService:Create(__NotificationScrollFrame, CONSTANTS.TWEEN.PANEL_OPEN, {Position = targetPos})
		state.panelTween:Play()
		if __NotificationBar then __NotificationBar.Visible = false end
		if __NotificationFrame then
			local backgroundTween = TweenService:Create(__NotificationFrame, CONSTANTS.TWEEN.BG_OPEN, {BackgroundTransparency = 0.1})
			backgroundTween:Play()
			__NotificationFrame.Active = false
		end
		state.isPanelOpen = true
		updateNoNotificationLabel()
	end

	function NotificationManager.ClosePanel()
		if not state.isPanelOpen or not __NotificationScrollFrame then return end
		if state.panelTween then state.panelTween:Cancel() end
		local targetPos = UDim2.new(0, 0, 0, -getPanelHeight())
		state.panelTween = TweenService:Create(__NotificationScrollFrame, CONSTANTS.TWEEN.PANEL_CLOSE, {Position = targetPos})
		state.panelTween:Play()
		if __NotificationFrame then
			local backgroundTween = TweenService:Create(__NotificationFrame, CONSTANTS.TWEEN.BG_CLOSE, {BackgroundTransparency = 1})
			backgroundTween:Play()
		end
		task.spawn(function()
			task.wait(0.32)
			if __NotificationBar then __NotificationBar.Visible = true end
		end)
		if __NotificationFrame then __NotificationFrame.Active = true end
		state.isPanelOpen = false
	end

	function NotificationManager.TogglePanel()
		if state.isPanelOpen then NotificationManager.ClosePanel() else NotificationManager.OpenPanel() end
	end

	local function fadeOutAndDestroyPopup(popup, popupData)
		if not popup or not popup.Parent then return end
		if popupData and popupData.autoDismissTask then
			pcall(function() task.cancel(popupData.autoDismissTask) end)
			popupData.autoDismissTask = nil
		end
		if popupData and popupData.dragConnection then
			pcall(function() popupData.dragConnection:Disconnect() end)
			popupData.dragConnection = nil
		end
		if popupData and popupData.endConnection then
			pcall(function() popupData.endConnection:Disconnect() end)
			popupData.endConnection = nil
		end
		local fadeTween = TweenService:Create(popup, CONSTANTS.TWEEN.FADE_OUT, {Position = UDim2.new(0.5, -250, -1, 0)})
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			if popup and popup.Parent then popup:Destroy() end
			for i, p in ipairs(state.activePopups) do
				if p.instance == popup then
					table.remove(state.activePopups, i)
					break
				end
			end
		end)
	end

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
				local alpha = math.clamp(1 - (math.abs(deltaX) / CONSTANTS.SWIPE_THRESHOLD), 0, 1)
				for _, child in ipairs(popup:GetDescendants()) do
					if child:IsA("TextLabel") or child:IsA("TextButton") then
						child.TextTransparency = 1 - alpha
					elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
						child.ImageTransparency = 1 - alpha
					elseif child:IsA("Frame") or child:IsA("ScrollingFrame") then
						child.BackgroundTransparency = 1 - alpha
					end
				end
			end
		end

		local function onInputEnded(input)
			if isDragging then
				isDragging = false
				local deltaX = input.Position.X - dragStartX
				if math.abs(deltaX) > CONSTANTS.SWIPE_THRESHOLD then
					if fadeOutCallback then fadeOutCallback(popup, popupData) end
				else
					local snapTween = TweenService:Create(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Position = UDim2.new(0.5, -250, 0.05, 0)
					})
					snapTween:Play()
					for _, child in ipairs(popup:GetDescendants()) do
						if child:IsA("TextLabel") or child:IsA("TextButton") then
							child.TextTransparency = 0
						elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
							child.ImageTransparency = 0
						elseif child:IsA("Frame") or child:IsA("ScrollingFrame") then
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

	local function createPopupNotification(data)
		if state.doNotDisturb or not __NotificationReplicaWindow or not __ScreenFrame then return nil end
		local popup = __NotificationReplicaWindow:Clone()
		popup.Name = "Popup_" .. tostring(#state.activePopups + 1)
		popup.Parent = __ScreenFrame
		popup.Visible = true
		popup.Position = UDim2.new(0.5, -250, -1, 0)
		popup.AnchorPoint = Vector2.new(0.5, 0)

		local titleLabel = popup:FindFirstChild("Title") or popup:FindFirstChildOfClass("TextLabel")
		if titleLabel then titleLabel.Text = data.title end
		local descLabel = popup:FindFirstChild("Description")
		if descLabel and data.description then descLabel.Text = data.description end
		local icon = popup:FindFirstChild("Icon")
		if icon and data.icon then icon.Image = data.icon end
		local dismissButton = popup:FindFirstChild("Dismiss")

		local popupData = { instance = popup, data = data, dismissButton = dismissButton, autoDismissTask = nil, dragConnection = nil, endConnection = nil }
		local tween = TweenService:Create(popup, CONSTANTS.TWEEN.POPUP, {Position = UDim2.new(0.5, -250, 0.05, 0)})
		tween:Play()

		local autoDismissTask = nil
		autoDismissTask = task.spawn(function()
			task.wait(CONSTANTS.NOTIFICATION_DURATION)
			if popup and popup.Parent and popupData and popupData.autoDismissTask == autoDismissTask then
				fadeOutAndDestroyPopup(popup, popupData)
			end
		end)
		popupData.autoDismissTask = autoDismissTask

		local dragConn, endConn = setupPopupSwipe(popup, popupData, fadeOutAndDestroyPopup)
		popupData.dragConnection = dragConn
		popupData.endConnection = endConn

		if dismissButton then
			dismissButton.MouseButton1Click:Connect(function() fadeOutAndDestroyPopup(popup, popupData) end)
		end

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
			if data.onClick then data.onClick() end
			NotificationManager.OpenPanel()
			fadeOutAndDestroyPopup(popup, popupData)
		end)
		table.insert(state.activePopups, popupData)
		return popupData
	end

	local function createPanelNotification(data)
		if not __NotificationReplicaWindow or not __NotificationScrollFrame then return nil end
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
			dismissButton.MouseButton1Click:Connect(function() NotificationManager.DismissPanelNotification(notification) end)
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
		notificationArea.MouseButton1Click:Connect(function() if data.onClick then data.onClick() end end)
		return notification
	end

	function NotificationManager.DismissPanelNotification(notification)
		if not notification or not notification.Parent then return end
		local fadeTween = TweenService:Create(notification, CONSTANTS.TWEEN.FADE_OUT, {Position = UDim2.new(0, -500, 0, 0)})
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			if notification and notification.Parent then notification:Destroy() end
			for i, n in ipairs(state.activeNotifications) do
				if n == notification then table.remove(state.activeNotifications, i); break end
			end
			updateCanvasSize()
		end)
	end

	function NotificationManager.ShowNotification(data)
		if not data or not data.title then
			warn("NotificationManager: Invalid notification data")
			return
		end
		if not CooldownManager.CanFire("notification", CONSTANTS.NOTIFICATION_COOLDOWN) then return end
		local panelNotif = createPanelNotification(data)
		table.insert(state.activeNotifications, panelNotif)
		task.spawn(function() playNotificationSound() end)
		updateCanvasSize()
		if state.doNotDisturb then return end
		createPopupNotification(data)
	end

	function NotificationManager.SetDoNotDisturb(enabled)
		state.doNotDisturb = enabled
		if state.dndButton then
			state.dndButton.BackgroundColor3 = enabled and Color3.fromRGB(85, 132, 141) or Color3.fromRGB(50, 77, 83)
		end
	end

	function NotificationManager.GetDoNotDisturb() return state.doNotDisturb end

	function NotificationManager.Initialize()
		if not __NotificationScrollFrame then return end
		local height = getPanelHeight()
		__NotificationScrollFrame.Position = UDim2.new(0, 0, 0, -height)
		__NotificationScrollFrame.Visible = true
		if __NotificationFrame then __NotificationFrame.BackgroundTransparency = 1 end
		state.isPanelOpen = false
		updateCanvasSize()

		local dndButton = __BtnNotificationReplicaFullScreen and __BtnNotificationReplicaFullScreen:FindFirstChild("DoNotDisturb", true)
		if dndButton then
			state.dndButton = dndButton
			dndButton.MouseButton1Click:Connect(function() NotificationManager.SetDoNotDisturb(not state.doNotDisturb) end)
			dndButton.BackgroundColor3 = state.doNotDisturb and Color3.fromRGB(85, 132, 141) or Color3.fromRGB(50, 77, 83)
		end

		local swipeStartY = nil
		local swipeStartTime = nil
		UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
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
		if __ScreenFrame then
			__ScreenFrame.InputBegan:Connect(function(input)
				if state.isPanelOpen and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
					local mousePos = UserInputService:GetMouseLocation()
					if not isPointInsidePanel(mousePos.X, mousePos.Y) then
						NotificationManager.ClosePanel()
					end
				end
			end)
		end
	end

	return NotificationManager
end

-- ============================================
-- APP MANAGER (FULLY INTEGRATED)
-- ============================================
function ZolinModules.AppManager(dependencies)
	local AppManager = {}
	local windowRefs = {}  -- appName -> window instance
	local window = {};
	window._maximize = nil
	window._restore = nil
	window._isMaximized = nil
	window._savedSize = nil
	window._savedPos = nil
	window._savedScale = nil
	window._dragConnections = nil
	
	local UserInputService = game:GetService("UserInputService")

	local MainUI = getMainUI()
	local ReplicatedWindow = MainUI and MainUI:WaitForChild("ReplicatedWindow", 5)
	local ReplicatedWindowSys = MainUI and MainUI:WaitForChild("ReplicatedWindow_Sys", 5)
	local bgPage = MainUI and MainUI.__ScreenFrame and MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
	local clearAll_button = bgPage and bgPage:FindFirstChild("ClearAll_Button")
	local navBar = MainUI and MainUI.__ScreenFrame and MainUI.__ScreenFrame:WaitForChild("NavigationBar")
	local BackButton = navBar and navBar:WaitForChild("Background")
	local ExitButton = navBar and navBar:WaitForChild("Exit")

	local AnimationManager = dependencies and dependencies.AnimationManager or ZolinModules.AnimationManager()
	local NotificationManager = dependencies and dependencies.NotificationManager or ZolinModules.NotificationManager({ CooldownManager = ZolinModules.CooldownManager() })
	local AppLoader = dependencies and dependencies.AppLoader or ZolinModules.AppLoader()
	
	
	local function triggerEvent(eventName, ...)
		if eventListeners[eventName] then
			for _, callback in ipairs(eventListeners[eventName]) do
				pcall(callback, ...)
			end
		end
	end

	function AppManager.Subscribe(eventName, callback)
		if eventListeners[eventName] then
			table.insert(eventListeners[eventName], callback)
			return true
		end
		return false
	end

	function AppManager.Unsubscribe(eventName, callback)
		if eventListeners[eventName] then
			for i, cb in ipairs(eventListeners[eventName]) do
				if cb == callback then
					table.remove(eventListeners[eventName], i)
					return true
				end
			end
		end
		return false
	end

	function AppManager.GetRunningApps()
		local copy = {}
		for i, name in ipairs(RunningApps) do copy[i] = name end
		return copy
	end

	function AppManager.GetBackgroundApps()
		local copy = {}
		for i, name in ipairs(BackgroundApps) do copy[i] = name end
		return copy
	end

	function AppManager.GetActiveApp() return ActiveApp end
	function AppManager.GetAppCount() return #RunningApps + #BackgroundApps end
	function AppManager.IsSystemApp(appName) return systemApps[appName] == true end
	function AppManager.RegisterSystemApp(appName) systemApps[appName] = true end

	local function registerAllApps()
		if ReplicatedWindow then
			for _, child in ipairs(ReplicatedWindow:GetChildren()) do
				if child:IsA("Frame") then
					local previewAppInfo = child:FindFirstChild("PreviewAppInfoZL")
					local imageLabel = previewAppInfo and previewAppInfo:FindFirstChild("ImageLabel")
					local dataFolder = child:FindFirstChild("Data")
					local descValue = dataFolder and dataFolder:FindFirstChild("Description")
					local versionValue = dataFolder and dataFolder:FindFirstChild("Version")
					local metadata = {
						name = child.Name,
						icon = imageLabel and imageLabel.Image or "rbxassetid://12905435514",
						description = descValue and descValue.Value or "",
						version = versionValue and versionValue.Value or "1.0",
						enabled = true,
						isSystem = false
					}
					AppLoader.RegisterApp(child.Name, metadata)
				end
			end
		end
		if ReplicatedWindowSys then
			for _, child in ipairs(ReplicatedWindowSys:GetChildren()) do
				if child:IsA("Frame") or child:IsA("Folder") then
					local metadata = {
						name = child.Name,
						icon = "rbxassetid://12905435514",
						description = "System Application",
						version = "1.0",
						enabled = true,
						isSystem = true
					}
					AppLoader.RegisterApp(child.Name, metadata)
					AppManager.RegisterSystemApp(child.Name)
				end
			end
		end
	end

	function AppManager.GetApplication(p0)
		if ZolinModules.Mode == "Mobile" then
		local inApps = MainUI.__ScreenFrame.Applications:FindFirstChild(p0)
		local inScrolling = MainUI.__ScreenFrame.BackgroundPage.ScrollingApps:FindFirstChild(p0)
		return inApps ~= nil or inScrolling ~= nil
		elseif ZolinModules.Mode == "Desktop" then
		local inApps = MainUI.__ZolinDesktop.__ScreenFrame.Applications:FindFirstChild(p0)
		return inApps ~= nil
		end
	end

	local function findAppTemplate(appName)
		if ReplicatedWindow then
			local template = ReplicatedWindow:FindFirstChild(appName)
			if template then return template, false end
		end
		if ReplicatedWindowSys then
			local template = ReplicatedWindowSys:FindFirstChild(appName)
			if template then return template, true end
		end
		return nil, false
	end

	function AppManager.LaunchApplication(p1)
		
		if MainUI and (MainUI.__ScreenFrame and MainUI.__ScreenFrame.Applications and MainUI.__ScreenFrame.Applications:FindFirstChild(p1)) or (MainUI.__ZolinDesktop.__ScreenFrame and MainUI.__ZolinDesktop.__ScreenFrame.Applications and MainUI.__ZolinDesktop.__ScreenFrame.Applications:FindFirstChild(p1)) then
			print("App already running")
			return false
		end
		local template, isSystemApp = findAppTemplate(p1)
		if not template then
			warn("Failed to register app: " .. p1 .. " not found")
			return false
		end
		if ZolinModules.Mode == "Mobile" then
		local clonedApp = template:Clone()
		clonedApp.Name = p1
		if MainUI and (MainUI.__ScreenFrame and MainUI.__ScreenFrame.Applications) and ZolinModules.Mode == "Mobile" then
			clonedApp.Parent = MainUI.__ScreenFrame.Applications
		elseif MainUI.__ZolinDesktop and MainUI.__ZolinDesktop.__ScreenFrame and MainUI.__ZolinDesktop.__ScreenFrame.Applications and ZolinModules.Mode == "Desktop" then
			clonedApp.Parent = MainUI.__ZolinDesktop.__ScreenFrame.Applications
		end
		local ModuleScript = clonedApp:FindFirstChildOfClass("ModuleScript")

		--[[ old method we used for loading modules
		if ModuleScript then
			local module = require(ModuleScript)
			if module and module.Init then
				local ui = clonedApp:FindFirstChild("UI")
				if ui then module.Init(ui, {}, clonedApp) else module.Init(clonedApp, {}, clonedApp) end
			end
		end
		--]]
		
		-- Check if this app should use ZolinModules launch type (built-in module)
		local launchType = ZolinModules.AppLaunchType and ZolinModules.AppLaunchType[p1]
		if launchType == "ZolinModules" then
			-- This is a built-in module, track it but don't show the cloned UI
			local modules = ZolinModules.GetAll()
			local builtInModules = {
				Settings = modules.SettingsApp,
				WallpaperSys = modules.WallpaperSysApp,
				ZolinInstaller = modules.ZolinInstaller,
				MemoryDisplay = modules.MemoryDisplayApp,
			}
			local builtInModule = builtInModules[p1]
			if builtInModule then
				table.insert(RunningApps, p1)
				ActiveApp = p1
				local ui = clonedApp:FindFirstChild("UI")
				if ui and builtInModule.Init then
					builtInModule.Init(ui, {}, clonedApp)
				end
				clonedApp.Visible = true
				openBuiltInModules[p1] = clonedApp
				print("Launched built-in module:", p1)
			end
			-- Inside AppManager.LaunchApplication, after the existing ZolinModules check:
		else
			-- First, try the new folder-based registry
			local appUrl = nil
			local appsFolder = MainUI.__Zolin:FindFirstChild("__AppsLaunchArgFolder")
			if appsFolder then
				local entry = appsFolder:FindFirstChild(p1)
				if entry and entry:IsA("StringValue") then
					appUrl = entry.Value
				end
			end
			-- Fallback to the old table
			if not appUrl then
				appUrl = ZolinModules.AppUrls and ZolinModules.AppUrls[p1]
			end
			if appUrl then
				print("Fetching app from URL:", appUrl);
				local success, result = pcall(function()
					return game:HttpGet(appUrl)
				end)
				if success and result then
					local fn, compileError = loadstring(result)
					if fn then
						local execSuccess, moduleReturn = pcall(fn)
						if execSuccess then
							if type(moduleReturn) == "function" then
								local ui = clonedApp:FindFirstChild("UI")
									moduleReturn(ui, {}, clonedApp)
							elseif type(moduleReturn) == "table" and moduleReturn.Init then
								local ui = clonedApp:FindFirstChild("UI")
									moduleReturn.Init(ui, {}, clonedApp)
								end
								table.insert(RunningApps, p1)
								ActiveApp = p1
								clonedApp.Visible = true
								openBuiltInModules[p1] = clonedApp
								print("Launched loadstring app:", p1)
							else
								warn("Failed to execute loadstring app:", p1, moduleReturn)
							end
						else
							warn("Failed to compile loadstring app:", p1, compileError)
						end
					else
						warn("Failed to fetch loadstring app:", p1, appUrl)
					end
				else
					warn("No URL found for loadstring app:", p1)
				return false
			end
		end
		clonedApp.Visible = true
		if ZolinModules.Mode == "Mobile" then
		if not isSystemApp and MainUI and MainUI.__ScreenFrame and MainUI.__ScreenFrame.HomeScreenScroller then
			MainUI.__ScreenFrame.HomeScreenScroller.Visible = false
		end
		end
		local oldActive = ActiveApp
		ActiveApp = p1
		if ZolinModules.Mode == "Mobile" then
		task.spawn(function() AnimationManager.AnimateWindow(clonedApp, "Open") end)
		end
		table.insert(RunningApps, p1)
		triggerEvent("onAppLaunched", p1)
		triggerEvent("onActiveAppChanged", p1, oldActive)

		local bgPage = MainUI and MainUI.__ScreenFrame and MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
		if bgPage and bgPage.Visible then AppManager.RefreshBackgroundPage() end
		return true
		elseif ZolinModules.Mode == "Desktop" then
			-- --------------------------------------------------------
			-- DESKTOP MODE: Launch as window
			-- --------------------------------------------------------
			if ZolinModules.Mode == "Desktop" then
				local desktopFolder = MainUI:FindFirstChild("__ZolinDesktop")
				if not desktopFolder then
					warn("__ZolinDesktop not found")
					return false
				end
				local desktopScreenFrame = desktopFolder:FindFirstChild("__ScreenFrame")
				if not desktopScreenFrame then
					warn("Desktop __ScreenFrame not found")
					return false
				end
				local replicatedSys = MainUI:FindFirstChild("ReplicatedWindow_Sys")
				if not replicatedSys then
					warn("Desktop ReplicatedWindow_Sys not found")
					return false
				end
				local windowTemplate = replicatedSys:FindFirstChild("ExampleWindowV2")
				if not windowTemplate then
					warn("ExampleWindowV2 template not found")
					return false
				end

				-- 1. Clone the window
				local windowApp = windowTemplate:Clone()
				windowApp.Name = p1
				spawn(function()
				AnimationManager.AnimateDesktopWindowOpen(windowApp, "Open");
				end)
				--windowApp.Visible = true
				windowApp.Parent = desktopScreenFrame:FindFirstChild("Applications");

				-- 2. Set title and icon
				local tileInfo = windowApp:FindFirstChild("TileInfo")
				if tileInfo then
					local nameLabel = tileInfo:FindFirstChild("AppName")
					if nameLabel then nameLabel.Text = p1 end
					local iconImg = tileInfo:FindFirstChild("AppIcon")
					if iconImg then
						local meta = AppLoader.GetAppMetadata(p1)
						if meta and meta.icon then
							iconImg.Image = meta.icon
						end
					end
				end

				-- 3. Place the app's UI into the window's UI frame
				local windowUI = windowApp:FindFirstChild("UI")
				if windowUI then
					-- Clone the app's UI contents into the window's UI frame
					local appUI = template:FindFirstChild("UI")
					if appUI then
						-- Clone all children of appUI directly into windowUI
						for _, child in ipairs(appUI:GetChildren()) do
							local clone = child:Clone()
							clone.Parent = windowUI
							-- Optionally set sizes/positions if needed, but assume they're already scaled.
						end
					else
						-- Fallback: if app has no UI frame, just clone the whole template into windowUI
						warn("App template missing 'UI' frame, using full template")
						local content = template:Clone()
						content.Parent = windowUI
						content.Size = UDim2.new(1, 0, 1, 0)
						content.Position = UDim2.new(0, 0, 0, 0)
					end
				else
					warn("Window template missing 'UI' frame")
					windowApp:Destroy()
					return false
				end

				--[ 4. Initialize the app module if it exists | desktop launch

				-- Check if this app should use ZolinModules launch type (built-in module)
				local launchType = ZolinModules.AppLaunchType and ZolinModules.AppLaunchType[p1]
				if launchType == "ZolinModules" then
					-- This is a built-in module, track it but don't show the cloned UI
					local modules = ZolinModules.GetAll()
					local builtInModules = {
						Settings = modules.SettingsApp,
						WallpaperSys = modules.WallpaperSysApp,
						ZolinInstaller = modules.ZolinInstaller,
					}
					local builtInModule = builtInModules[p1]
					if builtInModule then
						table.insert(RunningApps, p1)
						ActiveApp = p1
						local ui = windowApp:FindFirstChild("UI")
						if ui and builtInModule.Init then
							builtInModule.Init(ui, {}, windowApp)
						end
						openBuiltInModules[p1] = windowApp
						print("Launched built-in module:", p1)
					end
					-- Inside AppManager.LaunchApplication, after the existing ZolinModules check:
				else
					-- First, try the new folder-based registry
					local appUrl = nil
					local appsFolder = MainUI.__Zolin:FindFirstChild("__AppsLaunchArgFolder")
					if appsFolder then
						local entry = appsFolder:FindFirstChild(p1)
						if entry and entry:IsA("StringValue") then
							appUrl = entry.Value
						end
					end
					-- Fallback to the old table
					if not appUrl then
						appUrl = ZolinModules.AppUrls and ZolinModules.AppUrls[p1]
					end
					if appUrl then
						print("Fetching app from URL:", appUrl);
						local success, result = pcall(function()
							return game:HttpGet(appUrl)
						end)
						if success and result then
							local fn, compileError = loadstring(result)
							if fn then
								local execSuccess, moduleReturn = pcall(fn)
								if execSuccess then
									if type(moduleReturn) == "function" then
										local ui = windowApp:FindFirstChild("UI")
										moduleReturn(ui, {}, windowApp)
									elseif type(moduleReturn) == "table" and moduleReturn.Init then
										local ui = windowApp:FindFirstChild("UI")
										moduleReturn.Init(ui, {}, windowApp)
									end
									table.insert(RunningApps, p1)
									ActiveApp = p1
									openBuiltInModules[p1] = windowApp
									print("Launched loadstring app:", p1)
								else
									warn("Failed to execute loadstring app:", p1, moduleReturn)
								end
							else
								warn("Failed to compile loadstring app:", p1, compileError)
							end
						else
							warn("Failed to fetch loadstring app:", p1, appUrl)
						end
					else
						warn("No URL found for loadstring app:", p1)
						return false
					end
				end
				--]]

				-- ----------------------------------------------------
				-- Window state (maximize/restore) – local variables
				-- These are shared by the Max button and drag logic
				-- ----------------------------------------------------
				local isMaximized = false
				local savedSize = windowApp.Size
				local savedPos = windowApp.Position
				local savedScale = 1


				-- 4. Connect window controls (Tilebar buttons)
				local tilebar = windowApp:FindFirstChild("Tilebar")
				if tilebar then
					-- Exit (close)
					local exitBtn = tilebar:FindFirstChild("Exit")
					if exitBtn then
						exitBtn.MouseButton1Click:Connect(function()
							-- bring window to front
							ZolinModules.ZIndexManagerInstance.BringToFront(windowApp);
							
							AppManager.CloseApp(p1)
						end)
					end

					-- Min (background)
					local minBtn = tilebar:FindFirstChild("Min")
					if minBtn then
						minBtn.MouseButton1Click:Connect(function()
							-- bring window to front
							ActiveApp = p1
							ZolinModules.ZIndexManagerInstance.BringToFront(windowApp);
							AppManager.HandleExit()  -- uses background logic
						end)
					end

					-- Max (toggle fullscreen / restore)
					local maxBtn = tilebar:FindFirstChild("Max")
					if maxBtn then
						-- State variables for this window
						local isMaximized = false
						local savedSize = windowApp.Size
						local savedPos = windowApp.Position
						local savedScale = windowApp.UIScale and windowApp.UIScale.Scale or 0.85;

						 function AppManager.maximize()
							savedSize = windowApp.Size
							savedPos = windowApp.Position
							local scale = windowApp:FindFirstChildOfClass("UIScale")
							if scale then
								savedScale = scale.Scale
								scale.Scale = 1
							end
							windowApp.Size = UDim2.new(1, 0, 0.94, 0)
							windowApp.Position = UDim2.new(0.5, 0, 0.47, 0)
							windowApp.AnchorPoint = Vector2.new(0.5, 0.5)
							isMaximized = true
						end

						function AppManager.restore()
							windowApp.Size = savedSize
							windowApp.Position = savedPos
							windowApp.AnchorPoint = Vector2.new(0, 0)
							local scale = windowApp:FindFirstChildOfClass("UIScale")
							if scale then
								scale.Scale = savedScale
							end
							isMaximized = false
						end

						-- Toggle
						maxBtn.MouseButton1Click:Connect(function()
							-- bring window to front
							ZolinModules.ZIndexManagerInstance.BringToFront(windowApp);
							
							if isMaximized then
								AppManager.restore()
							else
							 AppManager.maximize()
							end
						end)

						-- Expose these to the drag logic
						window._maximize = AppManager.maximize
						window._restore = AppManager.restore
						window._isMaximized = function() return isMaximized end
						window._savedSize = { get = function() return savedSize end, set = function(s) savedSize = s end }
						window._savedPos = { get = function() return savedPos end, set = function(p) savedPos = p end }
						window._savedScale = { get = function() return savedScale end, set = function(s) savedScale = s end }
					end
				end
				-- 5. Make window draggable via Tilebar
				if tilebar then
					local dragging = false
					local dragStart, startPos
					local dragConnection, endConnection

					local function startDrag(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							if isMaximized then
								AppManager.restore()
								startPos = windowApp.Position
							end
							dragging = true
							dragStart = input.Position
							startPos = windowApp.Position
							ZolinModules.ZIndexManagerInstance.BringToFront(windowApp)
							if ActiveApp ~= p1 then
								local oldActive = ActiveApp
								ActiveApp = p1
								triggerEvent("onActiveAppChanged", p1, oldActive)
							end
						end
					end

					local function updateDrag(input)
						if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
						local delta = input.Position - dragStart
						local newX = startPos.X.Offset + delta.X
						local newY = startPos.Y.Offset + delta.Y
						windowApp.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
						ZolinModules.ZIndexManagerInstance.BringToFront(windowApp)
						if ActiveApp ~= p1 then
							local oldActive = ActiveApp
							ActiveApp = p1
							triggerEvent("onActiveAppChanged", p1, oldActive)
						end
					end

					local function endDrag(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							if not isMaximized then
								local absPos = windowApp.AbsolutePosition
								local absSize = windowApp.AbsoluteSize
								local desktopAbsPos = desktopScreenFrame.AbsolutePosition
								local desktopSize = desktopScreenFrame.AbsoluteSize
								if absPos.Y <= desktopAbsPos.Y + 7.5 then
									AppManager.maximize()
									dragging = false
									return
								end
							end
							dragging = false
						end
					end
					tilebar.InputBegan:Connect(startDrag)
					dragConnection = UserInputService.InputChanged:Connect(updateDrag)
					endConnection = UserInputService.InputEnded:Connect(endDrag)

					-- Store connections for cleanup (optional)
					window._dragConnections = { dragConnection, endConnection }
				end

				-- 6. Store window reference and track the app
				ZolinModules.ZIndexManagerInstance.Register(windowApp, windowApp.ZIndex)
				windowRefs[p1] = window
				table.insert(RunningApps, p1)
				ActiveApp = p1
				triggerEvent("onAppLaunched", p1)
				triggerEvent("onActiveAppChanged", p1, nil)

				-- Optional: bring window to front | we should tell ZolinZIndexManager to bring it to front
				ZolinModules.ZIndexManagerInstance.BringToFront(windowApp)
				print("Launched desktop window for:", p1)
				return true
			end
		end
	end

	function AppManager.HandleExit()
			if ActiveApp then
				if AppManager.IsSystemApp(ActiveApp) then
					AppManager.CloseApp(ActiveApp)
				else 
					AppManager.ExitApplication(ActiveApp) 
				end
			end
		end

	function AppManager.CloseApp(p3)
		local app = nil
		if ZolinModules.Mode == "Mobile" then
			app = MainUI.__ScreenFrame.Applications:FindFirstChild(p3)
		elseif ZolinModules.Mode == "Desktop" then
			app = MainUI.__ZolinDesktop.__ScreenFrame.Applications:FindFirstChild(p3)
		end
		if app then
			local isSystem = AppManager.IsSystemApp(p3)
			if isSystem and ActiveApp == p3 then
				if ZolinModules.Mode == "Mobile" then
				AnimationManager.AnimateWindow(p3, "Close", "Destroy")
				end
			end
			if ZolinModules.Mode == "Desktop" then
			ZolinModules.ZIndexManagerInstance.Unregister(app)
			AnimationManager.AnimateDesktopWindowOpen(app, "Close", "Destroy");
			end
			for i, name in ipairs(RunningApps) do
				if name == p3 then
					table.remove(RunningApps, i)
					break
				end
			end
			for i, name in ipairs(BackgroundApps) do
				if name == p3 then
					table.remove(BackgroundApps, i)
					break
				end
			end
			local oldActive = ActiveApp
			if ActiveApp == p3 then
				ActiveApp = nil
				if #RunningApps == 0 and #BackgroundApps == 0 then
					if ZolinModules.Mode == "Mobile" then
					if MainUI and MainUI.__ScreenFrame and MainUI.__ScreenFrame.HomeScreenScroller then
						MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
					end
					elseif ZolinModules.Mode == "Desktop" then
						-- we will not do this for desktop
					end
				end
			end
			-- attempt to destroy the app, using the same logic as AnimationManager with endConnection method
			if ZolinModules.Mode == "Mobile" then
				AnimationManager.AnimateWindow(p3, "Close", "Destroy");
			end;
			print("App closed: " .. p3)
			if ZolinModules.Mode == "Mobile" then
			AppManager.RemovePreview(p3)
			-- Refresh background page if it's open
			local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
			if bgPage and bgPage.Visible then
				AppManager.RefreshBackgroundPage()
			end
			elseif ZolinModules.Mode == "Desktop" then
				-- we will not do this for desktop
			end
			triggerEvent("onAppClosed", p3)
			if oldActive == p3 then
				triggerEvent("onActiveAppChanged", ActiveApp, oldActive)
			end
		else
			warn("Attempted to close non-existent app: " .. tostring(p3))
		end
	end

	function AppManager.CloseAllApps()
		local appsToClose = {}
		for _, name in ipairs(RunningApps) do
			table.insert(appsToClose, name)
		end
		for _, name in ipairs(BackgroundApps) do
			table.insert(appsToClose, name)
		end

		for _, name in ipairs(appsToClose) do
			AppManager.CloseApp(name)
		end
		if ZolinModules.Mode == "Mobile" then
		if MainUI and MainUI.__ScreenFrame and MainUI.__ScreenFrame.HomeScreenScroller then
			MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
		end
		local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
		if bgPage and bgPage.Visible then
			AppManager.RefreshBackgroundPage()
		end
		elseif ZolinModules.Mode == "Desktop" then
			-- we will not do this for desktop
		end
		triggerEvent("onAppsCleared")
	end

	function AppManager.ExitApplication(p4)
		local app = nil
		if ZolinModules.Mode == "Mobile" then
		app = MainUI.__ScreenFrame.Applications:FindFirstChild(p4)
		elseif ZolinModules.Mode == "Desktop" then
			app = MainUI.__ZolinDesktop.__ScreenFrame.Applications:FindFirstChild(p4)
		end
		if app then
			local isSystem = AppManager.IsSystemApp(p4)

			-- System apps should NOT be backgrounded - close them instead
			if isSystem then
				AppManager.CloseApp(p4)
				return
			end
			if ZolinModules.Mode == "Mobile" then
			-- Only show home screen for non-system apps
			if not isSystem then
				MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
			end
			AnimationManager.AnimateWindow(p4, "Close", true);
			
			elseif ZolinModules.Mode == "Desktop" then
				spawn(function()
				AnimationManager.AnimateDesktopWindowOpen(app, "Close");
				end)
				local win = windowRefs[p4]
				if win then
					win.Visible = false
				end
			end
			for i, name in ipairs(RunningApps) do
				if name == p4 then
					table.remove(RunningApps, i)
					break
				end
			end
			table.insert(BackgroundApps, p4)

			local oldActive = ActiveApp
			if ActiveApp == p4 then
				ActiveApp = nil
			end

			-- Trigger events
			triggerEvent("onAppBackgrounded", p4)
			if oldActive == p4 then
				triggerEvent("onActiveAppChanged", ActiveApp, oldActive)
			end
			if ZolinModules.Mode == "Mobile" then
			local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
			if bgPage and bgPage.Visible then
				AppManager.RefreshBackgroundPage()
			end
			elseif ZolinModules.Mode == "Desktop" then
				-- we will not do this for desktop
			end
		else
			warn("Attempted to minimize non-existent app: " .. tostring(p4))
		end
	end

	function AppManager.ExitAllApps()
		local appsToBg = {}
		for _, name in ipairs(RunningApps) do
			if AppManager.IsSystemApp(name) then AppManager.CloseApp(name)
			else table.insert(appsToBg, name) end
		end
		for _, name in ipairs(appsToBg) do AppManager.ExitApplication(name) end
	end

	function AppManager.ResumeApplication(p5)
	if not AppManager.GetApplication(p5) then print("Attempted to resume non-existent app: " .. tostring(p5)) return false end
		local app = nil
		if ZolinModules.Mode == "Mobile" then
		app = MainUI.__ScreenFrame.Applications:FindFirstChild(p5)
		elseif ZolinModules.	Mode == "Desktop" then
			app = MainUI.__ZolinDesktop.__ScreenFrame.Applications:FindFirstChild(p5)
		end
		if app then
			local isSystem = AppManager.IsSystemApp(p5)
			if ZolinModules.Mode == "Mobile" then
			app.Visible = true
			if not isSystem then
				MainUI.__ScreenFrame.HomeScreenScroller.Visible = false
			end
			spawn(function()
				AnimationManager.AnimateWindow(app, "Open")
			end);
			elseif ZolinModules.Mode == "Desktop" then
				AnimationManager.AnimateDesktopWindowOpen(app, "Open")
				ZolinModules.ZIndexManagerInstance.BringToFront(app)
			end
			for i, name in ipairs(BackgroundApps) do
				if name == p5 then
					table.remove(BackgroundApps, i)
					break
				end
			end
			table.insert(RunningApps, p5)

			local oldActive = ActiveApp
			ActiveApp = p5

			-- Trigger events
			triggerEvent("onAppResumed", p5)
			triggerEvent("onActiveAppChanged", p5, oldActive)
			if ZolinModules.Mode == "Mobile" then
			local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
			if bgPage and bgPage.Visible then
				bgPage.Visible = false
				if not isSystem then
					MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
				end
			end
			elseif ZolinModules.Mode == "Desktop" then
				-- we will not do this for desktop
			end
		end
	end

	function AppManager.GoHomeScreen()
		local bgPage = MainUI and MainUI.__ScreenFrame and MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
		if bgPage then
			bgPage.Visible = false
			local frameNote = bgPage:FindFirstChild("FrameNote")
			local scrollingApps = bgPage:FindFirstChild("ScrollingApps")
			local clearAll = bgPage:FindFirstChild("ClearAll_Button")
			if frameNote then frameNote.Visible = false end
			if scrollingApps then scrollingApps.Visible = false end
			if clearAll then clearAll.Visible = false end
		end
		if MainUI and MainUI.__ScreenFrame and MainUI.__ScreenFrame.HomeScreenScroller then
			MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
		end
		AppManager.ExitAllApps()
	end
	
	function AppManager.BackButton()
		if backButtonDebounce then
			print("Back button is on cooldown.")
			return
		end
		local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
		local frameNote = bgPage:FindFirstChild("FrameNote")
		local scrollingApps = bgPage:FindFirstChild("ScrollingApps")
		local clearAll = bgPage:FindFirstChild("ClearAll_Button")
		if not bgPage then return end
		backButtonDebounce = true
		bgPage.Visible = not bgPage.Visible
		if bgPage.Visible then
			for _, appName in ipairs(RunningApps) do
				local app = MainUI.__ScreenFrame.Applications:FindFirstChild(appName)
				if app then
					app.Visible = false
				end
			end
			if ExitButton then ExitButton.Visible = false end
			
			if frameNote then frameNote.Visible = true end
			if clearAll then clearAll.Visible = false end
			
			if MainUI.__ScreenFrame.HomeScreenScroller then
				MainUI.__ScreenFrame.HomeScreenScroller.Visible = false
			end
			AppManager.RefreshBackgroundPage()
		else
			if ExitButton then ExitButton.Visible = true end
			if MainUI.__ScreenFrame.HomeScreenScroller then
				MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
			end
			local frameNote = bgPage:FindFirstChild("FrameNote")
			local scrollingApps = bgPage:FindFirstChild("ScrollingApps")
			local clearAll = bgPage:FindFirstChild("ClearAll_Button")
			if frameNote then frameNote.Visible = false end
			if scrollingApps then scrollingApps.Visible = false end
			if clearAll then clearAll.Visible = false end
		end
		task.delay(BACK_BUTTON_COOLDOWN, function()
			backButtonDebounce = false
			print("Back button cooldown ended")
		end)
	end
	function AppManager.RemovePreview(appName)
		local bgPage = MainUI and MainUI.__ScreenFrame and MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
		if not bgPage then return end
		local scrollingApps = bgPage:FindFirstChild("ScrollingApps")
		if not scrollingApps then return end
		local preview = scrollingApps:FindFirstChild(appName .. "_preview")
		if preview then preview:Destroy() end
	end

	function AppManager.RefreshBackgroundPage()
		local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
		if not bgPage then return end
		local scrollingApps = bgPage:FindFirstChild("ScrollingApps")
		local frameNote = bgPage:FindFirstChild("FrameNote")
		local clearAll = bgPage:FindFirstChild("ClearAll_Button")
		local BackUI = bgPage:FindFirstChild("BackUI")
		if not scrollingApps then return end

		-- Count existing previews BEFORE clearing
		local existingPreviews = 0
		for _, child in ipairs(scrollingApps:GetChildren()) do 
			if child:IsA("Frame") and child.Name:match("_preview$") then
				existingPreviews = existingPreviews + 1
				if existingPreviews >= 2 then
					scrollingApps.UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
				else
					scrollingApps.UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
				end
			end
		end

		-- Clear all existing previews
		for _, child in ipairs(scrollingApps:GetChildren()) do 
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		if BackUI and BackUI:IsA("TextButton") then
			-- Disconnect previous connections to prevent duplicates
			pcall(function() BackUI.MouseButton1Click:Disconnect() end)
			BackUI.MouseButton1Click:Connect(function()
				if bgPage and bgPage.Visible then
					AppManager.BackButton()
					AppManager.HandleExit();
				end
			end)
		end

		-- Build list of currently running/backgrounded apps (excluding system apps from preview)
		local function buildAppList()
			local appNames = {}
			for _, name in ipairs(RunningApps) do
				if not AppManager.IsSystemApp(name) then
					table.insert(appNames, name)
				end
			end
			for _, name in ipairs(BackgroundApps) do
				if not table.find(appNames, name) and not AppManager.IsSystemApp(name) then
					table.insert(appNames, name)
				end
			end
			return appNames
		end

		local allAppNames = buildAppList()

		-- If no apps, show empty state and return
		if #allAppNames == 0 and #MainUI.__ScreenFrame.Applications:GetChildren() == 0 then
			if frameNote then 
				frameNote.Visible = true 
			end
			if clearAll then clearAll.Visible = false end
			scrollingApps.Visible = false

			-- Stop monitor loop if running
			if monitorLoopRunning then
				monitorLoopRunning = false
			end
			return
		elseif #allAppNames > 0 and #MainUI.__ScreenFrame.Applications:GetChildren() > 0 then
			-- Apps exist, show them
			scrollingApps.Visible = true
			if frameNote then frameNote.Visible = false end
			if clearAll then clearAll.Visible = true end
		end

		-- Start monitor loop if not already running
		if not monitorLoopRunning then
			monitorLoopRunning = true
			spawn(function()
				while bgPage and bgPage.Visible do
					task.wait(0.5)  -- Check every 0.5 seconds

					-- Re-build list of currently running/backgrounded apps
					local currentAppNames = buildAppList()

					-- Also check if any previews exist in scrollingApps
					local hasPreviews = false
					for _, child in ipairs(scrollingApps:GetChildren()) do 
						if child:IsA("Frame") and child.Name:match("_preview$") then
							hasPreviews = true
							break
						end
					end

					-- If no apps are running/backgrounded AND no previews exist
					if #currentAppNames == 0 then
						if bgPage and bgPage.Visible then
							if #buildAppList() == 0 then
								if frameNote then 
									frameNote.Visible = true 
								end
								if clearAll then clearAll.Visible = false end
								scrollingApps.Visible = false
							end
						end
						triggerEvent("onAppsCleared")
						monitorLoopRunning = false
						break
					elseif #currentAppNames ~= #allAppNames then
						-- App count changed, refresh the background page
						allAppNames = currentAppNames
						AppManager.RefreshBackgroundPage()
						break
					end
				end
				monitorLoopRunning = false
			end)
		end

		-- Create previews for each app
		for _, appName in ipairs(allAppNames) do
			local appInstance = MainUI.__ScreenFrame.Applications:FindFirstChild(appName)
			if not appInstance then
				continue
			end
			AppManager.RemovePreview(appName)
			local appUI = appInstance:FindFirstChild("UI")
			if not appUI then
				warn("App UI not found for:", appName)
				continue
			end
			local previewTemplate = ReplicatedWindowSys:FindFirstChild("ExampleWindow")
			if not previewTemplate then
				warn("No ExampleWindow template found in ReplicatedWindow")
				return
			end
			local preview = previewTemplate:Clone()
			preview.Name = appName .. "_preview"
			preview.Parent = scrollingApps
			local previewUIContainer = preview:FindFirstChild("UI")
			if not previewUIContainer then
				warn("Preview template missing 'UI' container for:", appName)
				preview:Destroy()
				continue
			end;
			for i, v in pairs(appInstance:GetChildren()) do
				if v:IsA("Frame") then
					local v1 = v:Clone();
					v1.Parent = previewUIContainer;
					if v.Name == "PreviewAppInfoZL" then
						v1:Destroy()
					end
				end;
			end;
			preview.Visible = true;
			local PreviewAppInfoZLPreview = preview:FindFirstChild("PreviewAppInfoZL");
			if PreviewAppInfoZLPreview then
				PreviewAppInfoZLPreview.Visible = true;
			else
				warn("Preview template missing 'PreviewAppInfoZL' for:", appName);
			end;
			local nameLabel = PreviewAppInfoZLPreview:FindFirstChild("AppNameLabel", true);
			local iconLabel = PreviewAppInfoZLPreview:FindFirstChild("ImageLabel", true);
			if iconLabel then
				local homeIcon = MainUI.AppData:FindFirstChild(appName, true);
				if homeIcon and homeIcon:FindFirstChild("icon") then
					iconLabel.Image = homeIcon.icon.Value;
				else
					warn("HomeScreenScroller missing icon for:", appName)
				end
			else
				warn("Preview template missing 'ImageLabel' for:", appName);
			end;
			if nameLabel then
				nameLabel.Text = appName;
			else
				warn("Preview template missing 'AppNameLabel' for:", appName);
			end;
			if OnBackUIDisableScrollingAnimation then
				spawn(function()
					for _, v in pairs(previewUIContainer:GetDescendants()) do
						if v:IsA("ScrollingFrame") then
							v.ScrollingEnabled = false;
						end;
						if v:IsA("TextBox") then
							v.ClearTextOnFocus = false;
							v.TextEditable = false;
						end;
						if v:IsA("TextButton") then
							v.AutoButtonColor = false;
						end;
						if v:IsA("ImageButton") then
							v.AutoButtonColor = false;
						end;
						if v:IsA("UIAspectRatioConstraint") and v.Parent.Name == "UI" then
							v:Destroy();
						end
					end;
				end)
			end
			previewUIContainer.MouseButton1Click:Connect(function()
				ExitButton.Visible = true;
				AppManager.ResumeApplication(appName);
				AppManager.RemovePreview(appName);
				if existingPreviews < 2 then
					scrollingApps.UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
				end
			end);
			previewUIContainer.InputBegan:Connect(function(input, gp)
				if gp then return end;
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					touchStarted = true;
					startY = input.Position.Y;
				end;
			end);
			previewUIContainer.InputEnded:Connect(function(input, gp)
				if gp then return end;
				if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and touchStarted then
					local deltaY = input.Position.Y - startY;
					if deltaY < -swipeThreshold then
						AppManager.CloseApp(appName);
						AppManager.RemovePreview(appName);
						task.wait(0.1)
						local remainingApps = buildAppList()
						if #remainingApps == 0 and #MainUI.__ScreenFrame.Applications:GetChildren() == 0 then
							if frameNote then frameNote.Visible = true end
							if clearAll then clearAll.Visible = false end
							if scrollingApps then scrollingApps.Visible = false end
							if bgPage and bgPage.Visible then
								task.wait(0.3)
								AppManager.BackButton()
							end
							triggerEvent("onAppsCleared")
						end
					end;
					touchStarted = false;
					if existingPreviews < 2 then
						scrollingApps.UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
					end
				end;
			end);
			preview.Active = true;
			preview.Selectable = true;
		end;
	end;
	if BackButton then
		if backButtonConnection then
			backButtonConnection:Disconnect()
			backButtonConnection = nil
		end
		backButtonConnection = BackButton.MouseButton1Click:Connect(function()
			AppManager.BackButton()
		end)
		print("Back button connected")
	end
	if ExitButton then
		ExitButton.MouseButton1Click:Connect(function() AppManager.HandleExit() end)
	end
	if clearAll_button then
		clearAll_button.MouseButton1Click:Connect(function()
			AppManager.CloseAllApps()
			task.wait(0.1)
			local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
			if bgPage and bgPage.Visible then
				local frameNote = bgPage:FindFirstChild("FrameNote")
				local scrollingApps = bgPage:FindFirstChild("ScrollingApps")
				local clearAll = bgPage:FindFirstChild("ClearAll_Button")
				if frameNote then frameNote.Visible = true end
				if clearAll then clearAll.Visible = false end
				if scrollingApps then scrollingApps.Visible = false end
			end
		end)
	end
	registerAllApps()
	return AppManager
end

-- ============================================
-- TASKBAR MANAGER (Desktop only)
-- ============================================
function ZolinModules.TaskbarManager()
	-- If an instance already exists, return it (singleton pattern)
	if ZolinModules._taskbarManagerInstance then
		return ZolinModules._taskbarManagerInstance
	end

	local TaskbarManager = {}
	local taskbarButtons = {}
	local isInitialized = false

	function TaskbarManager.Init()
		if isInitialized then
			print("TaskbarManager already initialized, skipping.")
			return
		end

		local MainUI = getMainUI()
		if not MainUI then
			warn("TaskbarManager: MainUI not found")
			return
		end

		if ZolinModules.Mode ~= "Desktop" then
			print("TaskbarManager: Skipping (not Desktop mode)")
			return
		end

		local desktopFolder = MainUI:FindFirstChild("__ZolinDesktop")
		if not desktopFolder then
			warn("TaskbarManager: __ZolinDesktop not found")
			return
		end

		local desktopScreenFrame = desktopFolder:FindFirstChild("__ScreenFrame")
		if not desktopScreenFrame then
			warn("TaskbarManager: desktop __ScreenFrame not found")
			return
		end

		local taskbarFrame = desktopScreenFrame:FindFirstChild("Taskbar")
		if not taskbarFrame then
			warn("TaskbarManager: TaskbarFrame not found")
			return
		end

		local taskbarApps = taskbarFrame:FindFirstChild("TaskbarApps")
		if not taskbarApps then
			warn("TaskbarManager: TaskbarApps not found")
			return
		end

		local replicatedIcons = MainUI:FindFirstChild("ReplicatedIcons")
		if not replicatedIcons then
			warn("TaskbarManager: ReplicatedIcons not found")
			return
		end

		local buttonTemplate = replicatedIcons:FindFirstChild("AppButtonTemplate")
		if not buttonTemplate then
			warn("TaskbarManager: AppButtonTemplate not found")
			return
		end

		-- Clean up any existing buttons (fresh start)
		for _, child in ipairs(taskbarApps:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		taskbarButtons = {}

		-- Get AppManager and AppLoader from modules
		local modules = ZolinModules.GetAll_Desktop()
		local AppManager = modules.AppManager
		local AppLoader = modules.AppLoader

		if not AppManager then
			warn("TaskbarManager: AppManager not available")
			return
		end

		-- Function to update highlights
		local function updateTaskbarHighlights(activeApp)
			for appName, btn in pairs(taskbarButtons) do
				-- Active/inactive background color
				if appName == activeApp then
					btn.BackgroundColor3 = Color3.fromRGB(30, 102, 158)  -- active color
				else
					btn.BackgroundColor3 = Color3.fromRGB(20, 67, 104)  -- inactive color
				end

				-- Highlight frames (if they exist)
				local highlight = btn:FindFirstChild("HighlightFrame")
				local highlightActive = btn:FindFirstChild("HighlightFrameActive")

				if highlight then
					local isOpen = false
					local RunningApps = AppManager.GetRunningApps and AppManager.GetRunningApps() or {}
					local BackgroundApps = AppManager.GetBackgroundApps and AppManager.GetBackgroundApps() or {}

					for _, name in ipairs(RunningApps) do
						if name == appName then isOpen = true; break end
					end
					if not isOpen then
						for _, name in ipairs(BackgroundApps) do
							if name == appName then isOpen = true; break end
						end
					end
					highlight.Visible = isOpen
				end

				if highlightActive then
					highlightActive.Visible = (appName == activeApp)
				end
			end
		end
		
		local StartMenuButton = taskbarFrame:FindFirstChild("StartMenuButton");
		if StartMenuButton then
			ZolinModules.StartMenuManager().Init();
			StartMenuButton.MouseButton1Click:Connect(function()
				ZolinModules.StartMenuManager().Toggle();
				print("StartMenuButton clicked")
			end)
		end
		
		-- Subscribe to app events (using the AppManager's Subscribe method)
		AppManager.Subscribe("onAppLaunched", function(appName)
			if ZolinModules.Mode ~= "Desktop" then return end
			if taskbarButtons[appName] then return end -- already exists

			local btn = buttonTemplate:Clone()
			btn.Name = appName
			btn.Parent = taskbarApps
			btn.Visible = true
			btn.Text = ""

			-- Set icon
			local icon = btn:FindFirstChild("AppIcon")
			if icon and icon:IsA("ImageLabel") then
				local meta = AppLoader.GetAppMetadata(appName)
				if meta and meta.icon then
					icon.Image = meta.icon
				end
			end

			taskbarButtons[appName] = btn

			-- Left-click: toggle minimize/restore
			btn.MouseButton1Click:Connect(function()
				local win = AppManager._windowRefs and AppManager._windowRefs[appName]
				if win then
					if win.Visible then
						AppManager.ExitApplication(appName)
					else
						AppManager.ResumeApplication(appName)
					end
				end
			end)

			-- Right-click: fire context menu event
			local contextEvent = MainUI:FindFirstChild("__Zolin") and
				MainUI.__Zolin:FindFirstChild("Remotes") and
				MainUI.__Zolin.Remotes:FindFirstChild("ContextMenuEvent")
			if contextEvent then
				btn.MouseButton2Click:Connect(function()
					contextEvent:Fire("taskbar", appName, {})
				end)
			end

			updateTaskbarHighlights(AppManager.GetActiveApp())
		end)

		AppManager.Subscribe("onAppClosed", function(appName)
			if ZolinModules.Mode ~= "Desktop" then return end
			local btn = taskbarButtons[appName]
			if btn then
				btn:Destroy()
				taskbarButtons[appName] = nil
			end
			updateTaskbarHighlights(AppManager.GetActiveApp())
		end)

		AppManager.Subscribe("onAppBackgrounded", function(appName)
			if ZolinModules.Mode ~= "Desktop" then return end
			updateTaskbarHighlights(AppManager.GetActiveApp())
		end)

		AppManager.Subscribe("onAppResumed", function(appName)
			if ZolinModules.Mode ~= "Desktop" then return end
			updateTaskbarHighlights(AppManager.GetActiveApp())
		end)

		AppManager.Subscribe("onActiveAppChanged", function(newActive, oldActive)
			if ZolinModules.Mode ~= "Desktop" then return end
			updateTaskbarHighlights(newActive)
		end)

		AppManager.Subscribe("onAppsCleared", function()
			for appName, btn in pairs(taskbarButtons) do
				btn:Destroy()
			end
			taskbarButtons = {}
		end)

		isInitialized = true
		print("TaskbarManager initialized successfully!")
	end
	
	
	-- Store instance globally
	ZolinModules._taskbarManagerInstance = TaskbarManager
	return TaskbarManager
end

function ZolinModules.StartMenuManager()
	if ZolinModules._startMenuManagerInstance then
		return ZolinModules._startMenuManagerInstance
	end

	local StartMenuManager = {}
	local isInitialized = false
	local startMenuFrame, appListFrame, powerListFrame
	local isOpen = false
	local overlay = nil

	function StartMenuManager.Toggle()
		if not isInitialized then print("StartMenuManager: Not initialized") return end
		if isOpen then
			StartMenuManager.Close()
		else
			StartMenuManager.Open()
		end
	end

	function StartMenuManager.Open()
		if not isInitialized then return end
		startMenuFrame.Visible = true
		overlay.Visible = true
		isOpen = true
		-- Bring to front
	end

	function StartMenuManager.Close()
		if not isInitialized then return end
		startMenuFrame.Visible = false
		overlay.Visible = false
		isOpen = false
	end

	function StartMenuManager.IsOpen()
		return isOpen
	end

	function StartMenuManager.Init()
		if isInitialized then return end

		local MainUI = getMainUI()
		if not MainUI then
			warn("StartMenuManager: MainUI not found")
			return
		end

		if ZolinModules.Mode ~= "Desktop" then
			print("StartMenuManager: Skipping (not Desktop mode)")
			return
		end

		local desktopFolder = MainUI:FindFirstChild("__ZolinDesktop")
		if not desktopFolder then
			warn("StartMenuManager: __ZolinDesktop not found")
			return
		end
		local desktopScreenFrame = desktopFolder:FindFirstChild("__ScreenFrame")
		if not desktopScreenFrame then
			warn("StartMenuManager: desktop __ScreenFrame not found")
			return
		end

		-- Find StartMenu frame
		startMenuFrame = desktopScreenFrame:FindFirstChild("StartMenu")
		if not startMenuFrame then
			warn("StartMenuManager: StartMenu frame not found")
			return
		end

		appListFrame = startMenuFrame:FindFirstChild("AppsList")
		if not appListFrame then
			warn("StartMenuManager: AppList not found")
			return
		end

		powerListFrame = startMenuFrame:FindFirstChild("PowerList")
		-- PowerList can be nil, that's fine.

		-- Create overlay for closing on outside click
		overlay = Instance.new("Frame")
		overlay.Name = "StartMenuOverlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundTransparency = 1
		overlay.Visible = false
		overlay.ZIndex = 998  -- behind menu
		overlay.Parent = desktopScreenFrame
		overlay.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or
				input.UserInputType == Enum.UserInputType.MouseButton2 then
				if startMenuFrame.Visible then
					local mousePos = game:GetService("UserInputService"):GetMouseLocation()
					local absPos = startMenuFrame.AbsolutePosition
					local absSize = startMenuFrame.AbsoluteSize
					local inside = mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
						mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y
					if not inside then
						StartMenuManager.Close()
					end
				end
			end
		end)

		-- Get modules
		local modules = ZolinModules.GetAll_Desktop()
		local AppManager = modules.AppManager
		local AppLoader = modules.AppLoader

		if not AppManager or not AppLoader then
			warn("StartMenuManager: AppManager or AppLoader not available")
			return
		end

		-- Populate app list
		local apps = AppLoader.GetAllApps()
		-- Clear existing children (keep layout)
		for _, child in ipairs(appListFrame:GetChildren()) do
			child:Destroy()
		end

		-- Ensure UIListLayout exists
		local layout = appListFrame:FindFirstChildOfClass("UIListLayout")
		if not layout then
			layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			layout.VerticalAlignment = Enum.VerticalAlignment.Top
			layout.Padding = UDim.new(0, 4)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = appListFrame
		end

		-- For each app, create an entry
		for order, appData in ipairs(apps) do
			if not AppManager.IsSystemApp(appData.name) then
				local entry = Instance.new("Frame")
				entry.Size = UDim2.new(1, 0, 0, 40)
				entry.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
				entry.BackgroundTransparency = 1
				entry.BorderSizePixel = 0
				entry.LayoutOrder = order
				entry.ZIndex = startMenuFrame.ZIndex + 1;
				entry.Parent = appListFrame
				
				local entryButton = Instance.new("TextButton")
				entryButton.Size = UDim2.new(1, 0, 1, 0)
				entryButton.BackgroundTransparency = 1
				entryButton.Text = ""
				entryButton.ZIndex = entry.ZIndex + 1;
				entryButton.Parent = entry

				-- Hover effect
				entry.MouseEnter:Connect(function()
					entry.BackgroundTransparency = 0.7
				end)
				entry.MouseLeave:Connect(function()
					entry.BackgroundTransparency = 1
				end)

				-- App icon
				local icon = Instance.new("ImageLabel")
				icon.Size = UDim2.new(0, 32, 0, 32)
				icon.Position = UDim2.new(0, 5, 0.5, -16)
				icon.BackgroundTransparency = 1
				icon.Image = appData.metadata.icon or "rbxassetid://12905435514"
				icon.ScaleType = Enum.ScaleType.Fit
				icon.ZIndex = entry.ZIndex + 1;
				icon.Parent = entry

				-- App name
				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -50, 1, 0)
				nameLabel.Position = UDim2.new(0, 45, 0, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = appData.name
				nameLabel.TextColor3 = Color3.new(1, 1, 1)
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.TextYAlignment = Enum.TextYAlignment.Center
				nameLabel.Font = Enum.Font.Gotham
				nameLabel.TextSize = 14
				nameLabel.ZIndex = entry.ZIndex + 1;
				nameLabel.Parent = entry

				-- Left click: launch app
				local function launch()
					if AppManager then
						-- Check if already running, resume or launch
						if AppManager.GetApplication(appData.name) then
							AppManager.ResumeApplication(appData.name)
						else
							AppManager.LaunchApplication(appData.name)
						end
					end
					StartMenuManager.Close()
				end

				entryButton.MouseButton1Click:Connect(launch)

				-- Right click: context menu
				entryButton.MouseButton2Click:Connect(function()
					local ContextEvent = MainUI:FindFirstChild("__Zolin") and
						MainUI.__Zolin:FindFirstChild("Remotes") and
						MainUI.__Zolin.Remotes:FindFirstChild("ContextMenuEvent")
					if ContextEvent then
						ContextEvent:Fire("startmenu", appData.name, entry)
					end
				end)
			end
		end

		-- Initially hidden
		startMenuFrame.Visible = false

		isInitialized = true
		print("StartMenuManager initialized successfully!")
	end

	ZolinModules._startMenuManagerInstance = StartMenuManager
	return StartMenuManager
end

-- ============================================
-- ZINDEX MANAGER (for desktop windows & UI layers)
-- ============================================
function ZolinModules.ZIndexManager()
	local ZIndexManager = {}
	local registered = {}
	local nextZ = 1000

	function ZIndexManager.Register(instance, baseZ)
		if registered[instance] then return false end
		baseZ = baseZ or nextZ
		registered[instance] = { baseZ = baseZ, currentZ = baseZ }
		instance.ZIndex = baseZ
		if baseZ + 1 > nextZ then nextZ = baseZ + 1 end
		print("[ZIndexManager] Registered:", instance.Name, "with ZIndex:", baseZ)
		return true
	end

	local function shiftHierarchy(instance, delta)
		if delta == 0 then return end
		instance.ZIndex = instance.ZIndex + delta
		for _, child in ipairs(instance:GetChildren()) do
			if child:IsA("GuiObject") then
				if child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("TextButton") or child:IsA("ImageButton") or child:IsA("TextBox") or child:IsA("ImageLabel") or child:IsA("TextLabel") then
					shiftHierarchy(child, delta)
				end
			end
		end
	end

function ZIndexManager.BringToFront(instance)
    local data = registered[instance]
    if not data then
        warn("[ZIndexManager] Instance not registered:", instance and instance.Name)
        return false
    end

    -- Count visible windows and find maxZ
    local visibleCount = 0
    local maxZ = 0
    for inst, d in pairs(registered) do
        if inst.Visible then
            visibleCount = visibleCount + 1
            if d.currentZ > maxZ then maxZ = d.currentZ end
        end
    end

    -- If only one visible window, no need to change
    if visibleCount <= 1 then
        return true
    end

    -- Check if this instance is uniquely the highest
    local countAtMax = 0
    local isThisAtMax = false
    for inst, d in pairs(registered) do
        if inst.Visible and d.currentZ == maxZ then
            countAtMax = countAtMax + 1
            if inst == instance then
                isThisAtMax = true
            end
        end
    end

    -- If this instance is the only one at maxZ, it's already highest, skip
    if countAtMax == 1 and isThisAtMax then
        print("[ZIndexManager] Already highest (unique), skipping:", instance.Name)
        return true
    end

    -- Set to maxZ + 1 (now it becomes the new highest)
    local newZ = maxZ + 1
    local delta = newZ - data.currentZ

    data.currentZ = newZ
    instance.ZIndex = newZ

    -- Shift children
    if delta ~= 0 then
        for _, child in ipairs(instance:GetChildren()) do
			if child:IsA("GuiObject") then
				if child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("TextButton") or child:IsA("ImageButton") or child:IsA("TextBox") or child:IsA("ImageLabel") or child:IsA("TextLabel") then
				shiftHierarchy(child, delta)
				end
            end
        end
    end

    if newZ + 1 > nextZ then nextZ = newZ + 1 end
    print("[ZIndexManager] Brought to front:", instance.Name, "new ZIndex:", newZ)
    return true
end
	
	function ZIndexManager.Reset(instance)
		local data = registered[instance]
		if not data then return false end
		data.currentZ = data.baseZ
		instance.ZIndex = data.baseZ
		return true
	end

	function ZIndexManager.ResetAll()
		for instance, data in pairs(registered) do
			data.currentZ = data.baseZ
			instance.ZIndex = data.baseZ
		end
		local maxBase = 0
		for _, data in pairs(registered) do
			if data.baseZ > maxBase then maxBase = data.baseZ end
		end
		nextZ = maxBase + 1
	end

	function ZIndexManager.ShiftAll(delta)
		if delta == 0 then return true end
		local maxZ = 0
		for instance, data in pairs(registered) do
			local newZ = data.currentZ + delta
			data.currentZ = newZ
			instance.ZIndex = newZ
			if newZ > maxZ then maxZ = newZ end
		end
		nextZ = maxZ + 1
		return true
	end

	function ZIndexManager.Unregister(instance)
		if registered[instance] then
			registered[instance] = nil
			print("[ZIndexManager] Unregistered:", instance.Name)
			return true
		end
		return false
	end

	function ZIndexManager.GetZIndex(instance)
		local data = registered[instance]
		return data and data.currentZ or nil
	end

	function ZIndexManager.GetHighestZ()
		local maxZ = 0
		for _, data in pairs(registered) do
			if data.currentZ > maxZ then maxZ = data.currentZ end
		end
		return maxZ
	end

	function ZIndexManager.GetAllRegistered()
		local result = {}
		for instance, data in pairs(registered) do
			result[instance] = { baseZ = data.baseZ, currentZ = data.currentZ }
		end
		return result
	end

	function ZIndexManager.PeekNextZ()
		return nextZ
	end

	return ZIndexManager
end

-- Create a global instance (so all parts of the code use the same manager)
ZolinModules.ZIndexManagerInstance = ZolinModules.ZIndexManager()

-- ============================================
-- VOLUME MANAGER
-- ============================================
function ZolinModules.VolumeManager()
	--if ZolinModules.Mode ~= "Mobile" then return end
	local VolumeManager = {}

	local UNMUTED_ICON = "rbxassetid://14840403306"
	local MUTED_ICON = "http://www.roblox.com/asset/?id=470648244"

	local MainUI = getMainUI()
	local __ScreenFrame = MainUI and MainUI:WaitForChild("__ScreenFrame")
	local VolumeFrame = __ScreenFrame and __ScreenFrame:WaitForChild("VolumeFrame")
	local FillFrame = VolumeFrame and VolumeFrame:WaitForChild("Fill")
	local OutlineStyle = VolumeFrame and VolumeFrame:FindFirstChild("OutlineStyle")
	local VolumeIconButton = VolumeFrame and VolumeFrame:FindFirstChild("VolumeIconButton")
	local AnimationManager = ZolinModules.AnimationManager()
	local MainSoundUI = MainUI and MainUI:FindFirstChild("MediaSoundUI")
	local NotificationSoundUI = MainUI and MainUI:FindFirstChild("NotificationsSoundUI")
	local VolumeOptionsFrame = __ScreenFrame and __ScreenFrame:FindFirstChild("VolumeStyleOptionsFrame")
	local MoreOptionsButton = VolumeFrame and VolumeFrame:FindFirstChild("MoreOptions")
	local __Zolin = MainUI and MainUI:FindFirstChild("__Zolin")
	local Remotes = __Zolin and __Zolin:FindFirstChild("Remotes")
	local moreOptionsVolStyleEvent = Remotes and Remotes:FindFirstChild("moreOptionsVolStyle")

	--[[
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
	--]]
	
	local function getTrackSize()
		if OutlineStyle then return OutlineStyle.AbsoluteSize
		else return (FillFrame and FillFrame.AbsoluteSize) or VolumeFrame.AbsoluteSize end
	end

	local function getTrackPosition()
		if OutlineStyle then return OutlineStyle.AbsolutePosition
		else return (FillFrame and FillFrame.AbsolutePosition) or VolumeFrame.AbsolutePosition end
	end

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

	local function applyVolume()
		if MainSoundUI then MainSoundUI.Volume = isMuted and 0 or currentVolume end
	end

	local function applyNotificationVolume()
		if NotificationSoundUI then NotificationSoundUI.Volume = isNotificationsMuted and 0 or currentNotificationVolume end
	end

	function VolumeManager.GetVolume() return currentVolume end
	function VolumeManager.SetVolume(value)
		value = math.clamp(value, 0, 1)
		currentVolume = value
		if isMuted then updateUI() else applyVolume(); updateUI() end
	end
	function VolumeManager.GetMuted() return isMuted end
	function VolumeManager.SetMuted(muted) isMuted = muted; applyVolume(); updateUI() end
	function VolumeManager.ToggleMute() VolumeManager.SetMuted(not isMuted) end
	function VolumeManager.GetNotificationVolume() return currentNotificationVolume end
	function VolumeManager.SetNotificationVolume(value)
		value = math.clamp(value, 0, 1)
		currentNotificationVolume = value
		applyNotificationVolume()
	end
	function VolumeManager.GetNotificationsMuted() return isNotificationsMuted end
	function VolumeManager.SetNotificationsMuted(muted) isNotificationsMuted = muted; applyNotificationVolume() end
	function VolumeManager.ToggleNotificationsMute() VolumeManager.SetNotificationsMuted(not isNotificationsMuted) end

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

	local function resetInactivityTimer()
		lastInteraction = tick()
		if not isOpen then openVolumeFrame() end
	end

	local function startInactivityMonitor()
		if inactivityThread then return end
		inactivityThread = task.spawn(function()
			while true do
				task.wait(1)
				if isOpen and tick() - lastInteraction > 3 then closeVolumeFrame() end
			end
		end)
	end

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

	local function getVolumeFromPosition(mouseY)
		local trackPos = getTrackPosition()
		local trackSize = getTrackSize()
		local topY = trackPos.Y
		local bottomY = trackPos.Y + trackSize.Y
		local distanceFromBottom = bottomY - mouseY
		return math.clamp(distanceFromBottom / trackSize.Y, 0, 1)
	end

	function VolumeManager.Initialize()
		if not (VolumeFrame and FillFrame and VolumeIconButton) then
			warn("VolumeManager: UI elements missing")
			return
		end
		SliderButton = createSliderButton()
		VolumeFrame.Position = UDim2.new(1.1, -5, 0.465, 0)
		isOpen = false
		updateUI()
		applyVolume()
		applyNotificationVolume()
		startInactivityMonitor()

		local UserInputService = game:GetService("UserInputService")

		VolumeFrame.MouseEnter:Connect(function() resetInactivityTimer() end)
		VolumeFrame.MouseLeave:Connect(function() dragging = false end)
		if VolumeOptionsFrame then
			VolumeOptionsFrame.MouseEnter:Connect(function() inVolumeOptionsFrameUI = true end)
			VolumeOptionsFrame.MouseLeave:Connect(function() inVolumeOptionsFrameUI = false end)
		end

		VolumeIconButton.MouseButton1Click:Connect(function() resetInactivityTimer(); VolumeManager.ToggleMute() end)
		if SliderButton then
			SliderButton.MouseButton1Down:Connect(function() resetInactivityTimer(); dragging = true; SliderButton.BackgroundColor3 = Color3.fromRGB(80, 255, 255) end)
		end
		if MoreOptionsButton and moreOptionsVolStyleEvent then
			MoreOptionsButton.MouseButton1Click:Connect(function() closeVolumeFrame(); moreOptionsVolStyleEvent:Fire("Open") end)
		end

		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				resetInactivityTimer()
				local mousePos = UserInputService:GetMouseLocation()
				VolumeManager.SetVolume(getVolumeFromPosition(mousePos.Y))
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
				local volume = isMuted and 0 or currentVolume
				if SliderButton then SliderButton.BackgroundColor3 = volume == 0 and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(34, 255, 255) end
			end
		end)

		if SliderButton then
			SliderButton.MouseButton1Click:Connect(function()
				resetInactivityTimer()
				local mousePos = UserInputService:GetMouseLocation()
				VolumeManager.SetVolume(getVolumeFromPosition(mousePos.Y))
			end)
		end

		if OutlineStyle then
			OutlineStyle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					resetInactivityTimer()
					local mousePos = UserInputService:GetMouseLocation()
					VolumeManager.SetVolume(getVolumeFromPosition(mousePos.Y))
				end
			end)
		end

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then
				resetInactivityTimer(); minusHeld = true; startAdjusting()
			elseif input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.KeypadPlus then
				resetInactivityTimer(); plusHeld = true; startAdjusting()
			end
		end)

		UserInputService.InputEnded:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then minusHeld = false
			elseif input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.KeypadPlus then plusHeld = false end
		end)

		print("VolumeManager initialized!")
	end

	function VolumeManager.Cleanup()
		if inactivityThread then task.cancel(inactivityThread); inactivityThread = nil end
	end

	return VolumeManager
end

-- ============================================
-- VOLUME STYLE OPTIONS
-- ============================================
function ZolinModules.VolumeStyleOptions()
	local VolumeStyleOptions = {}
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")

	local MainUI = getMainUI()
	local __ScreenFrame = MainUI and MainUI:WaitForChild("__ScreenFrame")
	local VolumeStyleOptionsFrame = __ScreenFrame and __ScreenFrame:WaitForChild("VolumeStyleOptionsFrame")
	local Assets = VolumeStyleOptionsFrame and VolumeStyleOptionsFrame:FindFirstChild("Assets")
	local FrameTemplate = Assets and Assets:FindFirstChild("FrameTemplate")
	local DoneButton = VolumeStyleOptionsFrame and VolumeStyleOptionsFrame:FindFirstChild("DoneButton")

	local VolumeManager = ZolinModules.VolumeManager()

	 ZolinModules.state = { isOpen = false, mediaVolume = 0.5, notificationVolume = 0.5, mediaSlider = nil, notificationSlider = nil, openTween = nil, closeTween = nil, activeRow = nil, keyboardConnections = nil }

	local function formatVolume(value) return math.floor(value * 100) .. "%" end

	local function setupKeyboardControls(slider, row, optionName)
		local function onKeyPress(input, gameProcessed)
			if gameProcessed then return end
			if ZolinModules.state.activeRow ~= row then return end
			local currentValue = (optionName == "Media") and ZolinModules.state.mediaVolume or ZolinModules.state.notificationVolume
			local newValue = currentValue
			if input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then
				newValue = math.max(0, currentValue - 0.05)
			elseif input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.KeypadPlus then
				newValue = math.min(1, currentValue + 0.05)
			else return end
			slider.setValue(newValue)
			if slider._onValueChanged then slider._onValueChanged(newValue) end
		end
		row.MouseEnter:Connect(function() ZolinModules.state.activeRow = row end)
		row.MouseLeave:Connect(function() if ZolinModules.state.activeRow == row then ZolinModules.state.activeRow = nil end end)
		return UserInputService.InputBegan:Connect(onKeyPress)
	end

	local function createSliderFromTemplate(parent, initialValue, optionName, iconId)
		local row = FrameTemplate:Clone()
		row.Name = optionName .. "Row"
		row.Parent = parent
		row.Visible = true

		local icon = row:FindFirstChild("Icon")
		if icon and icon:IsA("ImageLabel") then icon.Image = iconId end

		local fill = row:FindFirstChild("Fill")
		if not fill then warn("Fill not found in FrameTemplate"); return nil end

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

		local outlineStyle = row:FindFirstChild("OutlineStyle")
		if not outlineStyle then warn("OutlineStyle not found in FrameTemplate"); return nil end

		outlineStyle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		outlineStyle.BorderSizePixel = 0

		clickArea.Parent = outlineStyle
		clickArea.Position = UDim2.new(0, 0, outlineStyle.Position.Y.Scale, 5)
		clickArea.Size = UDim2.new(initialValue, 0, outlineStyle.Size.Y.Scale, 0)
		clickArea.BackgroundColor3 = optionName == "Media" and Color3.fromRGB(34, 255, 255) or Color3.fromRGB(255, 200, 50)
		clickArea.BackgroundTransparency = 0
		clickArea.Text = ""

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = clickArea

		local outlineCorner = outlineStyle:FindFirstChild("UICorner")
		if not outlineCorner then
			outlineCorner = Instance.new("UICorner")
			outlineCorner.CornerRadius = UDim.new(1, 0)
			outlineCorner.Parent = outlineStyle
		end

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

		local onValueChanged = nil
		local dragging = false

		local function getMaxWidth() return outlineStyle.AbsoluteSize.X end

		local function updateFromPosition(mouseX)
			local outlineAbsPos = outlineStyle.AbsolutePosition
			local maxWidth = getMaxWidth()
			if maxWidth <= 0 then return initialValue end
			local relativeX = math.clamp(mouseX - outlineAbsPos.X, 0, maxWidth)
			local newValue = relativeX / maxWidth
			newValue = math.clamp(newValue, 0, 1)
			clickArea.Size = UDim2.new(newValue, 0, outlineStyle.Size.Y.Scale, 0)
			local buttonX = (newValue * maxWidth) - (sliderButton.AbsoluteSize.X / 2)
			local buttonMinX = -sliderButton.AbsoluteSize.X / 2
			local buttonMaxX = maxWidth - (sliderButton.AbsoluteSize.X / 2)
			buttonX = math.clamp(buttonX, buttonMinX, buttonMaxX)
			sliderButton.Position = UDim2.new(0, buttonX, 0.5, -9)
			valueLabel.Text = formatVolume(newValue)
			return newValue
		end

		local function triggerValueChange(newValue) if onValueChanged then onValueChanged(newValue) end end

		clickArea.MouseButton1Down:Connect(function() dragging = true; sliderButton.BackgroundColor3 = Color3.fromRGB(80, 255, 255); if glow then glow.BackgroundColor3 = Color3.fromRGB(80, 255, 255) end end)
		sliderButton.MouseButton1Down:Connect(function() dragging = true; sliderButton.BackgroundColor3 = Color3.fromRGB(80, 255, 255); if glow then glow.BackgroundColor3 = Color3.fromRGB(80, 255, 255) end end)

		local inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local mousePos = UserInputService:GetMouseLocation()
				triggerValueChange(updateFromPosition(mousePos.X))
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

		local outlineClickConnection = outlineStyle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local mousePos = UserInputService:GetMouseLocation()
				triggerValueChange(updateFromPosition(mousePos.X))
			end
		end)

		local slider = {
			row = row, fill = clickArea, button = sliderButton, valueLabel = valueLabel, outlineStyle = outlineStyle, _onValueChanged = onValueChanged,
			setValue = function(value)
				value = math.clamp(value, 0, 1)
				local maxWidth = getMaxWidth()
				clickArea.Size = UDim2.new(value, 0, outlineStyle.Size.Y.Scale, 0)
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
		slider.setValue(initialValue)
		slider.setOnValueChanged = function(callback) onValueChanged = callback; slider._onValueChanged = callback end
		local keyboardConn = setupKeyboardControls(slider, row, optionName)
		slider._connections = { inputChangedConnection, inputEndedConnection, outlineClickConnection, keyboardConn }
		return slider, keyboardConn
	end

	local function openPopup()
		if ZolinModules.state.isOpen then return end
		VolumeStyleOptionsFrame.Visible = true
		if DoneButton then DoneButton.Visible = true end
		ZolinModules.state.isOpen = true
		local targetPos = UDim2.new(0.5, 0, 0.94, 0)
		local targetPos2 = UDim2.new(0.808, 0, 0.889, 0)
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	 	ZolinModules.state.openTween = TweenService:Create(VolumeStyleOptionsFrame.UI, tweenInfo, {Position = targetPos})
		ZolinModules.state.openTween:Play()
		if DoneButton then
			local DoneButtonPos = TweenService:Create(DoneButton, tweenInfo, {Position = targetPos2})
			DoneButtonPos:Play()
			local DoneButtonTweenAndBackground = TweenService:Create(DoneButton, tweenInfo, {BackgroundTransparency = 0})
			DoneButtonTweenAndBackground:Play()
			local DoneButtonTween = TweenService:Create(DoneButton, tweenInfo, {TextTransparency = 0})
			DoneButtonTween:Play()
		end
		local bgTweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		local BG_Tween = TweenService:Create(VolumeStyleOptionsFrame, bgTweenInfo, {BackgroundTransparency = 0.5})
		BG_Tween:Play()
	end

	local function closePopup()
		local targetPos = UDim2.new(0.5, 0, 1.5, 0)
		local targetPos2 = UDim2.new(0.808, 0, 1.889, 0)
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		ZolinModules.state.closeTween = TweenService:Create(VolumeStyleOptionsFrame.UI, tweenInfo, {Position = targetPos})
		ZolinModules.state.closeTween:Play()
		if DoneButton then
			local DoneButtonPos = TweenService:Create(DoneButton, tweenInfo, {Position = targetPos2})
			DoneButtonPos:Play()
			local DoneButtonTweenAndBackground = TweenService:Create(DoneButton, tweenInfo, {BackgroundTransparency = 1})
			DoneButtonTweenAndBackground:Play()
			local DoneButtonTween = TweenService:Create(DoneButton, tweenInfo, {TextTransparency = 1})
			DoneButtonTween:Play()
		end
		ZolinModules.state.closeTween.Completed:Connect(function()
			VolumeStyleOptionsFrame.Visible = false
			if DoneButton then DoneButton.Visible = false end
			ZolinModules.state.isOpen = false
		end)
		local bgTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local BG_Tween = TweenService:Create(VolumeStyleOptionsFrame, bgTweenInfo, {BackgroundTransparency = 1})
		BG_Tween:Play()
	end

	function VolumeStyleOptions.Initialize()
		if not (VolumeStyleOptionsFrame and Assets and FrameTemplate) then
			warn("VolumeStyleOptions: Required UI elements missing")
			return
		end
		for _, child in ipairs(VolumeStyleOptionsFrame.UI:GetChildren()) do
			if child:IsA("Frame") and child ~= DoneButton then child:Destroy() end
		end
		ZolinModules.state.isOpen = false
		ZolinModules.state.mediaVolume = VolumeManager.GetVolume()
		ZolinModules.state.notificationVolume = 0.5
		local mediaSlider, mediaKeyboard = createSliderFromTemplate(VolumeStyleOptionsFrame.UI, ZolinModules.state.mediaVolume, "Media", "rbxassetid://470648244")
		mediaSlider.setOnValueChanged(function(value) ZolinModules.state.mediaVolume = value; VolumeManager.SetVolume(value) end)
		local notificationSlider, notificationKeyboard = createSliderFromTemplate(VolumeStyleOptionsFrame.UI, ZolinModules.state.notificationVolume, "Notifications", "rbxassetid://11401835408")
		notificationSlider.setOnValueChanged(function(value)
			ZolinModules.state.notificationVolume = value
			local notificationsSoundUI = MainUI and MainUI:FindFirstChild("NotificationsSoundUI")
			if notificationsSoundUI then notificationsSoundUI.Volume = value end
		end)
		local mediaRow = mediaSlider.row
		local notificationRow = notificationSlider.row
		mediaRow.Position = UDim2.new(0.5, -175, 0.2, 0)
		notificationRow.Position = UDim2.new(0.5, -175, 0.45, 0)
		ZolinModules.state.mediaSlider = mediaSlider
		ZolinModules.state.notificationSlider = notificationSlider
		ZolinModules.state.keyboardConnections = { mediaKeyboard, notificationKeyboard }
		if DoneButton then
			DoneButton.MouseButton1Click:Connect(function() closePopup() end)
		end
		local function onScreenClick(input)
			if ZolinModules.state.isOpen then
				local mousePos = UserInputService:GetMouseLocation()
				local absPos = VolumeStyleOptionsFrame.AbsolutePosition
				local absSize = VolumeStyleOptionsFrame.AbsoluteSize
				local isInside = mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y
				if not isInside then if DoneButton then DoneButton.Visible = false end; closePopup() end
			end
		end
		UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then onScreenClick(input) end
		end)
		VolumeStyleOptionsFrame.Visible = false
		VolumeStyleOptionsFrame.UI.Position = UDim2.new(0.5, 0, 1.1, 0)
		VolumeStyleOptionsFrame.BackgroundTransparency = 1
		print("VolumeStyleOptions initialized!")
	end

	function VolumeStyleOptions.Open() openPopup(); if ZolinModules.state.mediaSlider then ZolinModules.state.mediaSlider.setValue(VolumeManager.GetVolume()) end end
	function VolumeStyleOptions.Close() closePopup() end
	function VolumeStyleOptions.Toggle() if ZolinModules.state.isOpen then closePopup() else openPopup() end end
	function VolumeStyleOptions.IsOpen() return ZolinModules.state.isOpen end

	return VolumeStyleOptions
end

-- ============================================
-- POWER MENU MANAGER
-- ============================================
function ZolinModules.PowerMenuManager()
	local PowerMenuManager = {}
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")

	local MainUI = getMainUI()
	local __ScreenFrame = MainUI and MainUI:WaitForChild("__ScreenFrame")
	local __Zolin = MainUI and MainUI:WaitForChild("__Zolin")
	local Remotes = __Zolin and __Zolin:WaitForChild("Remotes")
	local CloseAllAppsEvent = Remotes and Remotes:WaitForChild("CloseAllApps")

	local state = {
		isOpen = false, overlay = nil, powerMenuFrame = nil, sliderButton = nil, sliderTrack = nil, sliderFill = nil,
		instructionLabel = nil, cancelButton = nil, cancelLabel = nil, isDragging = false, dragStartX = 0, currentDragX = 0,
		tween = nil, dragConnection = nil, endConnection = nil, isShuttingDown = false
	}

	local function createPowerMenuUI()
		if state.overlay then return end
		local overlay = Instance.new("Frame")
		overlay.Name = "PowerMenuOverlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.Position = UDim2.new(0.5, 0, 0.5, 0)
		overlay.AnchorPoint = Vector2.new(0.5, 0.5)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 1
		overlay.ZIndex = 10000
		overlay.Parent = __ScreenFrame or MainUI

		local powerMenuFrame = Instance.new("Frame")
		powerMenuFrame.Name = "PowerMenuFrame"
		powerMenuFrame.Size = UDim2.new(0, 300, 0, 180)
		powerMenuFrame.Position = UDim2.new(0.5, -150, 0, -180)
		powerMenuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		powerMenuFrame.BackgroundTransparency = 1
		powerMenuFrame.BorderSizePixel = 0
		powerMenuFrame.ZIndex = overlay.ZIndex + 1
		powerMenuFrame.Parent = overlay

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 25)
		corner.Parent = powerMenuFrame

		local instructionLabel = Instance.new("TextLabel")
		instructionLabel.Name = "InstructionLabel"
		instructionLabel.Size = UDim2.new(1, 0, 0, 30)
		instructionLabel.Position = UDim2.new(0, 0, 0, 10)
		instructionLabel.BackgroundTransparency = 1
		instructionLabel.Text = "Slide To Power OFF"
		instructionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		instructionLabel.Font = Enum.Font.Gotham
		instructionLabel.TextSize = 17
		instructionLabel.TextScaled = false
		instructionLabel.ZIndex = overlay.ZIndex + 1

		local sliderTrack = Instance.new("Frame")
		sliderTrack.Name = "SliderTrack"
		sliderTrack.Size = UDim2.new(0.9, 0, 0, 50)
		sliderTrack.Position = UDim2.new(0.05, 0, 0.35, -25)
		sliderTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		sliderTrack.BackgroundTransparency = 0.8
		sliderTrack.BorderSizePixel = 0
		sliderTrack.ZIndex = overlay.ZIndex + 1
		sliderTrack.Parent = powerMenuFrame
		instructionLabel.Parent = sliderTrack

		local trackUIStroke = Instance.new("UIStroke")
		trackUIStroke.Color = Color3.fromRGB(255, 255, 255)
		trackUIStroke.Thickness = 1.5
		trackUIStroke.Parent = sliderTrack
		trackUIStroke.Transparency = 0.15

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(0, 25)
		trackCorner.Parent = sliderTrack

		local sliderFill = Instance.new("Frame")
		sliderFill.Name = "SliderFill"
		sliderFill.Size = UDim2.new(0, 0, 1, 0)
		sliderFill.BackgroundColor3 = Color3.fromRGB(99, 99, 99)
		sliderFill.BorderSizePixel = 0
		sliderFill.ZIndex = overlay.ZIndex + 1
		sliderFill.Parent = sliderTrack

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 25)
		fillCorner.Parent = sliderFill

		local powerIcon = Instance.new("ImageLabel")
		powerIcon.Name = "PowerIcon"
		powerIcon.Size = UDim2.new(0, 24, 0, 24)
		powerIcon.Position = UDim2.new(0, 10, 0.5, -12)
		powerIcon.BackgroundTransparency = 1
		powerIcon.Image = "rbxassetid://78125880206412"
		powerIcon.ZIndex = overlay.ZIndex + 2
		powerIcon.Parent = sliderTrack

		local sliderButton = Instance.new("ImageButton")
		sliderButton.Name = "SliderButton"
		sliderButton.Size = UDim2.new(0, 44, 0, 44)
		sliderButton.Position = UDim2.new(0, 3, 0.5, -22)
		sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		sliderButton.BackgroundTransparency = 0
		sliderButton.BorderSizePixel = 0
		sliderButton.Image = "rbxassetid://105578383603577"
		sliderButton.ScaleType = Enum.ScaleType.Fit
		sliderButton.ZIndex = overlay.ZIndex + 2
		sliderButton.Parent = sliderTrack
		sliderButton.ImageColor3 = Color3.fromRGB(0, 0, 0)

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(1, 0)
		buttonCorner.Parent = sliderButton

		local cancelButton = Instance.new("ImageButton")
		cancelButton.Name = "CancelButton"
		cancelButton.Size = UDim2.new(0, 75, 0, 75)
		cancelButton.Position = UDim2.new(0.5, 0, 0.89, 0)
		cancelButton.AnchorPoint = Vector2.new(0.5, 1)
		cancelButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		cancelButton.BackgroundTransparency = 0.2
		cancelButton.Image = "rbxassetid://4458805208"
		cancelButton.ImageColor3 = Color3.fromRGB(0, 0, 0)
		cancelButton.ZIndex = overlay.ZIndex + 2
		cancelButton.Parent = overlay

		local cancelButtonCorner = Instance.new("UICorner")
		cancelButtonCorner.CornerRadius = UDim.new(1, 0)
		cancelButtonCorner.Parent = cancelButton

		local cancelLabel = Instance.new("TextLabel")
		cancelLabel.Name = "CancelLabel"
		cancelLabel.Size = UDim2.new(1, 0, 0, 20)
		cancelLabel.Position = UDim2.new(0.5, 0, 1, 25)
		cancelLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		cancelLabel.BackgroundTransparency = 1
		cancelLabel.Text = "Cancel"
		cancelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		cancelLabel.Font = Enum.Font.Gotham
		cancelLabel.TextSize = 14
		cancelLabel.TextScaled = true
		cancelLabel.ZIndex = overlay.ZIndex + 1
		cancelLabel.Parent = cancelButton

		cancelButton.MouseEnter:Connect(function() pcall(function() cancelButton.BackgroundColor3 = Color3.fromRGB(157, 157, 157) end) end)
		cancelButton.MouseLeave:Connect(function() pcall(function() cancelButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end) end)
		cancelButton.MouseButton1Click:Connect(function() PowerMenuManager.Close(1) end)

		state.overlay = overlay
		state.powerMenuFrame = powerMenuFrame
		state.sliderButton = sliderButton
		state.sliderTrack = sliderTrack
		state.sliderFill = sliderFill
		state.instructionLabel = instructionLabel
		state.cancelButton = cancelButton
		state.cancelLabel = cancelLabel
	end

	local function updateSliderPosition(dragX)
		if not state.sliderTrack or not state.sliderButton then return 0 end
		local trackWidth = 0
		local buttonWidth = 0
		local success = pcall(function()
			trackWidth = state.sliderTrack.AbsoluteSize.X
			buttonWidth = state.sliderButton.AbsoluteSize.X
		end)
		if not success or trackWidth <= 0 or buttonWidth <= 0 then return 0 end
		local maxDrag = trackWidth - buttonWidth - 6
		local newDragX = math.clamp(dragX, 0, maxDrag)
		local progress = newDragX / maxDrag
		state.sliderButton.Position = UDim2.new(0, 3 + newDragX, 0.5, -22)
		if state.sliderFill then state.sliderFill.Size = UDim2.new(progress, 0, 1, 0) end
		local targetTransparency = 1 - (progress * 0.7)
		if state.overlay then pcall(function() local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.1, Enum.EasingStyle.Linear), { BackgroundTransparency = targetTransparency }); bgTween:Play() end) end
		if state.instructionLabel then state.instructionLabel.TextTransparency = 1 - (progress * 0.8) end
		if state.cancelButton then
			local cancelAlpha = math.clamp(1 - (progress * 1.2), 0, 1)
			state.cancelButton.ImageTransparency = cancelAlpha
			state.cancelButton.BackgroundTransparency = 0.2 + (cancelAlpha * 0.8)
		end
		if state.cancelLabel then
			local cancelLabelAlpha = math.clamp(1 - (progress * 1.2), 0, 1)
			state.cancelLabel.TextTransparency = cancelLabelAlpha
		end
		if progress >= 0.999 then PowerMenuManager.Close(1) end
		return progress
	end

	local function resetSlider()
		if state.sliderButton then pcall(function() local resetTween = TweenService:Create(state.sliderButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 3, 0.5, -22) }); resetTween:Play() end) end
		if state.sliderFill then pcall(function() local fillTween = TweenService:Create(state.sliderFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 0, 1, 0) }); fillTween:Play() end) end
		if state.overlay then pcall(function() local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }); bgTween:Play() end) end
		if state.instructionLabel then pcall(function() local labelTween = TweenService:Create(state.instructionLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }); labelTween:Play() end) end
		if state.cancelButton then pcall(function() local cancelTween = TweenService:Create(state.cancelButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0, BackgroundTransparency = 0.2 }); cancelTween:Play() end) end
		if state.cancelLabel then pcall(function() local labelTween = TweenService:Create(state.cancelLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }); labelTween:Play() end) end
		state.currentDragX = 0
	end

	local function animateMenuIn()
		if not state.powerMenuFrame then return end
		pcall(function() local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.5 }); bgTween:Play() end)
		pcall(function() local menuTween = TweenService:Create(state.powerMenuFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -150, 0, 20) }); menuTween:Play() end)
	end

	local function animateMenuOut(p1)
		if not state.powerMenuFrame then return end
		pcall(function()
			if p1 == 1 then local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }); bgTween:Play() end
		end)
		pcall(function()
			local menuTween = TweenService:Create(state.powerMenuFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -150, 0, -180) })
			menuTween:Play()
			local FadeOutTween2 = TweenService:Create(state.cancelButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 1, BackgroundTransparency = 1 })
			local FadeOutTween3 = TweenService:Create(state.cancelLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 })
			FadeOutTween3:Play()
			FadeOutTween2:Play()
			menuTween.Completed:Connect(function()
				if state.overlay then
					if p1 == 1 then state.overlay:Destroy() end
					state.overlay = nil
					state.powerMenuFrame = nil
					state.sliderButton = nil
					state.sliderTrack = nil
					state.sliderFill = nil
					state.instructionLabel = nil
					state.cancelButton = nil
					state.cancelLabel = nil
				end
			end)
		end)
	end

	local function setupDragHandlers()
		if not state.sliderButton then return end
		local isDragging = false
		local startDragX = 0
		local startButtonX = 0
		local function onDragStart(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				state.isDragging = true
				startDragX = input.Position.X
				local buttonPos = state.sliderButton.Position
				startButtonX = buttonPos.X.Offset - 3
				pcall(function() state.sliderButton.BackgroundColor3 = Color3.fromRGB(240, 240, 240) end)
			end
		end
		local function onDragMove(input)
			if not isDragging then return end
			local deltaX = input.Position.X - startDragX
			local newDragX = startButtonX + deltaX
			updateSliderPosition(newDragX)
			state.currentDragX = newDragX
		end
		local function onDragEnd(input)
			if isDragging then
				isDragging = false
				state.isDragging = false
				pcall(function() state.sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end)
				local trackWidth = 0
				local buttonWidth = 0
				local success = pcall(function() trackWidth = state.sliderTrack.AbsoluteSize.X; buttonWidth = state.sliderButton.AbsoluteSize.X end)
				if success and trackWidth > 0 and buttonWidth > 0 then
					local maxDrag = trackWidth - buttonWidth - 6
					local progress = state.currentDragX / maxDrag
					if progress < 0.998 then resetSlider() end
				else resetSlider() end
			end
		end
		state.sliderButton.InputBegan:Connect(onDragStart)
		state.dragConnection = UserInputService.InputChanged:Connect(onDragMove)
		state.endConnection = UserInputService.InputEnded:Connect(onDragEnd)
	end

	local function cleanupDragHandlers()
		if state.dragConnection then state.dragConnection:Disconnect(); state.dragConnection = nil end
		if state.endConnection then state.endConnection:Disconnect(); state.endConnection = nil end
	end

	function PowerMenuManager.Init() print("PowerMenuManager initialized!") end
	function PowerMenuManager.Open()
		if state.isOpen then return end
		state.isShuttingDown = false
		createPowerMenuUI()
		task.wait()
		animateMenuIn()
		setupDragHandlers()
		state.isOpen = true
	end
	function PowerMenuManager.Close(p1)
		if not state.isOpen then return end
		cleanupDragHandlers()
		animateMenuOut(p1)
		state.isOpen = false
	end
	function PowerMenuManager.Toggle()
		if state.isOpen then PowerMenuManager.Close(1) else PowerMenuManager.Open() end
	end
	function PowerMenuManager.IsOpen() return state.isOpen end

	local onShutdownCallback = nil
	function PowerMenuManager.SetOnShutdown(callback) onShutdownCallback = callback end

	local originalUpdate = updateSliderPosition
	updateSliderPosition = function(dragX)
		if not state.sliderTrack or not state.sliderButton then return 0 end
		local trackWidth = 0
		local buttonWidth = 0
		local success = pcall(function() trackWidth = state.sliderTrack.AbsoluteSize.X; buttonWidth = state.sliderButton.AbsoluteSize.X end)
		if not success or trackWidth <= 0 or buttonWidth <= 0 then return 0 end
		local maxDrag = trackWidth - buttonWidth - 6
		local newDragX = math.clamp(dragX, 0, maxDrag)
		local progress = newDragX / maxDrag
		if state.sliderButton then pcall(function() state.sliderButton.Position = UDim2.new(0, 3 + newDragX, 0.5, -22) end) end
		if state.sliderFill then pcall(function() state.sliderFill.Size = UDim2.new(progress, 0, 1, 0) end) end
		if state.overlay then
			local targetTransparency = 1 - (progress * 0.7)
			pcall(function() local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.1, Enum.EasingStyle.Linear), { BackgroundTransparency = targetTransparency }); bgTween:Play() end)
		end
		if state.instructionLabel then state.instructionLabel.TextTransparency = 1 - (progress * 0.8) end
		if state.cancelButton then
			local cancelAlpha = math.clamp(1 - (progress * 1.2), 0, 1)
			state.cancelButton.ImageTransparency = cancelAlpha
			state.cancelButton.BackgroundTransparency = 0.2 + (cancelAlpha * 0.8)
		end
		if state.cancelLabel then state.cancelLabel.TextTransparency = math.clamp(1 - (progress * 1.2), 0, 1) end
		if progress >= 0.999 and not state.isShuttingDown then
			state.isShuttingDown = true
			if onShutdownCallback then onShutdownCallback()
			else
				if state.overlay then pcall(function() local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.25, Enum.EasingStyle.Linear), { BackgroundTransparency = 0 }); bgTween:Play() end) end
				task.spawn(function()
					print("Shutting down...")
					if CloseAllAppsEvent then CloseAllAppsEvent:Fire() end
					task.wait(3.75)
					local mainUI = getMainUI()
					if mainUI then mainUI:Destroy() end
				end)
			end
			PowerMenuManager.Close(0)
		end
		return progress
	end

	return PowerMenuManager
end

-- ============================================
-- CLOCK MODULE
-- ============================================
function ZolinModules.ClockManager()
	local ClockModule = {}

	local MainUI = getMainUI()
	if not MainUI then
		warn("ClockManager: Could not find ScreenGui ancestor")
		return ClockModule
	end

	-- Ensure __Zolin and Runtime exist
	local zolin = MainUI:FindFirstChild("__Zolin")
	if not zolin then
		zolin = Instance.new("Folder")
		zolin.Name = "__Zolin"
		zolin.Parent = MainUI
	end
	local Runtime = zolin:FindFirstChild("Runtime")
	if not Runtime then
		Runtime = Instance.new("Folder")
		Runtime.Name = "Runtime"
		Runtime.Parent = zolin
	end

	-- Create/Get StringValues
	local Clock = Runtime:FindFirstChild("Clock") or Instance.new("StringValue", Runtime)
	Clock.Name = "Clock"
	local Uptime = Runtime:FindFirstChild("CurrentUptime") or Instance.new("StringValue", Runtime)
	Uptime.Name = "CurrentUptime"

	-- Timezone offset (e.g., 3 for GMT+3, can be changed)
	local timeZoneOffset = 3
	local startTime = os.time()

	local function formatUptime(seconds)
		local h = math.floor(seconds / 3600)
		local m = math.floor((seconds % 3600) / 60)
		local s = math.floor(seconds % 60)
		return string.format("%02d:%02d:%02d", h, m, s)
	end

	local function getFormattedTime()
		local utc = os.date("!*t")
		local hour = (utc.hour + timeZoneOffset) % 24
		local minute = utc.min
		local second = utc.sec
		local ampm = hour >= 12 and "PM" or "AM"
		local hour12 = hour % 12
		if hour12 == 0 then hour12 = 12 end

		if ZolinModules.Mode == "Desktop" then
			-- Desktop: include seconds
			return string.format("%02d:%02d:%02d %s", hour12, minute, second, ampm)
		else
			-- Mobile: no seconds (original format)
			return string.format("%02d:%02d %s", hour12, minute, ampm)
		end
	end

	local function getFormattedDate()
		local utc = os.date("!*t")
		local timestamp = os.time(utc) + (timeZoneOffset * 3600)
		local localDate = os.date("*t", timestamp)
		return string.format("%02d/%02d/%04d", localDate.month, localDate.day, localDate.year)
	end

	local function Update()
		local timeStr = getFormattedTime()
		local dateStr = getFormattedDate()
		local uptimeStr = formatUptime(os.time() - startTime)

		-- Update global Runtime values
		Clock.Value = timeStr
		Uptime.Value = uptimeStr

		-- Update global variables
		ZolinModules.CurrentUptime = uptimeStr
		ZolinModules.CurrentTime = timeStr

		-- Update UI elements that have the "Clock" or "Date" attribute
		for _, v in pairs(MainUI:GetDescendants()) do
			if v:IsA("TextLabel") or v:IsA("TextButton") then
				if v:GetAttribute("Clock") == true and v.Visible then
					v.Text = timeStr
				end
				if ZolinModules.Mode == "Desktop" then
					if v:GetAttribute("Date") == true and v.Visible then
						v.Text = dateStr
					end
				end
			end
		end
	end

	function ClockModule.Init()
		Update()
		task.spawn(function()
			while true do
				task.wait(0.05)
				Update()
			end
		end)
	end

	return ClockModule
end

-- ============================================
-- PLATFORM MANAGER
-- ============================================
function ZolinModules.PlatformManager()
	local PlatformManager = {}
	local MainUI = getMainUI()
	if not MainUI then
		warn("PlatformManager: Could not find ScreenGui ancestor")
		return PlatformManager
	end
	local DeviceTree = MainUI:FindFirstChild("DeviceTree")
	local DevicePlatform = DeviceTree and DeviceTree:FindFirstChild("DevicePlatform")
	if not DevicePlatform then
		DevicePlatform = Instance.new("StringValue")
		DevicePlatform.Name = "DevicePlatform"
		DevicePlatform.Parent = DeviceTree or MainUI
	end
	function PlatformManager.GetCurrentPlatform()
		local userInputService = game:GetService("UserInputService")
		local isConsole = userInputService.GamepadEnabled
		local isMobile = userInputService.TouchEnabled
		local isDesktop = not isMobile and not isConsole
		DevicePlatform.Value = isConsole and "console" or isMobile and "mobile" or "desktop"
		print("PlatformManager: Current Platform is " .. DevicePlatform.Value)
		return DevicePlatform.Value
	end
	PlatformManager.GetCurrentPlatform()
	return PlatformManager
end

-- ============================================
-- SETTINGS MANAGER
-- ============================================
function ZolinModules.SettingsManager()
	local SettingsManager = {}
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	local MainUI = getMainUI()
	if not MainUI then
		warn("SettingsManager: Could not find ScreenGui ancestor")
		return SettingsManager
	end

	-- Settings storage
	local settingsFolder = MainUI:FindFirstChild("SettingsData")
	if not settingsFolder then
		settingsFolder = Instance.new("Folder")
		settingsFolder.Name = "SettingsData"
		settingsFolder.Parent = MainUI
	end

	-- Default settings
	local defaultSettings = {
		Wallpaper = {
			type = "string",
			value = "rbxassetid://2387794684" -- default wallpaper
		},
		-- Media volume (main volume)
		Volume = {
			type = "number",
			value = 0.5
		},
		-- Notification volume
		NotificationVolume = {
			type = "number",
			value = 0.5
		},
		-- Media mute
		Muted_Media = {
			type = "boolean",
			value = false
		},
		-- Notification mute
		Muted_Notifications = {
			type = "boolean",
			value = false
		},
		-- UI animations toggle
		AnimationUI = {
			type = "boolean",
			value = true
		},
		-- Transition speed
		TransitionSpeed = {
			type = "number",
			value = 1
		},
		-- Device name
		DeviceName = {
			type = "string",
			value = "ZolinPhone"
		},
	}

	-- Load or create setting
	local function getSetting(settingName, settingType, defaultValue)
		local setting = settingsFolder:FindFirstChild(settingName)
		if not setting then
			if settingType == "string" then
				setting = Instance.new("StringValue")
			elseif settingType == "number" then
				setting = Instance.new("NumberValue")
			elseif settingType == "boolean" then
				setting = Instance.new("BoolValue")
			end
			setting.Name = settingName
			setting.Value = defaultValue
			setting.Parent = settingsFolder
		end
		return setting
	end

	-- Initialize all settings
	for name, data in pairs(defaultSettings) do
		getSetting(name, data.type, data.value)
	end

	-- Public functions
	function SettingsManager.GetSetting(settingName)
		local setting = settingsFolder:FindFirstChild(settingName)
		return setting and setting.Value or nil
	end

	function SettingsManager.SetSetting(settingName, value)
		local setting = settingsFolder:FindFirstChild(settingName)
		if setting then
			setting.Value = value
			return true
		end
		return false
	end

	function SettingsManager.GetUserInfo()
		local userId = player.UserId
		local accountAge = player.AccountAge
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return {
			UserName = player.Name,
			DisplayName = player.DisplayName,
			UserId = userId,
			AccountAgeDays = accountAge,
			AccountCreationDate = os.date("%Y-%m-%d", os.time() - (accountAge * 86400)),
			CurrentHealth = humanoid and humanoid.Health or 0,
			MaxHealth = humanoid and humanoid.MaxHealth or 100,
			WalkSpeed = humanoid and humanoid.WalkSpeed or 16,
			JumpPower = humanoid and humanoid.JumpPower or 50
		}
	end

	function SettingsManager.GetOSInfo()
		local deviceTree = MainUI:FindFirstChild("DeviceTree")
		return {
			OSName = deviceTree and deviceTree:FindFirstChild("DeviceName") and deviceTree.DeviceName.Value or "ZolinOS",
			Version = deviceTree and deviceTree:FindFirstChild("ZolinVersion") and deviceTree.ZolinVersion.Value or "1.1",
			BuildDate = "2026",
			DeviceName = deviceTree and deviceTree:FindFirstChild("DeviceName") and deviceTree.DeviceName.Value or "ZolinPhone"
		}
	end

	print("SettingsManager initialized!")
	return SettingsManager
end

-- ============================================
-- ZOLIN LAUNCHER
-- ============================================
function ZolinModules.ZolinLauncher()
	local MainUI = getMainUI()
	if not MainUI then
		warn("ZolinLauncher: Could not find ScreenGui")
		return
	end
	if ZolinModules.Mode == "Mobile" then
	local __ScreenFrame = MainUI:FindFirstChild("__ScreenFrame")
	if not __ScreenFrame then
		warn("ZolinLauncher: __ScreenFrame not found")
		return
	end

	local HomeScreenScroller = __ScreenFrame:FindFirstChild("HomeScreenScroller")
	local ReplicatedIcons = MainUI:FindFirstChild("ReplicatedIcons")
	local appIconTemplate = ReplicatedIcons and ReplicatedIcons:FindFirstChild("AppIconTemplate")

	local modules = ZolinModules.GetAll();
	local AppManager = modules.AppManager
	local AppLoader = modules.AppLoader

	-- Store built-in modules that can be launched (AppName -> ModuleFunction)
	local builtInModules = {
		Settings = modules.SettingsApp,
		ZolinInstaller = modules.ZolinInstaller
	}

	-- Store which built-in modules are currently open/running
	local openBuiltInModules = {}

	local function populateHomeScreen()
		if not AppLoader then
			warn("AppLoader not available")
			return
		end

		print("Populating home screen...")

		if not HomeScreenScroller then
			warn("HomeScreenScroller not found")
			return
		end

		-- Clear existing icons
		for _, child in ipairs(HomeScreenScroller:GetChildren()) do
			if child ~= appIconTemplate and child:IsA("ImageButton") then
				child:Destroy()
			end
		end

		local apps = AppLoader.GetAllApps()
		for _, appData in ipairs(apps) do
			if AppManager and AppManager.IsSystemApp and AppManager.IsSystemApp(appData.name) then
				-- Skip system apps
			else
				if not appIconTemplate then
					warn("AppIconTemplate not found")
					return
				end

				local icon = appIconTemplate:Clone()
				icon.Name = appData.name
				icon.Visible = true
				icon.Parent = HomeScreenScroller

				local iconImage = icon:FindFirstChild("IconImage") or icon
				if iconImage:IsA("ImageLabel") or iconImage:IsA("ImageButton") then
					iconImage.Image = appData.metadata.icon
				end

				local label = icon:FindFirstChild("AppName")
				if label and label:IsA("TextLabel") then
					label.Text = appData.name
				end

				icon.MouseButton1Click:Connect(function()
					if MainUI.__ScreenFrame.BackgroundPage.Visible then
						return
					end
					if AppManager then
						-- Check if this is a built-in module
						local builtInModule = builtInModules[appData.name]

						if builtInModule then
							-- Check if the built-in module is already open
							local moduleUI = openBuiltInModules[appData.name]
							if moduleUI and moduleUI.Visible then
								-- Module is already open, bring it to front or close it
								moduleUI.Visible = false
								openBuiltInModules[appData.name] = nil
							else
								-- Create or show the built-in module UI
								-- First, check if we already have a cloned app for this module
								local appInstance = MainUI.__ScreenFrame.Applications:FindFirstChild(appData.name)
								if not appInstance and not AppManager.GetApplication(appData.name) then
									-- Create a new app instance for the built-in module
									AppManager.LaunchApplication(appData.name)
								elseif not AppManager.GetActiveApp() then
									-- Resume the existing app
									openBuiltInModules[appData.name] = appInstance
									AppManager.ResumeApplication(appData.name)
									
								end
							end
						else
							-- Launch regular app via AppManager
							if not AppManager.GetApplication(appData.name) then
								AppManager.LaunchApplication(appData.name)
							elseif not AppManager.GetActiveApp() then
								AppManager.ResumeApplication(appData.name)
							end
						end
					end
				end)
			end
		end
	end
	populateHomeScreen()
	print("ZolinLauncher: Home screen ready!")
	elseif ZolinModules.Mode == "Desktop" then
		local __ZolinDesktop = MainUI:FindFirstChild("__ZolinDesktop")
		if not __ZolinDesktop then
			warn("ZolinLauncher: __ZolinDesktop not found")
			return
		end
		local __ScreenFrame = __ZolinDesktop:FindFirstChild("__ScreenFrame")
		if not __ScreenFrame then
			warn("ZolinLauncher: __ScreenFrame not found")
			return
		end

		local HomeScreenScroller = __ScreenFrame:FindFirstChild("HomeScreenScrollerV2")
		local ReplicatedIcons = MainUI:FindFirstChild("ReplicatedIcons")
		local appIconTemplate = ReplicatedIcons and ReplicatedIcons:FindFirstChild("AppIconTemplateV2")

		local modules = ZolinModules.GetAll_Desktop()
		local AppManager = modules.AppManager
		local AppLoader = modules.AppLoader

		-- Ensure we have a remote for right‑click events
		local __Zolin = MainUI:FindFirstChild("__Zolin")
		if not __Zolin then
			__Zolin = Instance.new("Folder")
			__Zolin.Name = "__Zolin"
			__Zolin.Parent = MainUI
		end
		local Remotes = __Zolin:FindFirstChild("Remotes")
		if not Remotes then
			Remotes = Instance.new("Folder")
			Remotes.Name = "Remotes"
			Remotes.Parent = __Zolin
		end
		local AppRightClick = Remotes:FindFirstChild("ContextMenuEvent")

		-- Store built‑in modules
		local builtInModules = {
			Settings = modules.SettingsApp,
			ZolinInstaller = modules.ZolinInstaller
		}
		local openBuiltInModules = {}

		local function populateHomeScreen()
			if not AppLoader then
				warn("AppLoader not available")
				return
			end

			if not HomeScreenScroller then
				warn("HomeScreenScrollerV2 not found")
				return
			end

			-- Clear existing icons
			for _, child in ipairs(HomeScreenScroller:GetChildren()) do
				if child ~= appIconTemplate and child:IsA("ImageButton") then
					child:Destroy()
				end
			end

			local apps = AppLoader.GetAllApps()
			for _, appData in ipairs(apps) do
				if AppManager and AppManager.IsSystemApp and AppManager.IsSystemApp(appData.name) then
					-- Skip system apps
				else
					if not appIconTemplate then
						warn("AppIconTemplateV2 not found")
						return
					end

					local icon = appIconTemplate:Clone()
					icon.Name = appData.name
					icon.Visible = true
					icon.Parent = HomeScreenScroller

					local iconImage = icon:FindFirstChild("IconImage") or icon
					if iconImage:IsA("ImageLabel") or iconImage:IsA("ImageButton") then
						iconImage.Image = appData.metadata.icon
					end

					local label = icon:FindFirstChild("AppName")
					if label and label:IsA("TextLabel") then
						label.Text = appData.name
					end

					-- ----- Double‑click detection -----
					local lastClickTime = 0
					local doubleClickThreshold = 0.3  -- seconds

					icon.MouseButton1Click:Connect(function()
						local now = tick()
						if now - lastClickTime <= doubleClickThreshold then
							-- Double‑click: launch or resume the app
							if AppManager then
								local builtInModule = builtInModules[appData.name]
								if builtInModule then
									local moduleUI = openBuiltInModules[appData.name]
									if moduleUI and moduleUI.Visible then
										moduleUI.Visible = false
										openBuiltInModules[appData.name] = nil
									else
										local appInstance = __ScreenFrame.Applications:FindFirstChild(appData.name)
										if not appInstance and not AppManager.GetApplication(appData.name) then
											AppManager.LaunchApplication(appData.name)
										elseif not AppManager.GetActiveApp() then
											openBuiltInModules[appData.name] = appInstance
											AppManager.ResumeApplication(appData.name)
										end
									end
								else
									if not AppManager.GetApplication(appData.name) then
										AppManager.LaunchApplication(appData.name)
									elseif not AppManager.GetActiveApp() then
										AppManager.ResumeApplication(appData.name)
									end
								end
							end
							lastClickTime = 0  -- reset to avoid triple‑click
						else
							-- Single‑click: just record the time
							lastClickTime = now
						end
					end)

					-- ----- Right‑click: fire remote event -----
					icon.MouseButton2Click:Connect(function()
						if AppRightClick then
							AppRightClick:Fire("app", appData.name, {})
							print("ContextMenu")
						end
					end)
				end
			end
		end
		populateHomeScreen()
		print("ZolinLauncher: Home screen ready!")
	end
end
-- ============================================
-- ZOLIN LISTENER
-- ============================================
function ZolinModules.ZolinListener()
	local MainUI = getMainUI()
	if not MainUI then
		warn("ZolinListener: Could not find ScreenGui")
		return
	end

	local __Zolin = MainUI:FindFirstChild("__Zolin")
	if not __Zolin then
		warn("ZolinListener: __Zolin folder not found")
		return
	end

	local Remotes = __Zolin:FindFirstChild("Remotes")
	if not Remotes then
		warn("ZolinListener: Remotes folder not found")
		return
	end

	local moreOptionsVolStyleEvent = Remotes:FindFirstChild("moreOptionsVolStyle")
	local CloseAllAppsEvent = Remotes:FindFirstChild("CloseAllApps")
	local updateZolinLauncherEvent = Remotes:FindFirstChild("updateZolinLauncher")
	local contactDirHWupdateEvent = Remotes:FindFirstChild("contactDirHWupdateEvent")
	local SendNotificationEvent = Remotes:FindFirstChild("SendNotificationEvent")
	local modules = ZolinModules.GetAll()
	local AppManager = modules.AppManager
	local VolumeStyleOptions = modules.VolumeStyleOptions
	local DirectHW = modules.DirectHW

	if moreOptionsVolStyleEvent then
		moreOptionsVolStyleEvent.Event:Connect(function(p1, p2)
			if p1 == "Toggle" then
				if VolumeStyleOptions and VolumeStyleOptions.Toggle then
					VolumeStyleOptions.Toggle()
				end
			elseif p1 == "Open" then
				if VolumeStyleOptions and VolumeStyleOptions.Open then
					VolumeStyleOptions.Open()
				end
			elseif p1 == "Close" then
				if VolumeStyleOptions and VolumeStyleOptions.Close then
					VolumeStyleOptions.Close()
				end
			end
		end)
		print("ZolinListener: moreOptionsVolStyleEvent connected")
	end

	if CloseAllAppsEvent then
		CloseAllAppsEvent.Event:Connect(function()
			if AppManager and AppManager.CloseAllApps then
				AppManager.CloseAllApps()
			end
		end)
		print("ZolinListener: CloseAllAppsEvent connected")
	end
	
	if updateZolinLauncherEvent then
		updateZolinLauncherEvent.Event:Connect(function()
		ZolinModules.ZolinLauncher()
		print("ZolinListener: updateZolinLauncherEvent fired")
		end)
		print("ZolinListener: updateZolinLauncherEvent connected")
	end
	
	if SendNotificationEvent then
		SendNotificationEvent.Event:Connect(function(...)
			ZolinModules.SendNotification(...)
		end)
		print("ZolinListener: SendNotificationEvent connected")
	end
	
	-- ===== contactDirHWupdateEvent =====
	if contactDirHWupdateEvent and DirectHW then
		contactDirHWupdateEvent.Event:Connect(function(...)
			local args = {...}
			local eventType = args[1]

			if eventType == "ViewportCreated" then
				local appName = args[2]
				local viewportData = args[3]
				print("[DirectHW Event] Viewport created for:", appName)

			elseif eventType == "ViewportDestroyed" then
				local appName = args[2]
				print("[DirectHW Event] Viewport destroyed for:", appName)

			elseif eventType == "ModelLoaded" then
				local appName = args[2]
				local assetId = args[3]
				print("[DirectHW Event] Model loaded in", appName, ":", assetId)

			elseif eventType == "CameraUpdated" then
				local appName = args[2]
				local cframe = args[3]
				local fov = args[4]
				print("[DirectHW Event] Camera updated for:", appName)

			elseif eventType == "RequestViewportInfo" then
				-- App is asking for list of active viewports
				local activeViewports = DirectHW.GetActiveViewports()
				local viewportNames = {}
				for _, vp in ipairs(activeViewports) do
					table.insert(viewportNames, vp.appName)
				end
				-- Fire back with the info
				contactDirHWupdateEvent:Fire("ViewportInfoResponse", viewportNames)

			elseif eventType == "SyncAllCameras" then
				-- Example: sync all cameras to a specific position
				local targetCFrame = args[2]
				if targetCFrame then
					for _, vp in ipairs(DirectHW.GetActiveViewports()) do
						DirectHW.SetCamera(vp, targetCFrame)
					end
				end

			elseif eventType == "PauseAllAnimations" then
				-- Example: pause all viewport animations
				for _, vp in ipairs(DirectHW.GetActiveViewports()) do
					for _, conn in ipairs(vp.animations) do
						-- We don't have a pause method, but we could add one
						-- For now, just disconnect them
						conn:Disconnect()
					end
					vp.animations = {}
				end

			elseif eventType == "DestroyAllViewports" then
				-- Emergency: destroy all viewports
				local allViewports = DirectHW.GetActiveViewports()
				for i = #allViewports, 1, -1 do
					DirectHW.Destroy(allViewports[i])
				end
				print("[DirectHW Event] All viewports destroyed")

			else
				-- Custom event – forward it if needed
				print("[DirectHW Event] Custom event:", eventType, unpack(args, 2))
			end
		end)
		print("ZolinListener: contactDirHWupdateEvent connected")
	end
	print("ZolinListener: Ready!")
end

-- ============================================
-- CONTEXT MENU MANAGER (Desktop only) - SINGLETON
-- ============================================
function ZolinModules.ContextMenuManager()
	if ZolinModules._contextMenuManagerInstance then
		return ZolinModules._contextMenuManagerInstance
	end

	local ContextMenuManager = {}
	local isInitialized = false
	local overlay, menuFrame
	local isOpen = false

	-- Helper to create a menu item
	local function createMenuItem(label, callback, iconId, isSeparator, order)
		if isSeparator then
			local sep = Instance.new("Frame")
			sep.Size = UDim2.new(1, 0, 0, 1)
			sep.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			sep.BackgroundTransparency = 0
			sep.BorderSizePixel = 0
			sep.LayoutOrder = order
			sep.Parent = menuFrame
			return sep
		end

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		btn.BackgroundTransparency = 0
		btn.BorderSizePixel = 0
		btn.Text = label or ""
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.AutoButtonColor = false
		btn.LayoutOrder = order
		btn.ZIndex = 1000
		btn.Parent = menuFrame

		if iconId then
			local icon = Instance.new("ImageLabel")
			icon.Size = UDim2.new(0, 20, 0, 20)
			icon.Position = UDim2.new(0, 5, 0.5, -10)
			icon.BackgroundTransparency = 1
			icon.Image = iconId
			icon.ScaleType = Enum.ScaleType.Fit
			icon.ZIndex = 1001
			icon.Parent = btn
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Padding = UDim.new(0, 30)
		end

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		end)

		if callback then
			btn.MouseButton1Click:Connect(function()
				local success, err = pcall(callback)
				if not success then
					warn("Context menu callback error:", err)
				end
				ContextMenuManager.Close()
			end)
		end

		return btn
	end

	-- Build menu from items table
	local function buildMenu(items)
		for _, child in ipairs(menuFrame:GetChildren()) do
			child:Destroy()
		end

		for order, item in ipairs(items) do
			if item.isSeparator then
				createMenuItem(nil, nil, nil, true, order)
			else
				createMenuItem(item.label, item.callback, item.icon, false, order)
			end
		end

		local totalHeight = 0
		for _, child in ipairs(menuFrame:GetChildren()) do
			if child:IsA("TextButton") then
				totalHeight = totalHeight + 30
			elseif child:IsA("Frame") then
				totalHeight = totalHeight + 1
			end
		end
		local NewUIListLayout = Instance.new("UIListLayout");
		NewUIListLayout.Parent = menuFrame;
		NewUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
		NewUIListLayout.FillDirection = Enum.FillDirection.Vertical;
		
		local newUIStroke = Instance.new("UIStroke");
		newUIStroke.Parent = menuFrame;
		newUIStroke.Color = Color3.fromRGB(255, 255, 255);
		newUIStroke.Thickness = 1.5;
		newUIStroke.Transparency = 0.6;
		
		-- Padding from UIListLayout (2 per gap) + extra margins (top/bottom)
		local gapPadding = math.max(0, 2 * (#items - 1))
		local extraPadding = 4
		totalHeight = totalHeight + gapPadding + extraPadding

		menuFrame.Size = UDim2.new(0, 220, 0, totalHeight)
	end

	function ContextMenuManager.Show(position, items)
		if not isInitialized then
			warn("ContextMenuManager not initialized")
			return
		end
		if not items or #items == 0 then return end

		buildMenu(items)

		local ViewportSize = game:GetService("Workspace").CurrentCamera.ViewportSize
		local menuWidth = 220
		local offsetX = 10
		local offsetY = 10
		local posX = math.max(10, math.min(position.X + offsetX, ViewportSize.X - menuWidth - 10))
		local posY = math.max(10, math.min(position.Y + offsetY, ViewportSize.Y - 10))

		menuFrame.Position = UDim2.new(0, posX, 0, posY)
		menuFrame.Visible = true
		overlay.Visible = true
		isOpen = true

		task.wait()
		local menuHeight = menuFrame.AbsoluteSize.Y
		local maxY = ViewportSize.Y - menuHeight - 10
		if posY > maxY then
			posY = math.max(10, position.Y - menuHeight - offsetY)
			menuFrame.Position = UDim2.new(0, posX, 0, posY)
		end
	end

	function ContextMenuManager.Close()
		if overlay then overlay.Visible = false end
		if menuFrame then menuFrame.Visible = false end
		isOpen = false
	end

	function ContextMenuManager.IsOpen()
		return isOpen
	end

	function ContextMenuManager.Init()
		if isInitialized then return end

		local MainUI = getMainUI()
		if not MainUI then
			warn("ContextMenuManager: MainUI not found")
			return
		end

		if ZolinModules.Mode ~= "Desktop" then
			print("ContextMenuManager: Skipping (not Desktop mode)")
			return
		end

		local desktopFolder = MainUI:FindFirstChild("__ZolinDesktop")
		if not desktopFolder then
			warn("ContextMenuManager: __ZolinDesktop not found")
			return
		end
		local desktopScreenFrame = desktopFolder:FindFirstChild("__ScreenFrame")
		if not desktopScreenFrame then
			warn("ContextMenuManager: desktop __ScreenFrame not found")
			return
		end

		-- ---- 1. Overlay ----
		overlay = Instance.new("Frame")
		overlay.Name = "ContextOverlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundTransparency = 1
		overlay.Visible = false
		overlay.ZIndex = 999
		overlay.Parent = desktopScreenFrame

		overlay.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or
				input.UserInputType == Enum.UserInputType.MouseButton2 then
				if menuFrame and menuFrame.Visible then
					local mousePos = game:GetService("UserInputService"):GetMouseLocation()
					local absPos = menuFrame.AbsolutePosition
					local absSize = menuFrame.AbsoluteSize
					local inside = mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
						mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y
					if not inside then
						ContextMenuManager.Close()
					end
				else
					ContextMenuManager.Close()
				end
			end
		end)

		-- ---- 2. Menu Frame (with UIListLayout and UIPadding) ----
		menuFrame = Instance.new("Frame")
		menuFrame.Name = "ContextMenu"
		menuFrame.Size = UDim2.new(0, 220, 0, 0)
		menuFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		menuFrame.BackgroundTransparency = 0
		menuFrame.BorderSizePixel = 0
		menuFrame.Visible = false
		menuFrame.ZIndex = 1000
		menuFrame.Parent = desktopScreenFrame

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 6)
		Corner.Parent = menuFrame

		local Stroke = Instance.new("UIStroke")
		Stroke.Color = Color3.fromRGB(60, 60, 70)
		Stroke.Thickness = 1
		Stroke.Parent = menuFrame

		-- UIListLayout (directly on menuFrame)
		local Layout = Instance.new("UIListLayout")
		Layout.FillDirection = Enum.FillDirection.Vertical
		Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		Layout.VerticalAlignment = Enum.VerticalAlignment.Top
		Layout.Padding = UDim.new(0, 2)
		Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Layout.Parent = menuFrame

		-- Left/right padding
		local Padding = Instance.new("UIPadding")
		Padding.PaddingLeft = UDim.new(0, 10)
		Padding.PaddingRight = UDim.new(0, 10)
		Padding.Parent = menuFrame

		-- ---- 3. Desktop right-click ----
		desktopScreenFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				if not isOpen then
					local mousePos = game:GetService("UserInputService"):GetMouseLocation()
					local defaultItems = {
						{ label = "Refresh", callback = function()
							print("Refreshing desktop...")
							local remotes = MainUI.__Zolin and MainUI.__Zolin:FindFirstChild("Remotes")
							if remotes then
								local evt = remotes:FindFirstChild("updateZolinLauncher")
								if evt then evt:Fire() end
							end
						end },
						{ isSeparator = true },
						{ label = "Personalize", callback = function()
							local modules = ZolinModules.GetAll_Desktop()
							if modules.AppManager then
								modules.AppManager.LaunchApplication("WallpaperSys")
							end
						end },
					}
					ContextMenuManager.Show(mousePos, defaultItems)
				end
			end
		end)

		-- ---- 4. ContextMenuEvent ----
		local ContextEvent = MainUI:FindFirstChild("__Zolin") and
			MainUI.__Zolin:FindFirstChild("Remotes") and
			MainUI.__Zolin.Remotes:FindFirstChild("ContextMenuEvent")
		if ContextEvent then
			ContextEvent.Event:Connect(function(source, appName, extra)
				if source == "taskbar" then
					local items = {
						{ label = "Restore", callback = function()
							local modules = ZolinModules.GetAll_Desktop()
							if modules.AppManager then
								modules.AppManager.ResumeApplication(appName)
							end
						end },
						{ label = "Minimize", callback = function()
							local modules = ZolinModules.GetAll_Desktop()
							if modules.AppManager then
								modules.AppManager.ExitApplication(appName)
							end
						end },
						{ isSeparator = true },
						{ label = "Close", callback = function()
							local modules = ZolinModules.GetAll_Desktop()
							if modules.AppManager then
								modules.AppManager.CloseApp(appName)
							end
						end },
					}
					local mousePos = game:GetService("UserInputService"):GetMouseLocation()
					ContextMenuManager.Show(mousePos, items)
				elseif source == "app" then
					local items = {
						{ label = "Open", callback = function()
							local modules = ZolinModules.GetAll_Desktop()
							if modules.AppManager then
								modules.AppManager.LaunchApplication(appName)
							end
						end },
					}
					local mousePos = game:GetService("UserInputService"):GetMouseLocation()
					ContextMenuManager.Show(mousePos, items)
				elseif source == "startmenu" then
					local items = {
						{ label = "Open", callback = function()
							local modules = ZolinModules.GetAll_Desktop()
							if modules.AppManager then
								modules.AppManager.LaunchApplication(appName)
							end
						end },
						{ isSeparator = true },
						{ label = "Close", callback = function()
							local modules = ZolinModules.GetAll_Desktop()
							if modules.AppManager then
								modules.AppManager.CloseApp(appName)
							end
						end },
					}
					local mousePos = game:GetService("UserInputService"):GetMouseLocation()
					ContextMenuManager.Show(mousePos, items)
				end
			end)
		end

		isInitialized = true
		print("ContextMenuManager initialized successfully!")
	end

	ZolinModules._contextMenuManagerInstance = ContextMenuManager
	return ContextMenuManager
end

-- ============================================
-- ZOLIN APPS
-- ============================================

--Settings Application
function ZolinModules.SettingsApp()
	local Settings = {}
	local TweenService = game:GetService("TweenService")
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	function Settings.Init(ui, launchArgs, appFolder)
		-- Get modules from ZolinModules
		local modules = nil;
		if ZolinModules.Mode == "Mobile" then
			modules = ZolinModules.GetAll()
		elseif ZolinModules.Mode == "Desktop" then
			modules = ZolinModules.GetAll_Desktop()
		end
		if not modules then warn("ZolinModules module not found/init") return end
		local SettingsManager = modules.SettingsManager
		local VolumeManager = modules.VolumeManager
		local PlatformManager = modules.PlatformManager
		local AppManager = modules.AppManager
		local PowerMenuManager = modules.PowerMenuManager

		-- UI References
		local settingsList = ui:WaitForChild("SettingsList")
		local closeButton = ui:FindFirstChild("CloseButton")

		-- Get references to Data folder for animations
		local MainUI = getMainUI()
		local dataFolder = MainUI and MainUI:FindFirstChild("__Zolin") and MainUI.__Zolin:FindFirstChild("Data")

		local animationUIValue = dataFolder and dataFolder:FindFirstChild("AnimationUI")
		local transitionSpeedValue = dataFolder and dataFolder:FindFirstChild("TransitionSpeed")

		-- Create default values if they don't exist
		if not animationUIValue then
			animationUIValue = Instance.new("BoolValue")
			animationUIValue.Name = "AnimationUI"
			animationUIValue.Value = true
			if dataFolder then animationUIValue.Parent = dataFolder end
		end

		if not transitionSpeedValue then
			transitionSpeedValue = Instance.new("NumberValue")
			transitionSpeedValue.Name = "TransitionSpeed"
			transitionSpeedValue.Value = 1
			if dataFolder then transitionSpeedValue.Parent = dataFolder end
		end

		-- ============================================
		-- USER INFO POPUP UI
		-- ============================================
		local userInfoPopup = nil
		local userInfoUpdateThread = nil
		local userInfoPopupActive = false

		local function createUserInfoPopup()
			if userInfoPopup then return end

			-- Create overlay background
			local overlay = Instance.new("Frame")
			overlay.Name = "UserInfoOverlay"
			overlay.Size = UDim2.new(1, 0, 1, 0)
			overlay.Position = UDim2.new(0, 0, 0, 0)
			overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			overlay.BackgroundTransparency = 0.5
			overlay.ZIndex = ui.ZIndex + 1
			overlay.Parent = ui.Parent

			-- Create popup frame
			local popup = Instance.new("Frame")
			popup.Name = "UserInfoPopup"
			popup.Size = UDim2.new(0, 400, 0, 500)
			popup.Position = UDim2.new(0.5, -200, 0.5, -250)
			popup.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
			popup.BorderSizePixel = 0
			popup.ZIndex = 6
			popup.Parent = overlay

			-- Add corner
			local popupCorner = Instance.new("UICorner")
			popupCorner.CornerRadius = UDim.new(0, 12)
			popupCorner.Parent = popup

			-- Add stroke
			local popupStroke = Instance.new("UIStroke")
			popupStroke.Thickness = 1
			popupStroke.Color = Color3.fromRGB(50, 50, 60)
			popupStroke.Parent = popup

			-- Title bar
			local titleBar = Instance.new("Frame")
			titleBar.Name = "TitleBar"
			titleBar.Size = UDim2.new(1, 0, 0, 50)
			titleBar.Position = UDim2.new(0, 0, 0, 0)
			titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
			titleBar.ZIndex = 6
			titleBar.Parent = popup

			local titleCorner = Instance.new("UICorner")
			titleCorner.CornerRadius = UDim.new(0, 12)
			titleCorner.Parent = titleBar

			-- Title label
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Size = UDim2.new(1, -50, 1, 0)
			titleLabel.Position = UDim2.new(0, 15, 0, 0)
			titleLabel.Text = "User Information"
			titleLabel.TextColor3 = Color3.new(1, 1, 1)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextSize = 20
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.ZIndex = 6
			titleLabel.Parent = titleBar

			-- Close button
			local closePopupButton = Instance.new("ImageButton")
			closePopupButton.Name = "ClosePopupButton"
			closePopupButton.Size = UDim2.new(0, 30, 0, 30)
			closePopupButton.Position = UDim2.new(1, -40, 0.5, -15)
			closePopupButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			closePopupButton.Image = "rbxassetid://4458805208"
			closePopupButton.ZIndex = 6
			closePopupButton.Parent = titleBar

			local closeCorner = Instance.new("UICorner")
			closeCorner.CornerRadius = UDim.new(1, 0)
			closeCorner.Parent = closePopupButton

			-- Content frame
			local contentFrame = Instance.new("ScrollingFrame")
			contentFrame.Name = "ContentFrame"
			contentFrame.Size = UDim2.new(1, -20, 1, -70)
			contentFrame.Position = UDim2.new(0, 10, 0, 60)
			contentFrame.BackgroundTransparency = 1
			contentFrame.ScrollBarThickness = 4
			contentFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
			contentFrame.ZIndex = 6
			contentFrame.Parent = popup

			local contentLayout = Instance.new("UIListLayout")
			contentLayout.Padding = UDim.new(0, 15)
			contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
			contentLayout.Parent = contentFrame

			-- Function to add info row
			local function addInfoRow(parent, label, value)
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 40)
				row.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
				row.BorderSizePixel = 0
				row.Parent = parent
				row.ZIndex = 6
				local rowCorner = Instance.new("UICorner")
				rowCorner.CornerRadius = UDim.new(0, 8)
				rowCorner.Parent = row

				local labelText = Instance.new("TextLabel")
				labelText.Size = UDim2.new(0.4, -10, 1, 0)
				labelText.Position = UDim2.new(0, 15, 0, 0)
				labelText.Text = label
				labelText.TextColor3 = Color3.fromRGB(150, 150, 150)
				labelText.BackgroundTransparency = 1
				labelText.Font = Enum.Font.Gotham
				labelText.TextSize = 14
				labelText.TextXAlignment = Enum.TextXAlignment.Left
				labelText.Parent = row
				labelText.ZIndex = 6

				local valueText = Instance.new("TextLabel")
				valueText.Size = UDim2.new(0.6, -10, 1, 0)
				valueText.Position = UDim2.new(0.4, 0, 0, 0)
				valueText.Text = tostring(value)
				valueText.TextColor3 = Color3.new(1, 1, 1)
				valueText.BackgroundTransparency = 1
				valueText.Font = Enum.Font.Gotham
				valueText.TextSize = 14
				valueText.TextXAlignment = Enum.TextXAlignment.Left
				valueText.Parent = row
				valueText.ZIndex = 6
			end

			-- Function to update user info
			local function updateUserInfoDisplay()
				local userInfo = SettingsManager.GetUserInfo()

				-- Clear existing rows
				for _, row in ipairs(contentFrame:GetChildren()) do
					if row:IsA("Frame") and row ~= contentLayout then
						row:Destroy()
					end
				end

				-- Profile section
				local profileSection = Instance.new("Frame")
				profileSection.Size = UDim2.new(1, 0, 0, 80)
				profileSection.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
				profileSection.BorderSizePixel = 0
				profileSection.Parent = contentFrame
				profileSection.ZIndex = 6
				local profileCorner = Instance.new("UICorner")
				profileCorner.CornerRadius = UDim.new(0, 12)
				profileCorner.Parent = profileSection

				-- Avatar icon placeholder
				local avatarIcon = Instance.new("Frame")
				avatarIcon.Size = UDim2.new(0, 50, 0, 50)
				avatarIcon.Position = UDim2.new(0, 15, 0.5, -25)
				avatarIcon.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
				avatarIcon.BorderSizePixel = 0
				avatarIcon.Parent = profileSection
				avatarIcon.ZIndex = 6
				local avatarCorner = Instance.new("UICorner")
				avatarCorner.CornerRadius = UDim.new(1, 0)
				avatarCorner.Parent = avatarIcon

				local avatarText = Instance.new("TextLabel")
				avatarText.Size = UDim2.new(1, 0, 1, 0)
				avatarText.Text = string.sub(userInfo.DisplayName, 1, 2):upper()
				avatarText.TextColor3 = Color3.new(1, 1, 1)
				avatarText.TextSize = 20
				avatarText.Font = Enum.Font.GothamBold
				avatarText.BackgroundTransparency = 1
				avatarText.Parent = avatarIcon
				avatarText.ZIndex = 6

				-- Name display
				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -80, 0, 25)
				nameLabel.Position = UDim2.new(0, 80, 0, 15)
				nameLabel.Text = userInfo.DisplayName
				nameLabel.TextColor3 = Color3.new(1, 1, 1)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextSize = 18
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Parent = profileSection
				nameLabel.ZIndex = 6

				local usernameLabel = Instance.new("TextLabel")
				usernameLabel.Size = UDim2.new(1, -80, 0, 20)
				usernameLabel.Position = UDim2.new(0, 80, 0, 42)
				usernameLabel.Text = "@" .. userInfo.UserName
				usernameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				usernameLabel.BackgroundTransparency = 1
				usernameLabel.Font = Enum.Font.Gotham
				usernameLabel.TextSize = 14
				usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
				usernameLabel.Parent = profileSection
				usernameLabel.ZIndex = 6

				-- Account Info
				addInfoRow(contentFrame, "User ID", userInfo.UserId)
				addInfoRow(contentFrame, "Account Age", userInfo.AccountAgeDays .. " days")
				addInfoRow(contentFrame, "Created", userInfo.AccountCreationDate)

				-- Separator
				local separator = Instance.new("Frame")
				separator.Size = UDim2.new(1, 0, 0, 1)
				separator.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
				separator.BorderSizePixel = 0
				separator.Parent = contentFrame
				separator.ZIndex = 6

				-- Humanoid Stats
				addInfoRow(contentFrame, "Health", string.format("%.0f / %.0f", userInfo.CurrentHealth, userInfo.MaxHealth))
				addInfoRow(contentFrame, "Walk Speed", string.format("%.1f", userInfo.WalkSpeed))
				addInfoRow(contentFrame, "Jump Power", string.format("%.0f", userInfo.JumpPower))

				-- Update canvas size
				task.wait()
				local totalHeight = contentLayout.AbsoluteContentSize.Y + 20
				contentFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
			end

			updateUserInfoDisplay()

			-- Close button function
			local function closeUserInfoPopup()
				if userInfoUpdateThread then
					task.cancel(userInfoUpdateThread)
					userInfoUpdateThread = nil
				end
				if userInfoPopup then
					userInfoPopup:Destroy()
					userInfoPopup = nil
				end
				userInfoPopupActive = false
			end

			closePopupButton.MouseButton1Click:Connect(closeUserInfoPopup)

			-- Click outside to close
			overlay.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local mousePos = game:GetService("UserInputService"):GetMouseLocation()
					local absPos = popup.AbsolutePosition
					local absSize = popup.AbsoluteSize
					local isInside = mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
						and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y
					if not isInside then
						closeUserInfoPopup()
					end
				end
			end)

			-- Animate popup in
			popup.BackgroundTransparency = 0
			popup.Position = UDim2.new(0.5, -200, 0.5, 250)
			local tween = TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, -200, 0.5, -250)
			})
			tween:Play()

			userInfoPopup = overlay
			userInfoPopupActive = true

			if userInfoUpdateThread then
				task.cancel(userInfoUpdateThread)
			end

			userInfoUpdateThread = task.spawn(function()
				while userInfoPopupActive and userInfoPopup and userInfoPopup.Parent do
					task.wait(1)
					if userInfoPopupActive then
						updateUserInfoDisplay()
					end
				end
			end)
		end

		-- ============================================
		-- DEFINE SETTINGS CATEGORIES
		-- ============================================
		local categories = {
			{
				name = "Personalization",
				items = {
					{name = "Change Wallpaper", type = "action", action = "wallpaper"},
					{name = "User Info", type = "info", key = "user", onClick = createUserInfoPopup},
					{name = "System Info", type = "info", key = "os"}
				}
			},
			{
				name = "Sounds",
				items = {
					{name = "Media", type = "slider", key = "Volume", min = 0, max = 1},
					{name = "Notifications", type = "slider", key = "NotificationVolume", min = 0, max = 1},
					{name = "Mute Media", type = "toggle", key = "Muted_Media"},
					{name = "Mute Notifications", type = "toggle", key = "Muted_Notifications"}
				}
			},
			{
				name = "System",
				items = {
					{name = "UI Animations", type = "toggle", settingName = "AnimationUI", valueRef = animationUIValue},
					{name = "Animation Speed", type = "animation_speed", settingName = "TransitionSpeed", valueRef = transitionSpeedValue, min = 0.25, max = 10},
					{name = "What's New (Changelogs)", type = "action", key = "changelogs"},
					{name = "Memory Display", type = "action", key = "memorydisplayApp"},
					{name = "Power Menu", type = "action", key = "power"},
				}
			}
		}

		-- Create category headers and items
		for _, category in ipairs(categories) do
			-- Category header
			local header = Instance.new("TextLabel")
			header.Size = UDim2.new(1, 0, 0, 30)
			header.Text = category.name
			header.TextColor3 = Color3.fromRGB(100, 200, 255)
			header.BackgroundTransparency = 1
			header.Font = Enum.Font.GothamBold
			header.TextSize = 18
			header.Parent = settingsList
			header.ZIndex = 6

			-- Category items
			for _, item in ipairs(category.items) do
				local itemFrame = Instance.new("Frame")
				itemFrame.Size = UDim2.new(1, -20, 0, 50)
				itemFrame.Position = UDim2.new(0, 10, 0, 0)
				itemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
				itemFrame.BorderSizePixel = 0
				itemFrame.Parent = settingsList
				itemFrame.ZIndex = 6

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(0.5, -10, 1, 0)
				nameLabel.Position = UDim2.new(0, 10, 0, 0)
				nameLabel.Text = item.name
				nameLabel.TextColor3 = Color3.new(1,1,1)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Parent = itemFrame
				nameLabel.ZIndex = 6

				if item.type == "toggle" then
					local toggle = Instance.new("TextButton")
					toggle.Size = UDim2.new(0, 60, 0, 30)
					toggle.Position = UDim2.new(1, -70, 0.5, -15)

					local currentValue
					if item.valueRef then
						currentValue = item.valueRef.Value
					else
						local settingValue = SettingsManager.GetSetting(item.key)
						currentValue = settingValue ~= nil and settingValue or false
					end

					toggle.Text = currentValue and "ON" or "OFF"
					toggle.BackgroundColor3 = currentValue and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
					toggle.Parent = itemFrame
					toggle.ZIndex = 7

					toggle.MouseButton1Click:Connect(function()
						local newValue
						if item.valueRef then
							newValue = not item.valueRef.Value
							item.valueRef.Value = newValue
						else
							newValue = not SettingsManager.GetSetting(item.key)
							SettingsManager.SetSetting(item.key, newValue)
						end

						toggle.Text = newValue and "ON" or "OFF"
						toggle.BackgroundColor3 = newValue and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)

						if item.key == "Muted_Media" then
							VolumeManager.SetMuted(newValue)
						elseif item.key == "Muted_Notifications" then
							VolumeManager.SetNotificationsMuted(newValue)
						end
					end)

				elseif item.type == "slider" then
					local valueLabel = Instance.new("TextLabel")
					valueLabel.Size = UDim2.new(0, 50, 1, 0)
					valueLabel.Position = UDim2.new(1, -60, 0, 0)
					local currentVal = SettingsManager.GetSetting(item.key) or item.min
					valueLabel.Text = string.format("%d%%", currentVal * 100)
					valueLabel.TextColor3 = Color3.new(1,1,1)
					valueLabel.BackgroundTransparency = 1
					valueLabel.Parent = itemFrame
					valueLabel.ZIndex = 6

					local minus = Instance.new("TextButton")
					minus.Size = UDim2.new(0, 30, 0, 30)
					minus.Position = UDim2.new(1, -120, 0.5, -15)
					minus.Text = "-"
					minus.Parent = itemFrame
					minus.ZIndex = 7

					local plus = Instance.new("TextButton")
					plus.Size = UDim2.new(0, 30, 0, 30)
					plus.Position = UDim2.new(1, -150, 0.5, -15)
					plus.Text = "+"
					plus.Parent = itemFrame
					plus.ZIndex = 7

					local updateSlider = function()
						local val = SettingsManager.GetSetting(item.key) or item.min
						valueLabel.Text = string.format("%d%%", val * 100)
						if item.key == "Volume" then
							if not VolumeManager then return end
							VolumeManager.SetVolume(val)
						elseif item.key == "NotificationVolume" then
							if not VolumeManager then return end
							VolumeManager.SetNotificationVolume(val)
						end
					end

					minus.MouseButton1Click:Connect(function()
						local newVal = math.max(item.min, (SettingsManager.GetSetting(item.key) or item.min) - 0.05)
						SettingsManager.SetSetting(item.key, newVal)
						updateSlider()
					end)

					plus.MouseButton1Click:Connect(function()
						local newVal = math.min(item.max, (SettingsManager.GetSetting(item.key) or item.min) + 0.05)
						SettingsManager.SetSetting(item.key, newVal)
						updateSlider()
					end)

				elseif item.type == "animation_speed" then
					local valueLabel = Instance.new("TextLabel")
					valueLabel.Size = UDim2.new(0, 50, 1, 0)
					valueLabel.Position = UDim2.new(1, -60, 0, 0)
					valueLabel.TextColor3 = Color3.new(1,1,1)
					valueLabel.BackgroundTransparency = 1
					valueLabel.Parent = itemFrame
					valueLabel.ZIndex = 6

					local currentSpeed = item.valueRef and item.valueRef.Value or 1
					valueLabel.Text = string.format("%.2fx", currentSpeed)

					local minus = Instance.new("TextButton")
					minus.Size = UDim2.new(0, 30, 0, 30)
					minus.Position = UDim2.new(1, -120, 0.5, -15)
					minus.Text = "-"
					minus.Parent = itemFrame
					minus.ZIndex = 7

					local plus = Instance.new("TextButton")
					plus.Size = UDim2.new(0, 30, 0, 30)
					plus.Position = UDim2.new(1, -150, 0.5, -15)
					plus.Text = "+"
					plus.Parent = itemFrame
					plus.ZIndex = 7

					local updateSpeedDisplay = function()
						local speed = item.valueRef and item.valueRef.Value or 1
						valueLabel.Text = string.format("%.2fx", speed)
					end

					minus.MouseButton1Click:Connect(function()
						if item.valueRef then
							local newSpeed = math.max(item.min, item.valueRef.Value - 0.25)
							item.valueRef.Value = newSpeed
							updateSpeedDisplay()
						end
					end)

					plus.MouseButton1Click:Connect(function()
						if item.valueRef then
							local newSpeed = math.min(item.max, item.valueRef.Value + 0.25)
							item.valueRef.Value = newSpeed
							updateSpeedDisplay()
						end
					end)

				elseif item.type == "info" then
					local infoLabel = Instance.new("TextLabel")
					infoLabel.Size = UDim2.new(0.5, -10, 1, 0)
					infoLabel.Position = UDim2.new(0.5, 0, 0, 0)
					infoLabel.Text = ""
					infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
					infoLabel.BackgroundTransparency = 1
					infoLabel.TextXAlignment = Enum.TextXAlignment.Right
					infoLabel.Parent = itemFrame
					infoLabel.ZIndex = 6

					if item.key == "user" then
						local userInfo = SettingsManager.GetUserInfo()
						infoLabel.Text = userInfo.DisplayName .. " (" .. userInfo.UserName .. ")"

						local clickButton = Instance.new("TextButton")
						clickButton.Size = UDim2.new(1, 0, 1, 0)
						clickButton.BackgroundTransparency = 1
						clickButton.Text = ""
						clickButton.Parent = itemFrame
						clickButton.ZIndex = 6

						clickButton.MouseButton1Click:Connect(function()
							createUserInfoPopup()
						end)

						clickButton.MouseEnter:Connect(function()
							itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
						end)
						clickButton.MouseLeave:Connect(function()
							itemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
						end)

					elseif item.key == "os" then
						local osInfo = SettingsManager.GetOSInfo()
						infoLabel.Text = osInfo.OSName .. " v" .. osInfo.Version
					end

				elseif item.type == "action" then
					local actionBtn = Instance.new("TextButton")
					actionBtn.Size = UDim2.new(0, 80, 0, 30)
					actionBtn.Position = UDim2.new(1, -90, 0.5, -15)
					actionBtn.Text = "Open"
					actionBtn.Parent = itemFrame
					actionBtn.ZIndex = 7

					if item.key == "power" then
						actionBtn.MouseButton1Click:Connect(function()
							if PowerMenuManager and PowerMenuManager.Toggle then
							PowerMenuManager.Toggle()
							else
								warn("PowerMenuManager.Toggle() is not a valid function")
							end
						end)
					end

					if item.action == "wallpaper" then
						actionBtn.MouseButton1Click:Connect(function()
							AppManager.HandleExit()
							AppManager.LaunchApplication("WallpaperSys")
						end)
					end
					
					if item.key == "changelogs" then
						actionBtn.MouseButton1Click:Connect(function()
							AppManager.HandleExit()
							AppManager.LaunchApplication("Changelogs")
						end)
					end
					if item.key == "memorydisplayApp" then
						actionBtn.MouseButton1Click:Connect(function()
							AppManager.HandleExit()
							AppManager.LaunchApplication("MemoryDisplay")
						end)
					end
				elseif item.type == "input" then
					local inputBox = Instance.new("TextBox")
					inputBox.Size = UDim2.new(0.4, -10, 0.7, 0)
					inputBox.Position = UDim2.new(0.6, 0, 0.15, 0)
					inputBox.Text = SettingsManager.GetSetting(item.key) or ""
					inputBox.PlaceholderText = "Enter device name"
					inputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
					inputBox.TextColor3 = Color3.new(1,1,1)
					inputBox.Parent = itemFrame
					inputBox.ZIndex = 7

					inputBox.FocusLost:Connect(function(enterPressed)
						if enterPressed and inputBox.Text ~= "" then
							SettingsManager.SetSetting(item.key, inputBox.Text)
						end
					end)
				end

				-- Add spacing
				local spacing = Instance.new("Frame")
				spacing.Size = UDim2.new(1, 0, 0, 5)
				spacing.BackgroundTransparency = 1
				spacing.Parent = settingsList
			end
		end

		-- Load initial values from VolumeManager
		local function loadInitialVolumeValues()
			if VolumeManager then
			local mediaVolume = VolumeManager.GetVolume()
			local notificationVolume = VolumeManager.GetNotificationVolume()
			local mediaMuted = VolumeManager.GetMuted()
			local notificationsMuted = VolumeManager.GetNotificationsMuted()
			SettingsManager.SetSetting("Volume", mediaVolume)
			SettingsManager.SetSetting("NotificationVolume", notificationVolume)
			SettingsManager.SetSetting("Muted_Media", mediaMuted)
			SettingsManager.SetSetting("Muted_Notifications", notificationsMuted)
			else
				warn("VolumeManager module not found. Cannot load initial volume values.")
			end
		end

		loadInitialVolumeValues()

		-- Close button
		if closeButton then
			closeButton.MouseButton1Click:Connect(function()
				AppManager.CloseApp("Settings")
			end)
		end

		ui.Visible = true
	end

	return Settings
end

-- ============================================
-- WALLPAPER SYSTEM APP
-- ============================================
function ZolinModules.WallpaperSysApp()
	local WallpaperSystem = {}
	local TweenService = game:GetService("TweenService")
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	-- References
	local MainUI = getMainUI()
	if not MainUI then
		warn("WallpaperSystem: MainUI not found")
		return WallpaperSystem
	end
	local __ScreenFrame = MainUI and MainUI:WaitForChild("__ScreenFrame")
	local WallpaperImage = __ScreenFrame and __ScreenFrame:FindFirstChild("Wallpaper")

	-- Settings storage
	local settingsFolder = MainUI and MainUI:FindFirstChild("SettingsData")
	if not settingsFolder and MainUI then
		settingsFolder = Instance.new("Folder")
		settingsFolder.Name = "SettingsData"
		settingsFolder.Parent = MainUI
	end

	local DEFAULT_WALLPAPERS = {
		{name = "Default", id = "rbxassetid://2387794684"},
		{name = "Nature lifegreen", id = "http://www.roblox.com/asset/?id=2340311201"},
		{name = "Art Background", id = "http://www.roblox.com/asset/?id=4026687450"},
		{name = "Galaxy", id = "http://www.roblox.com/asset/?id=601106736"},
		{name = "Dark Red", id = "http://www.roblox.com/asset/?id=2041062764"},
		{name = "Beach", id = "http://www.roblox.com/asset/?id=381428334"}
	}

	local currentSelectedWallpaper = nil
	local currentScaleMode = "Fit"
	local selectedScaleButton = nil
	local tempWallpaper = nil

	-- Helper functions
	local function getSavedWallpaper()
		local savedWallpaper = settingsFolder and settingsFolder:FindFirstChild("CurrentWallpaper")
		if savedWallpaper then
			return savedWallpaper.Value
		end
		return DEFAULT_WALLPAPERS[1].id
	end

	local function saveWallpaper(assetId)
		if not settingsFolder then return end
		local savedWallpaper = settingsFolder:FindFirstChild("CurrentWallpaper")
		if not savedWallpaper then
			savedWallpaper = Instance.new("StringValue")
			savedWallpaper.Name = "CurrentWallpaper"
			savedWallpaper.Parent = settingsFolder
		end
		savedWallpaper.Value = assetId
	end

	local function saveScaleMode(mode)
		if not settingsFolder then return end
		local savedMode = settingsFolder:FindFirstChild("WallpaperScaleMode")
		if not savedMode then
			savedMode = Instance.new("StringValue")
			savedMode.Name = "WallpaperScaleMode"
			savedMode.Parent = settingsFolder
		end
		savedMode.Value = mode
	end

	local function getSavedScaleMode()
		local savedMode = settingsFolder and settingsFolder:FindFirstChild("WallpaperScaleMode")
		if savedMode then
			return savedMode.Value
		end
		return "Fit"
	end

	local function getScaleTypeFromMode(mode)
		if mode == "Fit" then
			return Enum.ScaleType.Fit
		elseif mode == "Stretch" then
			return Enum.ScaleType.Stretch
		elseif mode == "Crop" then
			return Enum.ScaleType.Crop
		end
		return Enum.ScaleType.Fit
	end

	local function updateTempWallpaperPreview()
		if not tempWallpaper then return end
		local scaleType = getScaleTypeFromMode(currentScaleMode)
		tempWallpaper.ScaleType = scaleType
	end

	local function applyWallpaper(assetId)
		if not WallpaperImage then return false end

		local fadeOut = TweenService:Create(WallpaperImage, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 1
		})
		fadeOut:Play()
		fadeOut.Completed:Wait()
		WallpaperImage.Image = assetId
		WallpaperImage.ScaleType = getScaleTypeFromMode(currentScaleMode)

		local fadeIn = TweenService:Create(WallpaperImage, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			ImageTransparency = 0
		})
		fadeIn:Play()
		saveWallpaper(assetId)
		saveScaleMode(currentScaleMode)
		return true
	end

	local function createHighlightStroke()
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(34, 255, 255)
		stroke.Thickness = 3
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		return stroke
	end

	local function clearHighlight()
		local applyUI = WallpaperSystem.ui and WallpaperSystem.ui:FindFirstChild("ApplyWallpaperUI")
		if not applyUI then return end
		local settingFrame = applyUI:FindFirstChild("Setting")
		if not settingFrame then return end
		local buttons = {"Fit", "Stretch", "Crop"}
		for _, btnName in ipairs(buttons) do
			local button = settingFrame:FindFirstChild(btnName)
			if button then
				for _, stroke in ipairs(button:GetChildren()) do
					if stroke:IsA("UIStroke") then
						stroke:Destroy()
					end
				end
				button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			end
		end
	end

	local function highlightButton(button)
		clearHighlight()
		local stroke = createHighlightStroke()
		stroke.Parent = button
		button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	end

	local function loadWallpapers()
		local ui = WallpaperSystem.ui
		if not ui then 
			warn("UI not found. Cannot load wallpapers.")
			return 
		end
		local wallpaperList = ui:FindFirstChild("WallpaperList")
		if not wallpaperList then 
			warn("WallpaperList not found. Cannot load wallpapers.")
			return 
		end

		for _, child in ipairs(wallpaperList:GetChildren()) do
			if child:IsA("ImageButton") then
				child:Destroy()
			end
		end

		local allWallpapers = DEFAULT_WALLPAPERS
		local assetsFolder = WallpaperSystem.assets
		local template = assetsFolder and assetsFolder:FindFirstChild("WallpaperPickerTemplate")

		for _, wallpaper in ipairs(allWallpapers) do
			if template then
				local button = template:Clone()
				button.Name = wallpaper.name
				button.Parent = wallpaperList
				button.Visible = true
				button.Image = wallpaper.id

				local nameLabel = button:FindFirstChild("WallpaperNameLabel")
				if nameLabel then
					nameLabel.Text = wallpaper.name
				end

				button:SetAttribute("WallpaperId", wallpaper.id)
				button:SetAttribute("WallpaperName", wallpaper.name)

				button.MouseButton1Click:Connect(function()
					currentSelectedWallpaper = {
						name = wallpaper.name,
						id = wallpaper.id
					}
					local applyUI = ui:FindFirstChild("ApplyWallpaperUI")
					if applyUI then
						tempWallpaper = applyUI:FindFirstChild("TempWallpaper")
						if tempWallpaper then
							tempWallpaper.Image = wallpaper.id
							updateTempWallpaperPreview()
						end
						wallpaperList.Visible = false
						applyUI.Visible = true
					end
				end)
			end
		end
	end

	local function setupScaleButtons()
		local ui = WallpaperSystem.ui
		if not ui then 
			warn("setupScaleButtons: UI not found")
			return 
		end

		local applyUI = ui:FindFirstChild("ApplyWallpaperUI")
		if not applyUI then 
			warn("setupScaleButtons: ApplyWallpaperUI not found")
			return 
		end

		local settingFrame = applyUI:FindFirstChild("Setting")
		if not settingFrame then 
			warn("setupScaleButtons: Setting frame not found")
			return 
		end

		-- Load saved scale mode
		currentScaleMode = getSavedScaleMode()

		-- Setup Fit button
		local fitButton = settingFrame:FindFirstChild("Fit")
		if fitButton then
			-- Clear existing connections to prevent duplicates
			pcall(function() fitButton.MouseButton1Click:Disconnect() end)
			fitButton.MouseButton1Click:Connect(function()
				--print("Fit button clicked")
				currentScaleMode = "Fit"
				highlightButton(fitButton)
				selectedScaleButton = fitButton
				updateTempWallpaperPreview()
			end)
			if currentScaleMode == "Fit" then
				highlightButton(fitButton)
				selectedScaleButton = fitButton
			end
		else
			warn("Fit button not found")
		end

		-- Setup Stretch button
		local stretchButton = settingFrame:FindFirstChild("Stretch")
		if stretchButton then
			pcall(function() stretchButton.MouseButton1Click:Disconnect() end)
			stretchButton.MouseButton1Click:Connect(function()
				--print("Stretch button clicked")
				currentScaleMode = "Stretch"
				highlightButton(stretchButton)
				selectedScaleButton = stretchButton
				updateTempWallpaperPreview()
			end)
			if currentScaleMode == "Stretch" then
				highlightButton(stretchButton)
				selectedScaleButton = stretchButton
			end
		else
			warn("Stretch button not found")
		end

		-- Setup Crop button
		local cropButton = settingFrame:FindFirstChild("Crop")
		if cropButton then
			pcall(function() cropButton.MouseButton1Click:Disconnect() end)
			cropButton.MouseButton1Click:Connect(function()
				--print("Crop button clicked")
				currentScaleMode = "Crop"
				highlightButton(cropButton)
				selectedScaleButton = cropButton
				updateTempWallpaperPreview()
			end)
			if currentScaleMode == "Crop" then
				highlightButton(cropButton)
				selectedScaleButton = cropButton
			end
		else
			warn("Crop button not found")
		end

		-- Setup Submit button
		local submitButton = settingFrame:FindFirstChild("Submit")
		if submitButton then
			pcall(function() submitButton.MouseButton1Click:Disconnect() end)
			submitButton.MouseButton1Click:Connect(function()
				print("Submit button clicked")
				if currentSelectedWallpaper then
					applyWallpaper(currentSelectedWallpaper.id)
					local wallpaperList = ui:FindFirstChild("WallpaperList")
					local applyUI = ui:FindFirstChild("ApplyWallpaperUI")
					if wallpaperList and applyUI then
						applyUI.Visible = false
						wallpaperList.Visible = true
					end
					-- Get NotificationManager from ZolinModules
					local modules = ZolinModules.GetAll()
					local NotificationManager = modules.NotificationManager
					if NotificationManager and NotificationManager.ShowNotification then
						NotificationManager.ShowNotification({
							title = "Wallpaper Changed",
							description = currentSelectedWallpaper.name .. " applied successfully!"
						})
					end
				else
					print("No wallpaper selected")
				end
			end)
		else
			warn("Submit button not found")
		end
	end

	function WallpaperSystem.Init(ui, launchArgs, appFolder)
		WallpaperSystem.ui = ui

		-- Get assets folder from the same parent as the UI (ReplicatedWindowSys)
		local replicatedWindowSys = ui and ui.Parent;
		if replicatedWindowSys then
			WallpaperSystem.assets = replicatedWindowSys:FindFirstChild("Assets")
		end

		if not WallpaperSystem.assets then
			warn("WallpaperSystem: Assets folder not found")
			return
		end

		local wallpaperList = ui:FindFirstChild("WallpaperList")
		local applyUI = ui:FindFirstChild("ApplyWallpaperUI")

		if wallpaperList then
			wallpaperList.Visible = true
		end
		if applyUI then
			applyUI.Visible = false
			tempWallpaper = applyUI:FindFirstChild("TempWallpaper")
		end

		loadWallpapers()
		setupScaleButtons()

		-- Setup back button
		if applyUI then
			local backButton = applyUI:FindFirstChild("BackButton")
			if backButton then
				pcall(function() backButton.MouseButton1Click:Disconnect() end)
				backButton.MouseButton1Click:Connect(function()
					local wallpaperList = ui:FindFirstChild("WallpaperList")
					local applyUI = ui:FindFirstChild("ApplyWallpaperUI")
					if applyUI and applyUI.Visible then
						applyUI.Visible = false
						if wallpaperList then
							wallpaperList.Visible = true
						end
					end
				end)
			end
		end

		ui.Visible = true
		print("WallpaperSystem initialized")
	end

	function WallpaperSystem.RefreshWallpapers()
		loadWallpapers()
	end

	function WallpaperSystem.GetCurrentWallpaper()
		return getSavedWallpaper()
	end

	function WallpaperSystem.GetCurrentScaleMode()
		return getSavedScaleMode()
	end

	return WallpaperSystem
end

-- ============================================
-- ZOLIN INSTALLER
-- ============================================
function ZolinModules.ZolinInstaller()
	local Installer = {}
	local TweenService = game:GetService("TweenService")

	function Installer.Init(ui, launchArgs, appFolder)
		local modules = ZolinModules.GetAll()
		local NotificationManager = modules.NotificationManager
		local AppManager = modules.AppManager

		-- Install UI elements
		local urlBar = ui:WaitForChild("URLBar")
		local installButton = ui:WaitForChild("InstallButton")
		local confirmationPopup = ui:WaitForChild("ConfirmationPopup")
		local yesButton = confirmationPopup and confirmationPopup:WaitForChild("Yes")
		local cancelButton = confirmationPopup and confirmationPopup:WaitForChild("Cancel")

		-- ===== UNINSTALL UI =====
		local uninstallButton = ui:FindFirstChild("UninstallButton")
		if not uninstallButton then
			uninstallButton = Instance.new("TextButton")
			uninstallButton.Name = "UninstallButton"
			uninstallButton.AnchorPoint = Vector2.new(0.5, 0.5)
			uninstallButton.Position = UDim2.new(0.5, 0, 0.63, 0)
			uninstallButton.Size = UDim2.new(0.4, 0, 0.08, 0)
			uninstallButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			uninstallButton.BackgroundTransparency = 0.2
			uninstallButton.Text = "Uninstall App"
			uninstallButton.TextColor3 = Color3.new(1, 1, 1)
			uninstallButton.Font = Enum.Font.GothamBold
			uninstallButton.TextSize = 16
			uninstallButton.ZIndex = ui.ZIndex + 1
			uninstallButton.Parent = ui

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = uninstallButton
		end

		-- Uninstall overlay (full screen app list)
		local uninstallOverlay = Instance.new("Frame")
		uninstallOverlay.Name = "UninstallOverlay"
		uninstallOverlay.Size = UDim2.new(1, 0, 1, 0)
		uninstallOverlay.Position = UDim2.new(0, 0, 0, 0)
		uninstallOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		uninstallOverlay.BackgroundTransparency = 1
		uninstallOverlay.ZIndex = ui.ZIndex + 10
		uninstallOverlay.Visible = false
		uninstallOverlay.Parent = ui

		local overlayBackground = Instance.new("Frame")
		overlayBackground.Name = "Background"
		overlayBackground.Size = UDim2.new(1, 0, 1, 0)
		overlayBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlayBackground.BackgroundTransparency = 0.5
		overlayBackground.ZIndex = uninstallOverlay.ZIndex
		overlayBackground.Parent = uninstallOverlay

		-- Title bar
		local titleBar = Instance.new("Frame")
		titleBar.Name = "TitleBar"
		titleBar.Size = UDim2.new(1, -20, 0, 40)
		titleBar.Position = UDim2.new(0, 10, 0, 10)
		titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		titleBar.BackgroundTransparency = 0
		titleBar.ZIndex = uninstallOverlay.ZIndex + 1
		titleBar.Parent = uninstallOverlay

		local titleCorner = Instance.new("UICorner")
		titleCorner.CornerRadius = UDim.new(0, 10)
		titleCorner.Parent = titleBar

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -50, 1, 0)
		titleLabel.Position = UDim2.new(0, 15, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "Installed Apps"
		titleLabel.TextColor3 = Color3.new(1, 1, 1)
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 20
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = uninstallOverlay.ZIndex + 1
		titleLabel.Parent = titleBar

		-- Close button for overlay
		local closeOverlayBtn = Instance.new("ImageButton")
		closeOverlayBtn.Name = "CloseButton"
		closeOverlayBtn.Size = UDim2.new(0, 30, 0, 30)
		closeOverlayBtn.Position = UDim2.new(1, -40, 0.5, -15)
		closeOverlayBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		closeOverlayBtn.Image = "rbxassetid://4458805208"
		closeOverlayBtn.ZIndex = uninstallOverlay.ZIndex + 1
		closeOverlayBtn.Parent = titleBar

		local closeCorner = Instance.new("UICorner")
		closeCorner.CornerRadius = UDim.new(1, 0)
		closeCorner.Parent = closeOverlayBtn

		-- ScrollingFrame for app list
		local appList = Instance.new("ScrollingFrame")
		appList.Name = "AppList"
		appList.Size = UDim2.new(1, -20, 1, -70)
		appList.Position = UDim2.new(0, 10, 0, 60)
		appList.BackgroundTransparency = 1
		appList.CanvasSize = UDim2.new(0, 0, 0, 0)
		appList.ScrollBarThickness = 6
		appList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
		appList.ZIndex = uninstallOverlay.ZIndex + 1
		appList.AutomaticCanvasSize = Enum.AutomaticSize.Y
		appList.Parent = uninstallOverlay

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 8)
		listLayout.SortOrder = Enum.SortOrder.Name
		listLayout.Parent = appList

		-- ===== UNINSTALL CONFIRMATION POPUP =====
		local uninstallConfirmPopup = Instance.new("Frame")
		uninstallConfirmPopup.Name = "UninstallConfirmPopup"
		uninstallConfirmPopup.AnchorPoint = Vector2.new(0.5, 0.5)
		uninstallConfirmPopup.Position = UDim2.new(0.5, 0, 1.5, 0)
		uninstallConfirmPopup.Size = UDim2.new(0.5, 0, 0.3, 0)
		uninstallConfirmPopup.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		uninstallConfirmPopup.BackgroundTransparency = 0
		uninstallConfirmPopup.ZIndex = uninstallOverlay.ZIndex + 5
		uninstallConfirmPopup.Visible = false
		uninstallConfirmPopup.Parent = ui

		local confirmCorner = Instance.new("UICorner")
		confirmCorner.CornerRadius = UDim.new(0, 12)
		confirmCorner.Parent = uninstallConfirmPopup

		local confirmText = Instance.new("TextLabel")
		confirmText.Name = "ConfirmText"
		confirmText.AnchorPoint = Vector2.new(0.5, 0.5)
		confirmText.Position = UDim2.new(0.5, 0, 0.3, 0)
		confirmText.Size = UDim2.new(0.9, 0, 0.3, 0)
		confirmText.BackgroundTransparency = 1
		confirmText.Text = "Are you sure you want to uninstall this app?"
		confirmText.TextColor3 = Color3.new(1, 1, 1)
		confirmText.Font = Enum.Font.GothamBold
		confirmText.TextSize = 16
		confirmText.TextWrapped = true
		confirmText.TextXAlignment = Enum.TextXAlignment.Center
		confirmText.ZIndex = uninstallConfirmPopup.ZIndex + 1
		confirmText.Parent = uninstallConfirmPopup

		local confirmYes = Instance.new("TextButton")
		confirmYes.Name = "ConfirmYes"
		confirmYes.AnchorPoint = Vector2.new(0.5, 0.5)
		confirmYes.Position = UDim2.new(0.35, 0, 0.7, 0)
		confirmYes.Size = UDim2.new(0.25, 0, 0.15, 0)
		confirmYes.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
		confirmYes.Text = "Uninstall"
		confirmYes.TextColor3 = Color3.new(1, 1, 1)
		confirmYes.Font = Enum.Font.GothamBold
		confirmYes.TextSize = 14
		confirmYes.ZIndex = uninstallConfirmPopup.ZIndex + 1
		confirmYes.Parent = uninstallConfirmPopup

		local confirmYesCorner = Instance.new("UICorner")
		confirmYesCorner.CornerRadius = UDim.new(0, 6)
		confirmYesCorner.Parent = confirmYes

		local confirmCancel = Instance.new("TextButton")
		confirmCancel.Name = "ConfirmCancel"
		confirmCancel.AnchorPoint = Vector2.new(0.5, 0.5)
		confirmCancel.Position = UDim2.new(0.65, 0, 0.7, 0)
		confirmCancel.Size = UDim2.new(0.25, 0, 0.15, 0)
		confirmCancel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		confirmCancel.Text = "Cancel"
		confirmCancel.TextColor3 = Color3.new(1, 1, 1)
		confirmCancel.Font = Enum.Font.GothamBold
		confirmCancel.TextSize = 14
		confirmCancel.ZIndex = uninstallConfirmPopup.ZIndex + 1
		confirmCancel.Parent = uninstallConfirmPopup

		local confirmCancelCorner = Instance.new("UICorner")
		confirmCancelCorner.CornerRadius = UDim.new(0, 6)
		confirmCancelCorner.Parent = confirmCancel

		-- Variables to store pending uninstall data
		local pendingUninstall = {
			appName = nil,
			entry = nil,
			appFrame = nil,
			appDataEntry = nil,
			isRunning = false
		}

		local function showUninstallConfirm()
			uninstallConfirmPopup.Visible = true
			TweenService:Create(uninstallConfirmPopup, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}):Play()
		end

		local function hideUninstallConfirm()
			local tween = TweenService:Create(uninstallConfirmPopup, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 1.5, 0)
			})
			tween:Play()
			tween.Completed:Connect(function()
				uninstallConfirmPopup.Visible = false
			end)
		end

		confirmCancel.MouseButton1Click:Connect(hideUninstallConfirm)

		confirmYes.MouseButton1Click:Connect(function()
			hideUninstallConfirm()
			local data = pendingUninstall
			if not data.appName then return end

			local mainUI = getMainUI()
			local zolin = mainUI and mainUI:FindFirstChild("__Zolin")

			-- Remove from __AppsLaunchArgFolder
			if data.entry and data.entry.Parent then data.entry:Destroy() end
			-- Remove from ReplicatedWindow
			if data.appFrame and data.appFrame.Parent then data.appFrame:Destroy() end
			-- Remove from AppData
			if data.appDataEntry and data.appDataEntry.Parent then data.appDataEntry:Destroy() end

			-- Remove from Applications (if currently running)
			local applications = mainUI.__ScreenFrame and mainUI.__ScreenFrame:FindFirstChild("Applications")
			if applications then
				local runningApp = applications:FindFirstChild(data.appName)
				if runningApp then runningApp:Destroy() end
			end

			-- Refresh home screen
			local remotes = zolin and zolin:FindFirstChild("Remotes")
			local refreshEvent = remotes and remotes:FindFirstChild("updateZolinLauncher")
			if refreshEvent then
				refreshEvent:Fire()
			end

			NotificationManager.ShowNotification({
				title = "Uninstaller",
				description = data.appName .. " has been uninstalled."
			})
			
			-- Clear pending data
			pendingUninstall = { appName = nil, entry = nil, appFrame = nil, appDataEntry = nil, isRunning = false }

			-- Refresh the uninstall list
			Installer.refreshUninstallList()
		end)

		-- ===== FUNCTION: Perform actual uninstall =====
		local function doUninstall(appName, entry, appFrame, appDataEntry)
			pendingUninstall.appName = appName
			pendingUninstall.entry = entry
			pendingUninstall.appFrame = appFrame
			pendingUninstall.appDataEntry = appDataEntry

			-- Check if app is currently running
			local mainUI = getMainUI()
			local applications = mainUI.__ScreenFrame and mainUI.__ScreenFrame:FindFirstChild("Applications")
			local isRunning = applications and applications:FindFirstChild(appName) ~= nil
			pendingUninstall.isRunning = isRunning

			if isRunning then
				-- Show extra warning
				confirmText.Text = "⚠️ This app is currently running!\n\nPlease close the app before uninstalling, or the uninstall may fail.\n\nAre you sure you want to continue?"
			else
				confirmText.Text = "Are you sure you want to uninstall \"" .. appName .. "\"?"
			end

			showUninstallConfirm()
		end

		-- ===== FUNCTION: Populate the uninstall list =====
		function Installer.refreshUninstallList()
			-- Clear existing list
			for _, child in ipairs(appList:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end

			local mainUI = getMainUI()
			local zolin = mainUI and mainUI:FindFirstChild("__Zolin")
			local appsFolder = zolin and zolin:FindFirstChild("__AppsLaunchArgFolder")
			local replicatedWindow = mainUI and mainUI:FindFirstChild("ReplicatedWindow")
			local appData = mainUI and mainUI:FindFirstChild("AppData")

			if not appsFolder then
				local noApps = Instance.new("TextLabel")
				noApps.Size = UDim2.new(1, 0, 0, 40)
				noApps.BackgroundTransparency = 1
				noApps.Text = "No installed apps found."
				noApps.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				noApps.Font = Enum.Font.Gotham
				noApps.TextSize = 16
				noApps.Parent = appList
				return
			end

			local hasApps = false
			for _, entry in ipairs(appsFolder:GetChildren()) do
				if entry:IsA("StringValue") and entry.Value ~= "" then
					local appName = entry.Name
					local appUrl = entry.Value

					local appFrame = replicatedWindow and replicatedWindow:FindFirstChild(appName)
					local appDataEntry = appData and appData:FindFirstChild(appName)

					if appFrame or appDataEntry then
						hasApps = true
						-- Check if running
						local applications = mainUI.__ScreenFrame and mainUI.__ScreenFrame:FindFirstChild("Applications")
						local isRunning = applications and applications:FindFirstChild(appName) ~= nil

						local row = Instance.new("Frame")
						row.Size = UDim2.new(1, -10, 0, 70)
						row.BackgroundColor3 = isRunning and Color3.fromRGB(60, 40, 40) or Color3.fromRGB(35, 35, 45)
						row.BorderSizePixel = 0
						row.Parent = appList
						row.ZIndex = uninstallOverlay.ZIndex + 1

						local rowCorner = Instance.new("UICorner")
						rowCorner.CornerRadius = UDim.new(0, 10)
						rowCorner.Parent = row

						-- Running indicator
						if isRunning then
							local runningIndicator = Instance.new("Frame")
							runningIndicator.Size = UDim2.new(0, 8, 0, 8)
							runningIndicator.Position = UDim2.new(0, 5, 0, 5)
							runningIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
							runningIndicator.BorderSizePixel = 0
							runningIndicator.ZIndex = uninstallOverlay.ZIndex + 3
							runningIndicator.Parent = row

							local indicatorCorner = Instance.new("UICorner")
							indicatorCorner.CornerRadius = UDim.new(1, 0)
							indicatorCorner.Parent = runningIndicator
						end

						-- App icon
						local appIcon = Instance.new("ImageLabel")
						appIcon.Size = UDim2.new(0, 40, 0, 40)
						appIcon.Position = UDim2.new(0, 15, 0.5, -20)
						appIcon.BackgroundTransparency = 1
						appIcon.ZIndex = uninstallOverlay.ZIndex + 2
						appIcon.Parent = row

						if appFrame then
							local preview = appFrame:FindFirstChild("PreviewAppInfoZL")
							if preview then
								local icon = preview:FindFirstChildOfClass("ImageLabel")
								if icon then appIcon.Image = icon.Image end
							end
						end

						-- App name
						local nameLabel = Instance.new("TextLabel")
						nameLabel.Size = UDim2.new(0.4, -65, 0, 25)
						nameLabel.Position = UDim2.new(0, 65, 0, 8)
						nameLabel.BackgroundTransparency = 1
						nameLabel.Text = appName .. (isRunning and " (Running)" or "")
						nameLabel.TextColor3 = isRunning and Color3.new(0, 255, 0) or Color3.new(1, 1, 1)
						nameLabel.Font = Enum.Font.GothamBold
						nameLabel.TextSize = 16
						nameLabel.TextXAlignment = Enum.TextXAlignment.Left
						nameLabel.ZIndex = uninstallOverlay.ZIndex + 2
						nameLabel.Parent = row

						-- Version
						local version = "Unknown"
						if appFrame then
							local data = appFrame:FindFirstChild("Data")
							if data then
								local verVal = data:FindFirstChild("Version")
								if verVal then version = verVal.Value end
							end
						end

						local versionLabel = Instance.new("TextLabel")
						versionLabel.Size = UDim2.new(0.4, -65, 0, 20)
						versionLabel.Position = UDim2.new(0, 65, 0, 35)
						versionLabel.BackgroundTransparency = 1
						versionLabel.Text = "v" .. version
						versionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
						versionLabel.Font = Enum.Font.Gotham
						versionLabel.TextSize = 12
						versionLabel.TextXAlignment = Enum.TextXAlignment.Left
						versionLabel.ZIndex = uninstallOverlay.ZIndex + 2
						versionLabel.Parent = row

						-- URL (truncated)
						local urlDisplay = #appUrl > 50 and string.sub(appUrl, 1, 47) .. "..." or appUrl
						local urlLabel = Instance.new("TextLabel")
						urlLabel.Size = UDim2.new(0.6, -10, 0, 15)
						urlLabel.Position = UDim2.new(0, 65, 0, 55)
						urlLabel.BackgroundTransparency = 1
						urlLabel.Text = urlDisplay
						urlLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
						urlLabel.Font = Enum.Font.Gotham
						urlLabel.TextSize = 10
						urlLabel.TextXAlignment = Enum.TextXAlignment.Left
						urlLabel.ZIndex = uninstallOverlay.ZIndex + 2
						urlLabel.Parent = row

						-- Uninstall button
						local uninstallAppBtn = Instance.new("TextButton")
						uninstallAppBtn.Size = UDim2.new(0, 80, 0, 30)
						uninstallAppBtn.Position = UDim2.new(1, -90, 0.5, -15)
						uninstallAppBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
						uninstallAppBtn.Text = "Uninstall"
						uninstallAppBtn.TextColor3 = Color3.new(1, 1, 1)
						uninstallAppBtn.Font = Enum.Font.GothamBold
						uninstallAppBtn.TextSize = 14
						uninstallAppBtn.ZIndex = uninstallOverlay.ZIndex + 2
						uninstallAppBtn.Parent = row

						local btnCorner = Instance.new("UICorner")
						btnCorner.CornerRadius = UDim.new(0, 6)
						btnCorner.Parent = uninstallAppBtn

						uninstallAppBtn.MouseButton1Click:Connect(function()
							doUninstall(appName, entry, appFrame, appDataEntry)
						end)
					end
				end
			end

			if not hasApps then
				local noApps = Instance.new("TextLabel")
				noApps.Size = UDim2.new(1, 0, 0, 40)
				noApps.BackgroundTransparency = 1
				noApps.Text = "No installed apps found."
				noApps.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				noApps.Font = Enum.Font.Gotham
				noApps.TextSize = 16
				noApps.Parent = appList
			end
		end

		-- ===== Show/Hide overlay =====
		local function showUninstallOverlay()
			Installer.refreshUninstallList()
			uninstallOverlay.Visible = true
			TweenService:Create(uninstallOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.5
			}):Play()
		end

		local function hideUninstallOverlay()
			local tween = TweenService:Create(uninstallOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1
			})
			tween:Play()
			tween.Completed:Connect(function()
				uninstallOverlay.Visible = false
			end)
		end

		uninstallButton.MouseButton1Click:Connect(showUninstallOverlay)
		closeOverlayBtn.MouseButton1Click:Connect(hideUninstallOverlay)
		overlayBackground.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				hideUninstallOverlay()
			end
		end)

		-- ===== INSTALL LOGIC (No app name needed - extracted from URL or user) =====
		if confirmationPopup then
			confirmationPopup.Visible = false
		end

		-- Update confirmation text for install
		local confirmTextInstall = confirmationPopup and confirmationPopup:FindFirstChild("ConfirmText")
		if confirmTextInstall then
			confirmTextInstall.Text = "Are you sure you want to install this app?"
		end

		local function showPopup()
			if not confirmationPopup then return end
			confirmationPopup.Visible = true
			TweenService:Create(confirmationPopup, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}):Play()
		end

		local function hidePopup()
			if not confirmationPopup then return end
			local tween = TweenService:Create(confirmationPopup, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 1.5, 0)
			})
			tween:Play()
			tween.Completed:Connect(function()
				confirmationPopup.Visible = false
			end)
		end

		installButton.MouseButton1Click:Connect(function()
			local url = urlBar.Text
			if url == "" then
				NotificationManager.ShowNotification({
					title = "Installer",
					description = "Please enter a loadstring URL."
				})
				return
			end
			showPopup()
		end)

		if cancelButton then
			cancelButton.MouseButton1Click:Connect(hidePopup)
		end

		if yesButton then
			yesButton.MouseButton1Click:Connect(function()
				hidePopup()
				local url = urlBar.Text

				local mainUI = getMainUI()
				local zolin = mainUI:FindFirstChild("__Zolin")
				if not zolin then warn("__Zolin not found"); return end

				local appsFolder = zolin:FindFirstChild("__AppsLaunchArgFolder")
				if not appsFolder then
					appsFolder = Instance.new("Folder")
					appsFolder.Name = "__AppsLaunchArgFolder"
					appsFolder.Parent = zolin
				end

				local success, result = pcall(function()
					local code = game:HttpGet(url)
					local fn, compileError = loadstring(code)
					if not fn then error("Compilation error: " .. tostring(compileError)) end

					-- Extract app name from the loadstring (heuristic: look for "app.Name = "xxx"")
					local appName = nil
					-- Try to find the app name from the code
					for name in string.gmatch(code, 'app%.Name%s*=%s*"([^"]+)"') do
						appName = name
						break
					end
					if not appName then
						for name in string.gmatch(code, '%.Name%s*=%s*"([^"]+)"') do
							appName = name
							break
						end
					end
					if not appName then
						-- Fallback: use a timestamp-based name
						appName = "App_" .. os.time()
					end

					-- Store the app entry
					local appEntry = appsFolder:FindFirstChild(appName)
					if not appEntry then
						appEntry = Instance.new("StringValue")
						appEntry.Name = appName
						appEntry.Parent = appsFolder
					end
					appEntry.Value = url

					-- Execute the loadstring
					fn()
					return appName
				end)

				if success then
					local remotes = zolin:FindFirstChild("Remotes")
					local refreshEvent = remotes and remotes:FindFirstChild("updateZolinLauncher")
					if refreshEvent then refreshEvent:Fire() end
					NotificationManager.ShowNotification({
						title = "Installer",
						description = (result or "App") .. " installed successfully!"
					})
					urlBar.Text = ""
				else
					NotificationManager.ShowNotification({
						title = "Installer Error",
						description = "Installation failed: " .. tostring(result)
					})
				end
			end)
		end

		urlBar.FocusLost:Connect(function(enterPressed)
			if enterPressed and urlBar.Text ~= "" then
				showPopup()
			end
		end)

		ui.Visible = true
		print("ZolinInstaller initialized (with Uninstall confirmation)")
	end
	-- ============================================
	-- NEW: AUTO-INSTALL FOLDER PROCESSING
	-- ============================================
	function Installer.processAutoInstallFolder()
		print("Starting auto-install from folder...");
		local mainUI = getMainUI()
		if not mainUI then return end
		local zolin = mainUI:FindFirstChild("__Zolin")
		if not zolin then return end

		-- Ensure the ZolinInstaller folder exists
		local zero = zolin:FindFirstChild("0");
		if not zero then return end;
		local installerFolder = zero:FindFirstChild("ZolinInstaller")
		if not installerFolder then
			installerFolder = Instance.new("Folder")
			installerFolder.Name = "ZolinInstaller"
			installerFolder.Parent = zero
		end

		local autoFolder = installerFolder:FindFirstChild("__autoInstallOnInit")
		if not autoFolder then
			autoFolder = Instance.new("Folder")
			autoFolder.Name = "__autoInstallOnInit"
			autoFolder.Parent = installerFolder
		end

		-- We'll collect entries first (in case destroying during iteration)
		local entries = {}
		for _, child in ipairs(autoFolder:GetChildren()) do
			if child:IsA("StringValue") and child.Value ~= "" then
				table.insert(entries, {name = child.Name, url = child.Value, object = child})
			end
		end

		if #entries == 0 then return end

		local appsFolder = zolin:FindFirstChild("__AppsLaunchArgFolder")
		if not appsFolder then
			appsFolder = Instance.new("Folder")
			appsFolder.Name = "__AppsLaunchArgFolder"
			appsFolder.Parent = zolin
		end

		local anythingInstalled = false

		for _, entry in ipairs(entries) do
			local appName = entry.name
			local url = entry.url
			local stringObj = entry.object

			-- Skip if already installed
			if (appsFolder:FindFirstChild(appName) and mainUI.ReplicatedWindow:FindFirstChild(appName)) or (appsFolder:FindFirstChild(appName) and mainUI.ReplicatedWindow_Sys:FindFirstChild(appName)) then
				-- Already installed; remove the auto-install entry to avoid re-processing
				stringObj:Destroy()
				continue
			end

			local success, result = pcall(function()
				local code = game:HttpGet(url)
				local fn, compileError = loadstring(code)
				if not fn then error("Compilation error: " .. tostring(compileError)) end
				-- The loadstring should create the app frame inside ReplicatedWindow or ReplicatedWindow_Sys
				fn()
				-- Register in __AppsLaunchArgFolder
				local appEntry = appsFolder:FindFirstChild(appName)
				if not appEntry then
					appEntry = Instance.new("StringValue")
					appEntry.Name = appName
					appEntry.Parent = appsFolder
				end
				appEntry.Value = url
				return true
			end)
			if success then
				anythingInstalled = true
				stringObj:Destroy()
				print("installed:", appName .." | SYSTEM PRELOAD INSTALLTION")
			else
				warn("Auto-install failed for", appName, result)
				stringObj:Destroy()
			end
		end

		if anythingInstalled then
			local remotes = zolin:FindFirstChild("Remotes")
			local refreshEvent = remotes and remotes:FindFirstChild("updateZolinLauncher")
			if refreshEvent then
				refreshEvent:Fire()
			end
		end
	end

	-- AUTO INSTALL
	Installer.processAutoInstallFolder();
	return Installer
end

-- ============================================
-- MEMORY DISPLAY APP (System Monitor + Graph)
-- ============================================
function ZolinModules.MemoryDisplayApp()
	local MemoryApp = {}
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local Stats = game:GetService("Stats")

	-- Graph settings
	local MAX_POINTS = 60           -- Show last 60 seconds (1 per second)
	local GRAPH_HEIGHT = 120        -- Pixels
	local BAR_WIDTH = 6
	local BAR_SPACING = 2
	local history = {}              -- Stores percentage values (0-100)

	-- Helper: get used/total memory in MB
	local function getMemoryStats()
		local mem = Stats:FindFirstChild("Memory")
		if mem then
			local used = mem:FindFirstChild("Used") and mem.Used.Value or 0
			local total = mem:FindFirstChild("Total") and mem.Total.Value or 1000
			return used / 1024 / 1024, total / 1024 / 1024
		end
		-- Fallback (simulate real usage for demo)
		return math.random(200, 800), 1024
	end

	-- Helper: format uptime
	local function getUptime()
		return ZolinModules.CurrentUptime or "00:00:00"
	end

	function MemoryApp.Init(ui, launchArgs, appFolder)
		local modules = ZolinModules.GetAll()
		local AppManager = modules.AppManager

		-- === Main container ===
		local mainFrame = Instance.new("Frame")
		mainFrame.Name = "MemoryDisplay"
		mainFrame.Size = UDim2.new(1, 0, 1, 0)
		mainFrame.BackgroundTransparency = 1
		mainFrame.Parent = 	ui

		-- === Title ===
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 40)
		title.Position = UDim2.new(0, 0, 0, 10)
		title.Text = "System Memory"
		title.TextColor3 = Color3.new(1,1,1)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 24
		title.BackgroundTransparency = 1
		title.Parent = mainFrame

		-- === Info labels ===
		local usedLabel = Instance.new("TextLabel")
		usedLabel.Size = UDim2.new(1, 0, 0, 30)
		usedLabel.Position = UDim2.new(0, 0, 0, 55)
		usedLabel.Text = "Used: 0 MB"
		usedLabel.TextColor3 = Color3.fromRGB(200,200,200)
		usedLabel.Font = Enum.Font.Gotham
		usedLabel.TextSize = 18
		usedLabel.BackgroundTransparency = 1
		usedLabel.Parent = mainFrame

		local totalLabel = Instance.new("TextLabel")
		totalLabel.Size = UDim2.new(1, 0, 0, 30)
		totalLabel.Position = UDim2.new(0, 0, 0, 85)
		totalLabel.Text = "Total: 0 MB"
		totalLabel.TextColor3 = Color3.fromRGB(200,200,200)
		totalLabel.Font = Enum.Font.Gotham
		totalLabel.TextSize = 18
		totalLabel.BackgroundTransparency = 1
		totalLabel.Parent = mainFrame

		local percentLabel = Instance.new("TextLabel")
		percentLabel.Size = UDim2.new(1, 0, 0, 40)
		percentLabel.Position = UDim2.new(0, 0, 0, 125)
		percentLabel.Text = "0%"
		percentLabel.TextColor3 = Color3.new(1,1,1)
		percentLabel.Font = Enum.Font.GothamBold
		percentLabel.TextSize = 32
		percentLabel.BackgroundTransparency = 1
		percentLabel.Parent = mainFrame

		-- === Progress bar ===
		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(0.8, 0, 0, 20)
		barBg.Position = UDim2.new(0.1, 0, 0, 175)
		barBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
		barBg.BorderSizePixel = 0
		barBg.Parent = mainFrame
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = barBg

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
		fill.BorderSizePixel = 0
		fill.Parent = barBg
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 10)
		fillCorner.Parent = fill

		-- === Uptime label ===
		local uptimeLabel = Instance.new("TextLabel")
		uptimeLabel.Size = UDim2.new(1, 0, 0, 25)
		uptimeLabel.Position = UDim2.new(0, 0, 0, 210)
		uptimeLabel.Text = "Uptime: " .. getUptime()
		uptimeLabel.TextColor3 = Color3.fromRGB(150,150,150)
		uptimeLabel.Font = Enum.Font.Gotham
		uptimeLabel.TextSize = 14
		uptimeLabel.BackgroundTransparency = 1
		uptimeLabel.Parent = mainFrame

		-- === Graph section ===
		local graphTitle = Instance.new("TextLabel")
		graphTitle.Size = UDim2.new(1, 0, 0, 25)
		graphTitle.Position = UDim2.new(0, 0, 0, 245)
		graphTitle.Text = "Memory Usage Over Time (last 60s)"
		graphTitle.TextColor3 = Color3.fromRGB(180,180,180)
		graphTitle.Font = Enum.Font.Gotham
		graphTitle.TextSize = 14
		graphTitle.BackgroundTransparency = 1
		graphTitle.Parent = mainFrame

		-- Graph container (background)
		local graphContainer = Instance.new("Frame")
		graphContainer.Size = UDim2.new(0.9, 0, 0, GRAPH_HEIGHT)
		graphContainer.Position = UDim2.new(0.05, 0, 0, 275)
		graphContainer.BackgroundColor3 = Color3.fromRGB(20,20,25)
		graphContainer.BorderSizePixel = 1
		graphContainer.BorderColor3 = Color3.fromRGB(60,60,70)
		graphContainer.Parent = mainFrame
		local graphCorner = Instance.new("UICorner")
		graphCorner.CornerRadius = UDim.new(0, 6)
		graphCorner.Parent = graphContainer

		-- Create bars (we will reuse them)
		local bars = {}
		local totalWidth = graphContainer.Size.X.Scale * 0.9 -- leave padding

		-- Pre-create bars
		for i = 1, MAX_POINTS do
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0, BAR_WIDTH, 0, 0)
			bar.Position = UDim2.new(0, 0, 0, 0) -- will be set in update
			bar.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
			bar.BorderSizePixel = 0
			bar.Parent = graphContainer
			table.insert(bars, bar)
		end

		-- === Close button ===
		local closeBtn = Instance.new("TextButton")
		closeBtn.Size = UDim2.new(0, 100, 0, 40)
		closeBtn.Position = UDim2.new(0.5, -50, 0, 420) -- adjust for graph
		closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
		closeBtn.Text = "Close"
		closeBtn.TextColor3 = Color3.new(1,1,1)
		closeBtn.Font = Enum.Font.Gotham
		closeBtn.TextSize = 16
		closeBtn.Parent = mainFrame
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = closeBtn

		closeBtn.MouseButton1Click:Connect(function()
			AppManager.CloseApp("MemoryDisplay")
		end)

		-- === Update loop ===
		local updateThread = nil
		local function updateStats()
			local usedMB, totalMB = getMemoryStats()
			local percent = (usedMB / totalMB) * 100
			percent = math.clamp(percent, 0, 100)

			-- Update labels
			usedLabel.Text = string.format("Used: %.0f MB", usedMB)
			totalLabel.Text = string.format("Total: %.0f MB", totalMB)
			percentLabel.Text = string.format("%.0f%%", percent)

			-- Update progress bar
			local targetWidth = math.clamp(percent / 100, 0, 1)
			local tween = TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(targetWidth, 0, 1, 0)
			})
			tween:Play()

			-- Color by usage
			if percent > 80 then
				fill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			elseif percent > 60 then
				fill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
			else
				fill.BackgroundColor3 = Color3.fromRGB(50, 181, 172)
			end

			-- Uptime
			uptimeLabel.Text = "Uptime: " .. getUptime()

			-- === Graph update ===
			-- Add new point
			table.insert(history, percent)
			if #history > MAX_POINTS then
				table.remove(history, 1)
			end

			-- Redraw bars
			local count = #history
			if count == 0 then return end

			-- Get container size (absolute)
			local containerAbsSize = graphContainer.AbsoluteSize
			local availWidth = containerAbsSize.X - 10 -- 5px padding each side
			local availHeight = containerAbsSize.Y - 6

			local barWidth = BAR_WIDTH
			local spacing = BAR_SPACING
			local totalBarWidth = (barWidth + spacing) * count - spacing
			local startX = 5 -- left padding

			-- If bars don't fit, reduce width proportionally
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

				-- Color based on value (gradient)
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

			-- Hide unused bars
			for i = count + 1, #bars do
				bars[i].Visible = false
			end
		end

		-- Initial update
		updateStats()

		-- Start periodic updates
		updateThread = RunService.Heartbeat:Connect(function()
			task.wait(1)
			updateStats()
		end)

		-- === Cleanup ===
		local function cleanup()
			if updateThread then
				updateThread:Disconnect()
				updateThread = nil
			end
		end

		appFolder.Destroying:Connect(cleanup)

		ui.Visible = true
	end

	return MemoryApp
end

-- ============================================
-- EXPORT ALL MODULES
-- ============================================
function ZolinModules.GetAll()
	local modules = {
		AnimationManager = ZolinModules.AnimationManager(),
		AppLoader = ZolinModules.AppLoader(),
		CooldownManager = ZolinModules.CooldownManager(),
		VolumeManager = ZolinModules.VolumeManager(),
		VolumeStyleOptions = ZolinModules.VolumeStyleOptions(),
		PowerMenuManager = ZolinModules.PowerMenuManager(),
		ClockManager = ZolinModules.ClockManager(),
		PlatformManager = ZolinModules.PlatformManager(),
		SettingsManager = ZolinModules.SettingsManager(),  -- Add this
		SettingsApp = ZolinModules.SettingsApp(),          -- Add this
		WallpaperSysApp = ZolinModules.WallpaperSysApp(),  -- Add this
		ZolinInstaller = ZolinModules.ZolinInstaller(),
		MemoryDisplayApp = ZolinModules.MemoryDisplayApp(),
	}
	local deps = {
		AnimationManager = modules.AnimationManager,
		AppLoader = modules.AppLoader,
		CooldownManager = modules.CooldownManager,
	}
	modules.NotificationManager = ZolinModules.NotificationManager(deps)
	modules.AppManager = ZolinModules.AppManager(deps)
	return modules
end
-- ============================================
-- EXPORT ALL MODULES
-- ============================================
function ZolinModules.GetAll_Desktop()
	local modules = {
		AnimationManager = ZolinModules.AnimationManager(),
		AppLoader = ZolinModules.AppLoader(),
		CooldownManager = ZolinModules.CooldownManager(),
		VolumeManager = ZolinModules.VolumeManager(),
		VolumeStyleOptions = ZolinModules.VolumeStyleOptions(),
		--PowerMenuManager = ZolinModules.PowerMenuManager(),
		ClockManager = ZolinModules.ClockManager(),
		PlatformManager = ZolinModules.PlatformManager(),
		SettingsManager = ZolinModules.SettingsManager(),  -- Add this
		SettingsApp = ZolinModules.SettingsApp(),          -- Add this
		WallpaperSysApp = ZolinModules.WallpaperSysApp(),  -- Add this
		ZolinInstaller = ZolinModules.ZolinInstaller(),
		ZIndexManager = ZolinModules.ZIndexManager(),
		TaskbarManager = ZolinModules.TaskbarManager(),
		StartMenuManager = ZolinModules.StartMenuManager(),
		ContextMenuManager = ZolinModules.ContextMenuManager(),
		MemoryDisplayApp = ZolinModules.MemoryDisplayApp(),
	}
	local deps = {
		AnimationManager = modules.AnimationManager,
		AppLoader = modules.AppLoader,
		CooldownManager = modules.CooldownManager,
	}
	--modules.NotificationManager = ZolinModules.NotificationManager(deps)
	modules.AppManager = ZolinModules.AppManager(deps)
	return modules
end

-- ============================================
-- AUTO-INITIALIZE ALL MODULES
-- ============================================
function ZolinModules.Init()
	if ZolinModules.Mode == "Mobile" then
		local MainUI = getMainUI()
		if MainUI then
			local SideButtons = MainUI:FindFirstChild("SideButtons")
			if SideButtons then
				local ButtonSettings = SideButtons:FindFirstChild("ButtonSettings")
				if ButtonSettings then
					ButtonSettings.MouseButton1Click:Connect(function()
						MainUI.__ScreenFrame.Visible = not MainUI.__ScreenFrame.Visible
					end)
				end
			end
			
			-- Show mobile frame, hide desktop frame
			local mobileFrame = MainUI:FindFirstChild("__ScreenFrame")
			if mobileFrame then
				mobileFrame.Visible = true
			end
			local desktopFolder = MainUI:FindFirstChild("__ZolinDesktop")
			if desktopFolder then
				desktopFolder.Visible = false
			end
		end

		-- Initialize modules for mobile
		local modules = ZolinModules.GetAll()
		spawn(function()
			for name, module in pairs(modules) do
				if module and module.Init then
					pcall(module.Init)
					print("Initialized:", name)
				elseif module and module.Initialize then
					pcall(module.Initialize)
					print("Initialized:", name)
				end
			end
			ZolinModules.ZolinListener()
			ZolinModules.ZolinLauncher()
		end)

	elseif ZolinModules.Mode == "Desktop" then
		local MainUI = getMainUI()
		if MainUI then
			local SideButtons = MainUI:FindFirstChild("SideButtons")
			if SideButtons then
				local ButtonSettings = SideButtons:FindFirstChild("ButtonSettings")
				if ButtonSettings then
					ButtonSettings.MouseButton1Click:Connect(function()
						MainUI.__ZolinDesktop.Visible = not MainUI.__ZolinDesktop.Visible
					end)
					end
				end
			end
			-- Hide mobile frame, show desktop frame
			local mobileFrame = MainUI:FindFirstChild("__ScreenFrame")
			if mobileFrame then
				mobileFrame.Visible = false
			end
			local desktopFolder = MainUI:FindFirstChild("__ZolinDesktop")
			if desktopFolder then
				desktopFolder.Visible = true
			end
			MainUI.__Zolin.Data.TransitionSpeed.Value = 0.25; -- like windows 10 fade animation

		-- Initialize modules for desktop
		local modules = ZolinModules.GetAll_Desktop()
		spawn(function()
			for name, module in pairs(modules) do
				if module and module.Init then
					pcall(module.Init)
					print("Initialized:", name)
				elseif module and module.Initialize then
					pcall(module.Initialize)
					print("Initialized:", name)
				end
			end
			ZolinModules.ZolinListener()
			ZolinModules.ZolinLauncher()
			end)
		end
	end
-- // AUTO INITIALIZE //

ZolinModules.Init();

return ZolinModules
