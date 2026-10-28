local RunService = game:GetService("RunService")
local inStudio = RunService:IsStudio()
if inStudio then
	warn("ZolinOS 3 is not supported in Studio. Use a compatible client runtime.")
	return
end

local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("ZolinOS")
if existing then
	local version = existing:GetAttribute("ZolinVersion")
	if not version then
		local tree = existing:FindFirstChild("DeviceTree", true)
		local value = tree and tree:FindFirstChild("ZolinVersion")
		version = value and value.Value
	end
	warn("ZolinOS is already loaded." .. (version and (" | version: " .. tostring(version)) or ""))
	return
end

local RAW_BASE = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/version-3/"
local function loadRemote(path, ...)
	local source = game:HttpGet(RAW_BASE .. path, true)
	local chunk, compileError = loadstring(source)
	assert(type(chunk) == "function", "Could not compile " .. path .. ": " .. tostring(compileError))
	return chunk(...)
end

local modules
local ok, err = xpcall(function()
	-- Match V2's loader: Initiator sets up the library and fetches ZolinModules.
	-- Neither module is looked up in the local DataModel.
	local initiator = loadRemote("Initiator.lua")
	assert(type(initiator) == "table" and type(initiator.Init) == "function", "Remote V3 Initiator must return a table with Init(options)")
	modules = initiator.Init()
	assert(type(modules) == "table" and type(modules.Shutdown) == "function", "Remote V3 startup did not return its facade")
end, debug.traceback)

if not ok then
	warn("[ZolinOS 3 startup] " .. tostring(err))
	if modules and type(modules.Shutdown) == "function" then modules.Shutdown() end
end

