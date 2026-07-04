-- ============================================
-- Fly System - Logic Script
-- ============================================
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local isFlying = false
local speed = 1
local maxSpeed = 50
local npcMode = false
local ui = nil
local appFolder = nil

-- ---- References to UI elements ----
local flyButton = nil
local speedDisplay = nil
local statusLabel = nil
local upButton = nil
local downButton = nil
local speedPlus = nil
local speedMinus = nil
local npcCheck = nil

-- ---- Flying state ----
local bodyGyro = nil
local bodyVelocity = nil
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastctrl = {f = 0, b = 0, l = 0, r = 0}
local currentSpeed = 0

-- ---- Cleanup flying ----
local function stopFlying()
    isFlying = false
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character.Humanoid.PlatformStand = false
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
        player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
    end
    ctrl = {f = 0, b = 0, l = 0, r = 0}
    lastctrl = {f = 0, b = 0, l = 0, r = 0}
    currentSpeed = 0
    
    if statusLabel then
        statusLabel.Text = "⏹️ Grounded"
    end
    if flyButton then
        flyButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        flyButton.Text = "🛫 Take Off"
    end
    print("[FlySystem] Stopped flying")
end

-- ---- Start flying ----
local function startFlying()
    local char = player.Character
    if not char then
        warn("[FlySystem] No character found")
        return
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        warn("[FlySystem] No humanoid found")
        return
    end
    
    -- Disable humanoid states
    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
    hum:ChangeState(Enum.HumanoidStateType.Swimming)
    hum.PlatformStand = true
    
    -- Get the torso (R6) or UpperTorso (R15)
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not torso then
        warn("[FlySystem] No torso found")
        return
    end
    
    -- Create body gyro and velocity
    bodyGyro = Instance.new("BodyGyro", torso)
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.cframe = torso.CFrame
    
    bodyVelocity = Instance.new("BodyVelocity", torso)
    bodyVelocity.velocity = Vector3.new(0, 0.1, 0)
    bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
    
    isFlying = true
    
    if statusLabel then
        statusLabel.Text = "🟢 Flying"
    end
    if flyButton then
        flyButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        flyButton.Text = "🛬 Land"
    end
    
    print("[FlySystem] Started flying")
end

-- ---- Toggle fly ----
local function toggleFly()
    if isFlying then
        stopFlying()
    else
        startFlying()
    end
end

-- ---- Update flying physics ----
local function updateFlying()
    if not isFlying then
        -- Still update to catch when character dies or disappears
        if not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") then
            if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
            if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
            isFlying = false
        end
        return
    end
    
    -- Check if character still exists and we have parts
    local char = player.Character
    if not char then
        stopFlying()
        return
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        stopFlying()
        return
    end
    
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not torso then
        stopFlying()
        return
    end
    
    -- Update gyro and velocity positions if they were destroyed
    if not bodyGyro or not bodyGyro.Parent then
        bodyGyro = Instance.new("BodyGyro", torso)
        bodyGyro.P = 9e4
        bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    end
    if not bodyVelocity or not bodyVelocity.Parent then
        bodyVelocity = Instance.new("BodyVelocity", torso)
        bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
    end
    
    -- Update speed based on input
    if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
        currentSpeed = currentSpeed + 0.5 + (currentSpeed / maxSpeed)
        if currentSpeed > maxSpeed then
            currentSpeed = maxSpeed
        end
    elseif currentSpeed ~= 0 then
        currentSpeed = currentSpeed - 1
        if currentSpeed < 0 then
            currentSpeed = 0
        end
    end
    
    local moveSpeed = speed * (npcMode and 1 or 1) -- NPC mode could add randomness here
    
    if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
        local camera = workspace.CurrentCamera
        bodyVelocity.velocity = ((camera.CFrame.lookVector * (ctrl.f + ctrl.b)) + 
            ((camera.CFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - 
            camera.CFrame.p)) * currentSpeed
        lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
    elseif currentSpeed ~= 0 then
        local camera = workspace.CurrentCamera
        bodyVelocity.velocity = ((camera.CFrame.lookVector * (lastctrl.f + lastctrl.b)) + 
            ((camera.CFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - 
            camera.CFrame.p)) * currentSpeed
    else
        bodyVelocity.velocity = Vector3.new(0, 0, 0)
    end
    
    bodyGyro.cframe = workspace.CurrentCamera.CoordinateFrame * 
        CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * currentSpeed / maxSpeed), 0, 0)
end

