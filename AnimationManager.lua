local v2 = {}
local TweenService = game:GetService("TweenService")

-- References
local MainUI = script:FindFirstAncestor("ZolinOS") and script:FindFirstAncestorOfClass("ScreenGui");
local DataFolder = MainUI and MainUI:FindFirstChild("__Zolin") and MainUI.__Zolin:FindFirstChild("Data")

-- Get transition speed multiplier (default 1 if not found)
local function getTransitionSpeed()
	if DataFolder then
		local speedValue = DataFolder:FindFirstChild("TransitionSpeed")
		if speedValue and speedValue:IsA("NumberValue") then
			return math.max(0.1, speedValue.Value) -- Minimum 0.1 to avoid zero
		end
	end
	return 1
end

-- Check if animation UI is enabled
local function isAnimationUIEnabled()
	if DataFolder then
		local animationUI = DataFolder:FindFirstChild("AnimationUI")
		if animationUI and animationUI:IsA("BoolValue") then
			return animationUI.Value
		end
	end
	return true -- Enabled by default
end

-- Base tween times
local BASE_OPEN_TIME = 0.5
local BASE_CLOSE_TIME = 0.25

local function createTweenInfo(baseTime, easingStyle, easingDirection)
	local speedMultiplier = getTransitionSpeed()
	local adjustedTime = math.max(0.05, baseTime * speedMultiplier)
	return TweenInfo.new(adjustedTime, easingStyle, easingDirection)
end

function v2.AnimateWindow(p0, p1)
	-- Check if animations are disabled
	if not isAnimationUIEnabled() then
		-- Skip animation, just set final state
		local target
		if type(p0) == "string" then
			local mainUI = script:FindFirstAncestorOfClass("ScreenGui")
			if mainUI then
				local appFolder = mainUI.__ScreenFrame and mainUI.__ScreenFrame.Applications and mainUI.__ScreenFrame.Applications:FindFirstChild(p0)
				if appFolder then
					target = appFolder
				else
					warn("AnimateWindow: No app found with name:", p0)
					return
				end
			else
				warn("AnimateWindow: Could not find ScreenGui ancestor")
				return
			end
		elseif p0:IsA("Instance") then
			target = p0
		else
			warn("AnimateWindow: Invalid p0 type:", type(p0))
			return
		end

		local window = target
		local uiScale = window:FindFirstChildOfClass("UIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Parent = window
		end
		uiScale.Scale = (p1 == "Open") and 1 or 0
		return true
	end

	if p0 == nil or p1 == nil then
		return
	end

	local target
	if type(p0) == "string" then
		local mainUI = script:FindFirstAncestorOfClass("ScreenGui")
		if mainUI then
			local appFolder = mainUI.__ScreenFrame and mainUI.__ScreenFrame.Applications and mainUI.__ScreenFrame.Applications:FindFirstChild(p0)
			if appFolder then
				target = appFolder
			else
				warn("AnimateWindow: No app found with name:", p0)
				return
			end
		else
			warn("AnimateWindow: Could not find ScreenGui ancestor")
			return
		end
	elseif p0:IsA("Instance") then
		target = p0
	else
		warn("AnimateWindow: Invalid p0 type:", type(p0))
		return
	end

	local window = target
	local uiScale = window:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Scale = (p1 == "Open") and 1 or 0
		uiScale.Parent = window
	end

	local tweenInfo = (p1 == "Open") and 
		createTweenInfo(BASE_OPEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) or 
		createTweenInfo(BASE_CLOSE_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

	local tween = TweenService:Create(uiScale, tweenInfo, {
		Scale = (p1 == "Open") and 1 or 0
	})
	tween:Play()
	tween.Completed:Wait()
	return true
end

function v2.AnimateVolumeFrame(p2, p3)
	-- Check if animations are disabled
	if not isAnimationUIEnabled() then
		-- Skip animation, just set final position
		if p2 == nil or p3 == nil then return end
		local volumeFrame = p2
		volumeFrame.Position = (p3 == "Open") and  UDim2.new(1, -5,0.465, 0) or UDim2.new(1.1, -5,0.465, 0)
		return true
	end

	if p2 == nil or p3 == nil then
		return
	end

	local volumeFrame = p2
	local baseTime = (p3 == "Open") and BASE_OPEN_TIME or BASE_CLOSE_TIME
	local tweenInfo = (p3 == "Open") and 
		createTweenInfo(baseTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) or 
		createTweenInfo(baseTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

	local tween = TweenService:Create(volumeFrame, tweenInfo, {
		Position = (p3 == "Open") and UDim2.new(1, -5,0.465, 0) or UDim2.new(1.1, -5,0.465, 0)
	})
	tween:Play()
	tween.Completed:Wait()
	return true
end

function v2.AnimateTextTransparency(p4, p5, p6, p7, p8, p9)
	-- Check if animations are disabled
	if not isAnimationUIEnabled() then
		-- Skip animation, just set final transparency
		if p4 == nil or p5 == nil then return end
		p4.TextTransparency = p5
		return true
	end

	if p4 == nil or p5 == nil or p6 == nil or p7 == nil or p8 == nil or p9 == nil then
		return
	end
	-- p5 -> TextTransparency.
	-- p6 -> TweenSpeed.
	-- p7 -> EasingStyle.
	-- p8 -> EasingDirection.
	-- p9 -> Should wait for completion.
	local textLabel = p4
	local speedMultiplier = getTransitionSpeed()
	local TweenSpeed = (p6 or 0.5) * speedMultiplier -- Multiply by speed multiplier (higher = slower)
	local tweenInfo = TweenInfo.new(TweenSpeed, p7, p8)
	local tween = TweenService:Create(textLabel, tweenInfo, {
		TextTransparency = p5
	});
	tween:Play()
	if p9 then
		tween.Completed:Wait();
		return true
	else
		return true
	end
end;

return v2
