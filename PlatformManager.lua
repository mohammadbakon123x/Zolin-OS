local PlatformManager = {}
local MainUI = script:FindFirstAncestorOfClass("ScreenGui");
local DeviceTree = MainUI:FindFirstChild("DeviceTree");
local DevicePlatform = DeviceTree and DeviceTree:FindFirstChild("DevicePlatfrom");
-- Get the platform (desktop, mobile, console)
function PlatformManager:GetCurrentPlatform()
	local userInputService = game:GetService("UserInputService")
	local isConsole = userInputService.GamepadEnabled
	local isMobile = userInputService.TouchEnabled
	local isDesktop = not isMobile and not isConsole
	DevicePlatform.Value =  isConsole and "console" or isMobile and "mobile" or "desktop"
	return DevicePlatform.Value
end

return PlatformManager;