-- ---- Input handling ----
local function setupInput()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not isFlying then return end
        
        local key = input.KeyCode
        if key == Enum.KeyCode.W then
            ctrl.f = 1
        elseif key == Enum.KeyCode.S then
            ctrl.b = 1
        elseif key == Enum.KeyCode.A then
            ctrl.l = 1
        elseif key == Enum.KeyCode.D then
            ctrl.r = 1
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not isFlying then return end
        
        local key = input.KeyCode
        if key == Enum.KeyCode.W then
            ctrl.f = 0
        elseif key == Enum.KeyCode.S then
            ctrl.b = 0
        elseif key == Enum.KeyCode.A then
            ctrl.l = 0
        elseif key == Enum.KeyCode.D then
            ctrl.r = 0
        end
    end)
end

-- ---- Main Init function ----
return function(uiRef, launchArgs, appFolderRef)
    ui = uiRef
    appFolder = appFolderRef
    
    -- Find UI elements
    flyButton = ui:FindFirstChild("FlyButton")
    speedDisplay = ui:FindFirstChild("SpeedDisplay")
    statusLabel = ui:FindFirstChild("StatusLabel")
    upButton = ui:FindFirstChild("UpButton")
    downButton = ui:FindFirstChild("DownButton")
    speedPlus = ui:FindFirstChild("SpeedPlus")
    speedMinus = ui:FindFirstChild("SpeedMinus")
    npcCheck = ui:FindFirstChild("NPCModeCheck")
    
    -- ---- Fly button ----
    if flyButton then
        flyButton.MouseButton1Click:Connect(toggleFly)
    end
    
    -- ---- Speed controls ----
    if speedPlus then
        speedPlus.MouseButton1Click:Connect(function()
            speed = math.min(speed + 1, 50)
            if speedDisplay then speedDisplay.Text = tostring(speed) end
        end)
    end
    
    if speedMinus then
        speedMinus.MouseButton1Click:Connect(function()
            speed = math.max(speed - 1, 1)
            if speedDisplay then speedDisplay.Text = tostring(speed) end
        end)
    end
    
    -- ---- Up/Down controls ----
    if upButton then
        local upConnection = nil
        upButton.MouseButton1Down:Connect(function()
            upConnection = RunService.Heartbeat:Connect(function()
                if isFlying and player.Character then
                    local torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
                    if torso then
                        torso.CFrame = torso.CFrame * CFrame.new(0, 2, 0)
                    end
                end
            end)
        end)
        upButton.MouseButton1Up:Connect(function()
            if upConnection then
                upConnection:Disconnect()
                upConnection = nil
            end
        end)
        upButton.MouseLeave:Connect(function()
            if upConnection then
                upConnection:Disconnect()
                upConnection = nil
            end
        end)
    end
    
    if downButton then
        local downConnection = nil
        downButton.MouseButton1Down:Connect(function()
            downConnection = RunService.Heartbeat:Connect(function()
                if isFlying and player.Character then
                    local torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
                    if torso then
                        torso.CFrame = torso.CFrame * CFrame.new(0, -2, 0)
                    end
                end
            end)
        end)
        downButton.MouseButton1Up:Connect(function()
            if downConnection then
                downConnection:Disconnect()
                downConnection = nil
            end
        end)
        downButton.MouseLeave:Connect(function()
            if downConnection then
                downConnection:Disconnect()
                downConnection = nil
            end
        end)
    end
    
    -- ---- NPC Mode ----
    if npcCheck then
        npcCheck.MouseButton1Click:Connect(function()
            npcMode = npcCheck.Active
            print("[FlySystem] NPC Mode:", npcMode)
        end)
    end
    
    -- ---- Setup input ----
    setupInput()
    
    -- ---- Main update loop ----
    RunService.Heartbeat:Connect(function()
        updateFlying()
    end)
    
    -- ---- Character death cleanup ----
    player.CharacterAdded:Connect(function()
        wait(0.5)
        if isFlying then
            -- Restart flying if it was active before death
            startFlying()
        end
    end)
    
    -- ---- Cleanup when app closes ----
    if appFolder then
        appFolder.AncestryChanged:Connect(function()
            if not appFolder.Parent then
                stopFlying()
                print("[FlySystem] App closed, stopped flying")
            end
        end)
    end
    
    -- ---- Emergency stop: Shift+Delete ----
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Delete and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            stopFlying()
            if statusLabel then statusLabel.Text = "⏹️ Emergency Stop" end
            print("[FlySystem] Emergency stop triggered (Shift+Delete)")
        end
    end)
    
    print("[FlySystem] Logic initialized!")
end
