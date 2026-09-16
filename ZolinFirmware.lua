
if game:GetService("RunService"):IsStudio() then
	print("Studio")
	return
end

-- ============================================================
-- Bootloader Manager - Populates Info & Mode Selection
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Wait for the ZolinOS ScreenGui and its __bootloader folder
local function getMainUI()
	local playerGui = player:WaitForChild("PlayerGui")
	return playerGui:FindFirstChild("ZolinOS")
end

local MainUI = getMainUI()
if not MainUI then
	warn("Bootloader: ZolinOS ScreenGui not found")
	return
end

local bootloader = MainUI:FindFirstChild("Bootloader")
if not bootloader then
	warn("Bootloader: Bootloader frame not found")
	return
end

local FrameList = bootloader:FindFirstChild("FrameList")
if not FrameList then
	warn("Bootloader: FrameList not found")
	return
end

local SelectionList = bootloader:FindFirstChild("SelectionList")
if not SelectionList then
	warn("Bootloader: SelectionList not found")
	return
end

local LoadingUI = bootloader:FindFirstChild("LoadingUI")
if not LoadingUI then
	warn("Bootloader: LoadingUI not found")
	return
end

local ImageOS_2 = LoadingUI:FindFirstChild("ImageOS_2")
if not ImageOS_2 then
	warn("Bootloader: ImageOS_2 not found")
	return
end

local LoadingCircle = LoadingUI:FindFirstChild("LoadingCircle")
if not LoadingCircle then
	warn("Bootloader: LoadingCircle not found")
	return
end

local MessageLabel = LoadingUI:FindFirstChild("MessageLabel")
if not MessageLabel then
	warn("Bootloader: MessageLabel not found")
	return
end

-- ---- References to UI containers (template folders) ----
local __bootloader = MainUI:FindFirstChild("__Bootloader")
if not __bootloader then
	warn("Bootloader: __Bootloader folder not found")
	return
end

local frameListFolder = __bootloader:FindFirstChild("__FrameList")
local selectionListFolder = __bootloader:FindFirstChild("__SelectionList")

if not frameListFolder or not selectionListFolder then
	warn("Bootloader: __FrameList or __SelectionList not found")
	return
end

-- ---- InfoLabel template ----
local infoTemplate = frameListFolder:FindFirstChild("InfoLabel")
if not infoTemplate then
	warn("Bootloader: InfoLabel template not found")
	return
end
infoTemplate.Visible = false  -- hide template

-- ---- SelectionButton template ----
local buttonTemplate = selectionListFolder:FindFirstChild("SelectionButton")
if not buttonTemplate then
	warn("Bootloader: SelectionButton template not found")
	return
end
buttonTemplate.Visible = false  -- hide template

-- ---- System owner detection ----
local OWNER_IDS = {1182428808, 11223634767, 4314696588}

local function isSystemOwner()
	local userId = player.UserId
	for _, id in ipairs(OWNER_IDS) do
		if userId == id then
			return true
		end
	end
	return false
end

-- ---- Build info text (as a table of lines) ----
local function getFriendCount(userId)
	if not userId then return 0 end

	local success, friendsPage = pcall(function()
		return Players:GetFriendsAsync(userId)
	end)

	if not success or not friendsPage then
		warn("Failed to get friends for user:", userId)
		return 0
	end

	local onlineCount = 0

	-- Loop through all pages
	while true do
		local currentPage = friendsPage:GetCurrentPage()
		if not currentPage or #currentPage == 0 then
			break
		end

		for _, friend in ipairs(currentPage) do
			if friend.IsOnline then
				onlineCount = onlineCount + 1
			end
		end

		if friendsPage.IsFinished then
			break
		end

		local advanceSuccess = pcall(function()
			friendsPage:AdvanceToNextPageAsync()
		end)

		if not advanceSuccess then
			warn("Failed to advance friends page for user:", userId)
			break
		end
	end

	return onlineCount
end

local function getInfoLines()
	local userId = player.UserId
	local displayName = player.DisplayName
	local userName = player.Name
	local friendCount = getFriendCount(userId)
	local isOwner = isSystemOwner()
	local gameName = game.Name or "Unknown"
	local placeId = game.PlaceId or 0
	local bootMode = "Bootloader"

	return {
		"Username: " .. userName,
		"Display Name: " .. displayName,
		"User ID: " .. userId,
		"Friends Online: " .. tostring(friendCount),
		"System Owner: " .. (isOwner and "✅ Yes" or "❌ No"),
		"Game: " .. gameName,
		"Place ID: " .. placeId,
		"Current Boot: " .. bootMode,
	}
end

-- ---- Populate InfoLabel lines into FrameList ----
local function populateInfoLabels()
	-- Clear existing info labels (keep template)
	for _, child in ipairs(FrameList:GetChildren()) do
		if child ~= infoTemplate then
			child:Destroy()
		end
	end

	-- Ensure FrameList has a UIListLayout
	local layout = FrameList:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 4)
		layout.Parent = FrameList
	end

	local lines = getInfoLines()
	for order, line in ipairs(lines) do
		local label = infoTemplate:Clone()
		label.Name = "InfoLine_" .. order
		label.Visible = true
		label.Text = line
		label.LayoutOrder = order
		label.Parent = FrameList
	end
end

populateInfoLabels()

-- ---- Mode options (LayoutOrder is determined by table order) ----
local modeOptions = {
	{ label = "Boot as [Mobile Mode]",              mode = "Mobile" },
	--{ label = "Boot as [Desktop Mode]",             mode = "Desktop" },
	--{ label = "Boot as [Desktop + Safe Mode] With Command Prompt [Beta]", mode = "__safeModeDesktop" },
}

-- ---- Clear existing buttons (keep template) ----
for _, child in ipairs(SelectionList:GetChildren()) do
	if child ~= buttonTemplate then
		child:Destroy()
	end
end

-- ---- Ensure UIListLayout exists on SelectionList ----
local layout = SelectionList:FindFirstChildOfClass("UIListLayout")
if not layout then
	layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = SelectionList
end

-- ---- Create selection buttons ----
local ZolinModeEvent = nil
local function getZolinModeEvent()
	if ZolinModeEvent then return ZolinModeEvent end
	local __Zolin = MainUI:FindFirstChild("__Zolin")
	if not __Zolin then return nil end
	local remotes = __Zolin:FindFirstChild("Remotes")
	if not remotes then return nil end
	ZolinModeEvent = remotes:FindFirstChild("ZolinModeEvent")
	return ZolinModeEvent
end

if LoadingUI then
	LoadingUI.Visible = false; -- hide loading screen
end
for order, option in ipairs(modeOptions) do
	local btn = buttonTemplate:Clone()
	btn.Name = "ModeButton_" .. option.mode
	btn.Visible = true
	btn.Text = option.label
	btn.LayoutOrder = order
	btn.Parent = SelectionList

	btn.MouseButton1Click:Connect(function()
		local mode = option.mode
		print("[Bootloader] Selected mode:", mode)

		local evt = getZolinModeEvent()
		if evt then
			evt:Fire("boot", mode)
		else
			warn("[Bootloader] ZolinModeEvent not found")
		end
	end)
end

print("[Bootloader] Ready. Waiting for mode selection...")
