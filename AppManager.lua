local v1 = {}
local UserInputService = game:GetService("UserInputService")
local MainUI = script:FindFirstAncestor("ZolinOS") and script:FindFirstAncestorOfClass("ScreenGui");
local ReplicatedWindow = MainUI:WaitForChild("ReplicatedWindow", 5)
local ReplicatedWindowSys = MainUI:WaitForChild("ReplicatedWindow_Sys", 5);
local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
local clearAll_button = bgPage and bgPage:FindFirstChild("ClearAll_Button")
local navBar = MainUI.__ScreenFrame:WaitForChild("NavigationBar")
local BackButton = navBar:WaitForChild("Background")
local ExitButton = navBar:WaitForChild("Exit")
local RunningApps = {}
local BackgroundApps = {}
local ActiveApp = nil
local touchStarted = false
local startY = 0
local swipeThreshold = 20  -- pixels
local v2 = require(script.Parent:WaitForChild("AnimationManager"));
local v3 = require(script.Parent:WaitForChild("NotificationManager"));
local AppLoader = require(script.Parent:WaitForChild("AppLoader"))

local OnBackUIDisableScrollingAnimation = true

-- Track system apps (won't appear on home screen)
local systemApps = {}

-- Event system for app state changes
local eventListeners = {
	onAppLaunched = {},      -- (appName)
	onAppClosed = {},        -- (appName)
	onAppBackgrounded = {},  -- (appName)
	onAppResumed = {},       -- (appName)
	onAppsCleared = {},      -- ()
	onActiveAppChanged = {}  -- (newActiveApp, oldActiveApp)
}

-- Function to trigger events
local function triggerEvent(eventName, ...)
	if eventListeners[eventName] then
		for _, callback in ipairs(eventListeners[eventName]) do
			pcall(callback, ...)
		end
	end
end

-- Public: Subscribe to events
function v1.Subscribe(eventName, callback)
	if eventListeners[eventName] then
		table.insert(eventListeners[eventName], callback)
		return true
	end
	return false
end

-- Public: Unsubscribe from events
function v1.Unsubscribe(eventName, callback)
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

-- Public: Get current app states
function v1.GetRunningApps()
	local copy = {}
	for i, name in ipairs(RunningApps) do
		copy[i] = name
	end
	return copy
end

function v1.GetBackgroundApps()
	local copy = {}
	for i, name in ipairs(BackgroundApps) do
		copy[i] = name
	end
	return copy
end

function v1.GetActiveApp()
	return ActiveApp
end

function v1.GetAppCount()
	return #RunningApps + #BackgroundApps
end

-- Check if an app is a system app
function v1.IsSystemApp(appName)
	return systemApps[appName] == true
end

-- Register a system app (won't appear on home screen)
function v1.RegisterSystemApp(appName)
	systemApps[appName] = true
end

local function registerAllApps()
	-- Register regular apps (from ReplicatedWindow)
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

	-- Register system apps (from ReplicatedWindowSys)
	for _, child in ipairs(ReplicatedWindowSys:GetChildren()) do
		if child:IsA("Frame") or child:IsA("Folder") then
			local metadata = {
				name = child.Name,
				icon = "rbxassetid://12905435514", -- Default system icon
				description = "System Application",
				version = "1.0",
				enabled = true,
				isSystem = true
			}
			AppLoader.RegisterApp(child.Name, metadata)
			v1.RegisterSystemApp(child.Name)
		end
	end
end

function v1.GetApplication(p0)
	local inApps = MainUI.__ScreenFrame.Applications:FindFirstChild(p0)
	local inScrolling = MainUI.__ScreenFrame.BackgroundPage.ScrollingApps:FindFirstChild(p0)
	return inApps ~= nil or inScrolling ~= nil
end

-- Find app template in either ReplicatedWindow or ReplicatedWindowSys
local function findAppTemplate(appName)
	-- First check regular apps
	local template = ReplicatedWindow:FindFirstChild(appName)
	if template then
		return template, false
	end

	-- Then check system apps
	template = ReplicatedWindowSys:FindFirstChild(appName)
	if template then
		return template, true
	end

	return nil, false
end

function v1.LaunchApplication(p1)
	if MainUI.__ScreenFrame.Applications:FindFirstChild(p1) then
		print("App already running")
		return false
	end

	local template, isSystemApp = findAppTemplate(p1)
	if not template then
		warn("Failed to register app: " .. p1 .. " not found in ReplicatedWindow or ReplicatedWindowSys")
		return false
	end

	local clonedApp = template:Clone()
	clonedApp.Name = p1
	clonedApp.Parent = MainUI.__ScreenFrame.Applications

	local LocalScript = clonedApp:FindFirstChildOfClass("LocalScript")
	local ModuleScript = clonedApp:FindFirstChildOfClass("ModuleScript")

	if ModuleScript then
		local module = require(ModuleScript)
		if module and module.Init then
			local ui = clonedApp:FindFirstChild("UI")
			if ui then
				module.Init(ui, {}, clonedApp)
			else
				module.Init(clonedApp, {}, clonedApp)
			end
		end
	end

	if LocalScript then
		LocalScript.Enabled = true
	end

	clonedApp.Visible = true

	-- Only hide home screen for non-system apps
	if not isSystemApp then
		MainUI.__ScreenFrame.HomeScreenScroller.Visible = false
	end

	local oldActive = ActiveApp
	ActiveApp = p1

	spawn(function()
		v2.AnimateWindow(clonedApp, "Open")
	end)

	table.insert(RunningApps, p1)

	-- Trigger events
	triggerEvent("onAppLaunched", p1)
	triggerEvent("onActiveAppChanged", p1, oldActive)

	local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
	if bgPage and bgPage.Visible then
		v1.RefreshBackgroundPage()
	end

	return true
end

function v1.HandleExit()
	if ActiveApp then
		-- Check if the active app is a system app
		if v1.IsSystemApp(ActiveApp) then
			-- System apps should be closed, not backgrounded
			v1.CloseApp(ActiveApp)
		else
			-- Regular apps go to background
			v1.ExitApplication(ActiveApp)
		end
	end
end

function v1.CloseApp(p3)
	local app = MainUI.__ScreenFrame.Applications:FindFirstChild(p3)
	if app then
		-- If it's a system app and it's the active app, animate close
		local isSystem = v1.IsSystemApp(p3)

		if isSystem and ActiveApp == p3 then
			v2.AnimateWindow(p3, "Close")
		end

		app:Destroy()
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
			-- Show home screen only if no other apps are running
			if #RunningApps == 0 and #BackgroundApps == 0 then
				MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
			end
		end

		print("App closed: " .. p3)
		v1.RemovePreview(p3)

		-- Trigger events
		triggerEvent("onAppClosed", p3)
		if oldActive == p3 then
			triggerEvent("onActiveAppChanged", ActiveApp, oldActive)
		end
	end
end

function v1.CloseAllApps()
	local appsToClose = {}
	for _, name in ipairs(RunningApps) do
		table.insert(appsToClose, name)
	end
	for _, name in ipairs(BackgroundApps) do
		table.insert(appsToClose, name)
	end

	for _, name in ipairs(appsToClose) do
		v1.CloseApp(name)
	end

	-- Show home screen after closing all apps
	MainUI.__ScreenFrame.HomeScreenScroller.Visible = true

	-- Trigger clear event
	triggerEvent("onAppsCleared")
end

function v1.ExitApplication(p4)
	local app = MainUI.__ScreenFrame.Applications:FindFirstChild(p4)
	if app then
		local isSystem = v1.IsSystemApp(p4)

		-- System apps should NOT be backgrounded - close them instead
		if isSystem then
			v1.CloseApp(p4)
			return
		end

		-- Only show home screen for non-system apps
		if not isSystem then
			MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
		end

		v2.AnimateWindow(p4, "Close")
		app.Visible = false
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

		local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
		if bgPage and bgPage.Visible then
			v1.RefreshBackgroundPage()
		end
	end
end

function v1.ExitAllApps()
	local appsToBg = {}
	for _, name in ipairs(RunningApps) do
		-- Check if it's a system app - if yes, close it instead
		if v1.IsSystemApp(name) then
			v1.CloseApp(name)
		else
			table.insert(appsToBg, name)
		end
	end
	for _, name in ipairs(appsToBg) do
		v1.ExitApplication(name)
	end
end

function v1.ResumeApplication(p5)
	local app = MainUI.__ScreenFrame.Applications:FindFirstChild(p5)
	if app then
		app.Visible = true

		local isSystem = v1.IsSystemApp(p5)
		if not isSystem then
			MainUI.__ScreenFrame.HomeScreenScroller.Visible = false
		end

		spawn(function()
			v2.AnimateWindow(app, "Open")
		end);

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

		local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
		if bgPage and bgPage.Visible then
			bgPage.Visible = false
			if not isSystem then
				MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
			end
		end
	end
end

function v1.GoHomeScreen()
	local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
	if bgPage then
		bgPage.Visible = false
		local frameNote = bgPage:FindFirstChild("FrameNote")
		local scrollingApps = bgPage:FindFirstChild("ScrollingApps")
		local clearAll = bgPage:FindFirstChild("ClearAll_Button")
		if frameNote then frameNote.Visible = false end
		if scrollingApps then scrollingApps.Visible = false end
		if clearAll then clearAll.Visible = false end
	end
	MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
	v1.ExitAllApps()
end

function v1.BackButton()
	local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
	if not bgPage then return end
	bgPage.Visible = not bgPage.Visible
	if bgPage.Visible then
		for _, v1 in ipairs(RunningApps) do
			local app = MainUI.__ScreenFrame.Applications:FindFirstChild(v1)
			if app then
				app.Visible = false
			end
		end
		ExitButton.Visible = false
		MainUI.__ScreenFrame.HomeScreenScroller.Visible = false
		v1.RefreshBackgroundPage()
	else
		ExitButton.Visible = true
		MainUI.__ScreenFrame.HomeScreenScroller.Visible = true
		local frameNote = bgPage:FindFirstChild("FrameNote")
		local scrollingApps = bgPage:FindFirstChild("ScrollingApps")
		local clearAll = bgPage:FindFirstChild("ClearAll_Button")
		if frameNote then frameNote.Visible = false end
		if scrollingApps then scrollingApps.Visible = false end
		if clearAll then clearAll.Visible = false end
	end
end

function v1.RemovePreview(appName)
	local bgPage = MainUI.__ScreenFrame:FindFirstChild("BackgroundPage")
	if not bgPage then return end
	local scrollingApps = bgPage:FindFirstChild("ScrollingApps")
	if not scrollingApps then return end
	local preview = scrollingApps:FindFirstChild(appName .. "_preview")
	if preview then
		preview:Destroy()
	end
end

function v1.RefreshBackgroundPage()
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
		BackUI.MouseButton1Click:Connect(function()
			if bgPage and bgPage.Visible then
				v1.BackButton()
				v1.HandleExit();
			end
		end)
	end

	-- Build list of currently running/backgrounded apps (excluding system apps from preview)
	local allAppNames = {}
	for _, name in ipairs(RunningApps) do
		-- Only show non-system apps in background page
		if not v1.IsSystemApp(name) then
			table.insert(allAppNames, name)
		end
	end
	for _, name in ipairs(BackgroundApps) do
		if not table.find(allAppNames, name) and not v1.IsSystemApp(name) then
			table.insert(allAppNames, name)
		end
	end

	-- If no apps are running/backgrounded
	if #allAppNames == 0 then
		scrollingApps.UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None
		if frameNote then frameNote.Visible = true end
		if clearAll then clearAll.Visible = false end
		scrollingApps.Visible = false
		if existingPreviews > 0 then
			task.wait(1)
			if bgPage and bgPage.Visible then
				v1.BackButton()
			end
		end
		-- Trigger apps cleared event when all apps are gone
		if existingPreviews > 0 then
			triggerEvent("onAppsCleared")
		end
		return
	elseif existingPreviews > 1 then
		scrollingApps.UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
	end

	-- Apps exist, show them
	scrollingApps.Visible = true
	if frameNote then frameNote.Visible = false end
	if clearAll then clearAll.Visible = true end

	for _, appName in ipairs(allAppNames) do
		local appInstance = MainUI.__ScreenFrame.Applications:FindFirstChild(appName)
		if not appInstance then
			continue
		end
		v1.RemovePreview(appName)
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
		end
		for i, v in pairs(appInstance:GetChildren()) do
			if v:IsA("Frame") then
				local v1 = v:Clone();
				v1.Parent = previewUIContainer;
				if v.Name == "PreviewAppInfoZL" then
					v1.Visible = true;
				end
			end;
		end;
		appInstance.Visible = false;
		preview.Visible = true;
		local nameLabel = preview:FindFirstChild("AppNameLabel", true);
		local iconLabel = preview:FindFirstChild("ImageLabel", true);
		if iconLabel then
			local homeIcon = MainUI.__ScreenFrame.HomeScreenScroller:FindFirstChild(appName)
			if homeIcon and homeIcon:FindFirstChild("AppIcon") then
				iconLabel.Image = homeIcon.AppIcon.Image
			end
		end;
		if nameLabel then
			nameLabel.Text = appName;
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
			v1.ResumeApplication(appName);
			v1.RemovePreview(appName);
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
					v1.CloseApp(appName);
					v1.RemovePreview(appName);
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

-- Button connections
BackButton.MouseButton1Click:Connect(function()
	v1.BackButton()
end)

ExitButton.MouseButton1Click:Connect(function()
	v1.HandleExit()
end)

if clearAll_button then
	clearAll_button.MouseButton1Click:Connect(function()
		v1.CloseAllApps();
	end)
end

registerAllApps()
return v1
