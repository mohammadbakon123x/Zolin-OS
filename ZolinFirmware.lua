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

-- ---- References to UI containers ----
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

-- ---- InfoLabel (template) ----
local infoLabel = frameListFolder:FindFirstChild("InfoLabel")
if infoLabel then
	infoLabel.Visible = true
else
	warn("Bootloader: InfoLabel not found")
end

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

-- ---- Build info text ----
local function getFriendCount(userId)
	local success, page = pcall(function()
		return Players:GetFriendsAsync(userId)
	end)

	if not success then 
		return "Error retrieving" 
	end

	local onlineCount = 0
	
	repeat
		for _, friend in ipairs(page:GetCurrentPage()) do
			if friend.IsOnline then
				onlineCount = onlineCount + 1
			end
		end

		if not page.IsFinished then
			local advanceSuccess = pcall(function()
				page:AdvanceToNextPageAsync()
			end)
			if not advanceSuccess then break end
		end
	until page.IsFinished

	return onlineCount
end

local function buildInfoText()
	local userId = player.UserId
	local displayName = player.DisplayName
	local userName = player.Name
	local friendCount = getFriendCount(player.UserId)
	local isOwner = isSystemOwner()
	local gameName = game.Name or "Unknown"
	local placeId = game.PlaceId or 0
	local bootMode = "Bootloader"

	local text = string.format([[
Username: %s
Display Name: %s
User ID: %d
Friends Online: %s
System Owner: %s
Game: %s
Place ID: %d
Current Boot: %s
]], userName, displayName, userId, tostring(friendCount), isOwner and "✅ Yes" or "❌ No", gameName, placeId, bootMode)

	return text
end

-- ---- Update InfoLabel ----
local function updateInfoLabel()
	if infoLabel then
		infoLabel.Text = buildInfoText()
	end
end
updateInfoLabel()

-- ---- Mode options (LayoutOrder is determined by table order) ----
local modeOptions = {
	{ label = "Boot as [Mobile Mode]",              mode = "Mobile" },
	{ label = "Boot as [Desktop Mode]",             mode = "Desktop" },
	{ label = "Boot as [Desktop + Safe Mode] With Command Prompt [Beta]", mode = "__safeModeDesktop" },
}

-- ---- Clear existing buttons (keep template) ----
for _, child in ipairs(selectionListFolder:GetChildren()) do
	if child ~= buttonTemplate then
		child:Destroy()
	end
end

-- ---- Ensure UIListLayout exists on SelectionList ----
local layout = selectionListFolder:FindFirstChildOfClass("UIListLayout")
if not layout then
	layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = selectionListFolder
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

for order, option in ipairs(modeOptions) do
	local btn = buttonTemplate:Clone()
	btn.Name = "ModeButton_" .. option.mode
	btn.Visible = true
	btn.Text = option.label
	btn.LayoutOrder = order
	btn.Parent = selectionListFolder

	btn.MouseButton1Click:Connect(function()
		local mode = option.mode
		print("[Bootloader] Selected mode:", mode)

		local evt = getZolinModeEvent()
		if evt then
			evt:Fire("boot", mode)
		else
			warn("[Bootloader] ZolinModeEvent not found")
		end

		-- Hide the bootloader UI
		bootloader.Visible = false
	end)
end

print("[Bootloader] Ready. Waiting for mode selection...")
