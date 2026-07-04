-- ============================================================
-- VIM Guardian Package Installer
-- ============================================================
local __AppPackage = {}

function __AppPackage.Install()
    local AppName = "VIMGuardian"
    local ZolinOS = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS")
    if not ZolinOS then warn("ZolinOS not found"); return end

    -- Check if already installed
    local replicatedWindow = ZolinOS:FindFirstChild("ReplicatedWindow_Sys")
    if not replicatedWindow then warn("ReplicatedWindow_Sys not found"); return end
    if replicatedWindow:FindFirstChild(AppName) then
        warn(AppName .. " already installed")
        return
    end

    local __Zolin = ZolinOS:FindFirstChild("__Zolin")
    if not __Zolin then warn("__Zolin not found"); return end

    local __AppsLaunchArgFolder = __Zolin:FindFirstChild("__AppsLaunchArgFolder")
    if not __AppsLaunchArgFolder then
        __AppsLaunchArgFolder = Instance.new("Folder")
        __AppsLaunchArgFolder.Name = "__AppsLaunchArgFolder"
        __AppsLaunchArgFolder.Parent = __Zolin
    end

    -- ======== BUILD APP FRAME ========
    local app = Instance.new("Frame")
    app.Name = AppName
    app.AnchorPoint = Vector2.new(0.5, 0.5)
    app.BackgroundTransparency = 0
    app.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    app.Size = UDim2.new(1, 0, 1, 0)
    app.Position = UDim2.new(0.5, 0, 0.5, 0)
    app.ZIndex = 6
    app.Visible = false
    app.Parent = replicatedWindow

    -- Data folder
    local dataFolder = Instance.new("Folder")
    dataFolder.Name = "Data"
    dataFolder.Parent = app

    local desc = Instance.new("StringValue")
    desc.Name = "Description"
    desc.Value = "Auto Clicker / Key Presser with Virtual Input Manager"
    desc.Parent = dataFolder

    local version = Instance.new("StringValue")
    version.Name = "Version"
    version.Value = "1.0.0"
    version.Parent = dataFolder

    -- ======== UI Frame ========
    local ui = Instance.new("Frame")
    ui.Name = "UI"
    ui.AnchorPoint = Vector2.new(0.5, 0.5)
    ui.Position = UDim2.new(0.5, 0, 0.495, 0)
    ui.Size = UDim2.new(1, 0, 0.89, 0)
    ui.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    ui.BackgroundTransparency = 0.15
    ui.ZIndex = app.ZIndex - 1
    ui.Parent = app

    -- Preview (for taskbar)
    local preview = Instance.new("Frame")
    preview.Name = "PreviewAppInfoZL"
    preview.AnchorPoint = Vector2.new(0.5, 0.5)
    preview.AutomaticSize = Enum.AutomaticSize.XY
    preview.BackgroundColor3 = Color3.fromRGB(59, 232, 189)
    preview.BackgroundTransparency = 0.35
    preview.Position = UDim2.new(0.082, 0, 0.031, 0)
    preview.Size = UDim2.new(0.165, 0, 0.061, 0)
    preview.ZIndex = 8
    preview.Visible = false
    preview.Parent = app

    local previewLabel = Instance.new("TextLabel")
    previewLabel.Name = "AppNameLabel"
    previewLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    previewLabel.Position = UDim2.new(0.409, 0, 0.5, 0)
    previewLabel.Size = UDim2.new(0, 150, 0, 25)
    previewLabel.BackgroundTransparency = 1
    previewLabel.TextScaled = true
    previewLabel.Font = Enum.Font.Oswald
    previewLabel.Text = "VIM Guardian"
    previewLabel.Parent = preview

    local previewIcon = Instance.new("ImageLabel")
    previewIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    previewIcon.AutomaticSize = Enum.AutomaticSize.XY
    previewIcon.BackgroundTransparency = 1
    previewIcon.Position = UDim2.new(0.9, 0, 0.5, 0)
    previewIcon.Size = UDim2.new(0, 39, 0, 39)
    previewIcon.Image = "rbxassetid://12905435514"  -- generic icon (you can change this)
    previewIcon.ScaleType = Enum.ScaleType.Fit
    previewIcon.Parent = preview

    -- ======== APP CONTENT ========

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.06, 0)
    title.Position = UDim2.new(0, 0, 0.01, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎮 VIM Guardian"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.ZIndex = ui.ZIndex + 1
    title.Parent = ui

    -- ---- Container for controls ----
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0.8, 0)
    container.Position = UDim2.new(0, 10, 0.08, 0)
    container.BackgroundTransparency = 1
    container.Parent = ui

    local controlLayout = Instance.new("UIListLayout")
    controlLayout.FillDirection = Enum.FillDirection.Vertical
    controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    controlLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    controlLayout.Padding = UDim.new(0, 10)
    controlLayout.Parent = container

    -- ---- Helper: Create a labeled row ----
    local function createRow(labelText, control)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundTransparency = 1
        row.Parent = container

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.25, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Right
        label.Parent = row

        control.Size = UDim2.new(0.4, 0, 0.7, 0)
        control.Position = UDim2.new(0.3, 0, 0.15, 0)
        control.Parent = row
        return row
    end

    -- ---- Key Dropdown ----
    local keyDropdown = Instance.new("TextButton")
    keyDropdown.Name = "KeyDropdown"
    keyDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    keyDropdown.Text = "E"
    keyDropdown.TextColor3 = Color3.new(1, 1, 1)
    keyDropdown.Font = Enum.Font.Gotham
    keyDropdown.TextSize = 14
    keyDropdown.ZIndex = ui.ZIndex + 2

    -- Simple key selection via cycling
    local keys = {"E", "Q", "R", "F", "G", "Z", "X", "C", "V", "B", "Space", "Shift", "Ctrl", "Alt"}
    local keyIndex = 1
    keyDropdown.MouseButton1Click:Connect(function()
        keyIndex = keyIndex % #keys + 1
        keyDropdown.Text = keys[keyIndex]
    end)

    createRow("Key:", keyDropdown)

    -- ---- Duration Box ----
    local durationBox = Instance.new("TextBox")
    durationBox.Name = "DurationBox"
    durationBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    durationBox.Text = "1"
    durationBox.TextColor3 = Color3.new(1, 1, 1)
    durationBox.Font = Enum.Font.Gotham
    durationBox.TextSize = 14
    durationBox.TextXAlignment = Enum.TextXAlignment.Center
    durationBox.PlaceholderText = "0.5"
    durationBox.ZIndex = ui.ZIndex + 2
    createRow("Duration (s):", durationBox)

    -- ---- Repeat Mode Dropdown ----
    local modeDropdown = Instance.new("TextButton")
    modeDropdown.Name = "RepeatModeDropdown"
    modeDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    modeDropdown.Text = "Forever"
    modeDropdown.TextColor3 = Color3.new(1, 1, 1)
    modeDropdown.Font = Enum.Font.Gotham
    modeDropdown.TextSize = 14
    modeDropdown.ZIndex = ui.ZIndex + 2

    local modes = {"Forever", "Count"}
    local modeIndex = 1
    modeDropdown.MouseButton1Click:Connect(function()
        modeIndex = modeIndex % #modes + 1
        modeDropdown.Text = modes[modeIndex]
    end)
    createRow("Mode:", modeDropdown)

    -- ---- Repeat Count Box ----
    local countBox = Instance.new("TextBox")
    countBox.Name = "RepeatCountBox"
    countBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    countBox.Text = "10"
    countBox.TextColor3 = Color3.new(1, 1, 1)
    countBox.Font = Enum.Font.Gotham
    countBox.TextSize = 14
    countBox.TextXAlignment = Enum.TextXAlignment.Center
    countBox.PlaceholderText = "10"
    countBox.ZIndex = ui.ZIndex + 2
    createRow("Repeat Count:", countBox)

    -- ---- Checkboxes row ----
    local function createCheckbox(labelText, initialChecked)
        local checkbox = Instance.new("TextButton")
        checkbox.Size = UDim2.new(0, 30, 0, 30)
        checkbox.BackgroundColor3 = initialChecked and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 60)
        checkbox.Text = initialChecked and "✓" or ""
        checkbox.TextColor3 = Color3.new(1, 1, 1)
        checkbox.Font = Enum.Font.Gotham
        checkbox.TextSize = 18
        checkbox.ZIndex = ui.ZIndex + 2
        checkbox.Active = initialChecked or false

        checkbox.MouseButton1Click:Connect(function()
            checkbox.Active = not checkbox.Active
            checkbox.Text = checkbox.Active and "✓" or ""
            checkbox.BackgroundColor3 = checkbox.Active and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 60)
        end)
        return checkbox
    end

    -- Trigger checkboxes
    local leftCheck = createCheckbox("Left Click", false)
    leftCheck.Name = "LeftTriggerCheck"
    local rightCheck = createCheckbox("Right Click", false)
    rightCheck.Name = "RightTriggerCheck"

    -- Row for checkboxes
    local checkRow = Instance.new("Frame")
    checkRow.Size = UDim2.new(1, 0, 0, 40)
    checkRow.BackgroundTransparency = 1
    checkRow.Parent = container

    local leftLabel = Instance.new("TextLabel")
    leftLabel.Size = UDim2.new(0.25, 0, 1, 0)
    leftLabel.BackgroundTransparency = 1
    leftLabel.Text = "Left Click"
    leftLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    leftLabel.Font = Enum.Font.Gotham
    leftLabel.TextSize = 14
    leftLabel.TextXAlignment = Enum.TextXAlignment.Right
    leftLabel.Parent = checkRow

    leftCheck.Size = UDim2.new(0, 30, 0, 30)
    leftCheck.Position = UDim2.new(0.3, 0, 0.1, 0)
    leftCheck.Parent = checkRow

    local rightLabel = Instance.new("TextLabel")
    rightLabel.Size = UDim2.new(0.25, 0, 1, 0)
    rightLabel.Position = UDim2.new(0.55, 0, 0, 0)
    rightLabel.BackgroundTransparency = 1
    rightLabel.Text = "Right Click"
    rightLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    rightLabel.Font = Enum.Font.Gotham
    rightLabel.TextSize = 14
    rightLabel.TextXAlignment = Enum.TextXAlignment.Right
    rightLabel.Parent = checkRow

    rightCheck.Size = UDim2.new(0, 30, 0, 30)
    rightCheck.Position = UDim2.new(0.85, 0, 0.1, 0)
    rightCheck.Parent = checkRow

    -- ---- NPC Mode Checkbox ----
    local npcCheck = createCheckbox("NPC Mode", false)
    npcCheck.Name = "NPCModeCheck"
    local npcLabel = Instance.new("TextLabel")
    npcLabel.Size = UDim2.new(0.25, 0, 1, 0)
    npcLabel.BackgroundTransparency = 1
    npcLabel.Text = "NPC Mode"
    npcLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    npcLabel.Font = Enum.Font.Gotham
    npcLabel.TextSize = 14
    npcLabel.TextXAlignment = Enum.TextXAlignment.Right
    npcLabel.Parent = checkRow
    npcCheck.Position = UDim2.new(0.3, 0, 0.1, 0)
    npcCheck.Size = UDim2.new(0, 30, 0, 30)
    npcCheck.Parent = checkRow

    -- ---- Status and Count labels ----
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0.05, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.92, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "⏹️ Stopped"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 16
    statusLabel.ZIndex = ui.ZIndex + 2
    statusLabel.Parent = ui

    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(0.2, 0, 0.05, 0)
    countLabel.Position = UDim2.new(0.4, 0, 0.92, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "0"
    countLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextSize = 16
    countLabel.ZIndex = ui.ZIndex + 2
    countLabel.Parent = ui

    -- ---- Buttons ----
    local startButton = Instance.new("TextButton")
    startButton.Name = "StartButton"
    startButton.Size = UDim2.new(0.2, 0, 0.05, 0)
    startButton.Position = UDim2.new(0.3, 0, 0.85, 0)
    startButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    startButton.Text = "▶ Start"
    startButton.TextColor3 = Color3.new(1, 1, 1)
    startButton.Font = Enum.Font.GothamBold
    startButton.TextSize = 16
    startButton.ZIndex = ui.ZIndex + 2
    startButton.Parent = ui

    local stopButton = Instance.new("TextButton")
    stopButton.Name = "StopButton"
    stopButton.Size = UDim2.new(0.2, 0, 0.05, 0)
    stopButton.Position = UDim2.new(0.55, 0, 0.85, 0)
    stopButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    stopButton.Text = "⏹ Stop"
    stopButton.TextColor3 = Color3.new(1, 1, 1)
    stopButton.Font = Enum.Font.GothamBold
    stopButton.TextSize = 16
    stopButton.ZIndex = ui.ZIndex + 2
    stopButton.Parent = ui

    -- ======== REGISTER THE APP ========
    local appEntry = __AppsLaunchArgFolder:FindFirstChild(AppName)
    if not appEntry then
        appEntry = Instance.new("StringValue")
        appEntry.Name = AppName
        appEntry.Parent = __AppsLaunchArgFolder
    end

    -- Store the app's logic URL (you'll upload the VIM Guardian logic script separately)
    appEntry.Value = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/main/VIMGuardianLogic.lua"

    print(AppName .. " package installed successfully!")
end

__AppPackage.Install()
