-- Changelogs 2.0.0: ZolinModules desktop + mobile app.
-- Data.ChangelogText stays editable in the original plain-text format.
local ZolinApp = {}
local activeViews = setmetatable({}, {__mode = "k"})
local DEFAULT_TEXT = [[
v1.12 (Current Version | 06/17/2026):
• Added ZolinInstaller
• Fixed bugs and improved performance
• New Zolin Modifier app

v1.11 (06/15/2026):
• Added Music Player
• Improved AI in PlayAsAI

v1.10 (06/10/2026):
• Initial release of ZolinOS
• System apps: Settings, Wallpaper
]]

local function trim(text)
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Match whole UTF-8 prefixes; byte slicing a bullet corrupts its last byte.
function ZolinApp.Parse(text)
	local sections = {}
	if type(text) ~= "string" then return sections end
	text = text:gsub("^\239\187\191", ""):gsub("\r\n", "\n"):gsub("\r", "\n")
	local section
	for rawLine in (text .. "\n"):gmatch("(.-)\n") do
		local line = trim(rawLine):gsub("^#+%s*", "")
		local version, metadata = line:match("^([vV]%d[%w%.%-]*)%s*(.*)$")
		if version then
			metadata = trim(metadata:gsub(":$", ""))
			if metadata:sub(1, 1) == "(" and metadata:sub(-1) == ")" then metadata = metadata:sub(2, -2) end
			section = {version = version, header = line, meta = metadata, items = {}, current = metadata:lower():find("current", 1, true) ~= nil}
			table.insert(sections, section)
		elseif section and line ~= "" then
			local item = line:match("^•%s*(.*)$") or line:match("^[-*]%s+(.*)$") or line:match("^%d+[.)]%s+(.*)$")
			if item then
				item = trim(item)
				if item ~= "" then table.insert(section.items, item) end
			elseif #section.items > 0 and rawLine:match("^%s") then
				section.items[#section.items] = section.items[#section.items] .. " " .. line
			else
				table.insert(section.items, line)
			end
		end
	end
	local hasCurrent = false
	for _, entry in ipairs(sections) do if entry.current then hasCurrent = true end end
	if not hasCurrent and sections[1] then sections[1].current = true end
	return sections
end

function ZolinApp.Filter(sections, query, selectedVersion)
	local results = {}
	query = trim(tostring(query or "")):lower()
	for _, section in ipairs(sections) do
		if not selectedVersion or section.version == selectedVersion then
			local headerMatch = query == "" or section.header:lower():find(query, 1, true) ~= nil
			local items = {}
			for _, item in ipairs(section.items) do
				if headerMatch or item:lower():find(query, 1, true) then table.insert(items, item) end
			end
			if headerMatch or #items > 0 then table.insert(results, {section = section, items = items}) end
		end
	end
	return results
end

local function disconnectAll(connections)
	for _, connection in ipairs(connections) do connection:Disconnect() end
	table.clear(connections)
end

local function buildView(ui, launchArgs, appFolder)
	local previous = activeViews[ui]
	if previous then previous:Destroy() end
	local stale = ui:FindFirstChild("ChangelogsView")
	if stale then stale:Destroy() end
	-- Migrate the old package without clearing controls owned by the window shell.
	for _, child in ipairs(ui:GetChildren()) do
		if child.Name == "ChangelogScroll" or child.Name == "ChangelogLoading" or (child:IsA("TextLabel") and child.Text:find("Changelogs", 1, true)) then child:Destroy() end
	end
	local controller = {connections = {}, sourceConnections = {}, sections = {}, query = "", selectedVersion = nil, destroyed = false, revision = 0}
	activeViews[ui] = controller
	local z = math.max(6, ui.ZIndex + 1)
	local colors = {background = Color3.fromRGB(15, 18, 27), surface = Color3.fromRGB(23, 28, 41), border = Color3.fromRGB(43, 51, 70), text = Color3.fromRGB(237, 241, 250), muted = Color3.fromRGB(150, 162, 185), accent = Color3.fromRGB(143, 174, 255), selected = Color3.fromRGB(40, 55, 84)}
	local function make(className, name, properties, parent)
		local object = Instance.new(className)
		object.Name = name
		if object:IsA("GuiObject") then object.ZIndex = z + 1 object.BorderSizePixel = 0 end
		for property, value in pairs(properties or {}) do object[property] = value end
		object.Parent = parent
		return object
	end
	local function corner(parent, radius) make("UICorner", "Corner", {CornerRadius = UDim.new(0, radius or 10)}, parent) end
	local function padding(parent, size)
		make("UIPadding", "Padding", {PaddingLeft = UDim.new(0, size), PaddingRight = UDim.new(0, size), PaddingTop = UDim.new(0, size), PaddingBottom = UDim.new(0, size)}, parent)
	end
	local function label(parent, name, text, size, color)
		return make("TextLabel", name, {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = text, RichText = false, TextWrapped = true, TextColor3 = color or colors.text, TextSize = size, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, parent)
	end
	local root = make("Frame", "ChangelogsView", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = colors.background, ClipsDescendants = true, Active = true}, ui)
	controller.root = root
	local heading = make("TextLabel", "Heading", {Position = UDim2.fromOffset(18, 15), Size = UDim2.new(1, -154, 0, 30), BackgroundTransparency = 1, Text = "What's new", TextColor3 = colors.text, TextSize = 25, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, root)
	local subtitle = make("TextLabel", "Subtitle", {Position = UDim2.fromOffset(18, 49), Size = UDim2.new(1, -36, 0, 20), BackgroundTransparency = 1, Text = "Release notes for ZolinOS", TextColor3 = colors.muted, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, root)
	local currentBadge = make("TextLabel", "CurrentRelease", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 19), Size = UDim2.fromOffset(112, 24), BackgroundColor3 = colors.selected, Text = "", TextColor3 = colors.accent, TextSize = 11, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd}, root)
	corner(currentBadge, 6)

	local toolbar = make("Frame", "Toolbar", {Position = UDim2.fromOffset(18, 83), Size = UDim2.new(1, -36, 0, 44), BackgroundTransparency = 1}, root)
	local search = make("TextBox", "Search", {Size = UDim2.new(1, -106, 1, 0), BackgroundColor3 = colors.surface, Text = "", PlaceholderText = "Search updates or versions", PlaceholderColor3 = colors.muted, TextColor3 = colors.text, TextSize = 13, Font = Enum.Font.Gotham, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, MultiLine = false}, toolbar)
	corner(search, 8)
	make("UIPadding", "TextPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 34)}, search)
	local clear = make("TextButton", "ClearSearch", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -108, 0, 0), Size = UDim2.fromOffset(32, 44), BackgroundTransparency = 1, Text = "×", TextColor3 = colors.muted, TextSize = 23, Font = Enum.Font.Gotham, Visible = false}, toolbar)
	local latest = make("TextButton", "LatestOnly", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(98, 44), BackgroundColor3 = colors.surface, Text = "Latest only", TextColor3 = colors.accent, TextSize = 12, Font = Enum.Font.GothamMedium}, toolbar)
	corner(latest, 8)
	local status = make("TextLabel", "ResultStatus", {Position = UDim2.fromOffset(18, 137), Size = UDim2.new(1, -36, 0, 20), BackgroundTransparency = 1, Text = "", TextColor3 = colors.muted, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, root)
	local body = make("Frame", "Body", {Position = UDim2.fromOffset(18, 170), Size = UDim2.new(1, -36, 1, -188), BackgroundTransparency = 1}, root)
	local sidebar = make("ScrollingFrame", "ReleaseArchive", {Size = UDim2.new(0, 174, 1, 0), BackgroundTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = colors.border, ScrollingDirection = Enum.ScrollingDirection.Y}, body)
	make("UIListLayout", "Layout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
	local scroll = make("ScrollingFrame", "ChangelogScroll", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = colors.border, ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true}, body)
	make("UIListLayout", "Layout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
	controller.search = search
	controller.scroll = scroll
	controller.sidebar = sidebar
	local rendered = {}
	local navConnections = {}
	local pending

	local function currentVersion()
		for _, section in ipairs(controller.sections) do if section.current then return section.version end end
		return controller.sections[1] and controller.sections[1].version
	end

	local function render()
		if controller.destroyed then return end
		for _, object in ipairs(rendered) do object:Destroy() end
		table.clear(rendered)
		disconnectAll(navConnections)
		for _, child in ipairs(sidebar:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
		local results = ZolinApp.Filter(controller.sections, controller.query, controller.selectedVersion)
		local itemCount = 0
		for order, result in ipairs(results) do
			local section = result.section
			local card = make("Frame", "ReleaseCard", {LayoutOrder = order, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = colors.surface}, scroll)
			card:SetAttribute("Version", section.version)
			corner(card, 10) padding(card, 16)
			make("UIStroke", "Border", {Color = section.current and Color3.fromRGB(67, 91, 133) or colors.border, Thickness = 1, Transparency = 0.25}, card)
			make("UIListLayout", "Layout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, card)
			local title = label(card, "Version", section.version .. (section.current and "  ·  CURRENT" or ""), 18, section.current and colors.accent or colors.text)
			title.Font = Enum.Font.GothamBold title.LayoutOrder = 1
			if section.meta ~= "" then local meta = label(card, "ReleaseDate", section.meta, 12, colors.muted) meta.LayoutOrder = 2 end
			for index, item in ipairs(result.items) do
				local itemLabel = label(card, "Change", "• " .. item, 14)
				itemLabel.LayoutOrder = index + 2
				itemCount += 1
			end
			if #result.items == 0 then local empty = label(card, "NoDetails", "No details were provided for this release.", 13, colors.muted) empty.LayoutOrder = 3 end
			table.insert(rendered, card)
		end
		if #results == 0 then
			local empty = make("Frame", "EmptyState", {Size = UDim2.new(1, -6, 0, 130), BackgroundColor3 = colors.surface}, scroll)
			corner(empty, 10) padding(empty, 18)
			local title = label(empty, "Title", #controller.sections == 0 and "No releases yet" or "No matching updates", 17)
			title.Font = Enum.Font.GothamBold
			local detail = label(empty, "Message", #controller.sections == 0 and "Add release notes to Data.ChangelogText to get started." or "Try a different search, or show all releases.", 13, colors.muted)
			detail.Position = UDim2.fromOffset(0, 40)
			table.insert(rendered, empty)
		end
		local function nav(text, version, order)
			local button = make("TextButton", "VersionButton", {LayoutOrder = order, Size = UDim2.new(1, -6, 0, 42), BackgroundColor3 = controller.selectedVersion == version and colors.selected or colors.surface, Text = text, TextColor3 = controller.selectedVersion == version and colors.accent or colors.muted, TextSize = 13, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd}, sidebar)
			corner(button, 7)
			table.insert(navConnections, button.Activated:Connect(function() controller:SelectVersion(version) end))
		end
		nav("All releases", nil, 0)
		for index, section in ipairs(controller.sections) do nav(section.version .. (section.current and "  /  Latest" or ""), section.version, index) end
		currentBadge.Text = currentVersion() and ("LATEST  " .. currentVersion()) or "NO RELEASES"
		status.Text = string.format("%d %s  ·  %d %s", #results, #results == 1 and "release" or "releases", itemCount, itemCount == 1 and "update" or "updates")
		latest.Text = controller.selectedVersion == currentVersion() and controller.selectedVersion ~= nil and "All releases" or "Latest only"
		clear.Visible = controller.query ~= ""
		scroll.CanvasPosition = Vector2.zero
		controller.resultCount = #results
		controller.itemCount = itemCount
	end

	local function queueRender()
		controller.revision += 1
		local revision = controller.revision
		if pending then pcall(task.cancel, pending) end
		pending = task.delay(0.08, function()
			pending = nil
			if not controller.destroyed and controller.revision == revision then render() end
		end)
	end

	function controller:SetQuery(query)
		if self.destroyed then return end
		self.query = tostring(query or "")
		if search.Text ~= self.query then search.Text = self.query end
		queueRender()
	end

	function controller:SelectVersion(version)
		if self.destroyed then return end
		self.selectedVersion = version
		render()
	end

	local sourceFolder
	local template
	local function resolveSource()
		template = nil
		if appFolder then
			local data = appFolder:FindFirstChild("Data")
			if data and data:IsA("Folder") then return data end
		end
		local screen = ui:FindFirstAncestorWhichIsA("ScreenGui")
		if screen then
			for _, name in ipairs({"ReplicatedWindow", "ReplicatedWindow_Sys"}) do
				local templates = screen:FindFirstChild(name)
				local candidate = templates and templates:FindFirstChild("Changelogs")
				if candidate then
					template = candidate
					local data = candidate:FindFirstChild("Data")
					if data and data:IsA("Folder") then return data end
				end
			end
		end
		local mirror = ui:FindFirstChild("ChangelogData")
		return mirror and mirror:IsA("Folder") and mirror or nil
	end

	function controller:Refresh()
		if self.destroyed then return end
		disconnectAll(self.sourceConnections)
		sourceFolder = resolveSource()
		local source = sourceFolder and sourceFolder:FindFirstChild("ChangelogText")
		local text = source and source:IsA("StringValue") and source.Value or DEFAULT_TEXT
		self.sections = ZolinApp.Parse(text)
		if self.selectedVersion then
			local exists = false
			for _, section in ipairs(self.sections) do if section.version == self.selectedVersion then exists = true end end
			if not exists then self.selectedVersion = nil end
		end
		if sourceFolder then
			table.insert(self.sourceConnections, sourceFolder.ChildAdded:Connect(function(child) if child.Name == "ChangelogText" then self:Refresh() end end))
			table.insert(self.sourceConnections, sourceFolder.ChildRemoved:Connect(function(child) if child.Name == "ChangelogText" then self:Refresh() end end))
		end
		if source and source:IsA("StringValue") then table.insert(self.sourceConnections, source:GetPropertyChangedSignal("Value"):Connect(function() self:Refresh() end)) end
		if template then
			local function templateChanged(child) if child.Name == "Data" then self:Refresh() end end
			table.insert(self.sourceConnections, template.ChildAdded:Connect(templateChanged))
			table.insert(self.sourceConnections, template.ChildRemoved:Connect(templateChanged))
		end
		render()
	end

	function controller:Destroy()
		if self.destroyed then return end
		self.destroyed = true
		self.revision += 1
		if pending then pcall(task.cancel, pending) pending = nil end
		disconnectAll(self.connections) disconnectAll(self.sourceConnections) disconnectAll(navConnections)
		if activeViews[ui] == self then activeViews[ui] = nil end
		root:Destroy()
	end
	local function layout()
		if controller.destroyed then return end
		local compact = ui.AbsoluteSize.X < 700
		local narrow = ui.AbsoluteSize.X < 300
		sidebar.Visible = not compact
		scroll.Position = compact and UDim2.new() or UDim2.fromOffset(190, 0)
		scroll.Size = compact and UDim2.fromScale(1, 1) or UDim2.new(1, -190, 1, 0)
		heading.TextSize = compact and 22 or 25
		currentBadge.Visible = ui.AbsoluteSize.X >= 340
		heading.Size = UDim2.new(1, currentBadge.Visible and -154 or -36, 0, 30)
		local smallHeight = ui.AbsoluteSize.Y < 330 or narrow
		subtitle.Visible = not smallHeight
		local toolbarY = smallHeight and 55 or 83
		toolbar.Position = UDim2.fromOffset(18, toolbarY)
		toolbar.Size = UDim2.new(1, -36, 0, narrow and 96 or 44)
		search.Size = UDim2.new(1, narrow and 0 or -106, 0, 44)
		clear.Position = UDim2.new(1, narrow and 0 or -108, 0, 0)
		latest.Position = UDim2.new(1, 0, 0, narrow and 52 or 0)
		local statusY = toolbarY + (narrow and 106 or 54)
		status.Position = UDim2.fromOffset(18, statusY)
		body.Position = UDim2.fromOffset(18, statusY + 33)
		body.Size = UDim2.new(1, -36, 1, -statusY - 49)
	end
	table.insert(controller.connections, ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
	table.insert(controller.connections, search:GetPropertyChangedSignal("Text"):Connect(function() controller:SetQuery(search.Text) end))
	table.insert(controller.connections, clear.Activated:Connect(function() controller:SetQuery("") end))
	table.insert(controller.connections, latest.Activated:Connect(function()
		local version = currentVersion()
		if controller.selectedVersion == version then controller:SelectVersion(nil) else controller:SelectVersion(version) end
	end))
	table.insert(controller.connections, root.Destroying:Connect(function() controller:Destroy() end))
	table.insert(controller.connections, ui.Destroying:Connect(function() controller:Destroy() end))
	if appFolder and appFolder ~= ui then
		table.insert(controller.connections, appFolder.Destroying:Connect(function() controller:Destroy() end))
		local function changed(child) if child.Name == "Data" then controller:Refresh() end end
		table.insert(controller.connections, appFolder.ChildAdded:Connect(changed))
		table.insert(controller.connections, appFolder.ChildRemoved:Connect(changed))
	end
	local function mirrorChanged(child) if child.Name == "ChangelogData" then controller:Refresh() end end
	table.insert(controller.connections, ui.ChildAdded:Connect(mirrorChanged))
	table.insert(controller.connections, ui.ChildRemoved:Connect(mirrorChanged))
	if type(launchArgs) == "table" then
		controller.query = type(launchArgs.query) == "string" and launchArgs.query or ""
		controller.selectedVersion = type(launchArgs.version) == "string" and launchArgs.version or nil
		search.Text = controller.query
	end
	controller:Refresh()
	local screen = ui:FindFirstAncestorWhichIsA("ScreenGui")
	if screen then
		for _, name in ipairs({"ReplicatedWindow", "ReplicatedWindow_Sys"}) do
			local templates = screen:FindFirstChild(name)
			if templates then
				local function replaced(child) if child.Name == "Changelogs" then controller:Refresh() end end
				table.insert(controller.connections, templates.ChildAdded:Connect(replaced))
				table.insert(controller.connections, templates.ChildRemoved:Connect(replaced))
			end
		end
	end
	layout()
	return controller
end

function ZolinApp.Init(ui, launchArgs, appFolder)
	if typeof(ui) ~= "Instance" or not ui:IsA("GuiObject") then return nil, "Changelogs requires a UI frame." end
	local ok, result = pcall(buildView, ui, launchArgs, appFolder)
	if not ok then
		local controller = activeViews[ui]
		if controller then controller:Destroy() end
		warn("Changelogs could not open: " .. tostring(result))
		return nil, result
	end
	return result
end

return ZolinApp
