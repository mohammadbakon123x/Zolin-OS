-- ============================================================
-- Fly System Package Installer
-- ============================================================
local __AppPackage = {}

function __AppPackage.Install()
    local AppName = "FlySystem"
    local ZolinOS = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS")
    if not ZolinOS then warn("ZolinOS not found"); return end

    -- Check if already installed
    local replicatedWindow = ZolinOS:FindFirstChild("ReplicatedWindow")
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
    desc.Value = "Advanced Fly System with speed control and NPC mode"
    desc.Parent = dataFolder

    local version = Instance.new("StringValue")
    version.Name = "Version"
    version.Value = "2.0.0"
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
    previewLabel.Text = "Fly System"
    previewLabel.Parent = preview

    local previewIcon = Instance.new("ImageLabel")
    previewIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    previewIcon.AutomaticSize = Enum.AutomaticSize.XY
    previewIcon.BackgroundTransparency = 1
    previewIcon.Position = UDim2.new(0.9, 0, 0.5, 0)
    previewIcon.Size = UDim2.new(0, 39, 0, 39)
    previewIcon.Image = "rbxassetid://12905435514"
    previewIcon.ScaleType = Enum.ScaleType.Fit
    previewIcon.Parent = preview

    -- ======== APP CONTENT ========

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.06, 0)
    title.Position = UDim2.new(0, 0, 0.01, 0)
    title.BackgroundTransparency = 1
    title.Text = "✈️ Fly System"
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
        label.Size = UDim2.new(0.3, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Right
        label.Parent = row

        control.Size = UDim2.new(0.4, 0, 0.7, 0)
        control.Position = UDim2.new(0.35, 0, 0.15, 0)
        control.Parent = row
        return row
    end

    -- ---- Speed Control ----
    local speedDisplay = Instance.new("TextLabel")
    speedDisplay.Name = "SpeedDisplay"
    speedDisplay.Size = UDim2.new(0.4, 0, 0.7, 0)
    speedDisplay.Position = UDim2.new(0.35, 0, 0.15, 0)
    speedDisplay.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    speedDisplay.Text = "1"
    speedDisplay.TextColor3 = Color3.new(1, 1, 1)
    speedDisplay.Font = Enum.Font.GothamBold
    speedDisplay.TextSize = 18
    speedDisplay.TextXAlignment = Enum.TextXAlignment.Center
    speedDisplay.ZIndex = ui.ZIndex + 2

    local speedRow = Instance.new("Frame")
    speedRow.Size = UDim2.new(1, 0, 0, 40)
    speedRow.BackgroundTransparency = 1
    speedRow.Parent = container

    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.3, 0, 1, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "Speed:"
    speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 14
    speedLabel.TextXAlignment = Enum.TextXAlignment.Right
    speedLabel.Parent = speedRow

    local speedMinus = Instance.new("TextButton")
    speedMinus.Name = "SpeedMinus"
    speedMinus.Size = UDim2.new(0, 30, 0, 30)
    speedMinus.Position = UDim2.new(0.35, 0, 0.15, 0)
    speedMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    speedMinus.Text = "-"
    speedMinus.TextColor3 = Color3.new(1, 1, 1)
    speedMinus.Font = Enum.Font.GothamBold
    speedMinus.TextSize = 18
    speedMinus.ZIndex = ui.ZIndex + 2
    speedMinus.Parent = speedRow

    speedDisplay.Position = UDim2.new(0.45, 0, 0.15, 0)
    speedDisplay.Size = UDim2.new(0.1, 0, 0.7, 0)
    speedDisplay.Parent = speedRow

    local speedPlus = Instance.new("TextButton")
    speedPlus.Name = "SpeedPlus"
    speedPlus.Size = UDim2.new(0, 30, 0, 30)
    speedPlus.Position = UDim2.new(0.55, 0, 0.15, 0)
    speedPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    speedPlus.Text = "+"
    speedPlus.TextColor3 = Color3.new(1, 1, 1)
    speedPlus.Font = Enum.Font.GothamBold
    speedPlus.TextSize = 18
    speedPlus.ZIndex = ui.ZIndex + 2
    speedPlus.Parent = speedRow

    -- ---- Fly Button ----
    local flyButton = Instance.new("TextButton")
    flyButton.Name = "FlyButton"
    flyButton.Size = UDim2.new(0.3, 0, 0.06, 0)
    flyButton.Position = UDim2.new(0.35, 0, 0.45, 0)
    flyButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    flyButton.Text = "🛫 Take Off"
    flyButton.TextColor3 = Color3.new(1, 1, 1)
    flyButton.Font = Enum.Font.GothamBold
    flyButton.TextSize = 16
    flyButton.ZIndex = ui.ZIndex + 2
    flyButton.Parent = ui

    -- ---- Up/Down Controls ----
    local upDownRow = Instance.new("Frame")
    upDownRow.Size = UDim2.new(1, 0, 0, 40)
    upDownRow.BackgroundTransparency = 1
    upDownRow.Position = UDim2.new(0, 0, 0.55, 0)
    upDownRow.Parent = ui

    local upButton = Instance.new("TextButton")
    upButton.Name = "UpButton"
    upButton.Size = UDim2.new(0.15, 0, 0.7, 0)
    upButton.Position = UDim2.new(0.35, 0, 0.15, 0)
    upButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    upButton.Text = "▲ UP"
    upButton.TextColor3 = Color3.new(1, 1, 1)
    upButton.Font = Enum.Font.GothamBold
    upButton.TextSize = 14
    upButton.ZIndex = ui.ZIndex + 2
    upButton.Parent = upDownRow

    local downButton = Instance.new("TextButton")
    downButton.Name = "DownButton"
    downButton.Size = UDim2.new(0.15, 0, 0.7, 0)
    downButton.Position = UDim2.new(0.55, 0, 0.15, 0)
    downButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
    downButton.Text = "▼ DOWN"
    downButton.TextColor3 = Color3.new(1, 1, 1)
    downButton.Font = Enum.Font.GothamBold
    downButton.TextSize = 14
    downButton.ZIndex = ui.ZIndex + 2
    downButton.Parent = upDownRow

    -- ---- Status Label ----
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0.05, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.75, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "⏹️ Grounded"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.ZIndex = ui.ZIndex + 2
    statusLabel.Parent = ui

    -- ---- NPC Mode Checkbox ----
    local npcCheck = Instance.new("TextButton")
    npcCheck.Name = "NPCModeCheck"
    npcCheck.Size = UDim2.new(0, 30, 0, 30)
    npcCheck.Position = UDim2.new(0.7, 0, 0.55, 0)
    npcCheck.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    npcCheck.Text = ""
    npcCheck.TextColor3 = Color3.new(1, 1, 1)
    npcCheck.Font = Enum.Font.Gotham
    npcCheck.TextSize = 18
    npcCheck.ZIndex = ui.ZIndex + 2
    npcCheck.Active = false
    npcCheck.Parent = ui

    npcCheck.MouseButton1Click:Connect(function()
        npcCheck.Active = not npcCheck.Active
        npcCheck.Text = npcCheck.Active and "✓" or ""
        npcCheck.BackgroundColor3 = npcCheck.Active and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 60)
    end)

    local npcLabel = Instance.new("TextLabel")
    npcLabel.Size = UDim2.new(0.2, 0, 0.05, 0)
    npcLabel.Position = UDim2.new(0.75, 0, 0.55, 0)
    npcLabel.BackgroundTransparency = 1
    npcLabel.Text = "NPC Mode"
    npcLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    npcLabel.Font = Enum.Font.Gotham
    npcLabel.TextSize = 14
    npcLabel.TextXAlignment = Enum.TextXAlignment.Left
    npcLabel.ZIndex = ui.ZIndex + 2
    npcLabel.Parent = ui

    -- ======== REGISTER THE APP ========
    local appEntry = __AppsLaunchArgFolder:FindFirstChild(AppName)
    if not appEntry then
        appEntry = Instance.new("StringValue")
        appEntry.Name = AppName
        appEntry.Parent = __AppsLaunchArgFolder
    end

    appEntry.Value = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/main/FlySystemLogic.lua"

    print(AppName .. " package installed successfully!")
end

__AppPackage.Install()
