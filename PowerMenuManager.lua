-- PowerMenuManager.lua
local PowerMenuManager = {}

-- ============================================
-- SERVICES
-- ============================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ============================================
-- REFERENCES
-- ============================================
local MainUI = script:FindFirstAncestor("ZolinOS") and script:FindFirstAncestorOfClass("ScreenGui");
local __ScreenFrame = MainUI and MainUI:WaitForChild("__ScreenFrame")
local __Zolin = MainUI and MainUI:WaitForChild("__Zolin")
local Remotes = __Zolin and __Zolin:WaitForChild("Remotes")
local CloseAllAppsEvent = Remotes and Remotes:WaitForChild("CloseAllApps")

-- ============================================
-- STATE
-- ============================================
local state = {
	isOpen = false,
	overlay = nil,
	powerMenuFrame = nil,
	sliderButton = nil,
	sliderTrack = nil,
	sliderFill = nil,
	instructionLabel = nil,
	cancelButton = nil,
	cancelLabel = nil,
	isDragging = false,
	dragStartX = 0,
	currentDragX = 0,
	tween = nil,
	dragConnection = nil,
	endConnection = nil,
	isShuttingDown = false
}

-- ============================================
-- UI CREATION
-- ============================================
local function createPowerMenuUI()
	if state.overlay then return end

	-- Create overlay background
	local overlay = Instance.new("Frame")
	overlay.Name = "PowerMenuOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0.5, 0, 0.5, 0)
	overlay.AnchorPoint = Vector2.new(0.5, 0.5)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 10000
	overlay.Parent = __ScreenFrame or MainUI

	-- Create power menu container (top center)
	local powerMenuFrame = Instance.new("Frame")
	powerMenuFrame.Name = "PowerMenuFrame"
	powerMenuFrame.Size = UDim2.new(0, 300, 0, 180)
	powerMenuFrame.Position = UDim2.new(0.5, -150, 0, -180)
	powerMenuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	powerMenuFrame.BackgroundTransparency = 1
	powerMenuFrame.BorderSizePixel = 0
	powerMenuFrame.ZIndex = overlay.ZIndex + 1 -- 202
	powerMenuFrame.Parent = overlay

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 25)
	corner.Parent = powerMenuFrame

	-- Instruction label
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Name = "InstructionLabel"
	instructionLabel.Size = UDim2.new(1, 0, 0, 30)
	instructionLabel.Position = UDim2.new(0, 0, 0, 10)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Text = "Slide To Power OFF"
	instructionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	instructionLabel.Font = Enum.Font.Gotham
	instructionLabel.TextSize = 17
	instructionLabel.TextScaled = false
	instructionLabel.ZIndex = overlay.ZIndex + 1 -- 202

	-- Slider track background
	local sliderTrack = Instance.new("Frame")
	sliderTrack.Name = "SliderTrack"
	sliderTrack.Size = UDim2.new(0.9, 0, 0, 50)
	sliderTrack.Position = UDim2.new(0.05, 0, 0.35, -25)
	sliderTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	sliderTrack.BackgroundTransparency = 0.8
	sliderTrack.BorderSizePixel = 0
	sliderTrack.ZIndex = overlay.ZIndex + 1 -- 202
	sliderTrack.Parent = powerMenuFrame
	instructionLabel.Parent = sliderTrack

	local trackUIStroke = Instance.new("UIStroke")
	trackUIStroke.Color = Color3.fromRGB(255, 255, 255)
	trackUIStroke.Thickness = 1.5
	trackUIStroke.Parent = sliderTrack
	trackUIStroke.Transparency = 0.15

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 25)
	trackCorner.Parent = sliderTrack

	-- Slider fill (red progress)
	local sliderFill = Instance.new("Frame")
	sliderFill.Name = "SliderFill"
	sliderFill.Size = UDim2.new(0, 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(99, 99, 99)
	sliderFill.BorderSizePixel = 0
	sliderFill.ZIndex = overlay.ZIndex + 1 -- 202
	sliderFill.Parent = sliderTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 25)
	fillCorner.Parent = sliderFill

	-- Power icon (lightning bolt)
	local powerIcon = Instance.new("ImageLabel")
	powerIcon.Name = "PowerIcon"
	powerIcon.Size = UDim2.new(0, 24, 0, 24)
	powerIcon.Position = UDim2.new(0, 10, 0.5, -12)
	powerIcon.BackgroundTransparency = 1
	powerIcon.Image = "rbxassetid://78125880206412"
	powerIcon.ZIndex = overlay.ZIndex + 2 -- 203
	powerIcon.Parent = sliderTrack

	-- Slider button (circle)
	local sliderButton = Instance.new("ImageButton")
	sliderButton.Name = "SliderButton"
	sliderButton.Size = UDim2.new(0, 44, 0, 44)
	sliderButton.Position = UDim2.new(0, 3, 0.5, -22)
	sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderButton.BackgroundTransparency = 0
	sliderButton.BorderSizePixel = 0
	--sliderButton.Image = "rbxassetid://13060233774"
	sliderButton.Image = "rbxassetid://105578383603577"
	sliderButton.ScaleType = Enum.ScaleType.Fit
	sliderButton.ZIndex = overlay.ZIndex + 2 -- 203
	sliderButton.Parent = sliderTrack
	sliderButton.ImageColor3 = Color3.fromRGB(0, 0, 0)

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(1, 0)
	buttonCorner.Parent = sliderButton

	-- Arrow icon on button
	local arrowIcon = Instance.new("TextLabel")
	arrowIcon.Name = "ArrowIcon"
	arrowIcon.Size = UDim2.new(1, 0, 1, 0)
	arrowIcon.BackgroundTransparency = 1
	arrowIcon.Text = "→"
	arrowIcon.TextColor3 = Color3.fromRGB(0, 0, 0)
	arrowIcon.TextSize = 24
	arrowIcon.Font = Enum.Font.GothamBold
	arrowIcon.ZIndex = overlay.ZIndex + 3 -- 204
	arrowIcon.Parent = sliderButton
	arrowIcon.Visible = false

	-- ============================================
	-- CANCEL BUTTON SECTION
	-- ============================================
	
	-- Cancel ImageButton
	local cancelButton = Instance.new("ImageButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(0, 75, 0, 75)
	cancelButton.Position = UDim2.new(0.5, 0, 0.89, 0)
	cancelButton.AnchorPoint = Vector2.new(0.5, 1)
	cancelButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cancelButton.BackgroundTransparency = 0.2
	cancelButton.Image = "rbxassetid://4458805208"
	cancelButton.ImageColor3 = Color3.fromRGB(0, 0, 0)
	cancelButton.ZIndex = overlay.ZIndex + 2 -- 203
	cancelButton.Parent = overlay

	local cancelButtonCorner = Instance.new("UICorner")
	cancelButtonCorner.CornerRadius = UDim.new(1, 0)
	cancelButtonCorner.Parent = cancelButton

	-- Cancel text label
	local cancelLabel = Instance.new("TextLabel")
	cancelLabel.Name = "CancelLabel"
	cancelLabel.Size = UDim2.new(1, 0, 0, 20)
	cancelLabel.Position = UDim2.new(0.5, 0, 1, 25)
	cancelLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	cancelLabel.BackgroundTransparency = 1
	cancelLabel.Text = "Cancel"
	cancelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	cancelLabel.Font = Enum.Font.Gotham
	cancelLabel.TextSize = 14
	cancelLabel.TextScaled = true
	cancelLabel.ZIndex = overlay.ZIndex + 1 -- 202
	cancelLabel.Parent = cancelButton

	-- Hover effect for cancel button
	cancelButton.MouseEnter:Connect(function()
		pcall(function()
			cancelButton.BackgroundColor3 = Color3.fromRGB(157, 157, 157)
		end)
	end)

	cancelButton.MouseLeave:Connect(function()
		pcall(function()
			cancelButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end)
	end)

	-- Cancel button click handler
	cancelButton.MouseButton1Click:Connect(function()
		PowerMenuManager.Close(1)
	end)

	-- Store references
	state.overlay = overlay
	state.powerMenuFrame = powerMenuFrame
	state.sliderButton = sliderButton
	state.sliderTrack = sliderTrack
	state.sliderFill = sliderFill
	state.instructionLabel = instructionLabel
	state.cancelButton = cancelButton
	state.cancelLabel = cancelLabel
end

-- ============================================
-- UPDATE SLIDER POSITION
-- ============================================
local function updateSliderPosition(dragX)
	-- Safety check: ensure UI elements exist
	if not state.sliderTrack or not state.sliderButton then
		return 0
	end

	-- Get AbsoluteSize safely with pcall
	local trackWidth = 0
	local buttonWidth = 0
	local success = pcall(function()
		trackWidth = state.sliderTrack.AbsoluteSize.X
		buttonWidth = state.sliderButton.AbsoluteSize.X
	end)

	if not success or trackWidth <= 0 or buttonWidth <= 0 then
		return 0
	end

	local maxDrag = trackWidth - buttonWidth - 6

	-- Clamp drag value
	local newDragX = math.clamp(dragX, 0, maxDrag)
	local progress = newDragX / maxDrag

	-- Update button position
	state.sliderButton.Position = UDim2.new(0, 3 + newDragX, 0.5, -22)

	-- Update fill width
	if state.sliderFill then
		state.sliderFill.Size = UDim2.new(progress, 0, 1, 0)
	end

	-- Update background transparency based on drag progress
	local targetTransparency = 1 - (progress * 0.7)
	if state.overlay then
		local successBg = pcall(function()
			local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {
				BackgroundTransparency = targetTransparency
			})
			bgTween:Play()
		end)
	end

	-- Update instruction label alpha
	if state.instructionLabel then
		local labelAlpha = 1 - (progress * 0.8)
		state.instructionLabel.TextTransparency = labelAlpha
	end

	-- Update cancel button alpha based on drag progress (fade out as user drags)
	if state.cancelButton then
		local cancelAlpha = 1 - (progress * 1.2)
		cancelAlpha = math.clamp(cancelAlpha, 0, 1)
		state.cancelButton.ImageTransparency = cancelAlpha
		state.cancelButton.BackgroundTransparency = 0.2 + (cancelAlpha * 0.8)
	end
	if state.cancelLabel then
		local cancelLabelAlpha = 1 - (progress * 1.2)
		cancelLabelAlpha = math.clamp(cancelLabelAlpha, 0, 1)
		state.cancelLabel.TextTransparency = cancelLabelAlpha
	end

	-- Trigger shutdown if fully dragged
	if progress >= 0.999 then
		PowerMenuManager.Close(1)
	end

	return progress
