-- ============================================================
-- Changelogs – Logic Script
-- ============================================================
local ZolinApp = {}

function ZolinApp.Init(ui, launchArgs, appFolder)
	local scrollFrame = ui:FindFirstChild("ChangelogScroll", true)
	if not scrollFrame then return end

	-- Get the changelog text from the Data folder
	local dataFolder = appFolder and appFolder:FindFirstChild("Data")
	local changelogText = ""
	if dataFolder then
		local textVal = dataFolder:FindFirstChild("ChangelogText")
		if textVal then
			changelogText = textVal.Value
		end
	end

	-- Clear any existing entries
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Parse the text into version blocks
	local sections = {}
	for line in changelogText:gmatch("[^\r\n]+") do
		if line:match("^v%d") then -- version header
			table.insert(sections, {header = line, items = {}})
		elseif #sections > 0 and line:match("^•") then
			table.insert(sections[#sections].items, line:sub(3)) -- remove the bullet
		end
	end

	if #sections == 0 then
		-- Fallback if parsing fails
		local defaultLabel = Instance.new("TextLabel")
		defaultLabel.Size = UDim2.new(1, 0, 0, 30)
		defaultLabel.BackgroundTransparency = 1
		defaultLabel.Text = "No changelog data."
		defaultLabel.TextColor3 = Color3.new(0.7,0.7,0.7)
		defaultLabel.Font = Enum.Font.Gotham
		defaultLabel.TextSize = 14
		defaultLabel.Parent = scrollFrame
		return
	end

	for _, section in ipairs(sections) do
		-- Version header
		local headerFrame = Instance.new("Frame")
		headerFrame.Size = UDim2.new(1, -10, 0, 35)
		headerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		headerFrame.BorderSizePixel = 0
		headerFrame.Parent = scrollFrame
		headerFrame.ZIndex = 7

		local headerCorner = Instance.new("UICorner")
		headerCorner.CornerRadius = UDim.new(0, 6)
		headerCorner.Parent = headerFrame

		local headerLabel = Instance.new("TextLabel")
		headerLabel.Size = UDim2.new(1, -10, 1, 0)
		headerLabel.Position = UDim2.new(0, 5, 0, 0)
		headerLabel.BackgroundTransparency = 1
		headerLabel.Text = section.header
		headerLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		headerLabel.Font = Enum.Font.GothamBold
		headerLabel.TextSize = 16
		headerLabel.TextXAlignment = Enum.TextXAlignment.Left
		headerLabel.Parent = headerFrame
		headerLabel.ZIndex = 7

		-- Items
		for _, item in ipairs(section.items) do
			local itemFrame = Instance.new("Frame")
			itemFrame.Size = UDim2.new(1, -10, 0, 25)
			itemFrame.BackgroundTransparency = 1
			itemFrame.Parent = scrollFrame
			itemFrame.ZIndex = 7

			local itemLabel = Instance.new("TextLabel")
			itemLabel.Size = UDim2.new(1, -10, 1, 0)
			itemLabel.Position = UDim2.new(0, 15, 0, 0)
			itemLabel.BackgroundTransparency = 1
			itemLabel.Text = "• " .. item
			itemLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
			itemLabel.Font = Enum.Font.Gotham
			itemLabel.TextSize = 13
			itemLabel.TextXAlignment = Enum.TextXAlignment.Left
			itemLabel.Parent = itemFrame
			itemLabel.ZIndex = itemFrame.ZIndex + 1
		end

		-- Spacer
		local spacer = Instance.new("Frame")
		spacer.Size = UDim2.new(1, 0, 0, 10)
		spacer.BackgroundTransparency = 1
		spacer.Parent = scrollFrame
		spacer.ZIndex = 7
	end

	print("Changelogs displayed")
end

return ZolinApp
