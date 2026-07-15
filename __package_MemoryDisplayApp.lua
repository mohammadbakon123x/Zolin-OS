-- ============================================================
-- TaskManager System App (Windows 10-style Task Manager)
-- ============================================================
local __TaskManagerPackage = {}

function __TaskManagerPackage.Install()
    local AppName = "TaskManager"
    local ZolinOS = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS")
    if not ZolinOS then warn("ZolinOS not found"); return end

    local replicatedWindowSys = ZolinOS:FindFirstChild("ReplicatedWindow_Sys")
    if not replicatedWindowSys then warn("ReplicatedWindow_Sys not found"); return end

    local __Zolin = ZolinOS:FindFirstChild("__Zolin")
    if not __Zolin then warn("__Zolin not found"); return end

    local __AppsLaunchArgFolder = __Zolin:FindFirstChild("__AppsLaunchArgFolder")
    if not __AppsLaunchArgFolder then
        __AppsLaunchArgFolder = Instance.new("Folder")
        __AppsLaunchArgFolder.Name = "__AppsLaunchArgFolder"
        __AppsLaunchArgFolder.Parent = __Zolin
    end

    -- Prevent double installation
    if __AppsLaunchArgFolder:FindFirstChild(AppName) and replicatedWindowSys:FindFirstChild(AppName) then
        warn(tostring(AppName) .. " already installed")
        return
    end

    -- ============================================================
    -- BUILD APP FRAME
    -- ============================================================
    local app = Instance.new("Frame")
    app.Name = AppName
    app.AnchorPoint = Vector2.new(0.5, 0.5)
    app.BackgroundTransparency = 0
    app.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    app.Size = UDim2.new(1, 0, 1, 0)
    app.Position = UDim2.new(0.5, 0, 0.5, 0)
    app.ZIndex = 6
    app.Visible = false
    app.Parent = replicatedWindowSys

    -- Data folder (metadata)
    local dataFolder = Instance.new("Folder")
    dataFolder.Name = "Data"
    dataFolder.Parent = app

    Instance.new("StringValue", dataFolder).Name = "Description"
    dataFolder.Description.Value = "Monitor system performance, processes, and resource usage"

    Instance.new("StringValue", dataFolder).Name = "Version"
    dataFolder.Version.Value = "2.0.0"

    -- ============================================================
    -- UI CONTAINER
    -- ============================================================
    local ui = Instance.new("Frame")
    ui.Name = "UI"
    ui.AnchorPoint = Vector2.new(0.5, 0.5)
    ui.Position = UDim2.new(0.5, 0, 0.495, 0)
    ui.Size = UDim2.new(1, 0, 0.89, 0)
    ui.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    ui.BackgroundTransparency = 0.2
    ui.ZIndex = app.ZIndex - 1
    ui.Parent = app

    -- ============================================================
    -- PREVIEW (for App Drawer)
    -- ============================================================
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
    previewLabel.Text = AppName
    previewLabel.Parent = preview

    local previewIcon = Instance.new("ImageLabel")
    previewIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    previewIcon.AutomaticSize = Enum.AutomaticSize.XY
    previewIcon.BackgroundTransparency = 1
    previewIcon.Position = UDim2.new(0.9, 0, 0.5, 0)
    previewIcon.Size = UDim2.new(0, 39, 0, 39)
    previewIcon.Image = "rbxassetid://12905435514"  -- Replace with a task manager icon
    previewIcon.ScaleType = Enum.ScaleType.Fit
    previewIcon.Parent = preview

    -- ============================================================
    -- MAIN UI ELEMENTS (Title Bar + Tabs)
    -- ============================================================

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0.06, 0)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = ui.ZIndex + 1
    titleBar.Parent = ui

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔧 Task Manager"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.ZIndex = ui.ZIndex + 2
    title.Parent = titleBar

    -- Close Button (Desktop only)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.ZIndex = ui.ZIndex + 3
    closeBtn.Parent = titleBar
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn

    -- Tab Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0.05, 0)
    tabContainer.Position = UDim2.new(0, 0, 0.06, 0)
    tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    tabContainer.BorderSizePixel = 0
    tabContainer.ZIndex = ui.ZIndex + 1
    tabContainer.Parent = ui

    -- ============================================================
    -- TABS (Performance, Processes, App History)
    -- ============================================================
    local tabNames = {"Performance", "Processes", "App History"}
    local tabButtons = {}
    local currentTab = "Performance"

    for i, tabName in ipairs(tabNames) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1 / #tabNames, 0, 1, 0)
        btn.Position = UDim2.new((i - 1) / #tabNames, 0, 0, 0)
        btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(25, 25, 35)
        btn.Text = tabName
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        btn.ZIndex = tabContainer.ZIndex + 1
        btn.Parent = tabContainer
        tabButtons[tabName] = btn

        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(tabButtons) do
                b.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            end
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            currentTab = tabName
            SwitchTab(tabName)
        end)
    end

    -- ============================================================
    -- CONTENT CONTAINER (swaps content per tab)
    -- ============================================================
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 0.89, 0)
    contentContainer.Position = UDim2.new(0, 0, 0.11, 0)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ZIndex = ui.ZIndex + 1
    contentContainer.Parent = ui

    -- ============================================================
    -- TAB CONTENT FUNCTIONS (to be filled by the logic script)
    -- ============================================================
    -- These will be populated by the TaskManager logic script
    -- The UI frame structure is ready for the logic to fill in

    -- ============================================================
    -- REGISTER THE APP
    -- ============================================================
    local appEntry = __AppsLaunchArgFolder:FindFirstChild(AppName)
    if not appEntry then
        appEntry = Instance.new("StringValue")
        appEntry.Name = AppName
        appEntry.Parent = __AppsLaunchArgFolder
    end
    appEntry.Value = "ZolinModules"  -- Mark as built-in module

    print(AppName .. " package installed successfully!")
end

-- ============================================================
-- INSTALL
-- ============================================================
__TaskManagerPackage.Install()
