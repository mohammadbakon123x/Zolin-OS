-- Task Manager package v3.0.0. The interface is provided by ZolinModules.TaskManagerApp.
-- Install(gui) upgrades the launch template; already-open windows update on their next launch.
local __TaskManagerPackage = {}
local APP_NAME = "TaskManager"
local VERSION = "3.0.0"
local ICON = "rbxassetid://12905435514"

local function defaultMainUI()
	local player = game:GetService("Players").LocalPlayer
	local gui = player and player:FindFirstChildOfClass("PlayerGui")
	return gui and gui:FindFirstChild("ZolinOS")
end

local function folder(parent, name, required)
	local found
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == name then
			assert(child:IsA("Folder"), name .. " must be a Folder")
			assert(not found, "Multiple " .. name .. " folders; repair the container first")
			found = child
		end
	end
	assert(found or not required, name .. " was not found")
	return found
end

local function setString(parent, name, value)
	local item
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == name then
			if not item and child:IsA("StringValue") then item = child else child:Destroy() end
		end
	end
	if not item then item = Instance.new("StringValue"); item.Name = name; item.Parent = parent end
	item.Value = value
	return item
end

function __TaskManagerPackage.Install(mainUI)
	mainUI = mainUI or defaultMainUI()
	if typeof(mainUI) ~= "Instance" then return false, "ZolinOS was not found; use Install(gui) to select a GUI" end
	local app, newRegistry, registryEntry
	local detached = {}
	local ok, result = pcall(function()
		local templates = folder(mainUI, "ReplicatedWindow_Sys", true)
		local userTemplates = folder(mainUI, "ReplicatedWindow", false)
		local zolin = folder(mainUI, "__Zolin", true)
		local registry = folder(zolin, "__AppsLaunchArgFolder", false)
		local oldApps, oldEntries = {}, {}
		local function collectApps(parent)
			if not parent then return end
			for _, item in ipairs(parent:GetChildren()) do
				if item.Name == APP_NAME then table.insert(oldApps, item) end
			end
		end
		collectApps(templates)
		collectApps(userTemplates)
		if registry then
			for _, item in ipairs(registry:GetChildren()) do
				if item.Name == APP_NAME then table.insert(oldEntries, item) end
			end
		end

		-- Build the replacement before touching the installed template.
		app = Instance.new("Frame")
		app.Name = "TaskManager"
		app.AnchorPoint = Vector2.new(0.5, 0.5)
		app.Position = UDim2.fromScale(0.5, 0.5)
		app.Size = UDim2.fromScale(1, 1)
		app.BackgroundColor3 = Color3.fromRGB(16, 20, 29)
		app.BorderSizePixel = 0
		app.ZIndex = 6
		app.Visible = false
		app:SetAttribute("PackageVersion", VERSION)

		local oldApp = oldApps[1]
		if oldApp then
			for name, value in pairs(oldApp:GetAttributes()) do
				if name ~= "PackageVersion" then app:SetAttribute(name, value) end
			end
		end
		local oldData = oldApp and oldApp:FindFirstChild("Data")
		local data = oldData and oldData:IsA("Folder") and oldData:Clone() or Instance.new("Folder")
		data.Name, data.Parent = "Data", app
		setString(data, "Description", "Monitor Roblox performance and manage ZolinOS applications")
		setString(data, "Version", VERSION)
		setString(data, "Icon", ICON)

		local ui = Instance.new("Frame")
		ui.Name = "UI"
		ui.AnchorPoint = Vector2.new(0.5, 0.5)
		ui.Position = UDim2.fromScale(0.5, 0.495)
		ui.Size = UDim2.fromScale(1, 0.89)
		ui.BackgroundColor3 = Color3.fromRGB(16, 20, 29)
		ui.BorderSizePixel = 0
		ui.ClipsDescendants = true
		ui.ZIndex = 7
		ui.Parent = app

		local preview = Instance.new("Frame")
		preview.Name = "PreviewAppInfoZL"
		preview.Size = UDim2.fromOffset(190, 40)
		preview.BackgroundTransparency = 1
		preview.Visible = false
		preview.ZIndex = 8
		preview.Parent = app
		local label = Instance.new("TextLabel")
		label.Name = "AppNameLabel"
		label.Size = UDim2.new(1, -44, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "Task Manager"
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextColor3 = Color3.fromRGB(237, 241, 248)
		label.ZIndex = 9
		label.Parent = preview
		local icon = Instance.new("ImageLabel")
		icon.Name = "ImageLabel"
		icon.Position = UDim2.new(1, -40, 0, 0)
		icon.Size = UDim2.fromOffset(40, 40)
		icon.BackgroundTransparency = 1
		icon.Image, icon.ScaleType = ICON, Enum.ScaleType.Fit
		icon.ZIndex = 9
		icon.Parent = preview

		if not registry then
			newRegistry = Instance.new("Folder")
			newRegistry.Name = "__AppsLaunchArgFolder"
			registry = newRegistry
		end
		registryEntry = Instance.new("StringValue")
		registryEntry.Name, registryEntry.Value = APP_NAME, "ZolinModules"
		app.Parent = templates
		if newRegistry then newRegistry.Parent = zolin end
		registryEntry.Parent = registry
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
		return false, "Task Manager installation failed: " .. tostring(result)
	end
	for _, old in ipairs(detached) do old.object:Destroy() end
	local zolin = mainUI:FindFirstChild("__Zolin")
	local remotes = zolin and zolin:FindFirstChild("Remotes")
	local refresh = remotes and remotes:FindFirstChild("updateZolinLauncher")
	if refresh and refresh:IsA("BindableEvent") then refresh:Fire() end
	return true, result
end

-- The package remains the Store's entry point; TaskManager uses the built-in launch path.
local gui = defaultMainUI()
if gui then
	local installed, appOrError = __TaskManagerPackage.Install(gui)
	if not installed then warn("[TaskManager] " .. tostring(appOrError)) end
end
return __TaskManagerPackage

