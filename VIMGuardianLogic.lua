-- ============================================
-- VIM Guardian - Logic Script
-- ============================================
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local isRunning = false
local isPaused = false
local currentTask = nil
local repeatCount = 0

-- References to UI elements (set by the Init function)
local ui = nil
local appFolder = nil

-- ---- Helper: Get Enum.KeyCode from string ----
local function getKeyCodeFromString(str)
    local map = {
        Space = Enum.KeyCode.Space,
        Enter = Enum.KeyCode.Return,
        Escape = Enum.KeyCode.Escape,
        Backspace = Enum.KeyCode.Backspace,
        Delete = Enum.KeyCode.Delete,
        Insert = Enum.KeyCode.Insert,
        Home = Enum.KeyCode.Home,
        End = Enum.KeyCode.End,
        PageUp = Enum.KeyCode.PageUp,
        PageDown = Enum.KeyCode.PageDown,
        F1 = Enum.KeyCode.F1,
        F2 = Enum.KeyCode.F2,
        F3 = Enum.KeyCode.F3,
        F4 = Enum.KeyCode.F4,
        F5 = Enum.KeyCode.F5,
        F6 = Enum.KeyCode.F6,
        F7 = Enum.KeyCode.F7,
        F8 = Enum.KeyCode.F8,
        F9 = Enum.KeyCode.F9,
        F10 = Enum.KeyCode.F10,
        F11 = Enum.KeyCode.F11,
        F12 = Enum.KeyCode.F12,
        Shift = Enum.KeyCode.LeftShift,
        Ctrl = Enum.KeyCode.LeftControl,
        Alt = Enum.KeyCode.LeftAlt,
    }
    if map[str] then return map[str] end
    return Enum.KeyCode[string.upper(str)] or Enum.KeyCode.E
end

-- ---- Helper: Send a key press ----
local function sendKeyPress(keyCode)
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.01)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

-- ---- Helper: Send mouse click ----
local function sendMouseClick(button)
    if button == "Left" then
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, true, game, 0, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton1, false, game, 0, 0)
    elseif button == "Right" then
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton2, true, game, 0, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(Enum.UserInputType.MouseButton2, false, game, 0, 0)
    end
end

-- ---- Main loop ----
local function runLoop()
    if isRunning then return end
    isRunning = true
    isPaused = false
    repeatCount = 0

    -- Get UI elements
    local keyDropdown = ui:FindFirstChild("KeyDropdown")
    local durationBox = ui:FindFirstChild("DurationBox")
    local modeDropdown = ui:FindFirstChild("RepeatModeDropdown")
    local countBox = ui:FindFirstChild("RepeatCountBox")
    local leftCheck = ui:FindFirstChild("LeftTriggerCheck")
    local rightCheck = ui:FindFirstChild("RightTriggerCheck")
    local npcCheck = ui:FindFirstChild("NPCModeCheck")
    local statusLabel = ui:FindFirstChild("StatusLabel")
    local countLabel = ui:FindFirstChild("CountLabel")

    local keyStr = keyDropdown and keyDropdown.Text or "E"
    local keyCode = getKeyCodeFromString(keyStr)
    local duration = tonumber(durationBox and durationBox.Text or "1") or 1
    duration = math.max(0.1, duration)
    local mode = modeDropdown and modeDropdown.Text or "Forever"
    local maxCount = tonumber(countBox and countBox.Text or "10") or 10
    maxCount = math.max(1, maxCount)
    local useLeft = leftCheck and leftCheck.Active or false
    local useRight = rightCheck and rightCheck.Active or false
    local npcMode = npcCheck and npcCheck.Active or false

    if statusLabel then statusLabel.Text = "🟢 Running..." end
    if countLabel then countLabel.Text = "0" end

    currentTask = task.spawn(function()
        while isRunning do
            if not isPaused then
                -- Send key press
                sendKeyPress(keyCode)

                -- Send mouse clicks if enabled
                if useLeft then sendMouseClick("Left") end
                if useRight then sendMouseClick("Right") end

                repeatCount = repeatCount + 1
                if countLabel then countLabel.Text = tostring(repeatCount) end

                -- Check if we've reached the limit
                if mode == "Count" and repeatCount >= maxCount then
                    if statusLabel then statusLabel.Text = "✅ Complete (" .. repeatCount .. ")" end
                    isRunning = false
                    break
                end

                -- Wait for next press (with NPC randomness if enabled)
                local waitTime = duration
                if npcMode then
                    waitTime = duration * (0.8 + (math.random() * 0.4))
                end
                task.wait(waitTime)
            else
                task.wait(0.1)
            end
        end
        if statusLabel and not isRunning then
            statusLabel.Text = "⏹️ Stopped"
        end
        isRunning = false
    end)
end

-- ---- Emergency Stop: Shift + Delete ----
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Delete and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        isRunning = false
        isPaused = false
        local statusLabel = ui and ui:FindFirstChild("StatusLabel")
        if statusLabel then statusLabel.Text = "⏹️ Emergency Stop" end
        if currentTask then
            task.cancel(currentTask)
            currentTask = nil
        end
        print("[VIM Guardian] Emergency stop triggered (Shift+Delete)")
    end
end)

-- ---- Main Init function ----
return function(uiRef, launchArgs, appFolderRef)
    ui = uiRef
    appFolder = appFolderRef

    -- Find controls
    local startButton = ui:FindFirstChild("StartButton")
    local stopButton = ui:FindFirstChild("StopButton")
    local statusLabel = ui:FindFirstChild("StatusLabel")

    -- ---- Start button ----
    if startButton then
        startButton.MouseButton1Click:Connect(function()
            if isRunning then
                if isPaused then
                    isPaused = false
                    if statusLabel then statusLabel.Text = "🟢 Running..." end
                end
                return
            end
            runLoop()
        end)
    end

    -- ---- Stop button ----
    if stopButton then
        stopButton.MouseButton1Click:Connect(function()
            isRunning = false
            isPaused = false
            if statusLabel then statusLabel.Text = "⏹️ Stopped" end
            if currentTask then
                task.cancel(currentTask)
                currentTask = nil
            end
        end)
    end

    -- ---- Status label click to toggle pause ----
    if statusLabel then
        statusLabel.MouseButton1Click:Connect(function()
            if isRunning then
                isPaused = not isPaused
                statusLabel.Text = isPaused and "⏸️ Paused" or "🟢 Running..."
            end
        end)
    end

    -- ---- Cleanup when app closes ----
    if appFolder then
        appFolder.AncestryChanged:Connect(function()
            if not appFolder.Parent then
                isRunning = false
                if currentTask then
                    task.cancel(currentTask)
                    currentTask = nil
                end
                print("[VIM Guardian] App closed, stopped all actions")
            end
        end)
    end

    print("[VIM Guardian] Logic initialized!")
end
