if game:GetService("RunService"):IsStudio() then warn("ZolinOS 3 is not supported in Studio.") return end
local ZolinOS = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS");
if ZolinOS then
	local version = ZolinOS:GetAttribute("ZolinVersion");
	if not version then
		local tree = ZolinOS:FindFirstChild("DeviceTree", true);
		version = tree and tree:FindFirstChild("ZolinVersion") and tree.ZolinVersion.Value;
	end
	warn("ZolinOS is already loaded." .. (version and (" | version: "..tostring(version)) or ""));
	return
end
local Initiator2 = loadstring(game:HttpGet("https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/Initiator2.lua"))();
task.wait();
Initiator2.Init();
