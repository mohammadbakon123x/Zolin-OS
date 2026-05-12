-- SettingsManager.lua
local SettingsManager = {}

local MainUI = script:FindFirstAncestorOfClass("ScreenGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

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

return SettingsManager