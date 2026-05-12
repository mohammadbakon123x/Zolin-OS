-- AppLoader.lua
local AppLoader = {}

local MainUI = script:FindFirstAncestorOfClass("ScreenGui")
local AppDataFolder = MainUI:FindFirstChild("AppData") or Instance.new("Folder", MainUI)
AppDataFolder.Name = "AppData"

local registeredApps = {}

-- App metadata structure
-- {
--     name = "AppName",
--     icon = "rbxassetid://...",
--     description = "Description",
--     version = "1.0",
--     author = "Author",
--     enabled = true
-- }

function AppLoader.RegisterApp(appName, metadata)
	registeredApps[appName] = metadata

	-- Save to AppData
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
			table.insert(apps, {name = name, metadata = meta})
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