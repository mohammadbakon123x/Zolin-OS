-- Changelogs package v2.0.0. Auto-installs in the local ZolinOS session.
-- For an explicit GUI (including Studio tests): package.Install(gui) -> success, appOrError.
local __AppPackage = {}
local APP_NAME = "Changelogs"
local LOGIC_URL = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/main/ChangelogsLogic.lua"
__AppPackage.LOGIC_URL = LOGIC_URL
local DEFAULT_TEXT = [[
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

local function folder(parent, name, required)
	local found
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == name then
			assert(child:IsA("Folder"), name .. " must be a Folder")
			assert(not found, "Multiple " .. name .. " folders; repair the container first")
			found = child
		end
	end
	assert(found or not required, name .. " folder was not found")
	return found
end

local function stringValue(parent, name, value)
	local item = Instance.new("StringValue")
	item.Name, item.Value, item.Parent = name, value, parent
	return item
end

local function defaultMainUI()
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	return playerGui and playerGui:FindFirstChild("ZolinOS")
end

function __AppPackage.Install(mainUI)
	if not mainUI then
		mainUI = defaultMainUI()
		if not mainUI then return false, "No local ZolinOS GUI; use Install(gui) to select one" end
	end
	if typeof(mainUI) ~= "Instance" then return false, "Install(gui) requires a Roblox instance" end

	local app, newRegistry, registryEntry
	local detached = {}
	local ok, result = pcall(function()
		local replicatedWindow = folder(mainUI, "ReplicatedWindow_Sys", true)
		local otherWindow = folder(mainUI, "ReplicatedWindow", false)
		local zolin = folder(mainUI, "__Zolin", true)
		local registry = folder(zolin, "__AppsLaunchArgFolder", false)
		folder(mainUI, "AppData", false) -- Existing app metadata belongs to ZolinModules.
		local oldApps, oldEntries, savedStrings = {}, {}, {}
		local function collect(parent, list)
			if parent then
				for _, child in ipairs(parent:GetChildren()) do
					if child.Name == APP_NAME then table.insert(list, child) end
				end
			end
		end
		collect(replicatedWindow, oldApps)
		collect(otherWindow, oldApps)
		collect(registry, oldEntries)
		local function preserveStrings(data)
			if not data or not data:IsA("Folder") then return end
			for _, item in ipairs(data:GetChildren()) do
				if item:IsA("StringValue") and savedStrings[item.Name] == nil then
					savedStrings[item.Name] = item.Value
				end
			end
		end
		-- Canonical Data wins over the UI mirror, including deliberately empty text.
		for _, oldApp in ipairs(oldApps) do preserveStrings(oldApp:FindFirstChild("Data")) end
		for _, oldApp in ipairs(oldApps) do
			local oldUI = oldApp:FindFirstChild("UI")
			preserveStrings(oldUI and oldUI:FindFirstChild("ChangelogData"))
		end
		if savedStrings.ChangelogText == nil then savedStrings.ChangelogText = DEFAULT_TEXT end
		savedStrings.Description = "Browse ZolinOS releases and improvements"
		savedStrings.Version = "2.0.0"
		savedStrings.Icon = savedStrings.Icon or "rbxassetid://12905435514"

		-- Build completely off the DataModel before changing an installed package.
		app = Instance.new("Frame")
		app.Name = "Changelogs"
		app.AnchorPoint = Vector2.new(0.5, 0.5)
		app.Position = UDim2.fromScale(0.5, 0.5)
		app.Size = UDim2.fromScale(1, 1)
		app.BackgroundColor3 = Color3.fromRGB(15, 18, 27)
		app.BorderSizePixel = 0
		app.ZIndex = 6
		app.Visible = false
		local data = Instance.new("Folder")
		data.Name, data.Parent = "Data", app
		for name, value in pairs(savedStrings) do stringValue(data, name, value) end
		local ui = Instance.new("Frame")
		ui.Name = "UI"
		ui.Size = UDim2.fromScale(1, 1)
		ui.BackgroundTransparency = 1
		ui.BorderSizePixel = 0
		ui.ZIndex = 7
		ui.Parent = app
		-- Desktop windows clone UI children, whereas mobile clones the full template.
		local mirror = data:Clone()
		mirror.Name, mirror.Parent = "ChangelogData", ui
		local loading = Instance.new("TextLabel")
		loading.Name = "ChangelogLoading"
		loading.Size = UDim2.fromScale(1, 1)
		loading.BackgroundTransparency = 1
		loading.Text = "Loading changelogs..."
		loading.TextColor3 = Color3.fromRGB(180, 191, 209)
		loading.Font = Enum.Font.Gotham
		loading.TextSize = 14
		loading.ZIndex = 8
		loading.Parent = ui
		local preview = Instance.new("Frame")
		preview.Name = "PreviewAppInfoZL"
		preview.Size = UDim2.fromOffset(195, 40)
		preview.BackgroundTransparency = 1
		preview.Visible = false
		preview.ZIndex = 8
		preview.Parent = app
		local previewLabel = Instance.new("TextLabel")
		previewLabel.Name = "AppNameLabel"
		previewLabel.Size = UDim2.new(1, -44, 1, 0)
		previewLabel.BackgroundTransparency = 1
		previewLabel.Text = APP_NAME
		previewLabel.TextColor3 = Color3.new(1, 1, 1)
		previewLabel.Font = Enum.Font.GothamBold
		previewLabel.TextSize = 16
		previewLabel.ZIndex = 9
		previewLabel.Parent = preview
		local icon = Instance.new("ImageLabel")
		icon.Name = "ImageLabel"
		icon.Position = UDim2.new(1, -39, 0, 0)
		icon.Size = UDim2.fromOffset(39, 39)
		icon.BackgroundTransparency = 1
		icon.Image = savedStrings.Icon
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = 9
		icon.Parent = preview

		if not registry then
			newRegistry = Instance.new("Folder")
			newRegistry.Name = "__AppsLaunchArgFolder"
			registry = newRegistry
		end
		registryEntry = stringValue(nil, APP_NAME, LOGIC_URL)
		app.Parent = replicatedWindow
		if newRegistry then newRegistry.Parent = zolin end
		registryEntry.Parent = registry
		-- Retain old objects until every publication step succeeds, for rollback.
		for _, group in ipairs({oldApps, oldEntries}) do
			for _, old in ipairs(group) do
				table.insert(detached, {object = old, parent = old.Parent})
				old.Parent = nil
			end
		end
		return app
	end)
	if not ok then
		if app then app:Destroy() end
		if registryEntry then registryEntry:Destroy() end
		if newRegistry then newRegistry:Destroy() end
		for _, old in ipairs(detached) do pcall(function() old.object.Parent = old.parent end) end
		return false, "Changelogs installation failed: " .. tostring(result)
	end
	for _, old in ipairs(detached) do old.object:Destroy() end
	local zolin = mainUI:FindFirstChild("__Zolin")
	local remotes = zolin and zolin:FindFirstChild("Remotes")
	local refresh = remotes and remotes:FindFirstChild("updateZolinLauncher")
	if refresh and refresh:IsA("BindableEvent") then refresh:Fire() end
	return true, result
end

-- Some Store paths replace the logic registry URL with this package URL after Install.
-- Returning Init keeps those launches compatible without changing the OS loader.
function __AppPackage.Init(ui, launchArgs, appFolder)
	local ok, result = pcall(function()
		assert(typeof(ui) == "Instance" and ui:IsA("GuiObject"), "Changelogs UI was not provided")
		local source = game:HttpGet(LOGIC_URL)
		assert(type(source) == "string" and source ~= "", "Changelogs renderer response was empty")
		local chunk, compileError = loadstring(source, "ChangelogsLogic")
		assert(chunk, "Changelogs renderer compilation failed: " .. tostring(compileError))
		local executed, renderer = pcall(chunk)
		assert(executed, "Changelogs renderer execution failed: " .. tostring(renderer))
		assert(type(renderer) == "table" and type(renderer.Init) == "function", "Changelogs renderer must return an Init function")
		return renderer.Init(ui, launchArgs or {}, appFolder)
	end)
	if ok then return result end
	local message = "Unable to load changelogs: " .. tostring(result)
	warn("[Changelogs] " .. message)
	pcall(function()
		if typeof(ui) ~= "Instance" or not ui:IsA("GuiObject") then return end
		local label = ui:FindFirstChild("ChangelogLoading", true)
		if not label or not label:IsA("TextLabel") then
			label = Instance.new("TextLabel")
			label.Name = "ChangelogLoading"
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.Gotham
			label.TextSize = 14
			label.ZIndex = ui.ZIndex + 2
			label.Parent = ui
		end
		label.TextWrapped = true
		label.TextColor3 = Color3.fromRGB(244, 167, 167)
		label.Text = message
	end)
	return nil, message
end

local function hasRunningApp(mainUI)
	if not mainUI then return false end
	local function containsApp(screen)
		local applications = screen and screen:FindFirstChild("Applications")
		local running = applications and applications:FindFirstChild(APP_NAME)
		return running and running:FindFirstChild("UI") ~= nil
	end
	if containsApp(mainUI:FindFirstChild("__ScreenFrame")) then return true end
	local desktop = mainUI:FindFirstChild("__ZolinDesktop")
	return containsApp(desktop and desktop:FindFirstChild("__ScreenFrame"))
end

-- Launcher execution already has its cloned UI; only explicit Install(gui) upgrades it.
local mainUI = defaultMainUI()
if not hasRunningApp(mainUI) then
	local installed, appOrError = __AppPackage.Install(mainUI)
	if not installed then warn("[Changelogs] " .. tostring(appOrError)) end
end
return __AppPackage
