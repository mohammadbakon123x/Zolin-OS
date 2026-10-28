-- Creates the V2 system registries; installed app packages populate them later.
local Initiator = {}
local SETUP_VERSION = 2
local MODULES_URL = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/version-3/ZolinModules.lua"
local previousImports = {
	ZolinMusic = {template = "ZolinMusic", id = "ZolinMusic", title = "Music Player", version = "3.0.0"},
	Changelogs = {template = "Changelogs", id = "Changelogs", title = "Changelogs", version = "3.0.0"},
	LibraryStands = {template = "TranslationUI", id = "Library Stands", title = "Library Stands", version = "3.23.9.7"},
}
local function ensure(parent, className, name, properties)
	local object = parent:FindFirstChild(name)
	if object then
		assert(object:IsA(className), "Initiator: " .. object:GetFullName() .. " must be a " .. className)
		return object
	end
	object = Instance.new(className)
	object.Name = name
	for property, value in pairs(properties or {}) do object[property] = value end
	object.Parent = parent
	return object
end
local function attribute(object, name, value)
	if object:GetAttribute(name) == nil then object:SetAttribute(name, value) end
end
local function authored(object, metadata)
	if not object then return false end
	for _, flag in ipairs({"UserPackage", "CustomPackage", "PreserveOnSetup", "PackageInstalled"}) do
		if object:GetAttribute(flag) == true then return true end
	end
	local title = object:GetAttribute("DisplayName")
	if title and title ~= metadata.title then return true end
	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer") then return true end
	end
	local musicData = object:FindFirstChild("MusicData")
	if musicData and #musicData:GetChildren() > 0 then return true end
	local values = object:FindFirstChild("Data")
	local version = values and values:FindFirstChild("Version")
	if version and version:IsA("StringValue") and version.Value ~= metadata.version then return true end
	-- The former setup explicitly retained complete authored player layouts.
	local ui = object:FindFirstChild("UI")
	if metadata.template == "ZolinMusic" and ui and not ui:FindFirstChild("MusicContent") then return true end
	return false
end
local function archive(root, category, object)
	local backup = ensure(root, "Folder", "LegacyBundledAssets")
	backup:SetAttribute("Hidden", true)
	backup:SetAttribute("InitiatorMigrationBackup", true)
	local folder = ensure(backup, "Folder", category)
	local name, suffix = object.Name, 1
	while folder:FindFirstChild(name) do
		suffix += 1
		name = object.Name .. "_" .. tostring(suffix)
	end
	object.Name = name
	object:SetAttribute("InitiatorArchived", true)
	object.Parent = folder
end
local function migratePreviousImports(root, sources, apps)
	local version = root:GetAttribute("InitiatorSetupVersion")
	if type(version) == "number" and version >= SETUP_VERSION then return end
	for key, metadata in pairs(previousImports) do
		local descriptor, app = sources:FindFirstChild(key), apps:FindFirstChild(metadata.template)
		local generatedDescriptor = descriptor and descriptor:IsA("Folder") and descriptor:GetAttribute("Bundled") == true
			and descriptor:GetAttribute("SourceModule") == key and descriptor:GetAttribute("AppId") == metadata.id
		local generatedTemplate = app and app:IsA("GuiObject") and app:GetAttribute("InitiatorTemplateVersion") == 1
			and app:GetAttribute("SourceModule") == key and app:GetAttribute("AppId") == metadata.id
		local custom = (descriptor ~= nil and not generatedDescriptor) or (app ~= nil and not generatedTemplate)
			or authored(descriptor, metadata) or authored(app, metadata)
		if not custom then
			-- Leave custom packages active. Archive only the explicitly tagged old defaults.
			if generatedDescriptor then archive(root, "AppSources", descriptor) end
			if generatedTemplate then archive(root, "AppTemplates", app) end
		end
	end
end
local function systemTemplate(parent, name, title)
	local object = ensure(parent, "Frame", name, {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false,
	})
	attribute(object, "InitiatorTemplateVersion", SETUP_VERSION)
	attribute(object, "DisplayName", title)
	attribute(object, "HiddenApp", true)
	attribute(object, "SystemApp", true)
	attribute(object, "HiddenFromHome", name ~= "Settings" and name ~= "ZolinInstaller")
	return object
end
local function createMainUI()
	local MainUI = nil
	MainUI = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS") or Instance.new("ScreenGui")
	MainUI.Name = "ZolinOS"
	MainUI.ClipToDeviceSafeArea = true
	MainUI.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
	MainUI.IgnoreGuiInset = true
	MainUI.DisplayOrder = 10
	MainUI.ResetOnSpawn = false
	MainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	MainUI.Parent = game.Players.LocalPlayer.PlayerGui
	return MainUI
end
function Initiator.Setup(root)
	root = root or createMainUI();
	assert(typeof(root) == "Instance", "Initiator.Setup expects the V3 library folder")
	local sources = ensure(root, "Folder", "AppSources")
	local templates = ensure(root, "Folder", "AppTemplates")
	local apps = ensure(templates, "Folder", "ReplicatedWindow")
	local system = ensure(templates, "Folder", "ReplicatedWindow_Sys")
	migratePreviousImports(root, sources, apps)
	for _, entry in ipairs({
		{"Settings", "Settings", apps}, {"ZolinInstaller", "ZolinInstaller", apps},
		{"Clock", "Clock", system}, {"TaskManager", "Task Manager", system},
		{"WallpaperSys", "Wallpaper", system}, {"HomeCustomization", "Home settings", system},
	}) do systemTemplate(entry[3], entry[1], entry[2]) end
	root:SetAttribute("InitiatorSetupVersion", SETUP_VERSION)
	return {AppSources = sources, AppTemplates = templates}
end
function Initiator.Init(options)
	local player = game:GetService("Players").LocalPlayer
	assert(player, "Initiator.Init must run on the client")
	local playerGui = player:WaitForChild("PlayerGui")
	local root = type(options) == "table" and options.RootFolder or nil
	root = root or playerGui:FindFirstChild("ZolinV3Libraries")
	if not root then
		root = Instance.new("Folder")
		root.Name = "ZolinV3Libraries"
		root.Parent = playerGui
	end
	Initiator.Setup(root)

	local source = game:HttpGet(MODULES_URL, true)
	local compiler = loadstring
	assert(type(compiler) == "function", "This client does not expose loadstring")
	local chunk, compileError = compiler(source, "@ZolinOS3/ZolinModules.lua")
	assert(type(chunk) == "function", "Could not compile remote ZolinModules: " .. tostring(compileError))
	local modules = chunk()
	assert(type(modules) == "table" and type(modules.Init) == "function", "Remote ZolinModules did not return its facade")
	if type(modules.BindRoot) == "function" then assert(modules.BindRoot(root), "Could not bind V3 library root") end
	local initOptions = table.clone(options or {})
	initOptions.RootFolder, initOptions.Initiator = root, Initiator
	modules.Init(initOptions)
	return modules
end
return Initiator