end

-- ============================================
-- RESET SLIDER
-- ============================================
local function resetSlider()
	if state.sliderButton then
		pcall(function()
			local resetTween = TweenService:Create(state.sliderButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 3, 0.5, -22)
			})
			resetTween:Play()
		end)
	end

	if state.sliderFill then
		pcall(function()
			local fillTween = TweenService:Create(state.sliderFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 0, 1, 0)
			})
			fillTween:Play()
		end)
	end

	if state.overlay then
		pcall(function()
			local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1
			})
			bgTween:Play()
		end)
	end

	if state.instructionLabel then
		pcall(function()
			local labelTween = TweenService:Create(state.instructionLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0
			})
			labelTween:Play()
		end)
	end

	-- Reset cancel button visibility
	if state.cancelButton then
		pcall(function()
			local cancelTween = TweenService:Create(state.cancelButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ImageTransparency = 0,
				BackgroundTransparency = 0.2
			})
			cancelTween:Play()
		end)
	end

	if state.cancelLabel then
		pcall(function()
			local labelTween = TweenService:Create(state.cancelLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0
			})
			labelTween:Play()
		end)
	end

	state.currentDragX = 0
end

-- ============================================
-- ANIMATE MENU IN/OUT
-- ============================================
local function animateMenuIn()
	if not state.powerMenuFrame then return end

	-- Fade in overlay background to 0.5
	pcall(function()
		local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.5
		})
		bgTween:Play()
	end)

	-- Slide menu in from top
	pcall(function()
		local menuTween = TweenService:Create(state.powerMenuFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -150, 0, 20)
		})
		menuTween:Play()
	end)
