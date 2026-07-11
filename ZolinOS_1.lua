if game:GetService("RunService"):IsStudio() then warn("ZolinOS is not supported in Studio.") return end
local ZolinOS = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS");
if ZolinOS then
	warn("ZolinOS is already loaded. | version: "..ZolinOS.DeviceTree.ZolinVersion.Value);
	return
end
loadstring(game:HttpGet("https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/Initiator.lua"))();
task.wait();
loadstring(game:HttpGet("https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/ZolinModules.lua"))();