end

local function animateMenuOut(p1)
	if not state.powerMenuFrame then return end

	-- Fade out overlay
	pcall(function()
		if p1 == 1 then
			local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1
			})
			bgTween:Play()
		else
			local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0
				})
			bgTween:Play()
		end
	end)

	-- Slide menu out to top
	pcall(function()
		local menuTween = TweenService:Create(state.powerMenuFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -150, 0, -180)
		})
		menuTween:Play()
		local FadeOutTween2 = TweenService:Create(state.cancelButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 1,
			BackgroundTransparency = 1
		})
		local FadeOutTween3 = TweenService:Create(state.cancelLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1
		})
		FadeOutTween3:Play()
		FadeOutTween2:Play()
		menuTween.Completed:Connect(function()
			if state.overlay then
				if p1 == 1 then
					state.overlay:Destroy()
				end
				state.overlay = nil
				state.powerMenuFrame = nil
				state.sliderButton = nil
				state.sliderTrack = nil
				state.sliderFill = nil
				state.instructionLabel = nil
				state.cancelButton = nil
				state.cancelLabel = nil
			end
		end)
	end)
end

-- ============================================
-- DRAG HANDLERS
-- ============================================
local function setupDragHandlers()
	if not state.sliderButton then return end

	local isDragging = false
	local startDragX = 0
	local startButtonX = 0

	local function onDragStart(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			state.isDragging = true
			startDragX = input.Position.X

			-- Get current button X offset safely
			local buttonPos = state.sliderButton.Position
			startButtonX = buttonPos.X.Offset - 3

			-- Visual feedback
			pcall(function()
				state.sliderButton.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			end)
		end
	end

	local function onDragMove(input)
		if not isDragging then return end

		local deltaX = input.Position.X - startDragX
		local newDragX = startButtonX + deltaX

		updateSliderPosition(newDragX)
		state.currentDragX = newDragX
	end

	local function onDragEnd(input)
		if isDragging then
			isDragging = false
			state.isDragging = false

			-- Reset button color
			pcall(function()
				state.sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			end)

			-- Check if fully dragged (with safety check)
			local trackWidth = 0
			local buttonWidth = 0
			local success = pcall(function()
				trackWidth = state.sliderTrack.AbsoluteSize.X
				buttonWidth = state.sliderButton.AbsoluteSize.X
			end)

			if success and trackWidth > 0 and buttonWidth > 0 then
				local maxDrag = trackWidth - buttonWidth - 6
				local progress = state.currentDragX / maxDrag

				if progress < 0.998 then
					resetSlider()
				end
			else
				resetSlider()
			end
		end
	end

	state.sliderButton.InputBegan:Connect(onDragStart)
	state.dragConnection = UserInputService.InputChanged:Connect(onDragMove)
	state.endConnection = UserInputService.InputEnded:Connect(onDragEnd)
end

-- ============================================
-- CLEANUP
-- ============================================
local function cleanupDragHandlers()
	if state.dragConnection then
		state.dragConnection:Disconnect()
		state.dragConnection = nil
	end
	if state.endConnection then
		state.endConnection:Disconnect()
		state.endConnection = nil
	end
end

-- ============================================
-- PUBLIC FUNCTIONS
-- ============================================
function PowerMenuManager.Init()
	print("PowerMenuManager initialized!")
end

function PowerMenuManager.Open()
	if state.isOpen then return end

	state.isShuttingDown = false
	createPowerMenuUI()

	-- Wait one frame for UI to render
	task.wait()

	animateMenuIn()
	setupDragHandlers()

	state.isOpen = true
end

function PowerMenuManager.Close(p1)
	if not state.isOpen then return end

	cleanupDragHandlers()
	animateMenuOut(p1)
	state.isOpen = false
end

function PowerMenuManager.Toggle()
	if state.isOpen then
		PowerMenuManager.Close(1)
	else
		PowerMenuManager.Open()
	end
end

function PowerMenuManager.IsOpen()
	return state.isOpen
end

-- Custom shutdown callback
local onShutdownCallback = nil

function PowerMenuManager.SetOnShutdown(callback)
	onShutdownCallback = callback
end

-- Override the shutdown print with callback
local originalUpdate = updateSliderPosition
updateSliderPosition = function(dragX)
	-- Safety check: ensure UI elements exist
	if not state.sliderTrack or not state.sliderButton then
		return 0
	end

	-- Get AbsoluteSize safely with pcall
	local trackWidth = 0
	local buttonWidth = 0
	local success = pcall(function()
		trackWidth = state.sliderTrack.AbsoluteSize.X
		buttonWidth = state.sliderButton.AbsoluteSize.X
	end)

	if not success or trackWidth <= 0 or buttonWidth <= 0 then
		return 0
	end

	local maxDrag = trackWidth - buttonWidth - 6

	local newDragX = math.clamp(dragX, 0, maxDrag)
	local progress = newDragX / maxDrag

	if state.sliderButton then
		pcall(function()
			state.sliderButton.Position = UDim2.new(0, 3 + newDragX, 0.5, -22)
		end)
	end

	if state.sliderFill then
		pcall(function()
			state.sliderFill.Size = UDim2.new(progress, 0, 1, 0)
		end)
	end

	if state.overlay then
		local targetTransparency = 1 - (progress * 0.7)
		pcall(function()
			local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {
				BackgroundTransparency = targetTransparency
			})
			bgTween:Play()
		end)
	end

	if state.instructionLabel then
		state.instructionLabel.TextTransparency = 1 - (progress * 0.8)
	end

	-- Fade out cancel button as user drags
	if state.cancelButton then
		local cancelAlpha = 1 - (progress * 1.2)
		cancelAlpha = math.clamp(cancelAlpha, 0, 1)
		state.cancelButton.ImageTransparency = cancelAlpha
		state.cancelButton.BackgroundTransparency = 0.2 + (cancelAlpha * 0.8)
	end
	if state.cancelLabel then
		local cancelLabelAlpha = 1 - (progress * 1.2)
		cancelLabelAlpha = math.clamp(cancelLabelAlpha, 0, 1)
		state.cancelLabel.TextTransparency = cancelLabelAlpha
	end

	if progress >= 0.999 and not state.isShuttingDown then
		state.isShuttingDown = true
		if onShutdownCallback then
			onShutdownCallback()
		else
			if state.overlay then
				local targetTransparency = 0
				pcall(function()
					local bgTween = TweenService:Create(state.overlay, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
						BackgroundTransparency = targetTransparency
					})
					bgTween:Play()
				end)
			end
			-- Shutdown logic
		spawn(function()
			print("Shutting down...")
			CloseAllAppsEvent:Fire()
			task.wait(3.75)
			MainUI:Destroy() -- Finishes at this point.
			end)
		end
		PowerMenuManager.Close(0)
	end

	return progress
end

return PowerMenuManager
