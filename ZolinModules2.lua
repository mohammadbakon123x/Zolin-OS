-- ZolinOS 3.0.0: desktop + mobile. Initiator remains a separate ModuleScript.
-- System services and built-in apps are embedded below. Installed apps load by URL.
local __v3Factories, __v3Cache, __v3Loading = {}, {}, {}
local function __v3Require(name)
	if __v3Cache[name] ~= nil then return __v3Cache[name] end
	assert(not __v3Loading[name], "Circular ZolinOS component: " .. tostring(name))
	local factory = assert(__v3Factories[name], "Unknown ZolinOS component: " .. tostring(name))
	__v3Loading[name] = true
	local ok, result = pcall(factory)
	__v3Loading[name] = nil
	if not ok then error(result, 2) end
	__v3Cache[name] = result
	return result
end
-- BEGIN COMPONENT: SignalBus
__v3Factories["SignalBus"] = function()
	local SignalBus = {}
	SignalBus.__index = SignalBus
	function SignalBus.new()
		return setmetatable({listeners = {}, destroyed = false}, SignalBus)
	end
	function SignalBus:On(topic, callback)
		assert(type(topic) == "string" and type(callback) == "function", "On requires a topic and callback")
		if self.destroyed then return function() end end
		local list = self.listeners[topic]
		if not list then list = {}; self.listeners[topic] = list end
		local entry = {callback = callback, connected = true}
		table.insert(list, entry)
		return function()
			if not entry.connected then return end
			entry.connected = false
			local i = table.find(list, entry)
			if i then table.remove(list, i) end
			if #list == 0 and self.listeners[topic] == list then self.listeners[topic] = nil end
		end
	end
	function SignalBus:Emit(topic, payload)
		if self.destroyed then return end
		local list = self.listeners[topic]
		if not list then return end
		for _, entry in ipairs(table.clone(list)) do
			if entry.connected then
				local ok, err = pcall(entry.callback, payload)
				if not ok then warn("[ZolinOS event " .. topic .. "] " .. tostring(err)) end
			end
		end
	end
	function SignalBus:Destroy()
		self.destroyed = true
		for _, list in pairs(self.listeners) do for _, entry in ipairs(list) do entry.connected = false end end
		table.clear(self.listeners)
	end
	return SignalBus


end
-- END COMPONENT: SignalBus
-- BEGIN COMPONENT: Preferences
__v3Factories["Preferences"] = function()
	local HttpService = game:GetService("HttpService")
	local Preferences = {}
	Preferences.__index = Preferences
	local DEFAULTS = {
		theme = "Dark", accent = {r = 47, g = 118, b = 204}, ["display.mode"] = "Mobile",
		["notifications.dnd"] = false, ["notifications.sound"] = true,
		["notifications.style"] = "V3",
		["volume.master"] = 0.7, ["volume.media"] = 0.7, ["volume.notifications"] = 0.6,
		["volume.muted.master"] = false, ["volume.muted.media"] = false, ["volume.muted.notifications"] = false,
		["wallpaper.style"] = "Hills", ["wallpaper.pattern"] = false,
		["home.widget.clock"] = false, ["home.widget.date"] = false,
		["home.labels"] = true, ["home.iconScale"] = 1, ["home.columns"] = 0,
		["appearance.animationStyle"] = "V3",
	}
	local function copy(value)
		if type(value) ~= "table" then return value end
		local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
	end
	function Preferences.new(ctx)
		local self = setmetatable({ctx = ctx, values = copy(DEFAULTS), destroyed = false}, Preferences)
		local stored = ctx.Player:GetAttribute("ZolinV3Preferences")
		if type(stored) == "string" then
			local ok, decoded = pcall(HttpService.JSONDecode, HttpService, stored)
			if ok and type(decoded) == "table" then
				for key, value in pairs(decoded) do if type(key) == "string" then self.values[key] = value end end
			end
		end
		return self
	end
	function Preferences:Get(key, default)
		local value = self.values[key]; if value == nil then value = default end
		return copy(value)
	end
	function Preferences:Set(key, value)
		if self.destroyed or type(key) ~= "string" then return false end
		if key == "theme" and value ~= "Dark" and value ~= "Light" then return false end
		if key == "display.mode" and value ~= "Auto" and value ~= "Desktop" and value ~= "Mobile" then return false end
		if key == "appearance.animationStyle" and value ~= "V2" and value ~= "V3" then return false end
		if key == "notifications.style" and value ~= "V2" and value ~= "V3" then return false end
		if key == "home.iconScale" then
			if type(value) ~= "number" or value ~= value then return false end
			value = math.clamp(value, 0.8, 1.3)
		elseif key == "home.columns" then
			if type(value) ~= "number" or value ~= value then return false end
			value = value == 0 and 0 or math.clamp(math.floor(value), 3, 6)
		elseif key == "home.labels" or key == "home.widget.clock" or key == "home.widget.date" then
			if type(value) ~= "boolean" then return false end
		end
		if key:match("^volume%.") and not key:match("%.muted%.") and key ~= "volume.apps" then
			if type(value) ~= "number" or value ~= value then return false end
			value = math.clamp(value, 0, 1)
		end
		if key == "accent" then
			if typeof(value) == "Color3" then value = {r = math.round(value.R * 255), g = math.round(value.G * 255), b = math.round(value.B * 255)} end
			if type(value) ~= "table" then return false end
			for _, channel in ipairs({"r", "g", "b"}) do if type(value[channel]) ~= "number" or value[channel] ~= value[channel] then return false end; value[channel] = math.clamp(value[channel], 0, 255) end
		end
		if self.values[key] == value then return true end
		self.values[key] = copy(value)
		self.ctx.Bus:Emit("settings.changed", {key = key, value = copy(value)})
		self:Save()
		return true
	end
	function Preferences:Save()
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, self.values)
		if ok then self.ctx.Player:SetAttribute("ZolinV3Preferences", encoded) end
	end
	function Preferences:Reset()
		self.values = copy(DEFAULTS); self:Save()
		for key, value in pairs(self.values) do self.ctx.Bus:Emit("settings.changed", {key = key, value = copy(value)}) end
	end
	function Preferences:Destroy() self:Save(); self.destroyed = true end
	return Preferences


end
-- END COMPONENT: Preferences
-- BEGIN COMPONENT: ThemeService
__v3Factories["ThemeService"] = function()
	local ThemeService = {}
	ThemeService.__index = ThemeService

	local DEFAULT_ACCENT = Color3.fromRGB(78, 139, 222)

	local function readAccent(value)
		if typeof(value) == "Color3" then return value end
		if type(value) ~= "table" then return DEFAULT_ACCENT end
		local r, g, b = value.r or value[1], value.g or value[2], value.b or value[3]
		if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return DEFAULT_ACCENT end
		local divisor = value.r ~= nil and 255 or (math.max(r, g, b) > 1 and 255 or 1)
		return Color3.new(math.clamp(r / divisor, 0, 1), math.clamp(g / divisor, 0, 1), math.clamp(b / divisor, 0, 1))
	end

	local function palette(name, accent)
		local dark = name == "Dark"
		local result = dark and {
			Background = Color3.fromRGB(17, 20, 27), Surface = Color3.fromRGB(25, 29, 38),
			SurfaceAlt = Color3.fromRGB(34, 40, 51), Text = Color3.fromRGB(238, 242, 248),
			Muted = Color3.fromRGB(158, 170, 188), Border = Color3.fromRGB(63, 73, 89),
			Success = Color3.fromRGB(74, 201, 141), Danger = Color3.fromRGB(246, 116, 131),
			Desktop = Color3.fromRGB(15, 24, 40),
		} or {
			Background = Color3.fromRGB(242, 245, 250), Surface = Color3.fromRGB(255, 255, 255),
			SurfaceAlt = Color3.fromRGB(232, 237, 244), Text = Color3.fromRGB(24, 33, 49),
			Muted = Color3.fromRGB(96, 110, 133), Border = Color3.fromRGB(191, 202, 217),
			Success = Color3.fromRGB(20, 136, 88), Danger = Color3.fromRGB(200, 54, 76),
			Desktop = Color3.fromRGB(219, 229, 244),
		}
		result.Accent = accent
		local function linear(channel)
			return channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4
		end
		local luminance = linear(accent.R) * 0.2126 + linear(accent.G) * 0.7152 + linear(accent.B) * 0.0722
		result.AccentText = (luminance + 0.05) / 0.05 > 1.05 / (luminance + 0.05) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		result.Title = accent:Lerp(result.Surface, dark and 0.84 or 0.92)
		result.TitleText = result.Text
		return result
	end

	function ThemeService.new(ctx)
		local self = setmetatable({ctx = ctx, _bindings = {}, _subscribers = {}, _destroyed = false}, ThemeService)
		local saved = ctx.Settings and ctx.Settings:Get("theme", "Dark") or "Dark"
		self._name = tostring(saved):lower() == "light" and "Light" or "Dark"
		self._accent = readAccent(ctx.Settings and ctx.Settings:Get("accent", nil))
		self._palette = palette(self._name, self._accent)
		if ctx.Bus then
			self._settingsUnsubscribe = ctx.Bus:On("settings.changed", function(change)
				if self._destroyed or self._saving or type(change) ~= "table" then return end
				if change.key == "theme" then self:_apply(tostring(change.value):lower() == "light" and "Light" or "Dark", self._accent) end
				if change.key == "accent" then self:_apply(self._name, readAccent(change.value)) end
			end)
		end
		return self
	end

	function ThemeService:Get() return self._palette end
	function ThemeService:GetTheme() return self._name end
	function ThemeService:GetAccent() return self._accent end

	function ThemeService:_apply(name, accent)
		if self._destroyed or (self._name == name and self._accent == accent) then return end
		self._name, self._accent = name, accent
		self._palette = palette(name, accent)
		for instance, binding in pairs(self._bindings) do
			for property, token in pairs(binding.tokens) do
				local value = self._palette[token]
				if value then pcall(function() instance[property] = value end) end
			end
		end
		for callback in pairs(self._subscribers) do pcall(callback, self._palette) end
		if self.ctx.Bus then self.ctx.Bus:Emit("theme.changed", {theme = name, accent = accent, palette = self._palette}) end
	end

	function ThemeService:SetTheme(name)
		if self._destroyed then return false end
		name = tostring(name):lower()
		if name ~= "dark" and name ~= "light" then return false, "Choose Dark or Light." end
		name = name == "light" and "Light" or "Dark"
		if self.ctx.Settings then
			self._saving = true
			self.ctx.Settings:Set("theme", name)
			self._saving = false
		end
		self:_apply(name, self._accent)
		return true
	end

	function ThemeService:SetAccent(color)
		if self._destroyed or typeof(color) ~= "Color3" then return false, "Accent must be a Color3." end
		if self.ctx.Settings then
			self._saving = true
			self.ctx.Settings:Set("accent", {r = math.round(color.R * 255), g = math.round(color.G * 255), b = math.round(color.B * 255)})
			self._saving = false
		end
		self:_apply(self._name, color)
		return true
	end

	function ThemeService:Bind(instance, tokens)
		if self._destroyed or typeof(instance) ~= "Instance" then return function() end end
		local binding = self._bindings[instance]
		if not binding then
			binding = {tokens = {}}
			self._bindings[instance] = binding
			binding.connection = instance.Destroying:Connect(function()
				if binding.connection then binding.connection:Disconnect() binding.connection = nil end
				self._bindings[instance] = nil
			end)
		end
		for property, token in pairs(tokens or {}) do
			binding.tokens[property] = token
			if self._palette[token] then pcall(function() instance[property] = self._palette[token] end) end
		end
		local removed = false
		return function()
			if removed then return end
			removed = true
			local current = self._bindings[instance]
			if not current then return end
			for property, token in pairs(tokens or {}) do
				if current.tokens[property] == token then current.tokens[property] = nil end
			end
			if next(current.tokens) == nil then
				if current.connection then current.connection:Disconnect() end
				self._bindings[instance] = nil
			end
		end
	end

	function ThemeService:Subscribe(callback)
		if self._destroyed or type(callback) ~= "function" then return function() end end
		self._subscribers[callback] = true
		return function() self._subscribers[callback] = nil end
	end

	function ThemeService:Unbind(instance, properties)
		local binding = self._bindings[instance]
		if not binding then return end
		for _, property in ipairs(properties or {}) do binding.tokens[property] = nil end
		if next(binding.tokens) == nil then
			if binding.connection then binding.connection:Disconnect() end
			self._bindings[instance] = nil
		end
	end

	function ThemeService:Destroy()
		if self._destroyed then return end
		self._destroyed = true
		if self._settingsUnsubscribe then self._settingsUnsubscribe() end
		for _, binding in pairs(self._bindings) do if binding.connection then binding.connection:Disconnect() end end
		table.clear(self._bindings)
		table.clear(self._subscribers)
	end

	return ThemeService

end
-- END COMPONENT: ThemeService
-- BEGIN COMPONENT: UI
__v3Factories["UI"] = function()
	local UI = {}

	local function clamp(value)
		value = tonumber(value) or 0
		if value ~= value then value = 0 end
		return math.clamp(value, 0, 1)
	end

	function UI.new(ctx)
		local api = {}
		local theme = ctx.Theme
		local inputService = game:GetService("UserInputService")
		local tweenService = game:GetService("TweenService")
		local titleGradients = setmetatable({}, {__mode = "k"})
		local pressControllers = setmetatable({}, {__mode = "k"})
		local activePresses, sharedPressConnections = {}, {}

		function api.bind(instance, tokens)
			return theme:Bind(instance, tokens)
		end
		local function stopSharedPressInput()
			if next(activePresses) then return end
			for _, connection in ipairs(sharedPressConnections) do connection:Disconnect() end
			table.clear(sharedPressConnections)
		end
		local function beginSharedPressInput()
			if #sharedPressConnections > 0 then return end
			table.insert(sharedPressConnections, inputService.InputChanged:Connect(function(input)
				for controller in pairs(activePresses) do controller.Move(input) end
			end))
			table.insert(sharedPressConnections, inputService.InputEnded:Connect(function(input)
				local snapshot = {}; for controller in pairs(activePresses) do table.insert(snapshot, controller) end
				for _, controller in ipairs(snapshot) do controller.Release(input) end
			end))
			table.insert(sharedPressConnections, inputService.WindowFocusReleased:Connect(function()
				local snapshot = {}; for controller in pairs(activePresses) do table.insert(snapshot, controller) end
				for _, controller in ipairs(snapshot) do controller.Cancel() end
			end))
		end
		function api.pressFeedback(button)
			if typeof(button) ~= "Instance" or not button:IsA("GuiButton") then return nil end
			if pressControllers[button] then return pressControllers[button] end
			local ignored = {TrackInput = true, SliderInput = true, FillInput = true, VolumeInput = true, DismissPanel = true, DismissMenus = true, NotificationToggle = true}
			if ignored[button.Name] or button:GetAttribute("DisablePressFeedback") == true then return nil end
			local empty = button:IsA("TextButton") and button.Text == "" or button:IsA("ImageButton") and button.Image == ""
			if empty and button.BackgroundTransparency > 0.95 and button.Size.X.Scale >= 0.95 and button.Size.Y.Scale >= 0.95 then return nil end
			local controller, connections, tweens = {}, {}, {}
			local destroyed, pointer, origin, style, cancelled, releasedAt = false, nil, nil, "V3", false, -math.huge
			local layer, halo, corner, scale, target, generation
			generation = 0
			local function connect(signal, callback) table.insert(connections, signal:Connect(callback)) end
			local function visible()
				if not button.Active or not button.Interactable or button:GetAttribute("DisablePressFeedback") == true then return false end
				local ancestor = button
				while ancestor and ancestor:IsA("GuiObject") do if not ancestor.Visible then return false end; ancestor = ancestor.Parent end
				return button.Parent ~= nil
			end
			local function stopTweens()
				generation += 1
				for _, entry in ipairs(tweens) do if entry.connection then entry.connection:Disconnect() end; entry.tween:Cancel() end
				table.clear(tweens)
			end
			local function animate(object, duration, easing, properties, done)
				if not object or not object.Parent then return end
				local current = generation
				local tween = tweenService:Create(object, TweenInfo.new(duration, easing, Enum.EasingDirection.Out), properties)
				local entry = {tween = tween}; table.insert(tweens, entry)
				if done then entry.connection = tween.Completed:Connect(function(state) if state == Enum.PlaybackState.Completed and generation == current and not destroyed then done() end end) end
				tween:Play()
			end
			local function prepare()
				local host = button:FindFirstChild("IconTile")
				if not host or not host:IsA("GuiObject") then host = button end
				if not layer then
					layer = Instance.new("Frame"); layer.Name = "PressFeedbackLayer"; layer.AnchorPoint = Vector2.new(0.5, 0.5); layer.Position = UDim2.fromScale(0.5, 0.5); layer.Size = UDim2.fromScale(1, 1); layer.BorderSizePixel = 0; layer.BackgroundTransparency = 1; layer.Active = false; layer.Interactable = false
					corner = Instance.new("UICorner"); corner.Parent = layer
					halo = Instance.new("UIStroke"); halo.Name = "PressFeedbackHalo"; halo.Thickness = 1; halo.Transparency = 1; halo.Parent = layer
				end
				layer.Parent, layer.ZIndex = host, host.ZIndex + 2
				local sourceCorner = host:FindFirstChildOfClass("UICorner"); corner.CornerRadius = sourceCorner and sourceCorner.CornerRadius or UDim.new(0, 8)
				local layout = host.Parent and (host.Parent:FindFirstChildOfClass("UIListLayout") or host.Parent:FindFirstChildOfClass("UIGridLayout") or host.Parent:FindFirstChildOfClass("UITableLayout"))
				local existing = host:FindFirstChildOfClass("UIScale")
				-- Layout-owned buttons keep their original geometry; only their inner
				-- feedback plate scales. Home tiles and free-positioned image controls
				-- can scale directly without moving their surrounding hit targets.
				local nextTarget = (not layout and (not existing or existing == scale)) and host or layer
				if nextTarget ~= target or not scale or not scale.Parent then
					if scale then scale.Scale = 1; scale:Destroy() end
					target = nextTarget; scale = Instance.new("UIScale"); scale.Name = "PressFeedbackScale"; scale.Scale = 1; scale.Parent = target
				end
				if style == "V2" then
					theme:Unbind(layer, {"BackgroundColor3"}); theme:Unbind(halo, {"Color"})
					layer.BackgroundColor3, halo.Color = Color3.new(1, 1, 1), Color3.new(1, 1, 1)
				else theme:Bind(layer, {BackgroundColor3 = "Accent"}); theme:Bind(halo, {Color = "Accent"}) end
			end
			local function point(input)
				return input and input.Position and Vector2.new(input.Position.X, input.Position.Y) or button.AbsolutePosition + button.AbsoluteSize * 0.5
			end
			local function samePointer(input)
				if not pointer or not input then return input == nil end
				return input == pointer or (pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
			end
			function controller.Press(input, instant)
				if destroyed or pointer or not visible() then return false end
				cancelled = false; style = ctx.Settings and ctx.Settings:Get("appearance.animationStyle", "V3") == "V2" and "V2" or "V3"
				stopTweens(); prepare(); pointer = input or {}; origin = point(input)
				activePresses[controller] = true; beginSharedPressInput()
				button:SetAttribute("PressFeedbackPressed", true); button:SetAttribute("PressFeedbackStyle", style)
				local factor = style == "V2" and 0.91 or 0.965
				if instant then scale.Scale = factor else animate(scale, style == "V2" and 0.09 or 0.07, Enum.EasingStyle.Quad, {Scale = factor}) end
				animate(layer, 0.07, Enum.EasingStyle.Quad, {BackgroundTransparency = style == "V2" and 0.86 or 0.92})
				animate(halo, 0.07, Enum.EasingStyle.Quad, {Transparency = style == "V2" and 0.78 or 0.48})
				return true
			end
			function controller.Cancel()
				if destroyed then return end
				pointer, origin, cancelled = nil, nil, true; activePresses[controller] = nil; stopSharedPressInput(); stopTweens()
				button:SetAttribute("PressFeedbackPressed", false)
				if scale and scale.Parent then scale.Scale = 1 end
				if layer then layer.BackgroundTransparency = 1; halo.Transparency = 1 end
			end
			function controller.Move(input)
				if not pointer or destroyed then return end
				if not visible() then controller.Cancel(); return end
				if input ~= pointer and not (pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
				local position = point(input)
				local p, s = button.AbsolutePosition, button.AbsoluteSize
				if (position - origin).Magnitude > 14 or position.X < p.X - 4 or position.Y < p.Y - 4 or position.X > p.X + s.X + 4 or position.Y > p.Y + s.Y + 4 then controller.Cancel() end
			end
			function controller.Release(input)
				if destroyed or not pointer or not samePointer(input) then return false end
				pointer, origin, releasedAt = nil, nil, os.clock(); activePresses[controller] = nil; stopSharedPressInput(); stopTweens()
				button:SetAttribute("PressFeedbackPressed", false)
				if style == "V2" then animate(scale, 0.11, Enum.EasingStyle.Quad, {Scale = 1.045}, function() animate(scale, 0.16, Enum.EasingStyle.Back, {Scale = 1}) end)
				else animate(scale, 0.22, Enum.EasingStyle.Back, {Scale = 1}) end
				animate(layer, 0.25, Enum.EasingStyle.Quad, {BackgroundTransparency = 1}); animate(halo, 0.25, Enum.EasingStyle.Quad, {Transparency = 1})
				return true
			end
			function controller.GetState() return {pressed = pointer ~= nil, style = style, cancelled = cancelled, scale = scale and scale.Scale or 1} end
			function controller.Destroy()
				if destroyed then return end
				controller.Cancel(); destroyed = true
				for _, connection in ipairs(connections) do connection:Disconnect() end; table.clear(connections)
				if scale then scale:Destroy() end; if layer then layer:Destroy() end
				pressControllers[button] = nil
			end
			connect(button.InputBegan, function(input)
				local kind, key = input.UserInputType, input.KeyCode
				if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch or key == Enum.KeyCode.ButtonA or key == Enum.KeyCode.Return or key == Enum.KeyCode.Space then controller.Press(input) end
			end)
			connect(button.InputEnded, controller.Release)
			connect(button.Activated, function(input)
				if pointer then controller.Release(input)
				elseif not cancelled and os.clock() - releasedAt > 0.12 then if controller.Press(input, true) then controller.Release(input) end end
			end)
			connect(button:GetPropertyChangedSignal("Active"), function() if not button.Active then controller.Cancel() end end)
			connect(button:GetPropertyChangedSignal("Visible"), function() if not button.Visible then controller.Cancel() end end)
			connect(button.Destroying, controller.Destroy)
			pressControllers[button] = controller
			return controller
		end

		function api.new(className, parent, props)
			props = props or {}
			local object = Instance.new(className)
			local bindings = {}
			if object:IsA("GuiObject") then
				object.BorderSizePixel = 0
				object.ZIndex = parent and parent:IsA("GuiObject") and parent.ZIndex + 1 or 1
				bindings.BackgroundColor3 = "Surface"
			end
			if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
				object.Font = Enum.Font.Gotham
				object.TextSize = 14
				bindings.TextColor3 = "Text"
			end
			if object:IsA("TextLabel") or object:IsA("ImageLabel") then object.BackgroundTransparency = 1 end
			if object:IsA("TextButton") or object:IsA("ImageButton") or object:IsA("TextBox") then bindings.BackgroundColor3 = "SurfaceAlt" end
			if object:IsA("TextButton") then object.AutoButtonColor = false end
			if object:IsA("TextBox") then
				object.ClearTextOnFocus = false
				bindings.PlaceholderColor3 = "Muted"
			end
			if object:IsA("ScrollingFrame") then
				object.BackgroundTransparency = 1
				object.ScrollBarThickness = 4
				bindings.ScrollBarImageColor3 = "Muted"
			end
			for property, value in pairs(props) do
				object[property] = value
				bindings[property] = nil
			end
			if next(bindings) then theme:Bind(object, bindings) end
			object.Parent = parent
			if object:IsA("GuiButton") then api.pressFeedback(object) end
			if object:IsA("TextBox") then
				local stroke = api.bevel(object)
				local alive = true
				local focused = object.Focused:Connect(function()
					if not alive or not stroke.Parent then return end
					theme:Bind(stroke, {Color = "Accent"}); stroke.Transparency = 0.05
				end)
				local blurred = object.FocusLost:Connect(function()
					if not alive or not stroke.Parent then return end
					theme:Bind(stroke, {Color = "Border"}); stroke.Transparency = 0.35
				end)
				local cleanup
				cleanup = object.Destroying:Connect(function() alive = false; focused:Disconnect(); blurred:Disconnect(); cleanup:Disconnect() end)
			end
			return object
		end

		function api.frame(parent, props) return api.new("Frame", parent, props) end
		function api.text(parent, text, props)
			local values = table.clone(props or {})
			values.Text = tostring(text or "")
			if values.RichText == nil then values.RichText = false end
			return api.new("TextLabel", parent, values)
		end
		function api.appIcon(parent, metadata, props)
			local values = table.clone(props or {})
			local image = tostring(metadata.icon or "")
			if image == "rbxassetid://12905435514" or image == "rbxassetid://0" then image = "" end
			values.Image = image
			values.BackgroundTransparency = 1
			local icon = api.new("ImageLabel", parent, values)
			local name = tostring(metadata.name or metadata.id or "ZolinOS")
			local first = utf8.offset(name, 2) or (#name + 1)
			local letter = api.text(icon, name:sub(1, first - 1):upper(), {Name = "Monogram", Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold, TextSize = 18, BackgroundTransparency = 1})
			api.bind(letter, {TextColor3 = "Accent"})
			local function refresh() letter.Visible = image == "" or not icon.IsLoaded end
			local changed = icon:GetPropertyChangedSignal("IsLoaded"):Connect(refresh)
			icon.Destroying:Connect(function() changed:Disconnect() end)
			refresh()
			return icon, letter
		end
		function api.button(parent, text, props)
			local values = table.clone(props or {})
			values.Text = tostring(text or "")
			if values.Size == nil then values.Size = UDim2.new(1, 0, 0, 36) end
			local button = api.new("TextButton", parent, values)
			local stroke = api.bevel(button)
			local hovered, selected = false, false
			local connections = {}
			local function edge()
				if not button.Parent or not stroke.Parent then return end
				local highlighted = button.Active and (hovered or selected)
				theme:Bind(stroke, {Color = highlighted and "Accent" or "Border"})
				stroke.Transparency = highlighted and 0.1 or 0.35
			end
			table.insert(connections, button.MouseEnter:Connect(function() hovered = true; edge() end))
			table.insert(connections, button.MouseLeave:Connect(function() hovered = false; edge() end))
			table.insert(connections, button.SelectionGained:Connect(function() selected = true; edge() end))
			table.insert(connections, button.SelectionLost:Connect(function() selected = false; edge() end))
			table.insert(connections, button:GetPropertyChangedSignal("Active"):Connect(edge))
			table.insert(connections, button.Destroying:Connect(function()
				for _, connection in ipairs(connections) do connection:Disconnect() end
				table.clear(connections)
			end))
			return button
		end
		function api.scroll(parent, props)
			local values = {CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true}
			for key, value in pairs(props or {}) do values[key] = value end
			return api.new("ScrollingFrame", parent, values)
		end
		function api.list(parent, padding)
			return api.new("UIListLayout", parent, {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, padding or 6)})
		end
		function api.pad(parent, amount)
			amount = amount or 10
			return api.new("UIPadding", parent, {PaddingLeft = UDim.new(0, amount), PaddingRight = UDim.new(0, amount), PaddingTop = UDim.new(0, amount), PaddingBottom = UDim.new(0, amount)})
		end
		function api.corner(parent, radius)
			local corner = parent:FindFirstChildOfClass("UICorner")
			if not corner then corner = api.new("UICorner", parent, {Name = "ModernCorner"}) end
			corner.CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 8)
			return corner
		end
		function api.bevel(instance)
			api.corner(instance, 8)
			local stroke = instance:FindFirstChild("ModernStroke") or instance:FindFirstChild("ClassicBevel")
			if not stroke or not stroke:IsA("UIStroke") then
				stroke = api.new("UIStroke", instance, {Name = "ModernStroke", ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 0.35})
				theme:Bind(stroke, {Color = "Border"})
			end
			return stroke
		end
		-- Compatibility helper: a quiet surface tint replaces the saturated title strip.
		function api.titleGradient(instance)
			if titleGradients[instance] then return titleGradients[instance] end
			theme:Unbind(instance, {"BackgroundColor3"})
			instance.BackgroundColor3 = Color3.new(1, 1, 1)
			local gradient = api.new("UIGradient", instance, {Name = "ModernTitleGradient", Rotation = 0})
			titleGradients[instance] = gradient
			local function update(palette)
				gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, palette.Title), ColorSequenceKeypoint.new(1, palette.Surface)})
			end
			update(theme:Get())
			local unsubscribe = theme:Subscribe(update)
			local connection
			connection = gradient.Destroying:Connect(function() titleGradients[instance] = nil; unsubscribe(); if connection then connection:Disconnect() end end)
			return gradient
		end

		function api.slider(parent, options)
			options = options or {}
			local header = options.Label ~= false
			local frame = api.frame(parent, {Name = options.Name or "Slider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, header and 56 or 34)})
			local label = api.text(frame, options.Label or options.Name or "Volume", {Size = UDim2.new(1, -60, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Visible = header})
			local valueLabel = api.text(frame, "", {Position = UDim2.new(1, -60, 0, 0), Size = UDim2.fromOffset(60, 22), TextXAlignment = Enum.TextXAlignment.Right, Visible = header})
			local target = api.new("TextButton", frame, {Name = "TrackInput", Position = UDim2.fromOffset(0, header and 22 or 0), Size = UDim2.new(1, 0, 0, 34), Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Active = true, Selectable = true})
			local track = api.frame(target, {Name = "Track", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), Size = UDim2.new(1, -18, 0, 5)})
			api.bind(track, {BackgroundColor3 = "Border"})
			api.corner(track, 8)
			local fill = api.frame(track, {Name = "Fill", Size = UDim2.fromScale(0, 1)})
			api.bind(fill, {BackgroundColor3 = "Accent"})
			api.corner(fill, 8)
			local thumb = api.frame(track, {Name = "Thumb", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(18, 18)})
			api.bind(thumb, {BackgroundColor3 = "Text"})
			api.bevel(thumb)
			local controller = {Frame = frame, Label = label, ValueLabel = valueLabel}
			local value, dragging, pointer, destroyed = 0, false, nil, false
			local connections = {}
			local function display()
				fill.Size = UDim2.fromScale(value, 1)
				thumb.Position = UDim2.fromScale(value, 0.5)
				local formatted
				if type(options.Format) == "function" then local ok, result = pcall(options.Format, value) if ok then formatted = result end end
				valueLabel.Text = tostring(formatted or (tostring(math.round(value * 100)) .. "%"))
			end
			function controller.SetValue(nextValue, silent)
				if destroyed then return end
				local nextClamped = clamp(nextValue)
				local changed = math.abs(value - nextClamped) > 0.00001
				value = nextClamped
				display()
				if changed and not silent and type(options.Changed) == "function" then
					local ok, err = pcall(options.Changed, value)
					if not ok then warn("[ZolinOS Slider] " .. tostring(err)) end
				end
			end
			function controller.CancelDrag() dragging, pointer = false, nil end
			local function move(position)
				if track.AbsoluteSize.X > 0 then controller.SetValue((position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X) end
			end
			table.insert(connections, target.InputBegan:Connect(function(input)
				if destroyed then return end
				local kind = input.UserInputType
				if (kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch) and not dragging then
					dragging, pointer = true, input
					move(input.Position)
				elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft then controller.SetValue(value - 0.05)
				elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight then controller.SetValue(value + 0.05) end
			end))
			table.insert(connections, inputService.InputChanged:Connect(function(input)
				if not dragging or destroyed then return end
				if input == pointer or (pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then move(input.Position) end
			end))
			table.insert(connections, inputService.InputEnded:Connect(function(input)
				if not dragging then return end
				if input == pointer or (pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then dragging, pointer = false, nil end
			end))
			table.insert(connections, inputService.WindowFocusReleased:Connect(function() dragging, pointer = false, nil end))
			function controller.Destroy()
				if destroyed then return end
				destroyed, dragging, pointer = true, false, nil
				for _, connection in ipairs(connections) do connection:Disconnect() end
				table.clear(connections)
				frame:Destroy()
			end
			table.insert(connections, frame.Destroying:Connect(controller.Destroy))
			controller.SetValue(options.Value or 0, true)
			return frame, controller
		end

		return api
	end

	return UI

end
-- END COMPONENT: UI
-- BEGIN COMPONENT: AppBridge
__v3Factories["AppBridge"] = function()
	local AppBridge = {}
	AppBridge.__index = AppBridge
	function AppBridge.new(ctx) return setmetatable({ctx = ctx, owners = {}, endpoints = {}, destroyed = false}, AppBridge) end
	local function name(value) return type(value) == "string" and #value > 0 and #value <= 96 end
	local function directKey(id, topic) return "bridge.direct." .. tostring(#id) .. ":" .. id .. ":" .. topic end
	function AppBridge:Create(appId)
		if self.destroyed then return nil, "Bridge is closed" end
		if not name(appId) then return nil, "Invalid app id" end
		local bridge, ctx = self, self.ctx
		local owner = {alive = true, cleanup = {}, id = appId}
		local settingPrefix = "appdata." .. tostring(#appId) .. ":" .. appId .. ":"
		self.owners[owner] = true
		local api = {Id = appId, AppId = appId, Version = 3}
		local function retain(disconnect)
			table.insert(owner.cleanup, disconnect); return disconnect
		end
		function api.Notify(data)
			if not owner.alive then return nil, "App closed" end
			data = type(data) == "table" and table.clone(data) or {message = tostring(data)}
			data.appId = appId
			if type(data.actions) == "table" then
				local actions = {}
				for _, action in ipairs(data.actions) do
					if type(action) == "table" then
						local item = table.clone(action)
						if type(item.callback) == "function" then
							local callback = item.callback
							item.callback = function(...) if owner.alive then return callback(...) end end
						end
						table.insert(actions, item)
					end
				end
				data.actions = actions
			end
			return ctx.Notifications:Push(data)
		end
		function api.OpenApp(id, args) if owner.alive then return ctx.Apps:Launch(id, args) end; return false, "App closed" end
		function api.CloseApp() if owner.alive then return ctx.Apps:Close(appId) end; return false end
		function api.Publish(topic, payload)
			if not owner.alive or not name(topic) then return false end
			ctx.Bus:Emit("bridge.broadcast." .. topic, {source = appId, data = payload})
			return true
		end
		function api.Subscribe(topic, callback)
			if not owner.alive or not name(topic) or type(callback) ~= "function" then return function() end end
			return retain(ctx.Bus:On("bridge.broadcast." .. topic, function(message) if owner.alive then callback(message.data, message.source) end end))
		end
		function api.Send(target, topic, payload)
			if not owner.alive or not name(target) or not name(topic) then return false, "Invalid message" end
			if not ctx.Apps:IsRunning(target) then return false, "Target app is closed" end
			ctx.Bus:Emit(directKey(target, topic), {source = appId, data = payload})
			return true
		end
		function api.OnMessage(topic, callback)
			if not owner.alive or not name(topic) or type(callback) ~= "function" then return function() end end
			return retain(ctx.Bus:On(directKey(appId, topic), function(message) if owner.alive then callback(message.data, message.source) end end))
		end
		function api.Handle(method, callback)
			if not owner.alive or not name(method) or type(callback) ~= "function" then return function() end end
			local entry = {owner = owner, callback = callback}
			bridge.endpoints[appId] = bridge.endpoints[appId] or {}
			local methods = bridge.endpoints[appId]
			methods[method] = entry
			return retain(function() if methods[method] == entry then methods[method] = nil end end)
		end
		function api.Request(target, method, payload)
			if not owner.alive or not name(target) or not name(method) then return false, "Invalid request" end
			local methods = bridge.endpoints[target]
			local endpoint = methods and methods[method]
			if not endpoint and target == "Clock" and ctx.Clock then
				local arguments = type(payload) == "table" and payload or {}
				if method == "addTimer" then return pcall(ctx.Clock.AddTimer, ctx.Clock, arguments.name, arguments.seconds) end
				if method == "getTimers" then return pcall(ctx.Clock.GetTimers, ctx.Clock) end
				if method == "addAlarm" then return pcall(ctx.Clock.AddAlarm, ctx.Clock, arguments.name, arguments.hour, arguments.minute, arguments.repeatDaily) end
				if method == "getAlarms" then return pcall(ctx.Clock.GetAlarms, ctx.Clock) end
			end
			if not endpoint or not endpoint.owner.alive then return false, "App endpoint is unavailable" end
			return pcall(endpoint.callback, payload, appId)
		end
		function api.GetTheme() return ctx.Theme:Get(), ctx.Theme:GetTheme(), ctx.Theme:GetAccent() end
		function api.OnThemeChanged(callback)
			if not owner.alive or type(callback) ~= "function" then return function() end end
			return retain(ctx.Theme:Subscribe(function(...) if owner.alive then callback(...) end end))
		end
		function api.BindTheme(object, tokens) if owner.alive then return retain(ctx.Theme:Bind(object, tokens)) end end
		function api.RegisterSound(sound, channel)
			if not owner.alive then return false end
			owner.sounds = owner.sounds or {}
			local registered = ctx.Volume:RegisterSound(sound, channel or "media", appId)
			if registered and not owner.sounds[sound] then
				owner.sounds[sound] = true
				retain(function() ctx.Volume:UnregisterSound(sound) end)
			end
			return registered
		end
		function api.GetSetting(key, fallback) return ctx.Settings:Get(settingPrefix .. tostring(key), fallback) end
		function api.SetSetting(key, value) if owner.alive then return ctx.Settings:Set(settingPrefix .. tostring(key), value) end; return false end
		function api.SetVolume(value)
			if owner.alive and ctx.Volume.SetAppVolume then return ctx.Volume:SetAppVolume(appId, value) end
			return false
		end
		api.Bus = {Publish = api.Publish, Subscribe = api.Subscribe, Send = api.Send, OnMessage = api.OnMessage, Request = api.Request, Handle = api.Handle}
		local function destroy()
			if not owner.alive then return end
			owner.alive = false
			for _, callback in ipairs(owner.cleanup) do pcall(callback) end
			table.clear(owner.cleanup); bridge.owners[owner] = nil
		end
		return api, destroy
	end
	function AppBridge:Destroy()
		self.destroyed = true
		for owner in pairs(self.owners) do owner.alive = false; for _, callback in ipairs(owner.cleanup) do pcall(callback) end end
		table.clear(self.owners); table.clear(self.endpoints)
	end
	return AppBridge


end
-- END COMPONENT: AppBridge
-- BEGIN COMPONENT: AppManager
__v3Factories["AppManager"] = function()
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local AppManager = {}
	AppManager.__index = AppManager
	local DEFAULT_ICON = ""
	function AppManager.new(ctx)
		local self = setmetatable({ctx = ctx, registry = {}, windows = {}, closing = {}, active = nil, order = 0, history = {}, destroyed = false, connections = {}}, AppManager)
		return self
	end
	function AppManager:_cancelMotion(record, snap)
		local motion = record.motion
		if not motion then return end
		record.motion = nil
		if motion.completed then motion.completed:Disconnect() end
		for _, tween in ipairs(motion.tweens) do tween:Cancel() end
		if snap and record.frame.Parent then
			record.frame.Position, record.frame.Size = record.layoutPosition, record.layoutSize
			record.scale.Scale = 1
		end
		record.frame:SetAttribute("TransitionState", "")
	end
	function AppManager:_smallBounds(record, style, kind)
		local position, size = record.layoutPosition, record.layoutSize
		local area = self.ctx.Mode == "Mobile" and self.ctx.MobileArea or self.ctx.DesktopArea
		local width = math.max(1, area.AbsoluteSize.X * size.X.Scale + size.X.Offset)
		local height = math.max(1, area.AbsoluteSize.Y * size.Y.Scale + size.Y.Offset)
		local x = area.AbsoluteSize.X * position.X.Scale + position.X.Offset
		local y = area.AbsoluteSize.Y * position.Y.Scale + position.Y.Offset
		local scale = style == "V2" and 0.02 or (kind == "minimize" and 0.9 or 0.94)
		local center = Vector2.new(x + width * 0.5, y + height * 0.5)
		if style == "V2" and self.ctx.Shell and type(self.ctx.Shell.GetIconBounds) == "function" then
			local bounds = self.ctx.Shell:GetIconBounds(record.id, self.ctx.Mode)
			if bounds then
				center = bounds.position + bounds.size * 0.5 - area.AbsolutePosition
				scale = math.clamp(math.min(bounds.size.X / width, bounds.size.Y / height), 0.02, 0.3)
			end
		end
		local top, bottom = self:_windowInsets()
		local left = math.clamp(center.X - width * scale * 0.5, 0, math.max(0, area.AbsoluteSize.X - width * scale))
		local upper = math.clamp(center.Y - height * scale * 0.5, top, math.max(top, area.AbsoluteSize.Y - bottom - height * scale))
		return UDim2.fromOffset(left, upper), size, scale
	end
	function AppManager:_startMotion(record, kind, fromPosition, fromSize, fromScale, toPosition, toSize, toScale, after)
		self:_cancelMotion(record, false)
		local style = self.ctx.Settings:Get("appearance.animationStyle", "V3") == "V2" and "V2" or "V3"
		local exiting = kind == "close" or kind == "minimize"
		local duration = style == "V2" and (exiting and 0.25 or (kind == "maximize" and 0.4 or 0.5)) or (exiting and 0.17 or (kind == "maximize" and 0.24 or 0.22))
		local easing = style == "V2" and (exiting and Enum.EasingStyle.Quart or Enum.EasingStyle.Quint) or Enum.EasingStyle.Quint
		local info = TweenInfo.new(duration, easing, exiting and Enum.EasingDirection.In or Enum.EasingDirection.Out)
		local frame = record.frame
		local area = self.ctx.Mode == "Mobile" and self.ctx.MobileArea or self.ctx.DesktopArea
		local motion = {kind = kind, exiting = exiting, layoutPosition = record.layoutPosition, layoutSize = record.layoutSize, mode = self.ctx.Mode, areaSize = area.AbsoluteSize, areaPosition = area.AbsolutePosition, tweens = {}}
		record.motion = motion
		frame.Position, frame.Size, frame.Visible, record.scale.Scale = fromPosition, fromSize, true, fromScale
		frame:SetAttribute("TransitionStyle", style); frame:SetAttribute("TransitionState", kind)
		local geometry = TweenService:Create(frame, info, {Position = toPosition, Size = toSize})
		local zoom = TweenService:Create(record.scale, info, {Scale = toScale})
		motion.tweens = {geometry, zoom}
		motion.completed = geometry.Completed:Connect(function(state)
			if record.motion ~= motion or state ~= Enum.PlaybackState.Completed then return end
			record.motion = nil
			motion.completed:Disconnect()
			zoom:Cancel()
			frame.Position, frame.Size, record.scale.Scale = toPosition, toSize, toScale
			frame:SetAttribute("TransitionState", "")
			if after then after() end
		end)
		geometry:Play(); zoom:Play()
	end
	function AppManager:_enter(record, kind, fromPosition, fromSize, fromScale)
		if record.closed then return end
		if not fromPosition then
			local style = self.ctx.Settings:Get("appearance.animationStyle", "V3")
			fromPosition, fromSize, fromScale = self:_smallBounds(record, style, kind)
		end
		self:_startMotion(record, kind, fromPosition, fromSize, fromScale, record.layoutPosition, record.layoutSize, 1)
	end
	function AppManager:_dispose(record, alreadyDestroying)
		if record.disposed then return end
		record.disposed = true
		self:_cancelMotion(record, false)
		if record.closingDestroyConnection then record.closingDestroyConnection:Disconnect(); record.closingDestroyConnection = nil end
		if record.controller then
			if type(record.controller) == "function" then pcall(record.controller)
			elseif type(record.controller) == "table" and type(record.controller.Destroy) == "function" then pcall(record.controller.Destroy, record.controller) end
			record.controller = nil
		end
		if record.destroyApi then record.destroyApi(); record.destroyApi = nil end
		if not alreadyDestroying then record.frame:Destroy() end
		if self.closing[record.id] == record then self.closing[record.id] = nil end
	end
	function AppManager:Register(metadata)
		assert(type(metadata) == "table" and type(metadata.id or metadata.name) == "string", "App id required")
		local id = metadata.id or metadata.name
		local previous = self.registry[id]
		if previous and previous.builtin and not metadata.builtin then return false end
		local item = table.clone(metadata)
		item.id, item.name, item.icon = id, item.name or id, item.icon or DEFAULT_ICON
		if not item.builtin then item.disabled = self.ctx.Settings:Get("apps." .. id .. ".disabled", item.disabled == true) end
		item.description, item.version = item.description or "", item.version or "3.0.0"
		item.enabled, item.isSystem = item.disabled ~= true, item.system == true
		if item.hiddenFromHome == nil then
			item.hiddenFromHome = item.isSystem and id ~= "Settings" and id ~= "ZolinInstaller"
		else
			item.hiddenFromHome = item.hiddenFromHome == true
		end
		self.registry[id] = item
		local appData = self.ctx.Gui.AppData:FindFirstChild(id)
		if not appData then appData = Instance.new("Folder"); appData.Name = id; appData.Parent = self.ctx.Gui.AppData end
		for key, value in pairs({name = item.name, icon = item.icon, description = item.description, version = item.version, enabled = item.enabled, isSystem = item.isSystem, hiddenFromHome = item.hiddenFromHome}) do
			local entry = appData:FindFirstChild(key)
			if not entry then entry = Instance.new(type(value) == "boolean" and "BoolValue" or "StringValue"); entry.Name = key; entry.Parent = appData end
			if entry:IsA("ValueBase") then pcall(function() entry.Value = value end) end
		end
		self.ctx.Bus:Emit("apps.changed", {event = "registered", id = id})
		return true
	end
	function AppManager:SetEnabled(id, enabled)
		local metadata = self.registry[id]
		if not metadata or metadata.builtin then return false end
		metadata.disabled = not enabled
		self.ctx.Settings:Set("apps." .. id .. ".disabled", not enabled)
		if not enabled then self:Close(id) end
		self:Register(metadata)
		return true
	end
	function AppManager:Unregister(id)
		local meta = self.registry[id]
		if not meta or meta.builtin then return false end
		self:Close(id); self.registry[id] = nil
		local data = self.ctx.Gui.AppData:FindFirstChild(id); if data then data:Destroy() end
		self.ctx.Bus:Emit("apps.changed", {event = "unregistered", id = id})
		return true
	end
	function AppManager:GetMetadata(id) local value = self.registry[id]; return value and table.clone(value) end
	function AppManager:List()
		local result = {}
		for _, item in pairs(self.registry) do table.insert(result, table.clone(item)) end
		table.sort(result, function(a, b) return a.name:lower() < b.name:lower() end)
		return result
	end
	function AppManager:GetRunning()
		local result = {}
		for id, record in pairs(self.windows) do
			if not record.closed then
				local meta = self.registry[id] or {}
				table.insert(result, {id = id, name = meta.name or id, icon = meta.icon or DEFAULT_ICON,
					state = record.loading and "Loading" or (record.minimized and "Minimized" or (self.active == id and "Active" or "Background")),
					window = record.frame, startedAt = record.startedAt, source = meta.source})
			end
		end
		table.sort(result, function(a, b) return a.name:lower() < b.name:lower() end)
		return result
	end
	function AppManager:GetActive() return self.active end
	function AppManager:IsRunning(id) return self.windows[id] ~= nil and not self.windows[id].closed end
	function AppManager:Subscribe(callback) return self.ctx.Bus:On("apps.changed", callback) end
	function AppManager:GetHistory()
		local result = {}; for _, row in pairs(self.history) do table.insert(result, table.clone(row)) end
		table.sort(result, function(a, b) if a.lastUsed == b.lastUsed then return a.name < b.name end; return a.lastUsed > b.lastUsed end)
		return result
	end
	function AppManager:_record(id, launched)
		local item = self.history[id]
		if not item then item = {id = id, name = id, launches = 0}; self.history[id] = item end
		if launched then item.launches += 1 end
		item.lastUsed = os.time()
	end
	function AppManager:_windowInsets()
		local area = self.ctx.Mode == "Mobile" and self.ctx.MobileArea or self.ctx.DesktopArea
		local height = math.max(1, area.AbsoluteSize.Y)
		local insets = self.ctx.WindowInsets or {}
		local top = tonumber(insets.Top) or 0
		local bottom = tonumber(insets.Bottom) or 0
		if top ~= top then top = 0 end
		if bottom ~= bottom then bottom = 0 end
		top = math.clamp(top, 0, height - 1)
		bottom = math.clamp(bottom, 0, height - top - 1)
		return top, bottom
	end
	function AppManager:_workSize()
		local area = self.ctx.Mode == "Mobile" and self.ctx.MobileArea or self.ctx.DesktopArea
		local top, bottom = self:_windowInsets()
		return Vector2.new(math.max(1, area.AbsoluteSize.X), math.max(1, area.AbsoluteSize.Y - top - bottom))
	end
	function AppManager:_layout(record)
		if record.closed then return end
		local mobile = self.ctx.Mode == "Mobile"
		local top, bottom = self:_windowInsets()
		local position, size, visible
		record.frame.Parent = mobile and self.ctx.MobileApplications or self.ctx.DesktopApplications
		record.title.Visible = not mobile
		record.grip.Visible = not mobile and not record.maximized
		if record.corner then record.corner.CornerRadius = UDim.new(0, (mobile or record.maximized) and 0 or 20) end
		if mobile then
			position, size = UDim2.fromOffset(0, top), UDim2.new(1, 0, 1, -top - bottom)
			record.ui.Position, record.ui.Size = UDim2.new(), UDim2.fromScale(1, 1)
			visible = not record.minimized and self.active == record.id
		else
			local available = self:_workSize()
			local w = math.clamp(record.rect.w, math.min(340, available.X), available.X)
			local h = math.clamp(record.rect.h, math.min(260, available.Y), available.Y)
			record.rect.w, record.rect.h = w, h
			record.rect.x = math.clamp(record.rect.x, 0, math.max(0, available.X - w))
			record.rect.y = math.clamp(record.rect.y, 0, math.max(0, available.Y - h))
			if record.maximized then
				position, size = UDim2.fromOffset(0, top), UDim2.new(1, 0, 1, -top - bottom)
			else
				position, size = UDim2.fromOffset(record.rect.x, record.rect.y + top), UDim2.fromOffset(w, h)
			end
			record.ui.Position, record.ui.Size = UDim2.fromOffset(4, 49), UDim2.new(1, -8, 1, -53)
			visible = not record.minimized
		end
		local area = mobile and self.ctx.MobileArea or self.ctx.DesktopArea
		local motion = record.motion
		local preserve = motion and motion.mode == self.ctx.Mode and motion.layoutPosition == position and motion.layoutSize == size and motion.areaSize == area.AbsoluteSize and motion.areaPosition == area.AbsolutePosition
		record.layoutPosition, record.layoutSize = position, size
		if not preserve then
			self:_cancelMotion(record, false)
			record.frame.Position, record.frame.Size = position, size
			record.scale.Scale = 1
		end
		record.frame.Visible = visible or (preserve and motion.exiting) or false
		local focused = self.active == record.id
		self.ctx.UI.bind(record.title, {BackgroundColor3 = focused and "Surface" or "SurfaceAlt"})
		self.ctx.UI.bind(record.caption, {TextColor3 = "Text"})
	end
	function AppManager:SetMode()
		local closing = {}; for _, record in pairs(self.closing) do table.insert(closing, record) end
		for _, record in ipairs(closing) do self:_dispose(record) end
		for _, record in pairs(self.windows) do if record.cancelDrag then record.cancelDrag() end; self:_layout(record) end
		self.ctx.Bus:Emit("apps.changed", {event = "mode", mode = self.ctx.Mode})
	end
	function AppManager:Resize()
		local closing = {}; for _, record in pairs(self.closing) do table.insert(closing, record) end
		for _, record in ipairs(closing) do self:_dispose(record) end
		for _, record in pairs(self.windows) do self:_layout(record) end
	end
	function AppManager:Focus(id)
		local record = self.windows[id]
		if not record or record.closed then return false, "App is closed" end
		local restoring = record.minimized or not record.frame.Visible
		local fromPosition, fromSize, fromScale
		if restoring and record.motion and record.frame.Visible then fromPosition, fromSize, fromScale = record.frame.Position, record.frame.Size, record.scale.Scale end
		if restoring then self:_cancelMotion(record, false) end
		record.minimized = false; self.active = id
		self.order += 1
		if self.order > 4500 then
			local ordered = {}; for _, r in pairs(self.windows) do table.insert(ordered, r) end
			table.sort(ordered, function(a, b) return a.frame.ZIndex < b.frame.ZIndex end)
			for index, r in ipairs(ordered) do r.frame.ZIndex = 20 + index end
			self.order = 30 + #ordered
		end
		record.frame.ZIndex = 20 + self.order
		for _, other in pairs(self.windows) do self:_layout(other) end
		if restoring then self:_enter(record, "restore", fromPosition, fromSize, fromScale) end
		self:_record(id, false)
		self.ctx.Bus:Emit("apps.changed", {event = "focused", id = id})
		return true
	end
	function AppManager:_nextActive()
		local winner
		for _, record in pairs(self.windows) do
			if not record.closed and not record.minimized and (not winner or record.frame.ZIndex > winner.frame.ZIndex) then winner = record end
		end
		self.active = winner and winner.id or nil
		for _, record in pairs(self.windows) do self:_layout(record) end
	end
	function AppManager:Minimize(id)
		local record = self.windows[id]
		if not record or record.closed then return false end
		if record.minimized then return true end
		if record.cancelDrag then record.cancelDrag() end
		local wasVisible = record.frame.Visible
		local fromPosition, fromSize, fromScale = record.frame.Position, record.frame.Size, record.scale.Scale
		self:_cancelMotion(record, false)
		record.minimized = true
		if self.active == id then self.active = nil; self:_nextActive() else self:_layout(record) end
		if wasVisible then
			local style = self.ctx.Settings:Get("appearance.animationStyle", "V3")
			local toPosition, toSize, toScale = self:_smallBounds(record, style, "minimize")
			self:_startMotion(record, "minimize", fromPosition, fromSize, fromScale, toPosition, toSize, toScale, function()
				if record.closed then return end
				record.frame.Visible = false
				record.frame.Position, record.frame.Size, record.scale.Scale = record.layoutPosition, record.layoutSize, 1
			end)
		end
		self.ctx.Bus:Emit("apps.changed", {event = "minimized", id = id})
		return true
	end
	function AppManager:ToggleMaximize(id)
		local record = self.windows[id]
		if not record or record.closed or self.ctx.Mode == "Mobile" then return false end
		if record.cancelDrag then record.cancelDrag() end
		local fromPosition, fromSize, fromScale = record.frame.Position, record.frame.Size, record.scale.Scale
		self:_cancelMotion(record, false)
		record.maximized = not record.maximized; self:_layout(record)
		self:_startMotion(record, "maximize", fromPosition, fromSize, fromScale, record.layoutPosition, record.layoutSize, 1)
		self.ctx.Bus:Emit("apps.changed", {event = "maximized", id = id})
		return true
	end
	function AppManager:Close(id, alreadyDestroying, immediate)
		local record = self.windows[id]
		if not record or record.closed then return false end
		record.closed = true; self.windows[id] = nil
		if record.loadThread and record.loadThread ~= coroutine.running() and coroutine.status(record.loadThread) ~= "dead" then pcall(task.cancel, record.loadThread) end
		for _, connection in ipairs(record.connections) do connection:Disconnect() end
		for _, object in ipairs(record.frame:GetDescendants()) do if object:IsA("Sound") then object:Stop() end end
		if record.destroyApi then record.destroyApi(); record.destroyApi = nil end
		local wasVisible = record.frame.Visible
		local fromPosition, fromSize, fromScale = record.frame.Position, record.frame.Size, record.scale.Scale
		self:_cancelMotion(record, false)
		if alreadyDestroying or immediate or self.destroyed or not wasVisible or not record.frame.Parent then self:_dispose(record, alreadyDestroying)
		else
			self.closing[id] = record
			record.frame.Name = id .. "_Closing"
			record.frame:SetAttribute("ClosingAppId", id)
			record.closingDestroyConnection = record.frame.Destroying:Connect(function() self:_dispose(record, true) end)
			local style = self.ctx.Settings:Get("appearance.animationStyle", "V3")
			local toPosition, toSize, toScale = self:_smallBounds(record, style, "close")
			self:_startMotion(record, "close", fromPosition, fromSize, fromScale, toPosition, toSize, toScale, function() self:_dispose(record) end)
		end
		if self.active == id then self.active = nil; self:_nextActive() end
		self.ctx.Bus:Emit("apps.changed", {event = "closed", id = id})
		return true
	end
	function AppManager:_makeWindow(meta)
		local ctx, UI = self.ctx, self.ctx.UI
		local size = self:_workSize()
		local count = #self:GetRunning()
		local rect = {x = 36 + (count % 5) * 26, y = 30 + (count % 5) * 24, w = math.min(800, size.X * 0.8), h = math.min(570, size.Y * 0.82)}
		local frame = UI.frame(ctx.DesktopApplications, {Name = meta.id, BackgroundTransparency = 0, Active = true, ClipsDescendants = true})
		local scale = UI.new("UIScale", frame, {Name = "TransitionScale", Scale = 1})
		UI.bevel(frame)
		local corner = frame:FindFirstChildOfClass("UICorner")
		if corner then corner.CornerRadius = UDim.new(0, 20) end
		local title = UI.frame(frame, {Name = "Tilebar", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 42), Active = true})
		local icon = UI.appIcon(title, meta, {Name = "AppIcon", Position = UDim2.fromOffset(12, 9), Size = UDim2.fromOffset(24, 24)})
		UI.bind(icon, {ImageColor3 = "Accent"})
		local caption = UI.text(title, meta.name, {Name = "AppName", Font = Enum.Font.GothamMedium, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -176, 1, 0)})
		local function control(name, text, offset)
			local button = UI.button(title, text, {Name = name, Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, offset, 0, 5), TextSize = 17})
			local buttonCorner = button:FindFirstChildOfClass("UICorner")
			if buttonCorner then buttonCorner.CornerRadius = UDim.new(1, 0) end
			return button
		end
		local minimize = control("Min", "–", -116)
		local maximize = control("Max", "□", -78)
		local close = control("Exit", "×", -40)
		local ui = UI.frame(frame, {Name = "UI", ClipsDescendants = true})
		local grip = UI.button(frame, "//", {Name = "ResizeGrip", Position = UDim2.new(1, -21, 1, -21), Size = UDim2.fromOffset(18, 18), TextSize = 12, ZIndex = 50})
		local record = {id = meta.id, frame = frame, ui = ui, title = title, caption = caption, grip = grip, rect = rect,
			corner = corner, scale = scale, startedAt = os.time(), connections = {}, closed = false, maximized = false, minimized = false, loading = true}
		local function connect(signal, callback) table.insert(record.connections, signal:Connect(callback)) end
		connect(minimize.Activated, function() self:Minimize(meta.id) end)
		connect(maximize.Activated, function() self:ToggleMaximize(meta.id) end)
		connect(close.Activated, function() self:Close(meta.id) end)
		connect(frame.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if self.active ~= meta.id then self:Focus(meta.id) end
			end
		end)
		local drag, lastTap = nil, 0
		record.cancelDrag = function() drag = nil end
		connect(UserInputService.WindowFocusReleased, record.cancelDrag)
		local function begin(input, kind)
			if ctx.Mode ~= "Desktop" or record.closed then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			self:_cancelMotion(record, true)
			self:Focus(meta.id)
			if kind == "move" then
				local localX = input.Position.X - title.AbsolutePosition.X
				if localX > title.AbsoluteSize.X - 124 then return end
				if os.clock() - lastTap < 0.3 then self:ToggleMaximize(meta.id); lastTap = 0; return end
				lastTap = os.clock()
			end
			if record.maximized then return end
			drag = {input = input, kind = kind, origin = Vector2.new(input.Position.X, input.Position.Y), rect = table.clone(record.rect)}
		end
		connect(title.InputBegan, function(input) begin(input, "move") end)
		connect(grip.InputBegan, function(input) begin(input, "resize") end)
		connect(UserInputService.InputChanged, function(input)
			if not drag or record.closed then return end
			if ctx.Mode ~= "Desktop" or record.minimized or record.maximized then drag = nil; return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= drag.input then return end
			local delta = Vector2.new(input.Position.X, input.Position.Y) - drag.origin
			if drag.kind == "move" then record.rect.x = drag.rect.x + delta.X; record.rect.y = drag.rect.y + delta.Y
			else record.rect.w = drag.rect.w + delta.X; record.rect.h = drag.rect.h + delta.Y end
			self:_layout(record)
		end)
		connect(UserInputService.InputEnded, function(input)
			if drag and (input == drag.input or input.UserInputType == Enum.UserInputType.MouseButton1) then drag = nil end
		end)
		connect(frame.Destroying, function() self:Close(meta.id, true) end)
		return record
	end
	function AppManager:Launch(id, args)
		if self.destroyed then return false, "Desktop is closed" end
		if self.closing[id] then self:_dispose(self.closing[id]) end
		if self:IsRunning(id) then
			self:Focus(id)
			local controller = self.windows[id].controller
			if type(args) == "table" and type(controller) == "table" then
				if args.section and type(controller.Navigate) == "function" then pcall(controller.Navigate, args.section) end
				if args.tab and type(controller.SelectTab) == "function" then pcall(controller.SelectTab, args.tab) end
			end
			return true
		end
		local meta = self.registry[id]
		if not meta then return false, "App is not installed: " .. tostring(id) end
		if meta.disabled then return false, "App is disabled" end
		local record = self:_makeWindow(meta)
		self.windows[id] = record
		self:_record(id, true)
		self:Focus(id)
		local api, destroyApi = self.ctx.Bridge:Create(id)
		record.api, record.destroyApi = api, destroyApi
		local loading = self.ctx.UI.text(record.ui, "Opening " .. meta.name .. "...", {Name = "Loading", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center})
		self:_enter(record, "open")
		self.ctx.Bus:Emit("apps.changed", {event = "launched", id = id})
		record.loadThread = task.spawn(function()
			local ok, result = xpcall(function()
				if not meta.render then error("App has no renderer") end
				loading:Destroy()
				return meta.render(record.ui, type(args) == "table" and args or {}, record.frame, api, record)
			end, debug.traceback)
			if record.closed then
				if ok and type(result) == "function" then pcall(result)
				elseif ok and type(result) == "table" and type(result.Destroy) == "function" then pcall(result.Destroy, result) end
				return
			end
			record.loading = false
			if ok then record.controller = result
			else
				warn("[ZolinOS app " .. id .. "] " .. tostring(result))
				record.ui:Destroy()
				record.ui = self.ctx.UI.frame(record.frame, {Name = "UI", ClipsDescendants = true})
				self:_layout(record)
				local errorPanel = self.ctx.UI.frame(record.ui, {Name = "AppError", Size = UDim2.fromScale(1, 1)})
				self.ctx.UI.text(errorPanel, meta.name .. " could not open", {Position = UDim2.fromOffset(18, 20), Size = UDim2.new(1, -36, 0, 30), TextSize = 21, Font = Enum.Font.GothamBold})
				local detail = tostring(result):match("^[^\n]+") or "Unexpected app error"
				self.ctx.UI.text(errorPanel, detail, {Position = UDim2.fromOffset(18, 60), Size = UDim2.new(1, -36, 1, -145), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top})
				local retry = self.ctx.UI.button(errorPanel, "Try again", {Position = UDim2.new(0, 18, 1, -60), Size = UDim2.fromOffset(130, 36)})
				table.insert(record.connections, retry.Activated:Connect(function() self:Close(id); self:Launch(id, args) end))
				if self.ctx.Notifications then self.ctx.Notifications:Push({appId = id, title = meta.name, message = "The application could not open. Open its window for details."}) end
			end
			self.ctx.Bus:Emit("apps.changed", {event = ok and "ready" or "error", id = id})
		end)
		return true
	end
	function AppManager:Destroy()
		if self.destroyed then return end
		self.destroyed = true
		local ids = {}; for id in pairs(self.windows) do table.insert(ids, id) end
		for _, id in ipairs(ids) do self:Close(id) end
		local closing = {}; for _, record in pairs(self.closing) do table.insert(closing, record) end
		for _, record in ipairs(closing) do self:_dispose(record) end
		for _, connection in ipairs(self.connections) do connection:Disconnect() end
		table.clear(self.registry)
	end
	return AppManager


end
-- END COMPONENT: AppManager
-- BEGIN COMPONENT: ExternalApps
__v3Factories["ExternalApps"] = function()
	local ExternalApps = {}
	ExternalApps.__index = ExternalApps
	local function stringValue(parent, name, fallback)
		local item = parent and parent:FindFirstChild(name)
		return item and item:IsA("StringValue") and item.Value ~= "" and item.Value or fallback
	end
	local function idForTemplate(template)
		return template:GetAttribute("AppId") or template.Name
	end
	function ExternalApps.new(ctx)
		local self = setmetatable({ctx = ctx, connections = {}, appSources = ctx.RootFolder:FindFirstChild("AppSources"), destroyed = false, refreshing = false}, ExternalApps)
		local queued = false
		local function schedule()
			if queued or self.destroyed then return end
			queued = true
			task.defer(function() queued = false; if not self.destroyed then self:Refresh() end end)
		end
		for _, folder in ipairs({ctx.Gui.ReplicatedWindow, ctx.Gui.ReplicatedWindow_Sys, ctx.Gui.__Zolin.__AppsLaunchArgFolder}) do
			table.insert(self.connections, folder.ChildAdded:Connect(schedule))
			table.insert(self.connections, folder.ChildRemoved:Connect(schedule))
		end
		return self
	end
	function ExternalApps:_cloneTemplate(template, ui, window)
		local oldUI = template and template:FindFirstChild("UI")
		if oldUI then
			for _, child in ipairs(oldUI:GetChildren()) do child:Clone().Parent = ui end
		end
		if template then
			for _, child in ipairs(template:GetChildren()) do
				if child.Name ~= "UI" and child.Name ~= "PreviewAppInfoZL" then
					local clone = child:Clone()
					if clone:IsA("GuiObject") then clone.Visible = false end
					clone.Parent = window
				end
			end
		end
		return window
	end
	function ExternalApps:_theme(ui)
		local function apply(object)
			if object:IsA("GuiButton") and self.ctx.UI.pressFeedback then
				local visibleControl = object.BackgroundTransparency < 0.95
					or (object:IsA("TextButton") and object.Text ~= "")
					or (object:IsA("ImageButton") and object.Image ~= "")
				if visibleControl then self.ctx.UI.pressFeedback(object) end
			end
			if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
				self.ctx.Theme:Bind(object, {TextColor3 = "Text"})
			end
			if object:IsA("GuiObject") and not object:IsA("ImageLabel") and not object:IsA("ImageButton") and object.BackgroundTransparency < 0.95 then
				self.ctx.Theme:Bind(object, {BackgroundColor3 = object:GetAttribute("ZolinBackgroundToken") or (object:IsA("TextButton") and "SurfaceAlt" or "Surface")})
			end
		end
		for _, item in ipairs(ui:GetDescendants()) do apply(item) end
		local connection = ui.DescendantAdded:Connect(apply)
		return function() connection:Disconnect() end
	end
	function ExternalApps:_executeRemote(url, api, ui, args, window)
		if type(self.ctx.SourceLoader) == "function" then return self.ctx.SourceLoader(url, api, ui, args, window) end
		local fetch = self.ctx.FetchSource or function(target) return game:HttpGet(target, true) end
		local okFetch, source = pcall(fetch, url)
		if not okFetch or type(source) ~= "string" then error("Could not download app source: " .. tostring(source)) end
		local compiler = self.ctx.CompileSource or loadstring
		if type(compiler) ~= "function" then error("This Roblox client does not expose loadstring. Use a compatible runtime or provide CompileSource.") end
		local okCompile, chunk = pcall(compiler, source, "@" .. url)
		if not okCompile or type(chunk) ~= "function" then error("App source did not compile: " .. tostring(chunk)) end
		local okRun, renderer = pcall(chunk)
		if not okRun then error("App source failed while loading: " .. tostring(renderer)) end
		return renderer
	end
	function ExternalApps:_render(meta, ui, args, window, api, record)
		local rendererWindow = self:_cloneTemplate(meta.template, ui, window)
		local stopTheme = self:_theme(ui)
		local apiValue = Instance.new("BindableFunction")
		apiValue.Name = "ZolinAPI"; apiValue.OnInvoke = function() return api end; apiValue.Parent = window
		args = table.clone(args); args.ZolinOS = api
		local source = meta.module
		local key = meta.template and meta.template:GetAttribute("SourceModule") or meta.sourceKey or meta.id
		local embedded = self.ctx.BundledSources and self.ctx.BundledSources[key]
		local renderer
		if meta.source and meta.source:match("^https?://") then renderer = self:_executeRemote(meta.source, api, ui, args, rendererWindow)
		elseif embedded then renderer = embedded.Load()
		elseif source then renderer = require(source)
		else
			local authored = false
			for _, scriptObject in ipairs(window:GetDescendants()) do
				if scriptObject:IsA("LocalScript") and scriptObject:GetAttribute("V3OriginallyEnabled") == true then scriptObject.Enabled = true; authored = true end
			end
			if not authored then stopTheme(); error("No app renderer is installed for " .. meta.name) end
			return {Destroy = stopTheme}
		end
		if record.closed then stopTheme(); return end
		local result
		local ok, err = xpcall(function()
			if type(renderer) == "function" then result = renderer(ui, args, rendererWindow, api)
			elseif type(renderer) == "table" and type(renderer.Mount) == "function" then result = renderer.Mount(self.ctx, ui, args, rendererWindow, api)
			elseif type(renderer) == "table" and type(renderer.Init) == "function" then result = renderer.Init(ui, args, rendererWindow, api)
			elseif renderer == nil then return
			else error("App renderer must return a function or a table with Init/Mount") end
		end, debug.traceback)
		if not ok then stopTheme(); error(err) end
		local cleaned = false
		return {Destroy = function()
			if cleaned then return end; cleaned = true
			stopTheme()
			if type(result) == "function" then pcall(result)
			elseif type(result) == "table" and type(result.Destroy) == "function" then pcall(result.Destroy, result) end
			-- Preserve editable data/playlist changes across closing and reopening.
			if meta.template and meta.template.Parent then
				for _, child in ipairs(rendererWindow:GetChildren()) do
					if child:IsA("Folder") and (child.Name == "Data" or child.Name:match("Data$")) then
						local old = meta.template:FindFirstChild(child.Name); if old then old:Destroy() end
						child:Clone().Parent = meta.template
					end
				end
			end
		end}
	end
	function ExternalApps:Refresh()
		if self.refreshing or self.destroyed then return end
		self.refreshing = true
		local seen = {}
		for _, folder in ipairs({self.ctx.Gui.ReplicatedWindow, self.ctx.Gui.ReplicatedWindow_Sys}) do
			for _, template in ipairs(folder:GetChildren()) do
				if (template:IsA("Frame") or template:IsA("Folder")) and template.Name ~= "ExampleWindow" and template.Name ~= "ExampleWindowV2" and template:GetAttribute("HiddenApp") ~= true then
					local id = idForTemplate(template)
					seen[id] = true
					local existing = self.ctx.Apps:GetMetadata(id)
					if (not existing or not existing.builtin) and not self.ctx.Settings:Get("apps." .. id .. ".uninstalled", false) then
						local data = template:FindFirstChild("Data")
						local preview = template:FindFirstChild("PreviewAppInfoZL")
						local image = preview and preview:FindFirstChildWhichIsA("ImageLabel")
						local entry = self.ctx.Gui.__Zolin.__AppsLaunchArgFolder:FindFirstChild(template.Name) or self.ctx.Gui.__Zolin.__AppsLaunchArgFolder:FindFirstChild(id)
						local source = self.ctx.Settings:Get("apps." .. id .. ".sourceURL", "")
						if source == "" then source = stringValue(self.ctx.Gui.__Zolin.__AppsLaunchArgFolder, entry and entry.Name or "", template:GetAttribute("SourceURL") or "") end
						local storedVersion = self.ctx.Settings:Get("apps." .. id .. ".version", "")
						local meta = {id = id, name = template:GetAttribute("DisplayName") or id,
							icon = stringValue(data, "Icon", image and image.Image or nil), description = stringValue(data, "Description", "Imported application"),
							version = storedVersion ~= "" and storedVersion or stringValue(data, "Version", "1.0"), template = template, source = source,
							system = template:GetAttribute("SystemApp") == true, hiddenFromHome = template:GetAttribute("HiddenFromHome")}
						meta.render = function(ui, args, window, api, record) return self:_render(meta, ui, args, window, api, record) end
						self.ctx.Apps:Register(meta)
					end
				end
			end
		end
		local remove = {}
		for _, metadata in ipairs(self.ctx.Apps:List()) do
			if not metadata.builtin and metadata.template and not metadata.template.Parent then table.insert(remove, metadata.id) end
		end
		for _, id in ipairs(remove) do self.ctx.Apps:Unregister(id) end
		self.refreshing = false
	end
	function ExternalApps:SetSourceURL(id, url, version)
		if type(id) ~= "string" or type(url) ~= "string" or not url:match("^https?://") then return false, "A valid app id and HTTP source URL are required" end
		local meta = self.ctx.Apps:GetMetadata(id)
		if not meta or meta.builtin then return false, "This app cannot use compatibility mode" end
		local launchArgs = self.ctx.Gui.__Zolin.__AppsLaunchArgFolder
		local entry = launchArgs:FindFirstChild(id) or (meta.template and launchArgs:FindFirstChild(meta.template.Name))
		if not entry then entry = Instance.new("StringValue"); entry.Name = id; entry.Parent = launchArgs end
		entry.Value = url
		if meta.template then meta.template:SetAttribute("SourceURL", url) end
		self.ctx.Settings:Set("apps." .. id .. ".sourceURL", url)
		if type(version) == "string" and version ~= "" then
			self.ctx.Settings:Set("apps." .. id .. ".version", version)
			local data = meta.template and meta.template:FindFirstChild("Data")
			local versionValue = data and data:FindFirstChild("Version")
			if versionValue and versionValue:IsA("StringValue") then versionValue.Value = version end
			meta.version = version
		end
		meta.source = url
		self.ctx.Apps:Register(meta)
		self:Refresh()
		return true
	end
	function ExternalApps:InstallModule(id, source, metadata)
		if not source or not source:IsA("ModuleScript") then return false, "Choose a ModuleScript" end
		local clone = source:Clone(); clone.Name = id; clone:SetAttribute("AppId", id)
		for key, value in pairs(metadata or {}) do if type(value) == "string" then clone:SetAttribute(key, value) end end
		local old = self.appSources:FindFirstChild(id); if old then old:Destroy() end
		clone.Parent = self.appSources; self:Refresh()
		return true
	end
	function ExternalApps:Destroy()
		self.destroyed = true
		for _, connection in ipairs(self.connections) do connection:Disconnect() end
	end
	return ExternalApps


end
-- END COMPONENT: ExternalApps
-- BEGIN COMPONENT: Shell
__v3Factories["Shell"] = function()
	-- V2 tablet skin with procedural wallpapers and V3 services.
	local Shell = {}
	Shell.__index = Shell
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local SURFACE_Z, HOME_Z, MENU_Z, STATUS_Z, NAV_Z = 1, 4, 8500, 9900, 10000

	local function monogram(name)
		name = tostring(name or "?")
		local ok, boundary = pcall(utf8.offset, name, 2)
		return (ok and name:sub(1, (boundary or #name + 1) - 1) or "?"):upper()
	end
	local function inRect(point, object)
		if not object or not object.Parent or not object.Visible then return false end
		local p, s = object.AbsolutePosition, object.AbsoluteSize
		return point.X >= p.X and point.Y >= p.Y and point.X <= p.X + s.X and point.Y <= p.Y + s.Y
	end
	local function minimized(app) return tostring(app.state or ""):lower() == "minimized" end
	local function wallpaperStyle(style) return ({Hills = "Aurora", Blue = "Bloom", Stars = "Dusk"})[style] or style or "Aurora" end

	function Shell.new(ctx)
		local self = setmetatable({ctx = ctx, connections = {}, unsubscribers = {}, desktopIcons = {}, mobileIcons = {}, taskButtons = {}, taskRows = {}, ProgramRows = {}, surfaces = {}, wallpapers = {}, destroyed = false}, Shell)
		local UI = ctx.UI
		local function connect(signal, callback)
			local c = signal:Connect(callback); table.insert(self.connections, c); return c
		end
		local function frame(parent, props) return UI.frame(parent, props) end
		local function text(parent, value, props) return UI.text(parent, value, props) end
		local function button(parent, value, props) return UI.button(parent, value, props) end
		local function transparentButton(parent, name, z)
			local b = button(parent, "", {Name = name, Text = "", BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = z})
			local edge = b:FindFirstChildOfClass("UIStroke"); if edge then edge.Enabled = false end
			return b
		end
		self.Bevel = function(object) UI.bevel(object); return object end
		local function activate(id, args)
			self:CloseMenus()
			if not ctx.Apps then return false end
			local ok, message = ctx.Apps:Launch(id, args)
			if ok == false and ctx.Notifications then ctx.Notifications:Push({appId = "system", title = "ZolinOS", message = tostring(message or "This app could not open.")}) end
			return ok
		end
		self.Activate = activate
		local function wallpaper(parent)
			local canvas = frame(parent, {Name = "Wallpaper", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2})
			local gradient = UI.new("UIGradient", canvas, {Rotation = 90})
			local glows = {}
			local function glow(name, position, scale)
				local holder = frame(canvas, {Name = name, Position = position, Size = UDim2.fromScale(scale, scale), BackgroundTransparency = 1, ZIndex = 2})
				UI.new("UIAspectRatioConstraint", holder, {AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width})
				local layers = {}
				for index = 1, 7 do
					local inset = (index - 1) * 0.035
					local layer = frame(holder, {Name = "Glow" .. index, Position = UDim2.fromScale(inset, inset), Size = UDim2.fromScale(1 - inset * 2, 1 - inset * 2), BackgroundTransparency = 0.965, ZIndex = 2})
					UI.corner(layer, UDim.new(1, 0)); table.insert(layers, layer)
				end
				table.insert(glows, layers)
			end
			glow("AccentGlow", UDim2.fromScale(0.54, -0.48), 0.88)
			glow("SecondaryGlow", UDim2.fromScale(-0.24, 0.35), 0.78)
			glow("QuietGlow", UDim2.fromScale(0.47, 0.64), 0.46)
			local stars = {}
			for index = 1, 30 do
				stars[index] = frame(canvas, {Name = "Star" .. index, Position = UDim2.fromScale(((index * 37) % 97) / 100, ((index * 19) % 61) / 100), Size = UDim2.fromOffset(index % 3 == 0 and 3 or 2, index % 3 == 0 and 3 or 2), BackgroundColor3 = Color3.fromRGB(235, 239, 250), ZIndex = 2, Visible = false})
			end
			table.insert(self.wallpapers, {canvas = canvas, gradient = gradient, glows = glows, stars = stars})
			return canvas
		end
		local function navImage(parent, name, image, fraction, kind)
			local b = UI.new("ImageButton", parent, {Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(fraction, 0, 0.5, 0), BackgroundTransparency = 1, AutoButtonColor = true, Image = image, ImageTransparency = 0.1, ImageColor3 = Color3.new(1, 1, 1), ScaleType = Enum.ScaleType.Fit, ZIndex = NAV_Z + 1})
			if UI.pressFeedback then UI.pressFeedback(b) end
			b:SetAttribute("ActionLabel", kind == "home" and "Home" or "Recent apps")
			local fallback = frame(b, {Name = "Fallback", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.55, 0.55), BackgroundTransparency = 1, ZIndex = NAV_Z + 2})
			UI.corner(fallback, kind == "home" and UDim.new(1, 0) or UDim.new(0, 3))
			UI.new("UIStroke", fallback, {Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.1})
			local function loaded() fallback.Visible = not b.IsLoaded end
			connect(b:GetPropertyChangedSignal("IsLoaded"), loaded); loaded()
			connect(b.Activated, function()
				if ctx.Notifications then ctx.Notifications:ClosePanel() end
				if ctx.Volume then ctx.Volume:ClosePanel() end
				if kind == "home" then
					self:CloseMenus()
					if ctx.Apps then
						for _, app in ipairs(ctx.Apps:GetRunning()) do
							local metadata = ctx.Apps:GetMetadata(app.id)
							if metadata and metadata.protected then ctx.Apps:Close(app.id)
							elseif not minimized(app) then ctx.Apps:Minimize(app.id) end
						end
					end
				else self:ToggleMenu("tasks") end
			end)
			return b
		end
		local function surface(area, mobile)
			UI.corner(area, 8)
			UI.new("UIStroke", area, {Name = "TabletBorder", Color = Color3.fromRGB(33, 33, 33), Thickness = 6, Transparency = 0.67})
			local data = {area = area, mobile = mobile, statusIcons = {}, pages = 1}
			data.wallpaper = wallpaper(area)
			local apps = Instance.new("Folder"); apps.Name, apps.Parent = "Applications", area
			data.applications = apps
			data.home = UI.scroll(area, {Name = "HomeScreenScroller", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.None, ScrollBarThickness = 0, ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, Active = true, ZIndex = 3})
			data.status = frame(area, {Name = "NotificationBar", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = STATUS_Z, Active = true})
			data.toggle = transparentButton(data.status, "NotificationToggle", STATUS_Z + 1); data.toggle.Size = UDim2.fromScale(1, 1)
			data.ranks = frame(data.status, {Name = "NotificationRankList", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = STATUS_Z + 2})
			data.time = text(data.ranks, "12:00 PM", {Name = "TimeLabel", Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(104, 28), Font = Enum.Font.Kalam, TextColor3 = Color3.new(1, 1, 1), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, ZIndex = STATUS_Z + 3})
			data.time:SetAttribute("Clock", true)
			connect(data.toggle.Activated, function()
				if not ctx.Notifications then return end
				if type(ctx.Notifications.ShouldIgnoreClick) == "function" and ctx.Notifications:ShouldIgnoreClick() then return end
				self:CloseMenus()
				ctx.Notifications:TogglePanel()
			end)
			data.volume = button(data.status, "Volume", {Name = "VolumeIconButton", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, TextTransparency = 1, ZIndex = STATUS_Z + 4})
			data.volume:FindFirstChildOfClass("UIStroke").Enabled = false
			data.volume:SetAttribute("ActionLabel", "Volume")
			data.volume:SetAttribute("PreventNotificationSwipe", true)
			local speaker = UI.new("ImageLabel", data.volume, {Name = "Speaker", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.74, 0.74), Image = "rbxassetid://470648244", ImageColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = STATUS_Z + 5})
			local fallback = text(data.volume, "♪", {Name = "SpeakerFallback", Size = UDim2.fromScale(1, 1), Font = Enum.Font.SourceSansBold, TextSize = 22, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = STATUS_Z + 5})
			local function speakerLoaded() fallback.Visible = not speaker.IsLoaded end
			connect(speaker:GetPropertyChangedSignal("IsLoaded"), speakerLoaded); speakerLoaded()
			local hint = text(data.volume, "Volume", {Name = "Tooltip", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 1, 5), Size = UDim2.fromOffset(64, 24), Font = Enum.Font.Gotham, TextSize = 11, BackgroundTransparency = 0, Visible = false, ZIndex = STATUS_Z + 6})
			UI.corner(hint, 6)
			connect(data.volume.MouseEnter, function() hint.Visible = true end)
			connect(data.volume.MouseLeave, function() hint.Visible = false end)
			connect(data.volume.SelectionGained, function() hint.Visible = true end)
			connect(data.volume.SelectionLost, function() hint.Visible = false end)
			connect(data.volume.Activated, function()
				hint.Visible = false; self:CloseMenus()
				if ctx.Volume then ctx.Volume:TogglePanel() end
			end)
			data.power = button(data.status, "⏻", {Name = "PowerMenuButton", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -38, 0.5, 0), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, TextSize = 20, TextColor3 = Color3.new(1, 1, 1), ZIndex = STATUS_Z + 4})
			data.power:FindFirstChildOfClass("UIStroke").Enabled = false
			data.power:SetAttribute("ActionLabel", "Power off")
			data.power:SetAttribute("PreventNotificationSwipe", true)
			connect(data.power.Activated, function()
				self:CloseMenus()
				if ctx.Notifications then ctx.Notifications:ClosePanel() end
				if ctx.Volume then ctx.Volume:ClosePanel() end
				if ctx.Power then ctx.Power:Toggle() end
			end)
			data.navigation = frame(area, {Name = "NavigationBar", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.87, BorderSizePixel = 0, ZIndex = NAV_Z})
			data.homeButton = navImage(data.navigation, "Exit", "rbxassetid://99851851", 0.25, "home")
			data.recentsButton = navImage(data.navigation, "Background", "rbxassetid://14657415531", 0.75, "recents")
			data.widgets = frame(area, {Name = "HomeWidgets", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8})
			data.clockWidget = transparentButton(data.widgets, "ClockWidget", 9)
			data.clockWidget.Position, data.clockWidget.Size = UDim2.fromOffset(24, 40), UDim2.fromOffset(230, 62)
			data.clockText = text(data.clockWidget, "", {Name = "Time", Size = UDim2.fromScale(1, 1), TextSize = 44, Font = Enum.Font.Kalam, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 10})
			connect(data.clockWidget.Activated, function() activate("Clock") end)
			data.dateWidget = text(data.widgets, "", {Name = "DateWidget", Position = UDim2.fromOffset(28, 106), Size = UDim2.fromOffset(310, 28), TextSize = 14, Font = Enum.Font.Kalam, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 10})
			table.insert(self.surfaces, data)
			return data
		end
		local desktop = frame(ctx.Gui, {Name = "__ZolinDesktop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.9), BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = SURFACE_Z})
		local desktopArea = frame(desktop, {Name = "__ScreenFrame", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = SURFACE_Z})
		local mobileArea = frame(ctx.Gui, {Name = "__ScreenFrame", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.9), BackgroundTransparency = 1, ClipsDescendants = true, Active = true, ZIndex = SURFACE_Z})
		self.desktopSurface, self.mobileSurface = surface(desktopArea, false), surface(mobileArea, true)
		self.DesktopRoot, self.DesktopArea, self.MobileArea = desktop, desktopArea, mobileArea
		self.DesktopIconHost, self.MobileIconHost = self.desktopSurface.home, self.mobileSurface.home
		self.DesktopTime, self.DesktopDate, self.MobileClock, self.MobileDate = self.desktopSurface.clockText, self.desktopSurface.dateWidget, self.mobileSurface.clockText, self.mobileSurface.dateWidget
		self.DesktopBrand, self.MobileBrand = self.desktopSurface.dateWidget, self.mobileSurface.dateWidget
		ctx.DesktopArea, ctx.MobileArea = desktopArea, mobileArea
		ctx.DesktopApplications, ctx.MobileApplications = self.desktopSurface.applications, self.mobileSurface.applications
		local overlayRoot = ctx.Mode == "Mobile" and mobileArea or desktopArea
		ctx.OverlayRoot = overlayRoot
		self.OverlayRoot = overlayRoot
		local menus = frame(overlayRoot, {Name = "ShellMenus", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = MENU_Z})
		self.MenuLayer = menus
		self.Backdrop = transparentButton(menus, "DismissMenus", MENU_Z + 1)
		self.Backdrop.Size, self.Backdrop.Visible = UDim2.fromScale(1, 1), false
		self.Backdrop.BackgroundColor3, self.Backdrop.BackgroundTransparency = Color3.new(0, 0, 0), 0.48
		connect(self.Backdrop.Activated, function() self:CloseMenus() end)
		local taskMenu = frame(menus, {Name = "BackgroundPage", Visible = false, ClipsDescendants = true, BackgroundColor3 = Color3.fromRGB(48, 87, 126), BackgroundTransparency = 0.15, ZIndex = MENU_Z + 2})
		UI.corner(taskMenu, 8); self.TaskMenu = taskMenu
		self.TaskList = UI.scroll(taskMenu, {Name = "ScrollingApps", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 1, -66), BackgroundTransparency = 1, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollBarThickness = 3, ZIndex = MENU_Z + 3})
		local recentLayout = UI.list(self.TaskList, 20); recentLayout.FillDirection, recentLayout.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center
		self.NoTasks = text(self.TaskList, "No recent items", {Name = "FrameNote", Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.SourceSansBold, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = MENU_Z + 4})
		local clearAll = button(taskMenu, "Clear all", {Name = "ClearAll_Button", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.fromOffset(112, 34), Font = Enum.Font.Oswald, TextSize = 14, ZIndex = MENU_Z + 4})
		UI.corner(clearAll, UDim.new(0.35, 0))
		connect(clearAll.Activated, function() if ctx.Apps then for _, app in ipairs(ctx.Apps:GetRunning()) do ctx.Apps:Close(app.id) end end end)
		local context = frame(menus, {Name = "HomeContextMenu", Size = UDim2.fromOffset(244, 216), Visible = false, ZIndex = MENU_Z + 3})
		UI.corner(context, 24); self.ContextMenu = context
		local function drawnIcon(parent, kind)
			local icon = frame(parent, {Name = "Icon", Position = UDim2.fromOffset(14, 9), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, ZIndex = MENU_Z + 6})
			local function part(x, y, w, h, round, rotation)
				local p = frame(icon, {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), Rotation = rotation or 0, ZIndex = MENU_Z + 7})
				ctx.Theme:Bind(p, {BackgroundColor3 = "Text"}); if round then UI.corner(p, round) end; return p
			end
			if kind == "widgets" then for _, p in ipairs({{3, 3}, {17, 3}, {3, 17}, {17, 17}}) do part(p[1], p[2], 10, 10, 3) end
			elseif kind == "wallpapers" then
				local picture = part(2, 4, 26, 22, 4); picture.BackgroundTransparency = 1
				local edge = UI.new("UIStroke", picture, {Thickness = 1.6}); ctx.Theme:Bind(edge, {Color = "Text"})
				part(6, 13, 13, 4, 2, -40); part(15, 15, 11, 4, 2, 40); part(18, 8, 4, 4, UDim.new(1, 0))
			elseif kind == "personalize" then part(4, 5, 20, 20, 6, 45); part(21, 20, 4, 8, 2, -35)
			else for index, x in ipairs({8, 19, 12}) do part(3, index * 7, 24, 2, 1); part(x, index * 7 - 3, 5, 8, 2) end end
		end
		for index, item in ipairs({{"Add widgets", "widgets"}, {"Wallpapers", "wallpapers"}, {"Personalize", "personalize"}, {"Home settings", "home"}}) do
			local control = transparentButton(context, "Action" .. index, MENU_Z + 4)
			control.Position, control.Size = UDim2.fromOffset(4, 4 + (index - 1) * 52), UDim2.new(1, -8, 0, 52)
			drawnIcon(control, item[2])
			text(control, item[1], {Position = UDim2.fromOffset(56, 0), Size = UDim2.new(1, -68, 1, 0), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, ZIndex = MENU_Z + 6})
			connect(control.Activated, function() if item[2] == "wallpapers" then activate("WallpaperSys") else activate("HomeCustomization", {section = item[2]}) end end)
		end
		-- Kept as an opt-in API surface for existing packages; no drawer is imposed on home.
		self.StartMenu = frame(menus, {Name = "ApplicationList", Visible = false, Size = UDim2.fromOffset(430, 450), ClipsDescendants = true, ZIndex = MENU_Z + 2})
		UI.corner(self.StartMenu, 16)
		self.Search = UI.new("TextBox", self.StartMenu, {Name = "SearchApplications", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 38), PlaceholderText = "Search apps", Text = "", TextSize = 13, ZIndex = MENU_Z + 3})
		UI.pad(self.Search, 10)
		self.ProgramList = UI.scroll(self.StartMenu, {Name = "Programs", Position = UDim2.fromOffset(12, 62), Size = UDim2.new(1, -24, 1, -74), ZIndex = MENU_Z + 3})
		UI.list(self.ProgramList, 6)
		self.NoPrograms = text(self.ProgramList, "No matching apps", {Name = "Empty", Size = UDim2.new(1, 0, 0, 38), TextSize = 13, ZIndex = MENU_Z + 4})
		connect(self.Search:GetPropertyChangedSignal("Text"), function() self:FilterPrograms() end)
		self.TaskHost = frame(menus, {Name = "CompatibilityTasks", Visible = false, BackgroundTransparency = 1, ZIndex = MENU_Z})
		local function blankHome(data, point)
			if not inRect(point, data.home) then return false end
			local icons = data.mobile and self.mobileIcons or self.desktopIcons
			for _, item in pairs(icons) do if inRect(point, item.button) then return false end end
			if data.clockWidget.Visible and inRect(point, data.clockWidget) then return false end
			return not self.menu
		end
		for _, data in ipairs(self.surfaces) do
			connect(data.home.InputBegan, function(input)
				local point = Vector2.new(input.Position.X, input.Position.Y)
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					if blankHome(data, point) then self:OpenContext(point) end; return
				end
				if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				if not blankHome(data, point) then return end
				local press = {input = input, point = point, data = data, canvas = data.home.CanvasPosition, moved = false}
				self.homePress = press
				task.delay(0.5, function()
					if not self.destroyed and self.homePress == press and not press.moved then press.opened = true; self:OpenContext(press.point) end
				end)
			end)
		end
		connect(UserInputService.InputChanged, function(input)
			local press = self.homePress
			if press and (input == press.input or input.UserInputType == Enum.UserInputType.MouseMovement) then
				if (Vector2.new(input.Position.X, input.Position.Y) - press.point).Magnitude > 10 then press.moved = true end
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			local press = self.homePress
			if press and (input == press.input or input.UserInputType == Enum.UserInputType.MouseButton1) then
				self.homePress = nil
				if press.moved and not press.opened then
					local width = math.max(1, press.data.home.AbsoluteSize.X)
					local page = math.clamp(math.floor(press.data.home.CanvasPosition.X / width + 0.5), 0, press.data.pages - 1)
					TweenService:Create(press.data.home, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(page * width, 0)}):Play()
				end
			end
		end)
		connect(UserInputService.WindowFocusReleased, function() self.homePress = nil end)
		connect(UserInputService.InputBegan, function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.Escape then
				if ctx.Notifications and ctx.Notifications._open then ctx.Notifications:ClosePanel()
				elseif ctx.Volume and ctx.Volume._open then ctx.Volume:ClosePanel()
				elseif self.menu then self:CloseMenus()
				elseif ctx.Apps and ctx.Apps:GetActive() then ctx.Apps:Minimize(ctx.Apps:GetActive()) end
			end
		end)
		connect(desktopArea:GetPropertyChangedSignal("AbsoluteSize"), function() self:Layout() end)
		connect(mobileArea:GetPropertyChangedSignal("AbsoluteSize"), function() self:Layout() end)
		connect(desktopArea:GetPropertyChangedSignal("AbsolutePosition"), function() self:Layout() end)
		connect(mobileArea:GetPropertyChangedSignal("AbsolutePosition"), function() self:Layout() end)
		connect(overlayRoot:GetPropertyChangedSignal("AbsoluteSize"), function() self:LayoutMenus() end)
		connect(desktop.Destroying, function() self:Destroy(true) end)
		if ctx.Bus then
			table.insert(self.unsubscribers, ctx.Bus:On("apps.changed", function() if not self.destroyed then self:RefreshApps(); self:RefreshTasks() end end))
			table.insert(self.unsubscribers, ctx.Bus:On("notifications.changed", function() if not self.destroyed then self:RefreshTray() end end))
			table.insert(self.unsubscribers, ctx.Bus:On("settings.changed", function(change)
				if self.destroyed or not change then return end
				if change.key == "wallpaper.style" or change.key == "wallpaper.pattern" then self:RefreshWallpaper() end
				if type(change.key) == "string" and change.key:sub(1, 5) == "home." then self:Layout() end
			end))
		end
		table.insert(self.unsubscribers, ctx.Theme:Subscribe(function() if not self.destroyed then self:RefreshWallpaper(); self:RefreshTasks() end end))
		local elapsed = 0
		connect(game:GetService("RunService").Heartbeat, function(dt) elapsed += dt; if elapsed >= 1 then elapsed = 0; self:RefreshClock() end end)
		self:SetMode(ctx.Mode or "Mobile"); self:RefreshWallpaper(); self:RefreshClock(); self:RefreshApps(); self:RefreshTasks()
		return self
	end

	function Shell:CloseMenus()
		if self.destroyed then return end
		self.menu, self.homePress = nil, nil
		self.Backdrop.Visible, self.TaskMenu.Visible, self.StartMenu.Visible, self.ContextMenu.Visible = false, false, false, false
		if self.Search:IsFocused() then self.Search:ReleaseFocus() end
	end
	function Shell:ToggleMenu(which)
		if self.destroyed then return end
		local wasOpen = self.menu == which
		self:CloseMenus(); if wasOpen then return end
		if self.ctx.Notifications then self.ctx.Notifications:ClosePanel() end
		if self.ctx.Volume then self.ctx.Volume:ClosePanel() end
		self.menu, self.Backdrop.Visible = which, true
		self.TaskMenu.Visible, self.StartMenu.Visible = which == "tasks", which == "start"
		if which == "tasks" then self:RefreshTasks() end
		if which == "start" then self.Search.Text = ""; self:FilterPrograms() end
		self:LayoutMenus()
	end
	function Shell:OpenContext(point)
		if self.destroyed then return end
		self:CloseMenus()
		self.contextPosition = point - self.OverlayRoot.AbsolutePosition
		self.menu, self.Backdrop.Visible, self.ContextMenu.Visible = "context", true, true
		self:LayoutMenus()
	end
	function Shell:LayoutMenus()
		if self.destroyed then return end
		local size = self.OverlayRoot.AbsoluteSize
		local top, bottom = self.ctx.WindowInsetsTop or 22, self.ctx.WindowInsetsBottom or 28
		local h = math.max(1, size.Y - top - bottom)
		self.TaskMenu.Position, self.TaskMenu.Size = UDim2.fromOffset(0, top), UDim2.new(1, 0, 0, h)
		local sw, sh = math.max(1, math.min(430, size.X - 16)), math.max(1, math.min(450, h - 8))
		self.StartMenu.Size, self.StartMenu.Position = UDim2.fromOffset(sw, sh), UDim2.fromOffset((size.X - sw) / 2, top + (h - sh) / 2)
		local cw, ch = math.min(244, math.max(1, size.X - 12)), math.min(216, math.max(1, h - 8))
		local point = self.contextPosition or Vector2.new((size.X - cw) / 2, top + 8)
		self.ContextMenu.Size = UDim2.fromOffset(cw, ch)
		self.ContextMenu.Position = UDim2.fromOffset(math.clamp(point.X, 6, math.max(6, size.X - cw - 6)), math.clamp(point.Y, top + 4, math.max(top + 4, size.Y - bottom - ch - 4)))
		local rowH = ch / 4
		for index = 1, 4 do
			local row = self.ContextMenu:FindFirstChild("Action" .. index)
			row.Position, row.Size = UDim2.fromOffset(4, (index - 1) * rowH), UDim2.new(1, -8, 0, rowH)
			local icon = row:FindFirstChild("Icon"); icon.Position = UDim2.fromOffset(14, (rowH - 30) / 2)
		end
		for _, row in pairs(self.taskRows) do row.button.Size = UDim2.new(0, math.clamp(size.X * 0.5, 168, 280), 1, -4) end
	end
	function Shell:RefreshWallpaper()
		if self.destroyed then return end
		local dark, accent = self.ctx.Theme:GetTheme() == "Dark", self.ctx.Theme:GetAccent()
		local style = wallpaperStyle(self.ctx.Settings:Get("wallpaper.style", "Aurora"))
		local skyTop, skyBottom, secondary
		if style == "Solid" then skyTop = accent:Lerp(dark and Color3.new() or Color3.new(1, 1, 1), 0.88); skyBottom, secondary = skyTop, accent
		elseif style == "Bloom" then skyTop, skyBottom = dark and Color3.fromRGB(12, 26, 34) or Color3.fromRGB(242, 249, 246), dark and Color3.fromRGB(22, 47, 51) or Color3.fromRGB(216, 235, 231); secondary = Color3.fromRGB(93, 182, 157)
		elseif style == "Dusk" then skyTop, skyBottom, secondary = Color3.fromRGB(18, 18, 37), Color3.fromRGB(45, 33, 62), Color3.fromRGB(184, 108, 160)
		else skyTop, skyBottom = dark and Color3.fromRGB(9, 15, 29) or Color3.fromRGB(241, 245, 253), dark and Color3.fromRGB(24, 33, 55) or Color3.fromRGB(214, 226, 246); secondary = Color3.fromRGB(137, 116, 204) end
		for _, wallpaper in ipairs(self.wallpapers) do
			wallpaper.canvas.BackgroundColor3 = Color3.new(1, 1, 1); wallpaper.gradient.Color = ColorSequence.new(skyTop, skyBottom)
			for index, layers in ipairs(wallpaper.glows) do for _, layer in ipairs(layers) do layer.Visible = style ~= "Solid"; layer.BackgroundColor3 = index == 2 and secondary or accent; layer.BackgroundTransparency = (dark or style == "Dusk") and 0.955 or 0.975 end end
			for _, star in ipairs(wallpaper.stars) do star.Visible = self.ctx.Settings:Get("wallpaper.pattern", false) == true; star.BackgroundTransparency = 0.72 end
		end
		self.wallpaperText = (dark or style == "Dusk") and Color3.fromRGB(255, 251, 251) or Color3.fromRGB(32, 47, 73)
		for _, collection in ipairs({self.desktopIcons, self.mobileIcons}) do for _, item in pairs(collection) do item.caption.TextColor3 = self.wallpaperText end end
		for _, data in ipairs(self.surfaces) do data.clockText.TextColor3, data.dateWidget.TextColor3 = self.wallpaperText, self.wallpaperText end
	end
	function Shell:RefreshClock()
		if self.destroyed then return end
		local now = DateTime.now(); local current = now:ToLocalTime()
		local hour = current.Hour % 12; if hour == 0 then hour = 12 end
		local clock = string.format("%02d:%02d%s", hour, current.Minute, current.Hour < 12 and "AM" or "PM")
		for _, data in ipairs(self.surfaces) do data.time.Text, data.clockText.Text = clock, clock; data.dateWidget.Text = now:FormatLocalTime("LL", "en-us") end
	end
	function Shell:RefreshTray()
		if self.destroyed then return end
		local order, seen = {}, {}
		if self.ctx.Notifications then for _, record in ipairs(self.ctx.Notifications:GetHistory()) do if not record.read and not record.dismissed and not seen[record.appId] then seen[record.appId] = true; table.insert(order, record.appId) end end end
		for _, data in ipairs(self.surfaces) do
			for id, icon in pairs(data.statusIcons) do if not seen[id] then icon:Destroy(); data.statusIcons[id] = nil end end
			local rankStart = data.time.AbsoluteSize.X + 14
			local maximum = math.max(0, math.floor((data.ranks.AbsoluteSize.X - rankStart) / 25))
			for index, id in ipairs(order) do
				local icon = data.statusIcons[id]
				if not icon then
					local meta = self.ctx.Apps and self.ctx.Apps:GetMetadata(id) or nil
					icon = self.ctx.UI.appIcon(data.ranks, meta or {name = id}, {Name = "AppIcon", Size = UDim2.fromOffset(18, 18), ZIndex = STATUS_Z + 3})
					icon:SetAttribute("AppId", id); data.statusIcons[id] = icon
				end
				icon.Position, icon.Visible = UDim2.fromOffset(rankStart + (index - 1) * 25, math.max(0, (data.status.AbsoluteSize.Y - 18) / 2)), index <= maximum
			end
		end
	end
	function Shell:_MakeAppIcon(parent, metadata)
		local UI = self.ctx.UI
		local outer = UI.button(parent, "", {Name = metadata.id, BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = HOME_Z})
		outer:FindFirstChildOfClass("UIStroke").Enabled = false
		local tile = UI.frame(outer, {Name = "IconTile", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(48, 48), BackgroundColor3 = Color3.fromRGB(65, 65, 65), ZIndex = HOME_Z + 1})
		self.ctx.Theme:Bind(tile, {BackgroundColor3 = "Title"}); UI.corner(tile, UDim.new(0.4, 0))
		UI.new("UIStroke", tile, {Color = Color3.fromRGB(65, 64, 64), Thickness = 4, Transparency = 0.58})
		local image, letter = UI.appIcon(tile, metadata, {Name = "IconImage", Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -10), ZIndex = HOME_Z + 2})
		image.ImageColor3 = Color3.new(1, 1, 1); letter.ZIndex = HOME_Z + 3
		local caption = UI.text(outer, metadata.name or metadata.id, {Name = "AppName", Position = UDim2.fromOffset(-12, 62), Size = UDim2.new(1, 24, 0, 28), Font = Enum.Font.SourceSansBold, TextSize = 14, TextWrapped = true, TextColor3 = self.wallpaperText or Color3.fromRGB(255, 251, 251), TextStrokeTransparency = 0.5, BackgroundTransparency = 1, ZIndex = HOME_Z + 3})
		local item = {button = outer, tile = tile, icon = image, letter = letter, caption = caption, metadata = metadata}
		item.connection = outer.Activated:Connect(function() if not self.destroyed then self.Activate(item.metadata.id) end end)
		return item
	end
	function Shell:RefreshApps()
		if self.destroyed then return end
		local entries = self.ctx.Apps and self.ctx.Apps:List() or {}
		local seen, visibleOrder = {}, 0
		for _, metadata in ipairs(entries) do
			seen[metadata.id] = true
			if not metadata.hiddenFromHome then
				visibleOrder += 1
				for _, pair in ipairs({{self.desktopIcons, self.DesktopIconHost}, {self.mobileIcons, self.MobileIconHost}}) do
					local item = pair[1][metadata.id]
					if item and (item.metadata.icon ~= metadata.icon or item.metadata.name ~= metadata.name) then item.connection:Disconnect(); item.button:Destroy(); item = nil end
					if not item then item = self:_MakeAppIcon(pair[2], metadata); pair[1][metadata.id] = item end
					item.metadata, item.order, item.button.Visible = metadata, visibleOrder, true
					item.caption.Text = metadata.name or metadata.id
					item.icon.ImageTransparency, item.letter.TextTransparency, item.caption.TextTransparency = metadata.disabled and 0.55 or 0, metadata.disabled and 0.55 or 0, metadata.disabled and 0.45 or 0
				end
			else
				for _, collection in ipairs({self.desktopIcons, self.mobileIcons}) do local item = collection[metadata.id]; if item then item.connection:Disconnect(); item.button:Destroy(); collection[metadata.id] = nil end end
			end
			local row = self.ProgramRows[metadata.id]
			if not row then
				local control = self.ctx.UI.button(self.ProgramList, metadata.name or metadata.id, {Name = metadata.id, Size = UDim2.new(1, -6, 0, 40), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 13, ZIndex = MENU_Z + 4})
				self.ctx.UI.pad(control, 10)
				row = {button = control, metadata = metadata}
				row.connection = control.Activated:Connect(function() self.Activate(row.metadata.id) end)
				self.ProgramRows[metadata.id] = row
			end
			row.metadata, row.button.Text = metadata, metadata.name or metadata.id
		end
		for _, collection in ipairs({self.desktopIcons, self.mobileIcons, self.ProgramRows}) do
			for id, item in pairs(collection) do if not seen[id] then item.connection:Disconnect(); item.button:Destroy(); collection[id] = nil end end
		end
		self:FilterPrograms(); self:Layout()
	end
	function Shell:FilterPrograms()
		if self.destroyed then return end
		local query, count = self.Search.Text:lower(), 0
		for _, row in pairs(self.ProgramRows) do row.button.Visible = query == "" or (tostring(row.metadata.name or row.metadata.id) .. " " .. tostring(row.metadata.description or "")):lower():find(query, 1, true) ~= nil; if row.button.Visible then count += 1 end end
		self.NoPrograms.Visible = count == 0
	end
	function Shell:GetIconBounds(id, mode)
		local collection = (mode or self.ctx.Mode) == "Mobile" and self.mobileIcons or self.desktopIcons
		local item = collection[id]
		return item and item.button.Parent and {position = item.button.AbsolutePosition, size = item.button.AbsoluteSize, button = item.button} or nil
	end
	function Shell:RefreshTasks()
		if self.destroyed then return end
		local running = self.ctx.Apps and self.ctx.Apps:GetRunning() or {}
		local active = self.ctx.Apps and self.ctx.Apps:GetActive()
		local seen = {}
		for _, app in ipairs(running) do
			seen[app.id] = true
			local row = self.taskRows[app.id]
			if not row then
				local control = self.ctx.UI.button(self.TaskList, "", {Name = app.id, Size = UDim2.new(0, 250, 1, -4), ZIndex = MENU_Z + 4})
				self.ctx.UI.corner(control, 16)
				local caption = self.ctx.UI.text(control, app.name or app.id, {Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -58, 0, 24), TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = MENU_Z + 5})
				local icon = self.ctx.UI.appIcon(control, self.ctx.Apps:GetMetadata(app.id) or {name = app.id}, {Name = "AppPreview", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(48, 48), ZIndex = MENU_Z + 5})
				local status = self.ctx.UI.text(control, "", {Position = UDim2.new(0, 12, 1, -32), Size = UDim2.new(1, -24, 0, 22), TextSize = 11, ZIndex = MENU_Z + 5})
				local close = self.ctx.UI.button(control, "×", {Name = "Close", Position = UDim2.new(1, -40, 0, 8), Size = UDim2.fromOffset(30, 30), TextSize = 20, ZIndex = MENU_Z + 6})
				row = {button = control, caption = caption, status = status, app = app, connections = {}}
				table.insert(row.connections, control.Activated:Connect(function() self.Activate(row.app.id) end))
				table.insert(row.connections, close.Activated:Connect(function() self.ctx.Apps:Close(row.app.id) end))
				self.taskRows[app.id] = row
			end
			row.app, row.caption.Text, row.status.Text = app, app.name or app.id, app.id == active and "Active" or (minimized(app) and "Minimized" or "Open")
		end
		for id, row in pairs(self.taskRows) do if not seen[id] then for _, c in ipairs(row.connections) do c:Disconnect() end; row.button:Destroy(); self.taskRows[id] = nil end end
		self.NoTasks.Visible = #running == 0
		local showMobileHome = not active
		if active then for _, app in ipairs(running) do if app.id == active and minimized(app) then showMobileHome = true end end end
		self.mobileSurface.home.Visible, self.mobileSurface.widgets.Visible = showMobileHome, showMobileHome
		self:LayoutMenus(); self:RefreshTray()
	end
	function Shell:LayoutTaskButtons() end
	function Shell:NotifyBoundsChanged()
		if self.destroyed then return end
		local bounds = self.ctx.OSBoundsFrame
		if not bounds then return end
		local size, position = bounds.AbsoluteSize, bounds.AbsolutePosition
		if self.lastBounds == size and self.lastPosition == position and self.lastMode == self.ctx.Mode then return end
		self.lastBounds, self.lastPosition, self.lastMode = size, position, self.ctx.Mode
		if self.ctx.Bus then self.ctx.Bus:Emit("surface.resize", {size = size, position = position, mode = self.ctx.Mode, insets = self.ctx.WindowInsets}) end
	end
	function Shell:Layout()
		if self.destroyed then return end
		local active = self.ctx.Mode == "Mobile" and self.mobileSurface or self.desktopSurface
		self.ctx.OSBoundsFrame = active.area
		local bounds = active.area.AbsoluteSize
		local top, bottom = math.clamp(bounds.Y * 0.05, 22, 34), math.clamp(bounds.Y * 0.06, 28, 48)
		self.ctx.WindowInsets = {Top = top, Bottom = bottom}
		self.ctx.WindowInsetsTop, self.ctx.WindowInsetsBottom = top, bottom
		local scale = math.clamp(tonumber(self.ctx.Settings:Get("home.iconScale", 1)) or 1, 0.65, 1.65)
		local wantedColumns = math.clamp(math.floor(tonumber(self.ctx.Settings:Get("home.columns", 0)) or 0), 0, 12)
		local labels = self.ctx.Settings:Get("home.labels", true) ~= false
		for _, data in ipairs(self.surfaces) do
			local size = data.area.AbsoluteSize
			local sh, nh = math.clamp(size.Y * 0.05, 22, 34), math.clamp(size.Y * 0.06, 28, 48)
			data.status.Position, data.status.Size = UDim2.new(), UDim2.new(1, 0, 0, sh)
			data.ranks.Size = UDim2.new(1, -sh - 18, 1, 0)
			data.volume.Size = UDim2.fromOffset(math.max(26, sh), sh)
			data.time.Size, data.time.TextSize = UDim2.fromOffset(math.clamp(sh * 4.5, 104, 160), sh), math.clamp(sh * 0.9, 16, 30)
			data.navigation.Position, data.navigation.Size = UDim2.new(0, 0, 1, -nh), UDim2.new(1, 0, 0, nh)
			local controlSize = math.max(24, nh * 0.84)
			data.homeButton.Size, data.recentsButton.Size = UDim2.fromOffset(controlSize, controlSize), UDim2.fromOffset(controlSize, controlSize)
			local small = size.Y < 390
			local hasClock, hasDate = self.ctx.Settings:Get("home.widget.clock", false) == true, self.ctx.Settings:Get("home.widget.date", false) == true
			local clockHeight, dateHeight = small and 38 or 62, small and 18 or 28
			local widgetBand = (hasClock or hasDate) and (16 + (hasClock and clockHeight or 0) + (hasDate and dateHeight or 0) + (hasClock and hasDate and 4 or 0)) or 0
			data.home.Position, data.home.Size = UDim2.fromOffset(0, sh + widgetBand), UDim2.new(1, 0, 1, -sh - nh - widgetBand)
			local collection = data.mobile and self.mobileIcons or self.desktopIcons
			local columns = wantedColumns > 0 and wantedColumns or math.clamp(math.floor(math.max(1, size.X) / (180 * scale)), 1, 8)
			local count = 0; for _ in pairs(collection) do count += 1 end
			local pages = math.max(1, math.ceil(count / columns)); data.pages = pages
			local tile = math.clamp(size.Y * 0.087, 36, 76) * scale
			local cell = math.max(1, size.X / columns)
			local captionFont = math.clamp(size.Y * 0.024, 14, 22) * scale
			local captionHeight = math.max(28, math.ceil(captionFont * 1.4))
			local buttonWidth, buttonHeight = math.min(cell - 10, math.max(80, tile * 1.8)), math.max(72, tile + (labels and captionHeight + 10 or 8))
			for _, item in pairs(collection) do
				local index = item.order - 1
				local page, slot = math.floor(index / columns), index % columns
				local pageCount = math.min(columns, count - page * columns)
				local x = page * size.X + size.X * 0.5 + (slot - (pageCount - 1) * 0.5) * cell
				item.button.AnchorPoint = Vector2.new(0.5, 0.5)
				item.button.Position, item.button.Size = UDim2.fromOffset(x, math.max(1, (size.Y - sh - nh - widgetBand) * 0.5)), UDim2.fromOffset(math.max(36, buttonWidth), buttonHeight)
				item.tile.Size = UDim2.fromOffset(tile, tile)
				item.caption.Position, item.caption.Size = UDim2.fromOffset(-12, tile + 9), UDim2.new(1, 24, 0, captionHeight)
				item.caption.Visible, item.caption.TextSize = labels, captionFont
				item.letter.TextSize = math.clamp(22 * scale, 14, 32)
			end
			data.home.CanvasSize = UDim2.fromOffset(pages * size.X, 0)
			if data.home.CanvasPosition.X > (pages - 1) * size.X then data.home.CanvasPosition = Vector2.new(math.max(0, (pages - 1) * size.X), 0) end
			data.clockWidget.Visible, data.dateWidget.Visible = hasClock, hasDate
			data.clockWidget.Position = UDim2.fromOffset(24, sh + 8)
			data.clockWidget.Size, data.clockText.TextSize = UDim2.fromOffset(math.max(120, math.min(230, size.X - 48)), clockHeight), small and 28 or 44
			data.dateWidget.Position = UDim2.fromOffset(28, sh + 8 + (hasClock and clockHeight + 4 or 0))
			data.dateWidget.Size, data.dateWidget.TextSize = UDim2.fromOffset(math.max(120, math.min(310, size.X - 56)), dateHeight), small and 12 or 14
		end
		self:LayoutMenus(); self:RefreshTray(); self:NotifyBoundsChanged()
	end
	function Shell:SetMode(mode)
		if self.destroyed then return end
		mode = mode == "Mobile" and "Mobile" or "Desktop"; self.ctx.Mode = mode
		self.DesktopRoot.Visible, self.MobileArea.Visible = mode == "Desktop", mode == "Mobile"
		local data = mode == "Mobile" and self.mobileSurface or self.desktopSurface
		self.StatusBar, self.StatusNotificationRankList, self.MobileNavigation = data.status, data.ranks, data.navigation
		self.VolumeIconButton = data.volume
		self.TrayVolume = data.volume
		self.NavigationButtons = {Home = data.homeButton, Tasks = data.recentsButton, Exit = data.homeButton, Background = data.recentsButton}
		self.Taskbar, self.Tray, self.TrayClock, self.TrayNotifications = data.navigation, data.ranks, data.time, data.toggle
		self.ctx.OSBoundsFrame = data.area
		self.ctx.OverlayRoot, self.OverlayRoot = data.area, data.area
		self.MenuLayer.Parent = data.area
		self:CloseMenus(); self:Layout()
	end
	function Shell:Destroy(fromRoot)
		if self.destroyed then return end
		self.destroyed, self.homePress = true, nil
		for _, c in ipairs(self.connections) do c:Disconnect() end
		for _, stop in ipairs(self.unsubscribers) do if type(stop) == "function" then stop() end end
		for _, collection in ipairs({self.desktopIcons, self.mobileIcons, self.ProgramRows}) do for _, item in pairs(collection) do if item.connection then item.connection:Disconnect() end end end
		for _, row in pairs(self.taskRows) do for _, c in ipairs(row.connections) do c:Disconnect() end end
		self.MenuLayer:Destroy(); self.MobileArea:Destroy()
		if not fromRoot then self.DesktopRoot:Destroy() end
	end
	return Shell

end
-- END COMPONENT: Shell
-- BEGIN COMPONENT: VolumeService
__v3Factories["VolumeService"] = function()
	local VolumeService = {}
	VolumeService.__index = VolumeService

	local KINDS = {"master", "media", "notifications"}
	local VALID = {master = true, media = true, notifications = true}
	local LABELS = {master = "Master output", media = "Apps & media", notifications = "Notifications"}
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local IDLE_SECONDS = 3

	local function unit(value, fallback)
		value = tonumber(value)
		if not value or value ~= value then return fallback or 0 end
		return math.clamp(value, 0, 1)
	end

	local function disconnect(connections)
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
	end

	function VolumeService.new(ctx)
		local self = setmetatable({ctx = ctx, _sounds = {}, _subscribers = {}, _connections = {}, _appConnections = {}, _appSliders = {}, _appRows = {}, _sliders = {}, _rows = {}, _destroyed = false, _open = false, _mixerOpen = false, _tweens = {}, _tweenSerials = {}, _heldKeys = {}, _keySerial = 0}, VolumeService)
		self:_readPreferences()
		self:_buildPanel()
		local function discover(sound)
			if not sound:IsA("Sound") then return end
			if sound:IsDescendantOf(ctx.Gui) or sound:GetAttribute("ZolinOSSound") == true then self:_register(sound, nil, nil, false) end
		end
		for _, sound in ipairs(ctx.Gui:GetDescendants()) do discover(sound) end
		table.insert(self._connections, ctx.Gui.DescendantAdded:Connect(discover))
		local soundService = game:GetService("SoundService")
		for _, sound in ipairs(soundService:GetDescendants()) do discover(sound) end
		table.insert(self._connections, soundService.DescendantAdded:Connect(discover))
		table.insert(self._connections, ctx.Gui.DescendantRemoving:Connect(function(sound)
			local record = self._sounds[sound]
			if record and not record.explicit then
				task.defer(function()
					if not self._destroyed and self._sounds[sound] == record and not sound:IsDescendantOf(ctx.Gui) and sound:GetAttribute("ZolinOSSound") ~= true then self:_removeSound(sound, true) end
				end)
			end
		end))
		if ctx.Bus then
			self._settingsUnsubscribe = ctx.Bus:On("settings.changed", function(change)
				if self._destroyed or self._saving or type(change) ~= "table" then return end
				if type(change.key) == "string" and change.key:sub(1, 7) == "volume." then
					self:_readPreferences()
					self:_applyAll()
					self:_renderAppRows()
					self:_emit()
				end
			end)
			self._modeUnsubscribe = ctx.Bus:On("mode.changed", function() self:_layoutPanel() end)
			self._resizeUnsubscribe = ctx.Bus:On("surface.resize", function() self:_layoutPanel() end)
		end
		if ctx.Apps and ctx.Apps.Subscribe then self._appsUnsubscribe = ctx.Apps:Subscribe(function() if not self._destroyed then self:_renderAppRows() end end) end
		self:_renderAppRows()
		return self
	end

	function VolumeService:_readPreferences()
		local settings = self.ctx.Settings
		self._volumes, self._muted = {}, {}
		for _, kind in ipairs(KINDS) do
			self._volumes[kind] = unit(settings and settings:Get("volume." .. kind, 1), 1)
			self._muted[kind] = settings and settings:Get("volume.muted." .. kind, false) == true or false
		end
		self._appVolumes = {}
		local apps = settings and settings:Get("volume.apps", {}) or {}
		if type(apps) == "table" then
			for appId, values in pairs(apps) do
				if type(appId) == "string" and type(values) == "table" then self._appVolumes[appId] = {volume = unit(values.volume, 1), muted = values.muted == true} end
			end
		end
	end

	function VolumeService:_save(key, value)
		if not self.ctx.Settings then return end
		self._saving = true
		self.ctx.Settings:Set(key, value)
		self._saving = false
	end

	function VolumeService:GetVolume(kind) return self._volumes[kind] or 0 end
	function VolumeService:IsMuted(kind) return self._muted[kind] == true end

	function VolumeService:SetVolume(kind, value)
		if self._destroyed or not VALID[kind] then return false end
		value = unit(value, self._volumes[kind])
		if self._volumes[kind] == value then return true end
		self._volumes[kind] = value
		self:_save("volume." .. kind, value)
		self:_applyAll()
		self:_emit()
		return true
	end

	function VolumeService:SetMuted(kind, muted)
		if self._destroyed or not VALID[kind] then return false end
		muted = muted == true
		if self._muted[kind] == muted then return true end
		self._muted[kind] = muted
		self:_save("volume.muted." .. kind, muted)
		self:_applyAll()
		self:_emit()
		return true
	end

	function VolumeService:GetAppVolume(appId)
		local values = self._appVolumes[tostring(appId)]
		return values and values.volume or 1
	end

	function VolumeService:IsAppMuted(appId)
		local values = self._appVolumes[tostring(appId)]
		return values and values.muted == true or false
	end

	function VolumeService:_saveApps()
		local copy = {}
		for id, values in pairs(self._appVolumes) do copy[id] = {volume = values.volume, muted = values.muted} end
		self:_save("volume.apps", copy)
	end

	function VolumeService:SetAppVolume(appId, value)
		if self._destroyed or appId == nil then return false end
		appId = tostring(appId)
		local values = self._appVolumes[appId] or {volume = 1, muted = false}
		values.volume = unit(value, values.volume)
		self._appVolumes[appId] = values
		self:_saveApps()
		self:_applyAll()
		if not self._appRows[appId] then self:_renderAppRows() end
		self:_emit()
		return true
	end

	function VolumeService:SetAppMuted(appId, muted)
		if self._destroyed or appId == nil then return false end
		appId = tostring(appId)
		local values = self._appVolumes[appId] or {volume = 1, muted = false}
		values.muted = muted == true
		self._appVolumes[appId] = values
		self:_saveApps()
		self:_applyAll()
		if not self._appRows[appId] then self:_renderAppRows() end
		self:_emit()
		return true
	end

	function VolumeService:_factor(record)
		if self._muted.master or self._muted[record.kind] then return 0 end
		local factor = self._volumes.master
		if record.kind ~= "master" then factor *= self._volumes[record.kind] or 1 end
		if record.appId then
			if self:IsAppMuted(record.appId) then return 0 end
			factor *= self:GetAppVolume(record.appId)
		end
		return factor
	end

	function VolumeService:_apply(sound, record)
		if self._destroyed then return end
		record.applied = math.clamp(record.base * self:_factor(record), 0, 10)
		pcall(function() sound.Volume = record.applied end)
	end

	function VolumeService:_applyAll()
		for sound, record in pairs(self._sounds) do self:_apply(sound, record) end
	end

	function VolumeService:_register(sound, kind, appId, explicit)
		if self._destroyed or typeof(sound) ~= "Instance" or not sound:IsA("Sound") then return false end
		if kind ~= nil and not VALID[kind] then return false end
		local record = self._sounds[sound]
		local newRecord = not record
		local previousApp = record and record.appId
		if not record then
			record = {original = sound.Volume, base = sound.Volume, connections = {}, explicit = explicit}
			self._sounds[sound] = record
		end
		record.explicit = record.explicit or explicit
		if kind ~= nil then record.kindOverride = kind end
		if appId ~= nil then record.appOverride = tostring(appId) end
		local function classify()
			local markedKind = sound:GetAttribute("ZolinSoundKind") or sound:GetAttribute("ZolinVolumeKind")
			record.kind = record.kindOverride or (VALID[markedKind] and markedKind or "media")
			local markedApp = sound:GetAttribute("ZolinAppId")
			record.appId = record.appOverride or (markedApp ~= nil and tostring(markedApp) or nil)
		end
		classify()
		if newRecord then
			table.insert(record.connections, sound:GetPropertyChangedSignal("Volume"):Connect(function()
				if self._destroyed or self._sounds[sound] ~= record then return end
				-- Comparing the last applied value also works with deferred property signals.
				if record.applied and math.abs(sound.Volume - record.applied) < 0.00001 then return end
				record.base = sound.Volume
				self:_apply(sound, record)
			end))
			for _, attribute in ipairs({"ZolinSoundKind", "ZolinVolumeKind", "ZolinAppId"}) do
				table.insert(record.connections, sound:GetAttributeChangedSignal(attribute):Connect(function()
					if self._destroyed then return end
					local oldApp = record.appId
					classify()
					self:_apply(sound, record)
					if oldApp ~= record.appId then self:_renderAppRows() end
				end))
			end
			table.insert(record.connections, sound.Destroying:Connect(function() self:_removeSound(sound, false) end))
		end
		self:_apply(sound, record)
		if record.appId and (previousApp ~= record.appId) and not self._appRows[record.appId] then self:_renderAppRows() end
		return true
	end

	function VolumeService:RegisterSound(sound, kind, appId) return self:_register(sound, kind, appId, true) end

	function VolumeService:_removeSound(sound, restore)
		local record = self._sounds[sound]
		if not record then return end
		self._sounds[sound] = nil
		disconnect(record.connections)
		if restore then pcall(function() sound.Volume = record.original end) end
		if not self._destroyed and record.appId then self:_renderAppRows() end
	end

	function VolumeService:UnregisterSound(sound) self:_removeSound(sound, true) end

	function VolumeService:PlayNotification()
		if self._destroyed or self:IsMuted("master") or self:IsMuted("notifications") then return false end
		if self.ctx.Settings and self.ctx.Settings:Get("notifications.sound", true) == false then return false end
		if not self._notificationSound then
			local sound = Instance.new("Sound")
			sound.Name = "ZolinNotificationChime"
			sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			sound.Volume = 0.65
			sound:SetAttribute("ZolinOSSound", true)
			sound:SetAttribute("ZolinSoundKind", "notifications")
			self:RegisterSound(sound, "notifications")
			sound.Parent = self.ctx.Gui
			self._notificationSound = sound
		end
		local ok = pcall(function() self._notificationSound:Stop() self._notificationSound.TimePosition = 0 self._notificationSound:Play() end)
		return ok
	end

	function VolumeService:GetAppChannels()
		local counts = {}
		for _, record in pairs(self._sounds) do if record.appId then counts[record.appId] = (counts[record.appId] or 0) + 1 end end
		for id in pairs(self._appVolumes) do counts[id] = counts[id] or 0 end
		local result = {}
		for id, count in pairs(counts) do
			local metadata = self.ctx.Apps and self.ctx.Apps:GetMetadata(id)
			table.insert(result, {id = id, name = metadata and metadata.name or id, icon = metadata and metadata.icon, count = count, volume = self:GetAppVolume(id), muted = self:IsAppMuted(id)})
		end
		table.sort(result, function(a, b) return a.name:lower() < b.name:lower() end)
		return result
	end

	function VolumeService:_cancelTween(name)
		self._tweenSerials[name] = (self._tweenSerials[name] or 0) + 1
		local record = self._tweens[name]
		if record then record.connection:Disconnect(); record.tween:Cancel(); self._tweens[name] = nil end
	end

	function VolumeService:_animate(name, value, finish)
		self:_cancelTween(name)
		local reveal = name == "compact" and self._compactReveal or self._mixerReveal
		local serial = self._tweenSerials[name]
		local distance = math.abs(reveal.Value - value)
		if distance < 0.001 then reveal.Value = value; finish(); return end
		local tween = TweenService:Create(reveal, TweenInfo.new(0.25 * math.max(0.4, distance), Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Value = value})
		local connection
		connection = tween.Completed:Connect(function(state)
			if self._destroyed or self._tweenSerials[name] ~= serial or state ~= Enum.PlaybackState.Completed then return end
			connection:Disconnect(); self._tweens[name] = nil
			finish()
		end)
		self._tweens[name] = {tween = tween, connection = connection}
		tween:Play()
	end

	function VolumeService:_applyVisuals()
		if self._destroyed or not self._compactHeight then return end
		local compact = self._compactReveal.Value
		self._compact.Position = UDim2.new(1, -12 + (self._compactWidth + 24) * (1 - compact), 0, self._compactCenter)
		local mixer = self._mixerReveal.Value
		self._panel.Position = UDim2.new(0.5, 0, 0, self._mixerBottom + (self._mixerHeight + self._bottomInset + 24) * (1 - mixer))
		self._done.Position = UDim2.new(0.5, self._mixerWidth / 2 - 88, 0, self._panel.Position.Y.Offset - 46)
		self._backdrop.BackgroundTransparency = 1 - 0.3 * mixer
	end

	function VolumeService:_cancelIdle()
		self._idleSerial = (self._idleSerial or 0) + 1
		if self._idleThread then pcall(task.cancel, self._idleThread); self._idleThread = nil end
	end

	function VolumeService:_touchIdle()
		self:_cancelIdle()
		if self._destroyed or not self._open or self._mixerOpen or self._drag then return end
		local serial = self._idleSerial
		self._idleThread = task.delay(IDLE_SECONDS, function()
			self._idleThread = nil
			if not self._destroyed and self._idleSerial == serial and self._open and not self._drag and not self._mixerOpen then self:ClosePanel() end
		end)
	end

	function VolumeService:_stopKeys()
		self._heldKeys = {}
		self._keySerial = (self._keySerial or 0) + 1
		if self._keyThread then pcall(task.cancel, self._keyThread); self._keyThread = nil end
	end

	function VolumeService:_cancelDrags()
		self._drag = nil
		for _, sliders in ipairs({self._sliders, self._appSliders}) do
			for _, slider in pairs(sliders) do if type(slider.CancelDrag) == "function" then slider.CancelDrag() end end
		end
	end

	function VolumeService:_adjustKeyboard(delta, absolute)
		local value
		if self._mixerOpen and self._activeMixerApp then
			local id = self._activeMixerApp
			value = absolute or math.clamp(self:GetAppVolume(id) + delta, 0, 1)
			if value > 0 then self:SetAppMuted(id, false) end
			self:SetAppVolume(id, value)
		else
			local kind = self._mixerOpen and (self._activeMixerKind or "master") or "master"
			if not self._mixerOpen and not self._open then self:OpenPanel() end
			value = absolute or math.clamp(self:GetVolume(kind) + delta, 0, 1)
			if value > 0 then self:SetMuted(kind, false) end
			self:SetVolume(kind, value)
		end
		self:_touchIdle()
	end

	function VolumeService:_handleKey(input, processed)
		if self._destroyed then return end
		if input.KeyCode == Enum.KeyCode.Escape then if self._open or self._mixerOpen then self:ClosePanel() end; return end
		if type(UserInputService.GetFocusedTextBox) == "function" and UserInputService:GetFocusedTextBox() then return end
		if processed and not self._mixerOpen and not self._open then return end
		local key = input.KeyCode
		local minus = key == Enum.KeyCode.Minus or key == Enum.KeyCode.KeypadMinus
		local plus = key == Enum.KeyCode.Equals or key == Enum.KeyCode.KeypadPlus
		if not minus and not plus then
			if self._open and not self._mixerOpen then
				if key == Enum.KeyCode.Up or key == Enum.KeyCode.DPadUp then self:_adjustKeyboard(0.05)
				elseif key == Enum.KeyCode.Down or key == Enum.KeyCode.DPadDown then self:_adjustKeyboard(-0.05)
				elseif key == Enum.KeyCode.Home then self:_adjustKeyboard(0, 1)
				elseif key == Enum.KeyCode.End then self:_adjustKeyboard(0, 0) end
			end
			return
		end
		if self._heldKeys[key] then return end
		self:_adjustKeyboard((plus and 1 or -1) * 0.05)
		self._heldKeys[key] = plus and 1 or -1
		if self._keyThread then return end
		local serial = self._keySerial
		self._keyThread = task.spawn(function()
			task.wait(0.25)
			while not self._destroyed and serial == self._keySerial and next(self._heldKeys) do
				local direction = 0
				for _, sign in pairs(self._heldKeys) do direction += sign end
				if direction ~= 0 then self:_adjustKeyboard(math.sign(direction) * 0.02) end
				task.wait(0.06)
			end
			if serial == self._keySerial then self._keyThread = nil end
		end)
	end

	function VolumeService:_setCompactFromY(y)
		local height = self._outline.AbsoluteSize.Y
		if height <= 0 then return end
		local value = math.clamp(1 - (y - self._outline.AbsolutePosition.Y) / height, 0, 1)
		if value > 0 then self:SetMuted("master", false) end
		self:SetVolume("master", value)
	end

	function VolumeService:_beginCompactDrag(input)
		if self._destroyed or not self._open or self._mixerOpen or self._drag then return end
		local touch = input.UserInputType == Enum.UserInputType.Touch
		if not touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		self._drag = {pointer = input, touch = touch}
		self:_touchIdle()
		self:_setCompactFromY(input.Position.Y)
	end

	function VolumeService:_moveCompactDrag(input)
		local drag = self._drag
		if not drag then return end
		if drag.touch then if input ~= drag.pointer then return end
		elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		self:_setCompactFromY(input.Position.Y)
	end

	function VolumeService:_endCompactDrag(input)
		local drag = self._drag
		if not drag then return end
		if drag.touch then if input ~= drag.pointer then return end
		elseif input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		self._drag = nil
		self:_touchIdle()
	end

	function VolumeService:_buildPanel()
		local ui = self.ctx.UI
		self._overlay = ui.frame(self.ctx.OverlayRoot or self.ctx.Gui, {Name = "VolumeOverlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 9100})
		self._backdrop = ui.new("TextButton", self._overlay, {Name = "DismissPanel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 1, Text = "", Visible = false, ZIndex = 9101, AutoButtonColor = false})
		table.insert(self._connections, self._backdrop.Activated:Connect(function() self:ClosePanel() end))
		self._compact = ui.frame(self.ctx.OverlayRoot or self.ctx.Gui, {Name = "VolumeFrame", AnchorPoint = Vector2.new(1, 0.5), Visible = false, Active = true, BackgroundTransparency = 0.04, ClipsDescendants = true, ZIndex = 9103})
		ui.bevel(self._compact); ui.corner(self._compact, 26)
		self.VolumeFrame = self._compact
		self._percent = ui.text(self._compact, "", {Name = "Percentage", Position = UDim2.fromOffset(0, 9), Size = UDim2.new(1, 0, 0, 22), TextSize = 11})
		self._outline = ui.frame(self._compact, {Name = "OutlineStyle", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.new(0, 18, 1, -132)})
		ui.bind(self._outline, {BackgroundColor3 = "SurfaceAlt"}); ui.corner(self._outline, 10)
		self._fill = ui.frame(self._compact, {Name = "Fill", AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(18, 0)})
		ui.bind(self._fill, {BackgroundColor3 = "Accent"}); ui.corner(self._fill, 10)
		self._trackInput = ui.new("TextButton", self._compact, {Name = "TrackInput", Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -120), BackgroundTransparency = 1, Text = "", Active = true, Selectable = true})
		self._thumb = ui.new("TextButton", self._compact, {Name = "SliderButton", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(42, 26), BackgroundTransparency = 1, Text = "", Active = true, Selectable = true})
		self._thumb:SetAttribute("DisablePressFeedback", true)
		local thumbBar = ui.frame(self._thumb, {Name = "Thumb", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 6)})
		ui.bind(thumbBar, {BackgroundColor3 = "Text"}); ui.corner(thumbBar, 4)
		self._muteIcon = ui.button(self._compact, "♪", {Name = "VolumeIconButton", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -81), Size = UDim2.fromOffset(38, 38), TextSize = 21})
		ui.corner(self._muteIcon, 19)
		self._more = ui.button(self._compact, "•••", {Name = "MoreOptions", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -38), Size = UDim2.fromOffset(40, 28), BackgroundTransparency = 1, TextSize = 17})
		table.insert(self._connections, self._muteIcon.Activated:Connect(function() self:SetMuted("master", not self:IsMuted("master")); self:_touchIdle() end))
		table.insert(self._connections, self._more.Activated:Connect(function() self:OpenMixer() end))
		table.insert(self._connections, self._trackInput.InputBegan:Connect(function(input) self:_beginCompactDrag(input) end))
		table.insert(self._connections, self._thumb.InputBegan:Connect(function(input) self:_beginCompactDrag(input) end))
		table.insert(self._connections, self._compact.InputBegan:Connect(function() self:_touchIdle() end))
		table.insert(self._connections, self._compact.MouseEnter:Connect(function() self:_touchIdle() end))
		self._mixer = ui.frame(self.ctx.OverlayRoot or self.ctx.Gui, {Name = "VolumeStyleOptionsFrame", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 9104})
		self.VolumeStyleOptionsFrame = self._mixer
		local assets = ui.new("Folder", self._mixer, {Name = "Assets"})
		local rowTemplate = ui.frame(assets, {Name = "FrameTemplate", Size = UDim2.new(1, 0, 0, 56), Visible = false})
		ui.frame(rowTemplate, {Name = "OutlineStyle", Size = UDim2.new(1, -64, 0, 6), Position = UDim2.fromOffset(48, 25)})
		ui.frame(rowTemplate, {Name = "Fill", Size = UDim2.fromOffset(0, 6), Position = UDim2.fromOffset(48, 25)})
		ui.new("ImageButton", rowTemplate, {Name = "Icon", Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, Image = ""})
		self._panel = ui.frame(self._mixer, {Name = "UI", AnchorPoint = Vector2.new(0.5, 1), Active = true, ClipsDescendants = true, ZIndex = 9105})
		ui.bevel(self._panel); ui.corner(self._panel, 22)
		ui.text(self._panel, "Media & notifications", {Name = "Media_Notif", Position = UDim2.fromOffset(18, 14), Size = UDim2.new(1, -70, 0, 27), TextSize = 20, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left})
		local caption = ui.text(self._panel, "Fine-tune your sound", {Name = "Subtitle", Position = UDim2.fromOffset(18, 43), Size = UDim2.new(1, -36, 0, 19), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
		ui.bind(caption, {TextColor3 = "Muted"})
		local handle = ui.frame(self._panel, {Name = "underline", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(40, 4)})
		ui.bind(handle, {BackgroundColor3 = "Muted"}); ui.corner(handle, 3)
		self._done = ui.button(self._mixer, "Done", {Name = "DoneButton", Size = UDim2.fromOffset(72, 32), ZIndex = 9107, TextSize = 13})
		ui.bind(self._done, {BackgroundColor3 = "Accent", TextColor3 = "AccentText"})
		table.insert(self._connections, self._done.Activated:Connect(function() self:CloseMixer() end))
		self._scroll = ui.scroll(self._panel, {Name = "Channels", Position = UDim2.fromOffset(16, 74), Size = UDim2.new(1, -32, 1, -132)})
		ui.list(self._scroll, 10)
		for index, kind in ipairs(KINDS) do
			local name = ({master = "Master", media = "Media", notifications = "Notifications"})[kind]
			local frame, slider = ui.slider(self._scroll, {Name = name, Label = LABELS[kind], Value = self._volumes[kind], Changed = function(value) self:SetVolume(kind, value) end})
			frame.LayoutOrder = index
			slider.Label.Size = UDim2.new(1, -124, 0, 22)
			slider.Label.TextTruncate = Enum.TextTruncate.AtEnd
			local mute = ui.button(frame, "Mute", {Position = UDim2.new(1, -116, 0, 0), Size = UDim2.fromOffset(52, 22), TextSize = 13})
			table.insert(self._connections, mute.Activated:Connect(function() self:SetMuted(kind, not self:IsMuted(kind)) end))
			local function select() self._activeMixerKind, self._activeMixerApp = kind, nil end
			table.insert(self._connections, frame.InputBegan:Connect(select))
			table.insert(self._connections, frame.MouseEnter:Connect(select))
			table.insert(self._connections, frame.TrackInput.InputBegan:Connect(select))
			table.insert(self._connections, frame.TrackInput.SelectionGained:Connect(select))
			self._sliders[kind], self._rows[kind] = slider, mute
		end
		ui.text(self._scroll, "App channels", {Name = "AppChannelsHeading", LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 26), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left})
		self._appsFrame = ui.frame(self._scroll, {Name = "AppChannels", LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
		ui.list(self._appsFrame, 10)
		self._compactReveal = ui.new("NumberValue", self._overlay, {Name = "CompactReveal", Value = 0})
		self._mixerReveal = ui.new("NumberValue", self._overlay, {Name = "MixerReveal", Value = 0})
		table.insert(self._connections, self._compactReveal.Changed:Connect(function() self:_applyVisuals() end))
		table.insert(self._connections, self._mixerReveal.Changed:Connect(function() self:_applyVisuals() end))
		table.insert(self._connections, self._overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_layoutPanel() end))
		table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed) self:_handleKey(input, processed) end))
		table.insert(self._connections, UserInputService.InputChanged:Connect(function(input) self:_moveCompactDrag(input) end))
		table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
			self:_endCompactDrag(input)
			if input.KeyCode then self._heldKeys[input.KeyCode] = nil end
		end))
		table.insert(self._connections, UserInputService.WindowFocusReleased:Connect(function() self._drag = nil; self:_stopKeys(); self:_touchIdle() end))
		self:_layoutPanel()
		self:_refreshPanel()
	end

	function VolumeService:_layoutPanel()
		if self._destroyed or self._layingOut then return end
		self._layingOut = true
		self:_cancelDrags(); self:_stopKeys()
		self:_cancelTween("compact"); self:_cancelTween("mixer")
		local parent = self.ctx.OverlayRoot or self.ctx.Gui
		if self._overlay.Parent ~= parent then self._overlay.Parent = parent end
		if self._compact.Parent ~= parent then self._compact.Parent = parent end
		if self._mixer.Parent ~= parent then self._mixer.Parent = parent end
		local bounds = self._overlay.AbsoluteSize
		local insets = self.ctx.WindowInsets or {}
		local top = (insets.Top or self.ctx.WindowInsetsTop or 24) + 8
		local bottom = (insets.Bottom or self.ctx.WindowInsetsBottom or 40) + 8
		self._bottomInset = bottom
		local available = math.max(1, bounds.Y - top - bottom)
		self._compactWidth = math.max(1, math.min(62, bounds.X - 24))
		self._compactHeight = math.min(350, available)
		self._compactCenter = top + available / 2
		self._compact.Size = UDim2.fromOffset(self._compactWidth, self._compactHeight)
		self._outline.Size = UDim2.fromOffset(18, math.max(1, self._compactHeight - 132))
		self._trackInput.Size = UDim2.new(1, 0, 0, math.max(1, self._compactHeight - 120))
		self._mixerWidth = math.max(1, math.min(640, bounds.X - 24))
		self._mixerHeight = math.min(490, available)
		self._mixerBottom = bounds.Y - bottom
		self._panel.Size = UDim2.fromOffset(self._mixerWidth, self._mixerHeight)
		self._compactReveal.Value, self._mixerReveal.Value = self._open and 1 or 0, self._mixerOpen and 1 or 0
		self._compact.Visible, self._mixer.Visible, self._backdrop.Visible = self._open, self._mixerOpen, self._mixerOpen
		self:_applyVisuals(); self:_refreshPanel()
		self._layingOut = false
		self:_touchIdle()
	end

	function VolumeService:_renderAppRows()
		if self._destroyed or not self._appsFrame then return end
		disconnect(self._appConnections)
		for _, slider in pairs(self._appSliders) do slider.Destroy() end
		self._appSliders, self._appRows = {}, {}
		for _, child in ipairs(self._appsFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
		local channels = self:GetAppChannels()
		local ui = self.ctx.UI
		if #channels == 0 then
			local empty = ui.text(self._appsFrame, "App audio channels appear here.", {Size = UDim2.new(1, -6, 0, 40), TextWrapped = true, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
			ui.bind(empty, {TextColor3 = "Muted"})
		end
		for index, channel in ipairs(channels) do
			local id = channel.id
			local frame, slider = ui.slider(self._appsFrame, {Name = "AppVolume_" .. id, Label = channel.name, Value = channel.volume, Changed = function(value) self:SetAppVolume(id, value) end})
			frame.LayoutOrder = index
			slider.Label.Size = UDim2.new(1, -124, 0, 22)
			slider.Label.TextTruncate = Enum.TextTruncate.AtEnd
			local mute = ui.button(frame, "Mute", {Position = UDim2.new(1, -116, 0, 0), Size = UDim2.fromOffset(52, 22), TextSize = 13})
			local function select() self._activeMixerKind, self._activeMixerApp = nil, id end
			table.insert(self._appConnections, mute.Activated:Connect(function() select(); self:SetAppMuted(id, not self:IsAppMuted(id)) end))
			table.insert(self._appConnections, frame.InputBegan:Connect(select))
			table.insert(self._appConnections, frame.MouseEnter:Connect(select))
			table.insert(self._appConnections, frame.TrackInput.InputBegan:Connect(select))
			table.insert(self._appConnections, frame.TrackInput.SelectionGained:Connect(select))
			self._appSliders[id], self._appRows[id] = slider, mute
		end
		self:_refreshPanel()
	end

	function VolumeService:_refreshPanel()
		if not self._panel then return end
		local ui = self.ctx.UI
		local muted = self:IsMuted("master")
		local value = muted and 0 or self:GetVolume("master")
		local height = math.max(1, (self._compactHeight or 350) - 132)
		self._percent.Text = muted and "Muted" or tostring(math.floor(value * 100 + 0.5)) .. "%"
		self._fill.Position = UDim2.new(0.5, 0, 0, 40 + height)
		self._fill.Size = UDim2.fromOffset(18, height * value)
		self._thumb.Position = UDim2.new(0.5, 0, 0, 40 + (1 - value) * height)
		self._muteIcon.Text = (muted or value == 0) and "×" or "♪"
		ui.bind(self._muteIcon, {BackgroundColor3 = muted and "SurfaceAlt" or "Accent", TextColor3 = muted and "Muted" or "AccentText"})
		ui.bind(self._fill, {BackgroundColor3 = value > 0 and "Accent" or "Border"})
		self._compact:SetAttribute("Volume", self:GetVolume("master"))
		self._compact:SetAttribute("Muted", muted)
		local function update(button, muted)
			button.Text = muted and "Unmute" or "Mute"
			ui.bind(button, {BackgroundColor3 = muted and "Accent" or "SurfaceAlt", TextColor3 = muted and "AccentText" or "Text"})
		end
		for kind, slider in pairs(self._sliders) do slider.SetValue(self._volumes[kind], true) update(self._rows[kind], self:IsMuted(kind)) end
		for id, slider in pairs(self._appSliders) do slider.SetValue(self:GetAppVolume(id), true) update(self._appRows[id], self:IsAppMuted(id)) end
	end

	function VolumeService:_emit()
		if self._destroyed then return end
		self:_refreshPanel()
		local state = {volumes = table.clone(self._volumes), muted = table.clone(self._muted)}
		for callback in pairs(self._subscribers) do pcall(callback, state) end
		if self.ctx.Bus then self.ctx.Bus:Emit("volume.changed", state) end
	end

	function VolumeService:Subscribe(callback)
		if self._destroyed or type(callback) ~= "function" then return function() end end
		self._subscribers[callback] = true
		return function() self._subscribers[callback] = nil end
	end

	function VolumeService:OpenPanel()
		if self._destroyed then return end
		if self.ctx.Notifications then self.ctx.Notifications:ClosePanel() end
		self:CloseMixer()
		self._open, self._compact.Visible = true, true
		self:_refreshPanel()
		self:_animate("compact", 1, function() end)
		self:_touchIdle()
	end
	function VolumeService:ClosePanel()
		if self._destroyed then return end
		self._open = false; self:_cancelDrags()
		self:_stopKeys(); self:_cancelIdle()
		self:_animate("compact", 0, function() if not self._open then self._compact.Visible = false end end)
		self:CloseMixer()
	end
	function VolumeService:TogglePanel() if self._open or self._mixerOpen then self:ClosePanel() else self:OpenPanel() end end
	function VolumeService:IsPanelOpen() return self._open end

	function VolumeService:OpenMixer()
		if self._destroyed then return end
		if self.ctx.Notifications then self.ctx.Notifications:ClosePanel() end
		self._open = false; self:_cancelDrags()
		self:_stopKeys(); self:_cancelIdle()
		self:_animate("compact", 0, function() if not self._open then self._compact.Visible = false end end)
		self._mixerOpen, self._mixer.Visible, self._backdrop.Visible = true, true, true
		self:_renderAppRows()
		self:_animate("mixer", 1, function() end)
	end
	function VolumeService:CloseMixer()
		if self._destroyed then return end
		self:_cancelDrags()
		self:_stopKeys()
		self._mixerOpen = false
		self:_animate("mixer", 0, function() if not self._mixerOpen then self._mixer.Visible, self._backdrop.Visible = false, false end end)
	end
	function VolumeService:ToggleMixer() if self._mixerOpen then self:CloseMixer() else self:OpenMixer() end end
	function VolumeService:IsMixerOpen() return self._mixerOpen end

	function VolumeService:Destroy()
		if self._destroyed then return end
		self._destroyed = true
		self._drag = nil
		self:_cancelIdle(); self:_stopKeys()
		self:_cancelTween("compact"); self:_cancelTween("mixer")
		if self._settingsUnsubscribe then self._settingsUnsubscribe() end
		if self._modeUnsubscribe then self._modeUnsubscribe() end
		if self._resizeUnsubscribe then self._resizeUnsubscribe() end
		if self._appsUnsubscribe then self._appsUnsubscribe() end
		disconnect(self._connections)
		disconnect(self._appConnections)
		for _, slider in pairs(self._sliders) do slider.Destroy() end
		for _, slider in pairs(self._appSliders) do slider.Destroy() end
		local sounds = {}
		for sound in pairs(self._sounds) do table.insert(sounds, sound) end
		for _, sound in ipairs(sounds) do self:_removeSound(sound, true) end
		if self._notificationSound then self._notificationSound:Destroy() end
		self._compact:Destroy()
		self._mixer:Destroy()
		self._overlay:Destroy()
		table.clear(self._subscribers)
	end

	return VolumeService

end
-- END COMPONENT: VolumeService
-- BEGIN COMPONENT: NotificationService
__v3Factories["NotificationService"] = function()
	local NotificationService = {}
	NotificationService.__index = NotificationService

	local FALLBACK_ICON = ""
	local PRIORITY = {low = 1, normal = 2, high = 3, critical = 4}
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")

	local function disconnect(connections)
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
	end

	local function cancel(thread)
		if thread then pcall(task.cancel, thread) end
	end

	function NotificationService.new(ctx)
		local self = setmetatable({ctx = ctx, _history = {}, _queue = {}, _toasts = {}, _connections = {}, _historyConnections = {}, _rankConnections = {}, _subscribers = {}, _nextId = 0, _open = false, _destroyed = false}, NotificationService)
		self._dnd = ctx.Settings and ctx.Settings:Get("notifications.dnd", false) == true or false
		self:_buildPanel()
		if ctx.Bus then
			self._settingsUnsubscribe = ctx.Bus:On("settings.changed", function(change)
				if self._destroyed or self._saving or type(change) ~= "table" then return end
				if change.key == "notifications.dnd" then self:_setDND(change.value == true)
				elseif change.key == "notifications.style" then
					local visible = {}
					for id, toast in pairs(self._toasts) do table.insert(visible, toast.record); self:_removeToast(id) end
					for _, record in ipairs(visible) do table.insert(self._queue, record) end
					self:_pump()
				end
			end)
			self._modeUnsubscribe = ctx.Bus:On("mode.changed", function() self:_layout() end)
			self._resizeUnsubscribe = ctx.Bus:On("surface.resize", function() self:_layout() end)
		end
		if ctx.Apps and ctx.Apps.Subscribe then self._appsUnsubscribe = ctx.Apps:Subscribe(function() if not self._destroyed then self:_render() end end) end
		self:_render()
		return self
	end

	function NotificationService:_metadata(appId)
		local metadata = self.ctx.Apps and self.ctx.Apps:GetMetadata(appId)
		return metadata or {id = appId, name = appId == "system" and "ZolinOS" or appId, icon = FALLBACK_ICON}
	end

	function NotificationService:Push(data)
		if self._destroyed or type(data) ~= "table" then return nil end
		self._nextId += 1
		local appId = tostring(data.appId or "system")
		local metadata = self:_metadata(appId)
		local duration = tonumber(data.duration)
		if not duration or duration ~= duration then duration = 6 end
		local record = {
			id = "notification-" .. self._nextId, order = self._nextId, appId = appId,
			title = tostring(data.title or metadata.name or "ZolinOS"), message = tostring(data.message or data.body or data.description or ""),
			icon = tostring(data.icon or metadata.icon or FALLBACK_ICON), time = os.time(), read = self._open,
			duration = duration == 0 and 0 or math.clamp(duration, 2, 30),
			priority = type(data.priority) == "number" and math.clamp(data.priority, 1, 4) or PRIORITY[data.priority] or 2,
			actions = {},
		}
		for _, action in ipairs(type(data.actions) == "table" and data.actions or {}) do
			if type(action) == "table" and type(action.callback) == "function" then
				table.insert(record.actions, {text = tostring(action.text or "Open"), callback = action.callback})
				if #record.actions == 3 then break end
			end
		end
		table.insert(self._history, 1, record)
		if #self._history > 200 then
			local oldest = table.remove(self._history)
			self:_removeToast(oldest.id)
			self:_removeQueued(oldest.id)
		end
		if not self._dnd and not self._open then
			table.insert(self._queue, record)
			table.sort(self._queue, function(a, b) if a.priority == b.priority then return a.order < b.order end return a.priority > b.priority end)
			self:_pump()
		end
		self:_emit("push", record.id)
		return record.id
	end

	function NotificationService:GetHistory()
		local result = {}
		for _, record in ipairs(self._history) do
			local copy = table.clone(record)
			copy.actions = {}
			for _, action in ipairs(record.actions) do table.insert(copy.actions, table.clone(action)) end
			table.insert(result, copy)
		end
		return result
	end

	function NotificationService:GetUnreadCount(appId)
		local count = 0
		for _, record in ipairs(self._history) do if not record.read and (appId == nil or record.appId == appId) then count += 1 end end
		return count
	end

	function NotificationService:MarkAllRead(appId)
		if self._destroyed then return end
		for _, record in ipairs(self._history) do if appId == nil or record.appId == appId then record.read = true end end
		self:_emit("read")
	end

	function NotificationService:_removeQueued(id)
		for index = #self._queue, 1, -1 do if self._queue[index].id == id then table.remove(self._queue, index) end end
	end

	function NotificationService:_removeToast(id)
		local toast = self._toasts[id]
		if not toast then return end
		self._toasts[id] = nil
		cancel(toast.timer)
		disconnect(toast.connections)
		toast.frame:Destroy()
	end

	function NotificationService:Dismiss(id)
		if self._destroyed then return end
		for index = #self._history, 1, -1 do if self._history[index].id == id then table.remove(self._history, index) end end
		self:_removeQueued(id)
		self:_removeToast(id)
		self:_pump()
		self:_emit("dismiss", id)
	end

	function NotificationService:Clear(appId)
		if self._destroyed then return end
		for index = #self._history, 1, -1 do
			local record = self._history[index]
			if appId == nil or record.appId == appId then
				table.remove(self._history, index)
				self:_removeQueued(record.id)
				self:_removeToast(record.id)
			end
		end
		self:_pump()
		self:_emit("clear")
	end

	function NotificationService:GetDND() return self._dnd end

	function NotificationService:_setDND(enabled)
		if self._destroyed or self._dnd == enabled then return end
		self._dnd = enabled
		if enabled then
			local ids = {}
			for id in pairs(self._toasts) do table.insert(ids, id) end
			for _, id in ipairs(ids) do self:_removeToast(id) end
			table.clear(self._queue)
		end
		self:_emit("dnd")
	end

	function NotificationService:SetDND(enabled)
		if self._destroyed then return end
		enabled = enabled == true
		if self.ctx.Settings then
			self._saving = true
			self.ctx.Settings:Set("notifications.dnd", enabled)
			self._saving = false
		end
		self:_setDND(enabled)
	end

	function NotificationService:_runAction(record, action)
		if self._destroyed then return end
		record.read = true
		self:_removeToast(record.id)
		self:ClosePanel()
		self:_emit("action", record.id)
		local ok, err = pcall(action.callback, record)
		if not ok then warn("[ZolinOS Notification] " .. tostring(err)) end
		self:_pump()
	end

	function NotificationService:_card(parent, record, connections, toast)
		local ui = self.ctx.UI
		local frame = ui.frame(parent, {Name = toast and "NotificationToast" or "NotificationItem", Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = toast and record.order or -record.order, Active = true})
		frame:SetAttribute("NotificationId", record.id)
		frame:SetAttribute("AppId", record.appId)
		ui.bevel(frame)
		local legacyStyle = self.ctx.Settings and self.ctx.Settings:Get("notifications.style", "V3") == "V2"
		if toast and legacyStyle then
			frame.BackgroundColor3 = self.ctx.Theme:Get().SurfaceAlt
			frame.BackgroundTransparency = 0.04
			ui.corner(frame, 16)
			local stroke = frame:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Thickness = 1; stroke.Transparency = 0.18 end
			frame:SetAttribute("NotificationStyle", "V2")
		else
			frame:SetAttribute("NotificationStyle", "V3")
		end
		ui.pad(frame, 10)
		ui.list(frame, 6)
		local header = ui.frame(frame, {Name = "Header", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 27), BackgroundTransparency = 1})
		ui.appIcon(header, {id = record.appId, name = self:_metadata(record.appId).name, icon = record.icon}, {Name = "AppIcon", Size = UDim2.fromOffset(24, 24)})
		local title = ui.new("TextButton", header, {Name = "Title", Position = UDim2.fromOffset(31, 0), Size = UDim2.new(1, -62, 1, 0), Text = record.title, Font = Enum.Font.GothamBold, TextSize = 17, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, AutoButtonColor = false})
		if toast and legacyStyle then
			title.Text = (self:_metadata(record.appId).name or record.appId) .. "  ·  " .. record.title
			title.TextSize = 15
		end
		if not record.read then ui.bind(title, {TextColor3 = "Accent"}) end
		table.insert(connections, title.Activated:Connect(function() self:OpenPanel(record.appId) end))
		local close = ui.button(header, "×", {Name = "Dismiss", Position = UDim2.new(1, -26, 0, 0), Size = UDim2.fromOffset(26, 26), TextSize = 20})
		table.insert(connections, close.Activated:Connect(function() self:Dismiss(record.id) end))
		local message = record.message
		local excerptLimit = self.ctx.Mode == "Mobile" and 140 or 280
		if toast and #message > excerptLimit then
			local endByte = utf8.offset(message, 0, math.min(excerptLimit, #message)) or 1
			message = message:sub(1, endByte - 1) .. "…"
		end
		if message ~= "" then ui.text(frame, message, {Name = "Message", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}) end
		if not toast then
			local metadata = self:_metadata(record.appId)
			local stamp = os.date("%H:%M", record.time)
			local detail = ui.text(frame, (metadata.name or record.appId) .. "  ·  " .. stamp, {Name = "Timestamp", LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 19), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left})
			ui.bind(detail, {TextColor3 = "Muted"})
		end
		if #record.actions > 0 then
			local count = math.min(toast and 2 or 3, #record.actions)
			local actions = ui.frame(frame, {Name = "Actions", LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1})
			for index = 1, count do
				local action = record.actions[index]
				local button = ui.button(actions, action.text, {Name = "Action", Position = UDim2.new((index - 1) / count, 0, 0, 0), Size = UDim2.new(1 / count, -4, 1, 0), TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd})
				table.insert(connections, button.Activated:Connect(function() self:_runAction(record, action) end))
			end
		end
		return frame
	end

	function NotificationService:_pump()
		if self._destroyed or self._dnd or self._open or self._shadePresent then return end
		local count = 0
		for _ in pairs(self._toasts) do count += 1 end
		while count < (self._toastLimit or 3) and #self._queue > 0 do
			local record = table.remove(self._queue, 1)
			local entry = {connections = {}, record = record}
			entry.frame = self:_card(self._toastStack, record, entry.connections, true)
			self._toasts[record.id] = entry
			if record.duration > 0 then
				entry.timer = task.delay(record.duration, function()
					entry.timer = nil
					if self._destroyed then return end
					self:_removeToast(record.id)
					self:_pump()
				end)
			end
			if self.ctx.Volume and (not self._lastChime or os.clock() - self._lastChime > 0.25) then
				self._lastChime = os.clock()
				self.ctx.Volume:PlayNotification()
			end
			count += 1
		end
	end

	function NotificationService:_cancelAnimation()
		self._animationSerial = (self._animationSerial or 0) + 1
		if self._animationConnection then self._animationConnection:Disconnect(); self._animationConnection = nil end
		if self._animation then self._animation:Cancel(); self._animation = nil end
	end

	function NotificationService:_applyReveal()
		if self._destroyed or not self._panelHeight then return end
		local progress = math.clamp(self._reveal.Value, 0, 1)
		self._panel.Position = UDim2.new(0.5, 0, 0, self._top - self._travel * (1 - progress))
		self._backdrop.BackgroundTransparency = 1 - progress * 0.36
		self._toastStack.Visible = progress < 0.001 and not self._open
	end

	function NotificationService:_finishAnimation(serial, target)
		if self._destroyed or serial ~= self._animationSerial then return end
		self._reveal.Value = target
		if target == 0 and not self._open then
			self._shadePresent = false
			self._panel.Visible, self._backdrop.Visible, self._toastStack.Visible = false, false, true
			self:_pump()
		end
	end

	function NotificationService:_animateTo(target)
		if self._destroyed then return end
		self:_cancelAnimation()
		local serial = self._animationSerial
		self._shadePresent = true
		self._panel.Visible, self._backdrop.Visible = true, true
		local distance = math.abs(self._reveal.Value - target)
		if distance < 0.001 then self:_finishAnimation(serial, target); return end
		local tween = TweenService:Create(self._reveal, TweenInfo.new(0.3 * math.max(0.35, distance), Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Value = target})
		self._animation = tween
		self._animationConnection = tween.Completed:Connect(function(state)
			if self._destroyed or serial ~= self._animationSerial or state ~= Enum.PlaybackState.Completed then return end
			self._animationConnection:Disconnect(); self._animationConnection = nil
			self._animation = nil
			self:_finishAnimation(serial, target)
		end)
		tween:Play()
	end

	function NotificationService:ShouldIgnoreClick()
		return os.clock() < (self._swipeSuppressUntil or 0)
	end

	local function inside(object, point)
		if typeof(object) ~= "Instance" or not object:IsA("GuiObject") then return false end
		local ancestor = object
		while ancestor and ancestor:IsA("GuiObject") do
			if not ancestor.Visible then return false end
			ancestor = ancestor.Parent
		end
		local position, size = object.AbsolutePosition, object.AbsoluteSize
		return size.X > 0 and size.Y > 0 and point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
	end

	local function inputPoint(input) return Vector2.new(input.Position.X, input.Position.Y) end

	function NotificationService:_beginGesture(input)
		if self._destroyed or self._gesture then return end
		local touch = input.UserInputType == Enum.UserInputType.Touch
		if not touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local point = inputPoint(input)
		local status = self.ctx.Shell and self.ctx.Shell.StatusBar
		if status then
			for _, control in ipairs(status:GetDescendants()) do
				if control:GetAttribute("PreventNotificationSwipe") == true and inside(control, point) then return end
			end
		end
		if self._open then
			for _, control in ipairs(self._headerControls or {}) do
				if control:GetAttribute("PreventNotificationSwipe") == true and inside(control, point) then return end
			end
		end
		local opening = not self._open
		if opening then
			if not inside(status, point) then return end
		else
			local header = inside(self._titlebar, point) and point.X < self._titlebar.AbsolutePosition.X + self._titlebar.AbsoluteSize.X - 42
			if not header and not inside(self._handle, point) and not inside(status, point) then return end
		end
		self._gesture = {pointer = input, touch = touch, origin = point, last = point, start = self._reveal.Value, opening = opening, claimed = false}
	end

	function NotificationService:_moveGesture(input)
		local gesture = self._gesture
		if not gesture then return end
		if gesture.touch then if input ~= gesture.pointer then return end
		elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local point = inputPoint(input)
		local delta = point - gesture.origin
		if not gesture.claimed then
			if math.abs(delta.X) > 10 and math.abs(delta.X) > math.abs(delta.Y) * 1.15 then self._gesture = nil; return end
			if math.abs(delta.Y) < 10 then return end
			if (gesture.opening and delta.Y < 0) or (not gesture.opening and delta.Y > 0) then self._gesture = nil; return end
			gesture.claimed = true
			self:_cancelAnimation()
			self._shadePresent = true
			self._panel.Visible, self._backdrop.Visible = true, true
		end
		gesture.last = point
		self._swipeSuppressUntil = os.clock() + 0.35
		self._reveal.Value = math.clamp(gesture.start + delta.Y / math.max(1, self._travel), 0, 1)
	end

	function NotificationService:_endGesture(input)
		local gesture = self._gesture
		if not gesture then return end
		if gesture.touch then if input ~= gesture.pointer then return end
		elseif input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		self._gesture = nil
		if not gesture.claimed then return end
		self._swipeSuppressUntil = os.clock() + 0.35
		local delta = gesture.last.Y - gesture.origin.Y
		local threshold = math.min(72, math.max(32, self._panelHeight * 0.18))
		if gesture.opening then
			if delta >= threshold or self._reveal.Value >= 0.5 then self:OpenPanel() else self:_animateTo(0) end
		else
			if -delta >= threshold or self._reveal.Value <= 0.5 then self:ClosePanel() else self:_animateTo(1) end
		end
	end

	function NotificationService:_buildPanel()
		local ui = self.ctx.UI
		self._overlay = ui.frame(self.ctx.OverlayRoot or self.ctx.Gui, {Name = "NotificationOverlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 9200})
		self._backdrop = ui.new("TextButton", self._overlay, {Name = "DismissPanel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 1, Text = "", Visible = false, ZIndex = 9201, AutoButtonColor = false})
		table.insert(self._connections, self._backdrop.Activated:Connect(function() self:ClosePanel() end))
		self._panel = ui.frame(self._overlay, {Name = "NotificationCenter", AnchorPoint = Vector2.new(0.5, 0), Visible = false, Active = true, ClipsDescendants = true, ZIndex = 9202})
		ui.bevel(self._panel)
		ui.corner(self._panel, 20)
		local title = ui.frame(self._panel, {Name = "Titlebar", Size = UDim2.new(1, 0, 0, 40), Active = true})
		self._titlebar = title
		ui.bind(title, {BackgroundColor3 = "Title"})
		ui.titleGradient(title)
		local caption = ui.text(title, "Notifications", {Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -58, 1, 0), TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left})
		self._caption = caption
		ui.bind(caption, {TextColor3 = "TitleText"})
		local close = ui.button(title, "×", {Position = UDim2.new(1, -36, 0, 5), Size = UDim2.fromOffset(30, 30), TextSize = 22})
		self._closeButton = close
		table.insert(self._connections, close.Activated:Connect(function() self:ClosePanel() end))
		self._dndButton = ui.button(self._panel, "", {Name = "DoNotDisturb", Position = UDim2.fromOffset(12, 50), Size = UDim2.new(0.61, -16, 0, 34), TextSize = 14})
		table.insert(self._connections, self._dndButton.Activated:Connect(function() self:SetDND(not self:GetDND()) end))
		local clear = ui.button(self._panel, "Clear", {Name = "ClearNotifications", Position = UDim2.new(0.61, 0, 0, 50), Size = UDim2.new(0.39, -12, 0, 34), TextSize = 14})
		self._clearButton = clear
		self._headerControls = {self._dndButton, clear, close}
		for _, control in ipairs(self._headerControls) do control:SetAttribute("PreventNotificationSwipe", true) end
		table.insert(self._connections, clear.Activated:Connect(function() self:Clear(self._filter) end))
		-- This remains a Frame: each app owns an ImageLabel and unread badge inside it.
		self.NotificationRankList = ui.frame(self._panel, {Name = "NotificationRankList", Position = UDim2.fromOffset(12, 96), Size = UDim2.new(1, -24, 0, 62), BackgroundTransparency = 1})
		self._rankScroll = ui.scroll(self.NotificationRankList, {Name = "AppIcons", Size = UDim2.fromScale(1, 1), ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollBarThickness = 3})
		local layout = ui.list(self._rankScroll, 7)
		layout.FillDirection = Enum.FillDirection.Horizontal
		self._historyScroll = ui.scroll(self._panel, {Name = "NotificationHistory", Position = UDim2.fromOffset(12, 170), Size = UDim2.new(1, -24, 1, -200)})
		ui.list(self._historyScroll, 9)
		self._handle = ui.new("TextButton", self._panel, {Name = "ShadeHandle", Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 24), Text = "", BackgroundTransparency = 1, Active = true, AutoButtonColor = false})
		local pill = ui.frame(self._handle, {Name = "DragPill", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(44, 4)})
		ui.bind(pill, {BackgroundColor3 = "Muted"}); ui.corner(pill, 4)
		self._toastStack = ui.frame(self._overlay, {Name = "ToastQueue", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 9203})
		ui.list(self._toastStack, 8)
		self._reveal = ui.new("NumberValue", self._overlay, {Name = "ShadeReveal", Value = 0})
		table.insert(self._connections, self._reveal.Changed:Connect(function() self:_applyReveal() end))
		table.insert(self._connections, self._overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_layout() end))
		table.insert(self._connections, UserInputService.InputBegan:Connect(function(input)
			if self._open and input.KeyCode == Enum.KeyCode.Escape then self:ClosePanel(); return end
			self:_beginGesture(input)
		end))
		table.insert(self._connections, UserInputService.InputChanged:Connect(function(input) self:_moveGesture(input) end))
		table.insert(self._connections, UserInputService.InputEnded:Connect(function(input) self:_endGesture(input) end))
		table.insert(self._connections, UserInputService.WindowFocusReleased:Connect(function()
			if self._gesture then self._gesture = nil; self:_animateTo(self._open and 1 or 0) end
		end))
		self:_layout()
	end

	function NotificationService:_layout()
		if self._destroyed or self._layingOut then return end
		self._layingOut = true
		local parent = self.ctx.OverlayRoot or self.ctx.Gui
		if self._overlay.Parent ~= parent then self._overlay.Parent = parent end
		self._gesture = nil
		self:_cancelAnimation()
		local bounds = self._overlay.AbsoluteSize
		local insets = self.ctx.WindowInsets or {}
		local top = tonumber(insets.Top or self.ctx.WindowInsetsTop) or 36
		local bottom = tonumber(insets.Bottom or self.ctx.WindowInsetsBottom) or 48
		self._top = math.max(0, top)
		self._panelHeight = math.max(1, bounds.Y - self._top - math.max(0, bottom) - 8)
		self._travel = self._panelHeight + 12
		local width = math.max(1, math.min(620, bounds.X - 16))
		self._panel.Size = UDim2.fromOffset(width, self._panelHeight)
		local oldCompact, oldRankHeight = self._compactRanks, self._rankButtonHeight
		self._compactRanks = self._panelHeight < 340
		local landscape = self._compactRanks and width >= 500
		self._rankButtonHeight = self._compactRanks and (landscape and 42 or 38) or 55
		if landscape then
			self._titlebar.Size = UDim2.new(1, 0, 0, 36)
			self._caption.Position, self._caption.Size, self._caption.TextSize = UDim2.fromOffset(16, 0), UDim2.new(1, -284, 1, 0), 17
			self._dndButton.Position, self._dndButton.Size, self._dndButton.TextSize = UDim2.new(1, -246, 0, 4), UDim2.fromOffset(142, 28), 12
			self._clearButton.Position, self._clearButton.Size, self._clearButton.TextSize = UDim2.new(1, -96, 0, 4), UDim2.fromOffset(56, 28), 12
			self.NotificationRankList.Position, self.NotificationRankList.Size = UDim2.fromOffset(12, 44), UDim2.new(1, -24, 0, 44)
			self._historyScroll.Position, self._historyScroll.Size = UDim2.fromOffset(12, 98), UDim2.new(1, -24, 1, -128)
		elseif self._compactRanks then
			self._titlebar.Size = UDim2.new(1, 0, 0, 32)
			self._caption.Position, self._caption.Size, self._caption.TextSize = UDim2.fromOffset(12, 0), UDim2.new(1, -52, 1, 0), 17
			self._dndButton.Position, self._dndButton.Size, self._dndButton.TextSize = UDim2.fromOffset(12, 36), UDim2.new(0.61, -16, 0, 26), 12
			self._clearButton.Position, self._clearButton.Size, self._clearButton.TextSize = UDim2.new(0.61, 0, 0, 36), UDim2.new(0.39, -12, 0, 26), 12
			self.NotificationRankList.Position, self.NotificationRankList.Size = UDim2.fromOffset(12, 68), UDim2.new(1, -24, 0, 40)
			self._historyScroll.Position, self._historyScroll.Size = UDim2.fromOffset(12, 116), UDim2.new(1, -24, 1, -146)
		else
			self._titlebar.Size = UDim2.new(1, 0, 0, 40)
			self._caption.Position, self._caption.Size, self._caption.TextSize = UDim2.fromOffset(16, 0), UDim2.new(1, -58, 1, 0), 19
			self._dndButton.Position, self._dndButton.Size, self._dndButton.TextSize = UDim2.fromOffset(12, 50), UDim2.new(0.61, -16, 0, 34), 14
			self._clearButton.Position, self._clearButton.Size, self._clearButton.TextSize = UDim2.new(0.61, 0, 0, 50), UDim2.new(0.39, -12, 0, 34), 14
			self.NotificationRankList.Position, self.NotificationRankList.Size = UDim2.fromOffset(12, 96), UDim2.new(1, -24, 0, 62)
			self._historyScroll.Position, self._historyScroll.Size = UDim2.fromOffset(12, 170), UDim2.new(1, -24, 1, -200)
		end
		self._closeButton.Position = UDim2.new(1, -36, 0, self._compactRanks and 2 or 5)
		if oldCompact ~= self._compactRanks or oldRankHeight ~= self._rankButtonHeight then self:_renderRanks() end
		self._reveal.Value = self._open and 1 or 0
		self._shadePresent = self._open
		self._panel.Visible, self._backdrop.Visible = self._open, self._open
		self:_applyReveal()
		self._toastStack.Position = UDim2.new(1, -12, 0, self._top + 8)
		self._toastStack.Size = UDim2.new(0, math.max(1, math.min(340, bounds.X - 24)), 0, 0)
		self._toastLimit = self.ctx.Mode == "Mobile" and 1 or math.clamp(math.floor(math.max(0, bounds.Y - 24) / 210), 1, 3)
		local active = {}
		for _, toast in pairs(self._toasts) do table.insert(active, toast.record) end
		table.sort(active, function(a, b) return a.order < b.order end)
		for index = self._toastLimit + 1, #active do
			local record = active[index]
			self:_removeToast(record.id)
			if not self._dnd and not self._open then table.insert(self._queue, record) end
		end
		table.sort(self._queue, function(a, b) if a.priority == b.priority then return a.order < b.order end return a.priority > b.priority end)
		self._layingOut = false
		self:_pump()
	end

	function NotificationService:_renderRanks()
		disconnect(self._rankConnections)
		for _, child in ipairs(self._rankScroll:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
		local ui, groups, order = self.ctx.UI, {}, {}
		for _, record in ipairs(self._history) do
			if not groups[record.appId] then groups[record.appId] = {unread = 0} table.insert(order, record.appId) end
			if not record.read then groups[record.appId].unread += 1 end
		end
		if self._filter and not groups[self._filter] then self._filter = nil end
		local function appButton(appId, index)
			local metadata = appId and self:_metadata(appId) or {name = "All", icon = FALLBACK_ICON}
			local selected = self._filter == appId
			local compact = self._compactRanks
			local button = ui.new("TextButton", self._rankScroll, {Name = appId and "AppGroup" or "AllGroups", Size = UDim2.fromOffset(compact and 48 or 54, self._rankButtonHeight or 55), LayoutOrder = index, Text = "", AutoButtonColor = true})
			button:SetAttribute("AppId", appId or "")
			ui.bind(button, {BackgroundColor3 = selected and "Accent" or "SurfaceAlt"})
			ui.bevel(button)
			local iconSize = compact and 22 or 24
			local _, letter = ui.appIcon(button, metadata, {Name = "AppIcon", Position = UDim2.fromOffset(compact and 13 or 15, compact and 1 or 4), Size = UDim2.fromOffset(iconSize, iconSize)})
			ui.bind(letter, {TextColor3 = selected and "AccentText" or "Text"})
			local caption = ui.text(button, metadata.name, {Position = UDim2.fromOffset(3, compact and 24 or 31), Size = UDim2.new(1, -6, 0, compact and 14 or 19), TextSize = compact and 10 or 11, TextTruncate = Enum.TextTruncate.AtEnd})
			ui.bind(caption, {TextColor3 = selected and "AccentText" or "Text"})
			local unread = appId and groups[appId].unread or self:GetUnreadCount()
			button:SetAttribute("UnreadCount", unread)
			local badge = ui.text(button, unread > 99 and "99+" or tostring(unread), {Name = "UnreadBadge", Position = UDim2.new(1, -21, 0, 1), Size = UDim2.fromOffset(20, 17), TextSize = 11, BackgroundTransparency = 0, Visible = unread > 0})
			ui.bind(badge, {BackgroundColor3 = "Title", TextColor3 = "TitleText"})
			table.insert(self._rankConnections, button.Activated:Connect(function() self._filter = appId self:_render() end))
		end
		appButton(nil, 0)
		for index, appId in ipairs(order) do appButton(appId, index) end
	end

	function NotificationService:_render()
		if self._destroyed then return end
		self._dndButton.Text = self._dnd and "Do not disturb: On" or "Do not disturb: Off"
		self.ctx.UI.bind(self._dndButton, {BackgroundColor3 = self._dnd and "Accent" or "SurfaceAlt", TextColor3 = self._dnd and "AccentText" or "Text"})
		self:_renderRanks()
		disconnect(self._historyConnections)
		for _, child in ipairs(self._historyScroll:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
		local count = 0
		for _, record in ipairs(self._history) do
			if not self._filter or record.appId == self._filter then self:_card(self._historyScroll, record, self._historyConnections, false) count += 1 end
		end
		if count == 0 then
			local text = self.ctx.UI.text(self._historyScroll, "You're all caught up.", {Name = "EmptyState", Size = UDim2.new(1, -6, 0, 80), TextSize = 17, TextWrapped = true})
			self.ctx.UI.bind(text, {TextColor3 = "Muted"})
		end
	end

	function NotificationService:_emit(action, id)
		if self._destroyed then return end
		self:_render()
		local state = {action = action, id = id, unread = self:GetUnreadCount(), total = #self._history, dnd = self._dnd}
		for callback in pairs(self._subscribers) do pcall(callback, state) end
		if self.ctx.Bus then self.ctx.Bus:Emit("notifications.changed", state) end
	end

	function NotificationService:Subscribe(callback)
		if self._destroyed or type(callback) ~= "function" then return function() end end
		self._subscribers[callback] = true
		return function() self._subscribers[callback] = nil end
	end

	function NotificationService:OpenPanel(appId)
		if self._destroyed then return end
		self._gesture = nil
		if self.ctx.Volume then self.ctx.Volume:ClosePanel() end
		self._open, self._filter = true, appId
		local ids = {}
		for id in pairs(self._toasts) do table.insert(ids, id) end
		for _, id in ipairs(ids) do self:_removeToast(id) end
		table.clear(self._queue)
		self:MarkAllRead()
		self:_animateTo(1)
	end
	function NotificationService:ClosePanel()
		if self._destroyed then return end
		self._gesture = nil
		self._open = false
		self:_animateTo(0)
	end
	function NotificationService:TogglePanel() if self._open then self:ClosePanel() else self:OpenPanel() end end

	function NotificationService:Destroy()
		if self._destroyed then return end
		self._destroyed = true
		self._gesture = nil
		self:_cancelAnimation()
		if self._settingsUnsubscribe then self._settingsUnsubscribe() end
		if self._modeUnsubscribe then self._modeUnsubscribe() end
		if self._resizeUnsubscribe then self._resizeUnsubscribe() end
		if self._appsUnsubscribe then self._appsUnsubscribe() end
		disconnect(self._connections)
		disconnect(self._rankConnections)
		disconnect(self._historyConnections)
		local ids = {}
		for id in pairs(self._toasts) do table.insert(ids, id) end
		for _, id in ipairs(ids) do self:_removeToast(id) end
		table.clear(self._queue)
		table.clear(self._history)
		table.clear(self._subscribers)
		self._overlay:Destroy()
	end

	return NotificationService

end
-- END COMPONENT: NotificationService
-- BEGIN COMPONENT: PowerService
__v3Factories["PowerService"] = function()
	local PowerService = {}
	PowerService.__index = PowerService

	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")

	function PowerService.new(ctx)
		return setmetatable({ctx = ctx, connections = {}, open = false, destroyed = false}, PowerService)
	end

	function PowerService:Open()
		if self.open or self.destroyed or self.ctx.destroyed then return false end
		self.open = true
		local ui, ctx = self.ctx.UI, self.ctx
		local overlay = ui.frame(ctx.Gui, {Name = "PowerOffOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 12000, ClipsDescendants = true})
		self.overlay = overlay
		local sheet = ui.frame(overlay, {Name = "PowerOffCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.new(0.82, 0, 0, 198), ZIndex = 12001})
		sheet.Size = UDim2.new(0.82, 0, 0, 198)
		ui.corner(sheet, 22); ui.pad(sheet, 16); ui.list(sheet, 10)
		local title = ui.text(sheet, "Power off ZolinOS?", {Name = "Title", Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.GothamBold, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left})
		local detail = ui.text(sheet, "This closes your open app windows and turns off the ZolinOS interface.", {Name = "Description", Size = UDim2.new(1, 0, 0, 34), TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left})
		ui.bind(detail, {TextColor3 = "Muted"})
		local track = ui.frame(sheet, {Name = "PowerSliderTrack", Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 0.1, Active = true})
		ui.corner(track, UDim.new(0.5, 0)); ui.bind(track, {BackgroundColor3 = "SurfaceAlt"})
		local fill = ui.frame(track, {Name = "PowerSliderFill", Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 0.12})
		ui.corner(fill, UDim.new(0.5, 0)); ui.bind(fill, {BackgroundColor3 = "Accent"})
		local hint = ui.text(track, "Slide to power off", {Name = "SliderHint", Size = UDim2.fromScale(1, 1), TextSize = 13, BackgroundTransparency = 1, ZIndex = 12002})
		local knob = ui.button(track, "⏻", {Name = "PowerSliderKnob", Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(44, 44), TextSize = 23, ZIndex = 12003})
		ui.corner(knob, UDim.new(1, 0)); knob:SetAttribute("DisablePressFeedback", true)
		local cancel = ui.button(sheet, "Cancel", {Name = "CancelPowerOff", Size = UDim2.new(1, 0, 0, 32), TextSize = 12})
		local dragging, pointer, startX, startOffset, completed = false, nil, 0, 3, false
		local sessionConnections = {}
		local function listen(signal, callback)
			local connection = signal:Connect(callback)
			table.insert(sessionConnections, connection)
			return connection
		end
		local function cleanup()
			if not overlay.Parent then return end
			self.open = false; self.overlay = nil
			for _, connection in ipairs(sessionConnections) do connection:Disconnect() end
			table.clear(sessionConnections)
			TweenService:Create(overlay, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
			task.delay(0.16, function() if overlay.Parent then overlay:Destroy() end end)
		end
		local function positionAt(x)
			local maxOffset = math.max(3, track.AbsoluteSize.X - knob.AbsoluteSize.X - 6)
			local offset = math.clamp(x - startX + startOffset, 3, maxOffset)
			local progress = (offset - 3) / math.max(1, maxOffset - 3)
			knob.Position = UDim2.fromOffset(offset, 3)
			fill.Size = UDim2.new(progress, 0, 1, 0)
			hint.TextTransparency = progress * 0.7
			if progress >= 0.985 and not completed then
				completed = true; dragging = false; self.open = false
				for _, app in ipairs(ctx.Apps:GetRunning()) do ctx.Apps:Close(app.id, false, true) end
				task.delay(0.18, function()
					if self.destroyed or ctx.destroyed then return end
					local runtime = ctx.Stop
					if type(runtime) == "function" then runtime() else ctx.Gui:Destroy() end
				end)
			end
		end
		listen(knob.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging, pointer = true, input; startX, startOffset = input.Position.X, knob.Position.X.Offset
			end
		end)
		listen(UserInputService.InputChanged, function(input)
			if not dragging then return end
			if input == pointer or (pointer and pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then positionAt(input.Position.X) end
		end)
		listen(UserInputService.InputEnded, function(input)
			if dragging and (input == pointer or input.UserInputType == Enum.UserInputType.MouseButton1) then
				dragging, pointer = false, nil
				if not completed then
					TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(3, 3)}):Play()
					TweenService:Create(fill, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0, 1, 0)}):Play()
					hint.TextTransparency = 0
				end
			end
		end)
		listen(cancel.Activated, cleanup)
		listen(overlay.Destroying, function()
			self.open = false; self.overlay = nil
			for _, connection in ipairs(sessionConnections) do connection:Disconnect() end
			table.clear(sessionConnections)
		end)
		TweenService:Create(overlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.38}):Play()
		return true
	end

	function PowerService:Close()
		if self.overlay and self.overlay.Parent then self.overlay:Destroy() end
		self.overlay, self.open = nil, false
	end

	function PowerService:Toggle()
		if self.open then self:Close(); return false end
		return self:Open()
	end

	function PowerService:IsOpen() return self.open end

	function PowerService:Destroy()
		if self.destroyed then return end
		self.destroyed = true
		for _, connection in ipairs(self.connections) do connection:Disconnect() end
		table.clear(self.connections)
		self:Close()
	end

	return PowerService

end
-- END COMPONENT: PowerService
-- BEGIN COMPONENT: ClockService
__v3Factories["ClockService"] = function()
	local ClockService = {}

	local function validNumber(value)
		return type(value) == "number" and value == value and value > -math.huge and value < math.huge
	end

	local function nextAlarm(hour, minute, now)
		local date = DateTime.fromUnixTimestamp(now):ToLocalTime()
		local result = DateTime.fromLocalTime(date.Year, date.Month, date.Day, hour, minute, 0).UnixTimestamp
		if result <= now then
			-- Advance the calendar in UTC, then construct the next local date. Adding
			-- 24 hours to a local alarm would drift across daylight-saving changes.
			local calendar = DateTime.fromUniversalTime(date.Year, date.Month, date.Day).UnixTimestamp
			date = DateTime.fromUnixTimestamp(calendar + 86400):ToUniversalTime()
			result = DateTime.fromLocalTime(date.Year, date.Month, date.Day, hour, minute, 0).UnixTimestamp
		end
		return result
	end

	local function localDay(timestamp)
		local date = DateTime.fromUnixTimestamp(timestamp):ToLocalTime()
		return string.format("%04d-%02d-%02d", date.Year, date.Month, date.Day)
	end

	function ClockService.new(ctx)
		local self = {timers = {}, alarms = {}, sequence = 0, destroyed = false}
		local elapsed = 0
		local function changed(kind, id)
			if ctx.Bus then ctx.Bus:Emit("clock.changed", {kind = kind, id = id}) end
		end
		local function nameFor(value, fallback)
			if value == nil then return fallback end
			if type(value) ~= "string" then return nil, "Enter a valid name." end
			value = value:match("^%s*(.-)%s*$")
			if #value > 160 then return nil, "Use a shorter name." end
			return value ~= "" and value or fallback
		end
		local function notify(title, message, tab)
			if not ctx.Notifications then return end
			pcall(function()
				ctx.Notifications:Push({appId = "Clock", title = title, message = message, duration = 12,
					actions = {{text = "Open Clock", callback = function()
						if not self.destroyed and ctx.Apps then ctx.Apps:Launch("Clock", {tab = tab}) end
					end}}})
			end)
		end
		function self:GetTimers()
			local result, now = {}, os.clock()
			for _, timer in pairs(self.timers) do
				table.insert(result, {id = timer.id, name = timer.name, duration = timer.duration, state = timer.state,
					remaining = timer.state == "running" and math.max(0, timer.deadline - now) or timer.remaining,
					deadline = timer.deadline, sequence = timer.sequence})
			end
			table.sort(result, function(a, b) return a.sequence < b.sequence end)
			return result
		end
		function self:AddTimer(name, seconds)
			if self.destroyed then return nil, "Clock service is unavailable." end
			if not validNumber(seconds) or seconds <= 0 or seconds > 604800 then return nil, "Duration must be greater than zero and at most seven days." end
			local title, err = nameFor(name, "Timer")
			if not title then return nil, err end
			self.sequence = self.sequence + 1
			local id = "timer-" .. self.sequence
			self.timers[id] = {id = id, name = title, duration = seconds, remaining = seconds,
				state = "running", deadline = os.clock() + seconds, sequence = self.sequence}
			changed("timer.added", id)
			return id
		end
		function self:PauseTimer(id)
			local timer = self.timers[id]
			if self.destroyed or not timer or timer.state ~= "running" then return false end
			timer.remaining = math.max(0, timer.deadline - os.clock())
			if timer.remaining <= 0 then
				timer.deadline, timer.state = nil, "completed"
				notify("Timer finished", timer.name .. " has finished.", "Timers")
				changed("timer.completed", id)
				return true
			end
			timer.deadline, timer.state = nil, "paused"
			changed("timer.paused", id)
			return true
		end
		function self:ResumeTimer(id)
			local timer = self.timers[id]
			if self.destroyed or not timer or timer.state == "running" then return false end
			if timer.remaining <= 0 then timer.remaining = timer.duration end
			timer.deadline, timer.state = os.clock() + timer.remaining, "running"
			changed("timer.resumed", id)
			return true
		end
		function self:ResetTimer(id)
			local timer = self.timers[id]
			if self.destroyed or not timer then return false end
			timer.remaining, timer.deadline, timer.state = timer.duration, nil, "paused"
			changed("timer.reset", id)
			return true
		end
		function self:DeleteTimer(id)
			if self.destroyed or not self.timers[id] then return false end
			self.timers[id] = nil
			changed("timer.deleted", id)
			return true
		end
		function self:GetAlarms()
			local result = {}
			for _, alarm in pairs(self.alarms) do
				table.insert(result, {id = alarm.id, name = alarm.name, hour = alarm.hour, minute = alarm.minute,
					repeatDaily = alarm.repeatDaily, enabled = alarm.enabled, nextAt = alarm.nextAt, sequence = alarm.sequence})
			end
			table.sort(result, function(a, b) return a.sequence < b.sequence end)
			return result
		end
		function self:AddAlarm(name, hour, minute, repeatDaily)
			if self.destroyed then return nil, "Clock service is unavailable." end
			if not validNumber(hour) or hour % 1 ~= 0 or hour < 0 or hour > 23 then return nil, "Hours must be between 0 and 23." end
			if not validNumber(minute) or minute % 1 ~= 0 or minute < 0 or minute > 59 then return nil, "Minutes must be between 0 and 59." end
			if repeatDaily ~= nil and type(repeatDaily) ~= "boolean" then return nil, "Choose a daily or one-time alarm." end
			local title, err = nameFor(name, "Alarm")
			if not title then return nil, err end
			self.sequence = self.sequence + 1
			local id = "alarm-" .. self.sequence
			self.alarms[id] = {id = id, name = title, hour = hour, minute = minute, repeatDaily = repeatDaily ~= false,
				enabled = true, nextAt = nextAlarm(hour, minute, DateTime.now().UnixTimestamp), sequence = self.sequence, firedDays = {}}
			changed("alarm.added", id)
			return id
		end
		function self:SetAlarmEnabled(id, enabled)
			local alarm = self.alarms[id]
			if self.destroyed or not alarm or type(enabled) ~= "boolean" then return false end
			alarm.enabled = enabled
			alarm.nextAt = enabled and nextAlarm(alarm.hour, alarm.minute, DateTime.now().UnixTimestamp) or nil
			changed("alarm.changed", id)
			return true
		end
		function self:DeleteAlarm(id)
			if self.destroyed or not self.alarms[id] then return false end
			self.alarms[id] = nil
			changed("alarm.deleted", id)
			return true
		end
		local connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
			if self.destroyed then return end
			elapsed = elapsed + dt
			if elapsed < 0.1 then return end
			elapsed = 0
			local monotonic, wall = os.clock(), DateTime.now().UnixTimestamp
			for id, timer in pairs(self.timers) do
				if timer.state == "running" and monotonic >= timer.deadline then
					timer.state, timer.remaining, timer.deadline = "completed", 0, nil
					notify("Timer finished", timer.name .. " has finished.", "Timers")
					changed("timer.completed", id)
				end
			end
			for id, alarm in pairs(self.alarms) do
				if alarm.enabled and alarm.nextAt and wall >= alarm.nextAt then
					local day = localDay(alarm.nextAt)
					if not alarm.firedDays[day] then
						alarm.firedDays[day] = true
						alarm.lastFiredDay = day
						notify("Alarm", alarm.name .. "  /  " .. string.format("%02d:%02d", alarm.hour, alarm.minute), "Alarms")
					end
					if alarm.repeatDaily then alarm.nextAt = nextAlarm(alarm.hour, alarm.minute, wall)
					else alarm.enabled, alarm.nextAt = false, nil end
					changed("alarm.fired", id)
				end
			end
		end)
		function self:Destroy()
			if self.destroyed then return end
			self.destroyed = true
			connection:Disconnect()
		end
		return self
	end

	return ClockService

end
-- END COMPONENT: ClockService
-- BEGIN COMPONENT: SettingsApp
__v3Factories["SettingsApp"] = function()
	local SettingsApp = {}

	function SettingsApp.Mount(ctx, ui, args, window, api)
		local UI = ctx.UI
		local connections, subscriptions, sliders, appRows = {}, {}, {}, {}
		local destroyed = false
		local root = UI.scroll(ui, {Name = "SettingsContent", Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5})
		local body = UI.frame(root, {Name = "SettingsBody", Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
		UI.pad(body, 12)
		UI.list(body, 12)
		local function connect(signal, fn) table.insert(connections, signal:Connect(fn)) end
		local function title(parent, value, size)
			return UI.text(parent, value, {Size = UDim2.new(1, 0, 0, size == 20 and 28 or 22), TextSize = size or 14, Font = Enum.Font.GothamBold, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
		end
		local function note(parent, value)
			local object = UI.text(parent, value, {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 11, TextWrapped = true, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
			UI.bind(object, {TextColor3 = "Muted"})
			return object
		end
		local function section(name, caption)
			local card = UI.frame(body, {Name = name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
			UI.pad(card, 12); UI.list(card, 8)
			title(card, caption)
			return card
		end
		local function row(parent, height)
			return UI.frame(parent, {Size = UDim2.new(1, 0, 0, height or 32), BackgroundTransparency = 1})
		end
		local function choice(parent, caption, index, count)
			local button = UI.button(parent, caption, {Position = UDim2.new((index - 1) / count, 3, 0, 0), Size = UDim2.new(1 / count, -6, 1, 0), TextSize = 12,
				BackgroundColor3 = ctx.Theme:Get().SurfaceAlt, TextColor3 = ctx.Theme:Get().Text})
			return button
		end
		title(body, "Settings", 20)
		note(body, "Make ZolinOS feel like home.")
		local appearance = section("Appearance", "Appearance")
		note(appearance, "Choose a theme and an accent for windows and your home screen.")
		local themeRow, themeButtons = row(appearance), {}
		for index, name in ipairs({"Dark", "Light"}) do
			local button = choice(themeRow, name, index, 2)
			themeButtons[name] = button
			connect(button.Activated, function() ctx.Theme:SetTheme(name) end)
		end
		local accentRow, accentButtons = row(appearance, 30), {}
		local accents = {Color3.fromRGB(0, 120, 215), Color3.fromRGB(83, 120, 211), Color3.fromRGB(145, 92, 199), Color3.fromRGB(204, 72, 80), Color3.fromRGB(213, 126, 38), Color3.fromRGB(42, 147, 109)}
		for index, color in ipairs(accents) do
			local button = UI.button(accentRow, "", {Name = "Accent" .. index, Position = UDim2.new((index - 1) / #accents, 3, 0, 0), Size = UDim2.new(1 / #accents, -6, 1, 0), BackgroundColor3 = color})
			local stroke = UI.new("UIStroke", button, {Thickness = 2, Enabled = false, Color = ctx.Theme:Get().Text})
			accentButtons[index] = stroke
			connect(button.Activated, function() ctx.Theme:SetAccent(color) end)
		end
		local animations = section("Animations", "Animations")
		note(animations, "Choose the feel of app transitions and tap feedback. V3 uses a gentle spring; V2 keeps the original bounce.")
		local animationRow, animationButtons = row(animations, 36), {}
		for index, name in ipairs({"V3", "V2"}) do
			local button = choice(animationRow, name == "V3" and "V3 · Smooth" or "V2 · Classic", index, 2)
			button.Name = "Animation" .. name
			animationButtons[name] = button
			connect(button.Activated, function() ctx.Settings:Set("appearance.animationStyle", name) end)
		end
		local sound = section("Sound", "Sound")
		local volumeControls = UI.button(sound, "Open volume controls", {Name = "OpenVolumeControls", Size = UDim2.new(1, 0, 0, 34), TextSize = 12})
		connect(volumeControls.Activated, function() ctx.Volume:OpenPanel() end)
		local muteButtons = {}
		for _, entry in ipairs({{"master", "Master volume"}, {"media", "Media"}, {"notifications", "Notifications"}}) do
			local kind, caption = entry[1], entry[2]
			local frame, slider = UI.slider(sound, {Name = kind .. "Volume", Label = caption, Value = ctx.Volume:GetVolume(kind), Format = function(value) return tostring(math.floor(value * 100 + 0.5)) .. "%" end,
			Changed = function(value) if not destroyed then ctx.Volume:SetVolume(kind, value) end end})
			sliders[kind] = slider
			frame.LayoutOrder = 0
			local mute = UI.button(sound, "", {Name = kind .. "Mute", Size = UDim2.new(1, 0, 0, 28), TextSize = 11})
			muteButtons[kind] = {button = mute, caption = caption}
			connect(mute.Activated, function() ctx.Volume:SetMuted(kind, not ctx.Volume:IsMuted(kind)) end)
		end
		local notifications = section("Notifications", "Notifications")
		note(notifications, "Choose the notification layout. V2 brings back the classic notification cards; V3 uses the current enhanced cards. Do Not Disturb silences pop-ups.")
		local dnd = UI.button(notifications, "", {Name = "DoNotDisturb", Size = UDim2.new(1, 0, 0, 34), TextSize = 12})
		connect(dnd.Activated, function() ctx.Notifications:SetDND(not ctx.Notifications:GetDND()) end)
		local notificationStyleRow, notificationStyleButtons = row(notifications, 36), {}
		for index, name in ipairs({"V3", "V2"}) do
			local button = choice(notificationStyleRow, name == "V3" and "V3 · Enhanced" or "V2 · Classic", index, 2)
			button.Name = "NotificationStyle" .. name
			notificationStyleButtons[name] = button
			connect(button.Activated, function() ctx.Settings:Set("notifications.style", name) end)
		end
		local display = section("Display", "Display")
		local modeNote = note(display, "")
		local modeRow, modeButtons = row(display), {}
		for index, name in ipairs({"Auto", "Desktop", "Mobile"}) do
			local button = choice(modeRow, name, index, 3)
			modeButtons[name] = button
			connect(button.Activated, function()
				if type(ctx.SetMode) == "function" then ctx.SetMode(name) end
			end)
		end
		local applications = section("Applications", "Applications")
		local appSummary = note(applications, "")
		local appList = UI.frame(applications, {Name = "InstalledApps", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
		UI.list(appList, 6)
		local about = section("About", "About")
		note(about, "ZolinOS  /  Version 3\nYour workspace, on desktop and mobile.")
		local palette, theme
		local function refresh()
			if destroyed then
				palette, theme = nil, nil
				return
			end
			palette, theme = ctx.Theme:Get(), ctx.Theme:GetTheme()
			for name, button in pairs(themeButtons) do
				button.BackgroundColor3 = name == theme and palette.Accent or palette.SurfaceAlt
				button.TextColor3 = name == theme and palette.AccentText or palette.Text
			end
			local animationStyle = ctx.Settings:Get("appearance.animationStyle", "V3")
			for name, button in pairs(animationButtons) do
				button.BackgroundColor3 = name == animationStyle and palette.Accent or palette.SurfaceAlt
				button.TextColor3 = name == animationStyle and palette.AccentText or palette.Text
			end
			local selected = ctx.Theme:GetAccent()
			for index, stroke in ipairs(accentButtons) do
				local color = accents[index]
				stroke.Enabled = math.abs(selected.R - color.R) + math.abs(selected.G - color.G) + math.abs(selected.B - color.B) < 0.015
				stroke.Color = palette.Text
			end
			for kind, slider in pairs(sliders) do
				slider.SetValue(ctx.Volume:GetVolume(kind), true)
				local entry = muteButtons[kind]
				entry.button.Text = entry.caption .. (ctx.Volume:IsMuted(kind) and ": Muted" or ": Sound on")
			end
			dnd.Text = "Do Not Disturb: " .. (ctx.Notifications:GetDND() and "On" or "Off")
			local preferred = ctx.Settings:Get("display.mode", "Auto")
			modeNote.Text = "Current layout: " .. ctx.Mode
			for name, button in pairs(modeButtons) do
				button.BackgroundColor3 = name == preferred and palette.Accent or palette.SurfaceAlt
				button.TextColor3 = name == preferred and palette.AccentText or palette.Text
			end
		end
		local notificationStyle = ctx.Settings:Get("notifications.style", "V3")
		for name, button in pairs(notificationStyleButtons) do
			button.BackgroundColor3 = name == notificationStyle and palette.Accent or palette.SurfaceAlt
			button.TextColor3 = name == notificationStyle and palette.AccentText or palette.Text
		end
		local function sourceLocation(url)
			if type(url) ~= "string" then return nil end
			local owner, repo, branch, path = url:match("raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/(.+)")
			if not owner then owner, repo, branch, path = url:match("github%.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)") end
			if not owner then owner, repo, branch, path = url:match("github%.com/([^/]+)/([^/]+)/edit/([^/]+)/(.+)") end
			if owner and path then return owner, repo, branch, path end
			return nil
		end
		local function encodePath(value)
			return (value:gsub("[^%w%-%._~/]", function(char) return string.format("%%%02X", string.byte(char)) end))
		end
		local function fetchText(url)
			if type(ctx.FetchSource) == "function" then return ctx.FetchSource(url) end
			return game:HttpGet(url, true)
		end
		local function versionFromSource(code)
			if type(code) ~= "string" then return nil end
			for _, pattern in ipairs({
				"[Bb]uild[Vv]ersion%s*=%s*['\"]([^'\"]+)",
				"[Bb]uild[Vv]ersion%s*=%s*[^\r\n]-['\"]([^'\"]+)['\"]",
				"[Vv]ersion%s*=%s*['\"]([^'\"]+)",
				"[Vv]ersion%.Value%s*=%s*['\"]([^'\"]+)",
				"ver%s*=%s*['\"]([^'\"]+)",
				"v(%d+%.%d+%.%d+)",
				"v(%d+%.%d+)",
				}) do
				local version = code:match(pattern)
				if version and version ~= "" then return version end
			end
			return nil
		end
		local function showCompatibility(meta)
			local owner, repo, branch, path = sourceLocation(meta.source)
			if not owner then
				ctx.Notifications:Push({appId = "system", title = "Compatibility Mode", message = "Version history needs a GitHub blob or raw Lua source URL."})
				return
			end
			local overlay = UI.frame(ui, {Name = "CompatibilityModeOverlay", Size = UDim2.fromScale(1, 1), ZIndex = 30, BackgroundTransparency = 0.04, ClipsDescendants = true})
			UI.pad(overlay, 12); UI.list(overlay, 8)
			local header = UI.frame(overlay, {Name = "Header", Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 1})
			UI.text(header, "Compatibility · " .. tostring(meta.name), {Size = UDim2.new(1, -80, 1, 0), Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left})
			local close = UI.button(header, "Close", {Position = UDim2.new(1, -72, 0, 2), Size = UDim2.fromOffset(72, 32), TextSize = 12})
			local status = UI.text(overlay, "Loading every GitHub file revision…", {Name = "HistoryStatus", Size = UDim2.new(1, 0, 0, 28), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2})
			UI.bind(status, {TextColor3 = "Muted"})
			local list = UI.scroll(overlay, {Name = "VersionHistory", Size = UDim2.new(1, 0, 1, -92), LayoutOrder = 3})
			UI.list(list, 6)
			connect(close.Activated, function() overlay:Destroy() end)
			local alive = true
			connect(overlay.Destroying, function() alive = false end)
			task.spawn(function()
				local allCommits, page = {}, 1
				local httpService = game:GetService("HttpService")
				while alive do
					local apiUrl = string.format("https://api.github.com/repos/%s/%s/commits?path=%s&sha=%s&per_page=100&page=%d", owner, repo, encodePath(path), encodePath(branch), page)
					local ok, response = pcall(fetchText, apiUrl)
					if not ok or type(response) ~= "string" then
						status.Text = "Could not read GitHub commit history. Check HTTP access and try again."
						return
					end
					local decoded, commits = pcall(httpService.JSONDecode, httpService, response)
					if not decoded or type(commits) ~= "table" or commits.message then
						status.Text = "GitHub returned an invalid history response."
						return
					end
					for _, commit in ipairs(commits) do table.insert(allCommits, commit) end
					if #commits < 100 then break end
					page += 1
				end
				if not alive then return end
				if #allCommits == 0 then status.Text = "No changes found for this Lua file."; return end
				status.Text = "Reading " .. #allCommits .. " file changes and BuildVersion values…"
				for index, commit in ipairs(allCommits) do
					if not alive then return end
					local sha = tostring(commit.sha or "")
					local currentDate = commit.commit and commit.commit.author and commit.commit.author.date or "Unknown date"
					local message = commit.commit and commit.commit.message or "No commit description"
					local raw = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", owner, repo, sha, path)
					local fetched, source = pcall(fetchText, raw)
					local version = fetched and versionFromSource(source) or nil
					version = version or ("Revision " .. sha:sub(1, 7))
					local item = UI.button(list, "", {Name = "Version_" .. index, Size = UDim2.new(1, -6, 0, 74), Text = "", AutoButtonColor = false})
					local dateText = tostring(currentDate):gsub("T", "  "):gsub("Z$", " UTC")
					UI.text(item, version .. (index == 1 and " · CURRENT" or ""), {Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -104, 0, 22), Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
					UI.text(item, dateText .. " · " .. tostring(message):gsub("\n.*", ""), {Position = UDim2.fromOffset(10, 31), Size = UDim2.new(1, -104, 0, 34), TextSize = 10, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})
					local use = UI.button(item, index == 1 and "Current" or "Use", {Position = UDim2.new(1, -82, 0.5, -15), Size = UDim2.fromOffset(72, 30), TextSize = 11, Active = index ~= 1})
					connect(use.Activated, function()
						if index == 1 then return end
						local revisionUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", owner, repo, sha, path)
						local changed, reason = ctx.External:SetSourceURL(meta.id, revisionUrl, version)
						if not changed then status.Text = tostring(reason or "Could not select this revision."); return end
						ctx.Apps:Close(meta.id, false, true)
						overlay:Destroy()
						ctx.Notifications:Push({appId = "system", title = "Compatibility Mode", message = meta.name .. " now uses " .. version .. "."})
						ctx.Apps:Launch(meta.id)
					end)
					task.wait(0.03)
				end
				if alive then status.Text = #allCommits .. " changes loaded · versions read from each Lua file's BuildVersion." end
			end)
		end
		local function showAppInfo(meta)
			local overlay = UI.frame(ui, {Name = "AppInfoOverlay", Size = UDim2.fromScale(1, 1), ZIndex = 30, BackgroundTransparency = 0.04, ClipsDescendants = true})
			UI.pad(overlay, 16); UI.list(overlay, 10)
			UI.text(overlay, "App Info", {Size = UDim2.new(1, 0, 0, 30), Font = Enum.Font.GothamBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left})
			UI.text(overlay, tostring(meta.name) .. "\nVersion " .. tostring(meta.version) .. "\n" .. tostring(meta.description ~= "" and meta.description or "No description provided.") .. "\n" .. (meta.builtin and "Built-in system app" or (meta.source and meta.source ~= "" and "URL app" or "Local app")), {Size = UDim2.new(1, 0, 0, 90), TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})
			local compatibility = UI.button(overlay, "Compatibility Mode · Version history", {Size = UDim2.new(1, 0, 0, 38), TextSize = 12, Active = not meta.builtin and type(meta.source) == "string" and meta.source ~= ""})
			local close = UI.button(overlay, "Back to Apps", {Size = UDim2.new(1, 0, 0, 34), TextSize = 12})
			connect(compatibility.Activated, function() if compatibility.Active then overlay:Destroy(); showCompatibility(meta) end end)
			connect(close.Activated, function() overlay:Destroy() end)
		end
		local function refreshApps()
			if destroyed then return end
			local apps, seen = ctx.Apps:List(), {}
			appSummary.Text = tostring(#apps) .. " applications installed"
			for index, metadata in ipairs(apps) do
				seen[metadata.id] = true
				local entry = appRows[metadata.id]
				if not entry then
					local frame = row(appList, 60)
					local name = UI.text(frame, "", {Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, -142, 0, 21), TextSize = 12, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left})
					local detail = UI.text(frame, "", {Position = UDim2.fromOffset(0, 29), Size = UDim2.new(1, -142, 0, 17), TextSize = 10, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left})
					UI.bind(detail, {TextColor3 = "Muted"})
					local open = UI.button(frame, "Open", {Position = UDim2.new(1, -132, 0, 14), Size = UDim2.fromOffset(62, 30), TextSize = 11})
					local info = UI.button(frame, "Info", {Position = UDim2.new(1, -64, 0, 14), Size = UDim2.fromOffset(62, 30), TextSize = 11})
					entry = {frame = frame, name = name, detail = detail, open = open, info = info,
						connection = open.Activated:Connect(function() ctx.Apps:Launch(metadata.id) end)}
					entry.infoConnection = info.Activated:Connect(function() showAppInfo(ctx.Apps:GetMetadata(metadata.id) or metadata) end)
					appRows[metadata.id] = entry
				end
				entry.frame.LayoutOrder = index
				entry.name.Text = metadata.name or metadata.id
				entry.detail.Text = metadata.disabled and "Disabled" or (metadata.system and "System application" or "Installed application")
				entry.open.Visible = not metadata.disabled
			end
			for id, entry in pairs(appRows) do
				if not seen[id] then entry.connection:Disconnect(); entry.infoConnection:Disconnect(); entry.frame:Destroy(); appRows[id] = nil end
			end
		end
		local controller = {}
		local sectionMap = {appearance = appearance, theme = appearance, sound = sound, volume = sound, notifications = notifications,
			animations = animations, animation = animations, display = display, applications = applications, apps = applications, about = about}
		local pendingSection
		local function applyNavigation()
			if destroyed or not pendingSection or root.AbsoluteSize.Y <= 0 or root.AbsoluteCanvasSize.Y <= 0 then return end
			local destination = pendingSection.AbsolutePosition.Y - root.AbsolutePosition.Y + root.CanvasPosition.Y
			root.CanvasPosition = Vector2.new(0, math.clamp(destination, 0, math.max(0, root.AbsoluteCanvasSize.Y - root.AbsoluteSize.Y)))
			pendingSection = nil
		end
		function controller.Navigate(sectionName)
			if destroyed or type(sectionName) ~= "string" then return false end
			pendingSection = sectionMap[sectionName:lower():gsub("%s+", "")]
			if not pendingSection then return false end
			applyNavigation()
			task.defer(applyNavigation)
			return true
		end
		function controller.Destroy()
			if destroyed then return end
			destroyed = true
			for _, connection in ipairs(connections) do connection:Disconnect() end
			for _, unsubscribe in ipairs(subscriptions) do unsubscribe() end
			for _, slider in pairs(sliders) do slider.Destroy() end
			for _, entry in pairs(appRows) do entry.connection:Disconnect(); entry.infoConnection:Disconnect() end
			root:Destroy()
		end
		connect(ui.Destroying, controller.Destroy)
		connect(root:GetPropertyChangedSignal("AbsoluteCanvasSize"), applyNavigation)
		table.insert(subscriptions, ctx.Theme:Subscribe(refresh))
		table.insert(subscriptions, ctx.Volume:Subscribe(refresh))
		table.insert(subscriptions, ctx.Apps:Subscribe(refreshApps))
		table.insert(subscriptions, ctx.Bus:On("settings.changed", refresh))
		table.insert(subscriptions, ctx.Bus:On("notifications.changed", refresh))
		table.insert(subscriptions, ctx.Bus:On("mode.changed", refresh))
		refresh(); refreshApps()
		if type(args) == "table" and args.section then controller.Navigate(args.section) end
		controller.Refresh = function() refresh(); refreshApps() end
		return controller
	end

	return SettingsApp

end
-- END COMPONENT: SettingsApp
-- BEGIN COMPONENT: ClockApp
__v3Factories["ClockApp"] = function()
	local ClockApp = {}

	local function durationText(seconds)
		seconds = math.max(0, math.ceil(seconds))
		return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
	end

	function ClockApp.Mount(ctx, ui, args, window, api)
		local UI = ctx.UI
		local connections, subscriptions, timerRows, alarmRows = {}, {}, {}, {}
		local destroyed, elapsed, currentTab, repeatDaily = false, 0, "Clock", true
		local root = UI.frame(ui, {Name = "ClockContent", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1})
		local function connect(signal, fn) table.insert(connections, signal:Connect(fn)) end
		local function frame(parent, name, position, size)
			return UI.frame(parent, {Name = name, Position = position or UDim2.new(), Size = size or UDim2.fromScale(1, 1), BackgroundTransparency = 1})
		end
		local function text(parent, value, position, size, fontSize, token)
			local object = UI.text(parent, value, {Position = position, Size = size, TextSize = fontSize or 12, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left})
			if token then UI.bind(object, {TextColor3 = token}) end
			return object
		end
		local function input(parent, name, placeholder, value, position, size)
			return UI.new("TextBox", parent, {Name = name, PlaceholderText = placeholder, Text = value or "", Position = position, Size = size,
				ClearTextOnFocus = false, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center})
		end
		text(root, "Clock", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 26), 20).Font = Enum.Font.GothamBold
		local tabBar = frame(root, "Tabs", UDim2.fromOffset(12, 42), UDim2.new(1, -24, 0, 32))
		local content = frame(root, "Pages", UDim2.fromOffset(12, 86), UDim2.new(1, -24, 1, -98))
		local pages, tabs = {}, {}
		local function selectTab(name)
			if not pages[name] or destroyed then return end
			currentTab = name
			local palette = ctx.Theme:Get()
			for key, page in pairs(pages) do
				page.Visible = key == name
				tabs[key].BackgroundColor3 = key == name and palette.Accent or palette.SurfaceAlt
				tabs[key].TextColor3 = key == name and palette.AccentText or palette.Text
			end
		end
		for index, name in ipairs({"Clock", "Timers", "Alarms"}) do
			pages[name] = frame(content, name)
			local palette = ctx.Theme:Get()
			tabs[name] = UI.button(tabBar, name, {Position = UDim2.new((index - 1) / 3, 2, 0, 0), Size = UDim2.new(1 / 3, -4, 1, 0), TextSize = 12,
				BackgroundColor3 = palette.SurfaceAlt, TextColor3 = palette.Text})
			connect(tabs[name].Activated, function() selectTab(name) end)
		end
		local timeLabel = text(pages.Clock, "", UDim2.new(0, 0, 0.13, 0), UDim2.new(1, 0, 0, 60), 36)
		timeLabel.Font, timeLabel.TextXAlignment = Enum.Font.Code, Enum.TextXAlignment.Center
		local dateLabel = text(pages.Clock, "", UDim2.new(0, 0, 0.13, 65), UDim2.new(1, 0, 0, 28), 12, "Muted")
		dateLabel.TextXAlignment = Enum.TextXAlignment.Center
		local nextLabel = text(pages.Clock, "", UDim2.new(0, 0, 0.13, 109), UDim2.new(1, 0, 0, 55), 12)
		nextLabel.TextWrapped, nextLabel.TextTruncate = true, Enum.TextTruncate.None
		nextLabel.TextXAlignment = Enum.TextXAlignment.Center

		local timerName = input(pages.Timers, "TimerName", "Timer name", "", UDim2.new(), UDim2.new(1, 0, 0, 30))
		local hours = input(pages.Timers, "TimerHours", "Hours", "0", UDim2.fromOffset(0, 37), UDim2.new(1 / 3, -5, 0, 30))
		local minutes = input(pages.Timers, "TimerMinutes", "Minutes", "5", UDim2.new(1 / 3, 2, 0, 37), UDim2.new(1 / 3, -5, 0, 30))
		local seconds = input(pages.Timers, "TimerSeconds", "Seconds", "0", UDim2.new(2 / 3, 5, 0, 37), UDim2.new(1 / 3, -5, 0, 30))
		text(pages.Timers, "Hours", UDim2.fromOffset(0, 68), UDim2.new(1 / 3, -5, 0, 15), 9, "Muted")
		text(pages.Timers, "Minutes", UDim2.new(1 / 3, 2, 0, 68), UDim2.new(1 / 3, -5, 0, 15), 9, "Muted")
		text(pages.Timers, "Seconds", UDim2.new(2 / 3, 5, 0, 68), UDim2.new(1 / 3, -5, 0, 15), 9, "Muted")
		local addTimer = UI.button(pages.Timers, "Start timer", {Name = "AddTimer", Position = UDim2.fromOffset(0, 87), Size = UDim2.new(1, 0, 0, 30), TextSize = 12})
		local timerError = text(pages.Timers, "", UDim2.fromOffset(0, 121), UDim2.new(1, 0, 0, 28), 10, "Danger")
		timerError.TextWrapped, timerError.TextTruncate = true, Enum.TextTruncate.None
		local timerList = UI.scroll(pages.Timers, {Name = "TimerList", Position = UDim2.fromOffset(0, 152), Size = UDim2.new(1, 0, 1, -152), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4})
		UI.list(timerList, 8)
		local timerEmpty = text(timerList, "No timers yet.", UDim2.new(), UDim2.new(1, -6, 0, 35), 12, "Muted")
		local alarmName = input(pages.Alarms, "AlarmName", "Alarm name", "", UDim2.new(), UDim2.new(1, 0, 0, 30))
		local alarmHour = input(pages.Alarms, "AlarmHours", "Hours (0–23)", "7", UDim2.fromOffset(0, 37), UDim2.new(0.5, -4, 0, 30))
		local alarmMinute = input(pages.Alarms, "AlarmMinutes", "Minutes (0–59)", "0", UDim2.new(0.5, 4, 0, 37), UDim2.new(0.5, -4, 0, 30))
		local repeatButton = UI.button(pages.Alarms, "Daily: On", {Name = "AlarmRepeat", Position = UDim2.fromOffset(0, 77), Size = UDim2.new(0.5, -4, 0, 30), TextSize = 11})
		local addAlarm = UI.button(pages.Alarms, "Add alarm", {Name = "AddAlarm", Position = UDim2.new(0.5, 4, 0, 77), Size = UDim2.new(0.5, -4, 0, 30), TextSize = 11})
		local alarmError = text(pages.Alarms, "", UDim2.fromOffset(0, 112), UDim2.new(1, 0, 0, 30), 10, "Danger")
		alarmError.TextWrapped, alarmError.TextTruncate = true, Enum.TextTruncate.None
		local alarmList = UI.scroll(pages.Alarms, {Name = "AlarmList", Position = UDim2.fromOffset(0, 152), Size = UDim2.new(1, 0, 1, -152), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4})
		UI.list(alarmList, 8)
		local alarmEmpty = text(alarmList, "No alarms yet.", UDim2.new(), UDim2.new(1, -6, 0, 35), 12, "Muted")
		local function number(box, maximum)
			if not box.Text:match("^%d+$") then return nil end
			local value = tonumber(box.Text)
			return value and value >= 0 and value <= maximum and value % 1 == 0 and value or nil
		end
		connect(addTimer.Activated, function()
			local h, m, s = number(hours, 168), number(minutes, 59), number(seconds, 59)
			if not h or not m or not s then timerError.Text = "Enter whole hours, minutes (0–59), and seconds (0–59)."; return end
			local id, err = ctx.Clock:AddTimer(timerName.Text, h * 3600 + m * 60 + s)
			timerError.Text = id and "" or err
			if id then timerName.Text = "" end
		end)
		connect(repeatButton.Activated, function() repeatDaily = not repeatDaily; repeatButton.Text = repeatDaily and "Daily: On" or "Daily: Off" end)
		connect(addAlarm.Activated, function()
			local h, m = number(alarmHour, 23), number(alarmMinute, 59)
			if not h or not m then alarmError.Text = "Use hours 0–23 and minutes 0–59."; return end
			local id, err = ctx.Clock:AddAlarm(alarmName.Text, h, m, repeatDaily)
			alarmError.Text = id and "" or err
			if id then alarmName.Text = "" end
		end)
		local function remove(rows, id)
			local entry = rows[id]
			for _, connection in ipairs(entry.connections) do connection:Disconnect() end
			entry.frame:Destroy(); rows[id] = nil
		end
		local function refresh()
			if destroyed then return end
			local now = DateTime.now()
			timeLabel.Text = now:FormatLocalTime("HH:mm:ss", "en-us")
			dateLabel.Text = now:FormatLocalTime("dddd, D MMMM YYYY", "en-us")
			local timers, alarms, seenTimers, seenAlarms = ctx.Clock:GetTimers(), ctx.Clock:GetAlarms(), {}, {}
			for index, timer in ipairs(timers) do
				seenTimers[timer.id] = true
				local entry = timerRows[timer.id]
				if not entry then
					local card = UI.frame(timerList, {Name = timer.id, Size = UDim2.new(1, -6, 0, 110)})
					local title = text(card, timer.name, UDim2.fromOffset(10, 5), UDim2.new(1, -20, 0, 19), 12)
					local remaining = text(card, "", UDim2.fromOffset(10, 25), UDim2.new(1, -20, 0, 29), 24)
					remaining.Font = Enum.Font.Code
					local track = UI.frame(card, {Position = UDim2.fromOffset(10, 58), Size = UDim2.new(1, -20, 0, 4)})
					UI.bind(track, {BackgroundColor3 = "SurfaceAlt"})
					local progress = UI.frame(track, {Size = UDim2.fromScale(0, 1)})
					UI.bind(progress, {BackgroundColor3 = "Accent"})
					local pause = UI.button(card, "", {Position = UDim2.fromOffset(6, 74), Size = UDim2.new(1 / 3, -8, 0, 28), TextSize = 10})
					local reset = UI.button(card, "Reset", {Position = UDim2.new(1 / 3, 2, 0, 74), Size = UDim2.new(1 / 3, -8, 0, 28), TextSize = 10})
					local delete = UI.button(card, "Delete", {Position = UDim2.new(2 / 3, -2, 0, 74), Size = UDim2.new(1 / 3, -4, 0, 28), TextSize = 10})
					entry = {frame = card, title = title, remaining = remaining, progress = progress, pause = pause, connections = {}}
					timerRows[timer.id] = entry
					table.insert(entry.connections, pause.Activated:Connect(function()
						if entry.value.state == "running" then ctx.Clock:PauseTimer(timer.id) else ctx.Clock:ResumeTimer(timer.id) end
					end))
					table.insert(entry.connections, reset.Activated:Connect(function() ctx.Clock:ResetTimer(timer.id) end))
					table.insert(entry.connections, delete.Activated:Connect(function() ctx.Clock:DeleteTimer(timer.id) end))
				end
				entry.value, entry.frame.LayoutOrder = timer, index
				entry.remaining.Text = durationText(timer.remaining)
				entry.pause.Text = timer.state == "running" and "Pause" or (timer.state == "completed" and "Start again" or "Resume")
				entry.title.Text = timer.name .. (timer.state == "paused" and "  /  Paused" or (timer.state == "completed" and "  /  Finished" or ""))
				entry.progress.Size = UDim2.fromScale(math.clamp(1 - timer.remaining / timer.duration, 0, 1), 1)
			end
			for id in pairs(timerRows) do if not seenTimers[id] then remove(timerRows, id) end end
			timerEmpty.Visible = #timers == 0
			local nextAt, nextName
			for index, alarm in ipairs(alarms) do
				seenAlarms[alarm.id] = true
				if alarm.enabled and alarm.nextAt and (not nextAt or alarm.nextAt < nextAt) then nextAt, nextName = alarm.nextAt, alarm.name end
				local entry = alarmRows[alarm.id]
				if not entry then
					local card = UI.frame(alarmList, {Name = alarm.id, Size = UDim2.new(1, -6, 0, 90)})
					local title = text(card, alarm.name, UDim2.fromOffset(10, 4), UDim2.new(1, -20, 0, 18), 12)
					local time = text(card, "", UDim2.fromOffset(10, 24), UDim2.new(1, -88, 0, 29), 25)
					time.Font = Enum.Font.Code
					local repeatLabel = text(card, "", UDim2.fromOffset(10, 59), UDim2.new(1, -88, 0, 19), 10, "Muted")
					local enabled = UI.button(card, "", {Position = UDim2.new(1, -70, 0, 24), Size = UDim2.fromOffset(60, 26), TextSize = 10})
					local delete = UI.button(card, "Delete", {Position = UDim2.new(1, -70, 0, 56), Size = UDim2.fromOffset(60, 26), TextSize = 10})
					entry = {frame = card, title = title, time = time, repeatLabel = repeatLabel, enabled = enabled, connections = {}}
					alarmRows[alarm.id] = entry
					table.insert(entry.connections, enabled.Activated:Connect(function() ctx.Clock:SetAlarmEnabled(alarm.id, not entry.value.enabled) end))
					table.insert(entry.connections, delete.Activated:Connect(function() ctx.Clock:DeleteAlarm(alarm.id) end))
				end
				entry.value, entry.frame.LayoutOrder = alarm, index
				entry.time.Text = string.format("%02d:%02d", alarm.hour, alarm.minute)
				entry.repeatLabel.Text = alarm.repeatDaily and "Every day" or "Once"
				entry.enabled.Text = alarm.enabled and "On" or "Off"
			end
			for id in pairs(alarmRows) do if not seenAlarms[id] then remove(alarmRows, id) end end
			alarmEmpty.Visible = #alarms == 0
			nextLabel.Text = nextAt and ("Next alarm: " .. nextName .. "\n" .. DateTime.fromUnixTimestamp(nextAt):FormatLocalTime("ddd HH:mm", "en-us")) or (tostring(#timers) .. " timers  /  No active alarms")
		end
		local controller = {Root = root, TimerRows = timerRows, AlarmRows = alarmRows, SelectTab = selectTab, Refresh = refresh}
		function controller.Destroy()
			if destroyed then return end
			destroyed = true
			for _, connection in ipairs(connections) do connection:Disconnect() end
			for _, unsubscribe in ipairs(subscriptions) do unsubscribe() end
			for id in pairs(timerRows) do remove(timerRows, id) end
			for id in pairs(alarmRows) do remove(alarmRows, id) end
			root:Destroy()
		end
		connect(ui.Destroying, controller.Destroy)
		connect(game:GetService("RunService").Heartbeat, function(dt) elapsed = elapsed + dt; if elapsed >= 0.25 then elapsed = 0; refresh() end end)
		table.insert(subscriptions, ctx.Bus:On("clock.changed", refresh))
		table.insert(subscriptions, ctx.Theme:Subscribe(function() selectTab(currentTab) end))
		selectTab(type(args) == "table" and args.tab or "Clock")
		if not pages[type(args) == "table" and args.tab or "Clock"] then selectTab("Clock") end
		refresh()
		return controller
	end

	return ClockApp

end
-- END COMPONENT: ClockApp
-- BEGIN COMPONENT: TaskManagerApp
__v3Factories["TaskManagerApp"] = function()
	local TaskManagerApp = {}

	function TaskManagerApp.Mount(ctx, ui, args, window, api)
		local UI, Stats = ctx.UI, game:GetService("Stats")
		local connections, subscriptions, rows = {}, {}, {}
		local destroyed, elapsed, selected = false, 0, nil
		local snapshot, byId, metricLabels, metrics = {}, {}, {}, {}
		local root = UI.frame(ui, {Name = "TaskManagerContent", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1})
		local function connect(signal, fn) table.insert(connections, signal:Connect(fn)) end
		local function label(parent, value, position, size, fontSize, token)
			local item = UI.text(parent, value, {Position = position, Size = size, TextSize = fontSize or 12, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left})
			if token then UI.bind(item, {TextColor3 = token}) end
			return item
		end
		label(root, "Task Manager", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 26), 20).Font = Enum.Font.GothamBold
		local grid = UI.frame(root, {Name = "Metrics", Position = UDim2.fromOffset(12, 44), Size = UDim2.new(1, -24, 0, 102), BackgroundTransparency = 1})
		UI.new("UIGridLayout", grid, {CellSize = UDim2.new(0.5, -4, 0, 48), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder})
		for index, entry in ipairs({{"memory", "Memory", "MB"}, {"fps", "Frame rate", "FPS"}, {"receive", "Receive", "KB/s"}, {"send", "Send", "KB/s"}}) do
			local card = UI.frame(grid, {Name = entry[1], LayoutOrder = index})
			label(card, entry[2], UDim2.fromOffset(8, 3), UDim2.new(1, -16, 0, 16), 10, "Muted")
			local value = label(card, "Unavailable", UDim2.fromOffset(8, 22), UDim2.new(1, -16, 0, 22), 16)
			metricLabels[entry[1]] = {label = value, unit = entry[3]}
		end
		local filter = UI.new("TextBox", root, {Name = "ProcessFilter", Position = UDim2.fromOffset(12, 154), Size = UDim2.new(1, -24, 0, 30),
			Text = "", PlaceholderText = "Search applications", ClearTextOnFocus = false, TextSize = 12})
		local heading = label(root, "APPLICATIONS", UDim2.fromOffset(12, 190), UDim2.new(1, -24, 0, 17), 10, "Muted")
		local list = UI.scroll(root, {Name = "ProcessList", Position = UDim2.fromOffset(12, 212), Size = UDim2.new(1, -24, 1, -262), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4})
		UI.list(list, 5)
		local empty = label(list, "No applications are running.", UDim2.new(), UDim2.new(1, -6, 0, 44), 12, "Muted")
		empty.TextWrapped, empty.TextTruncate = true, Enum.TextTruncate.None
		local focusButton = UI.button(root, "Focus", {Name = "FocusSelected", Position = UDim2.new(0, 12, 1, -42), Size = UDim2.new(0.5, -16, 0, 28), TextSize = 12})
		local endButton = UI.button(root, "End task", {Name = "EndSelected", Position = UDim2.new(0.5, 4, 1, -42), Size = UDim2.new(0.5, -16, 0, 28), TextSize = 12})
		local status = label(root, "Client totals. App usage is unavailable.", UDim2.new(0, 12, 1, -13), UDim2.new(1, -24, 0, 12), 9, "Muted")
		local function protected(id)
			local metadata = ctx.Apps:GetMetadata(id)
			return id == "TaskManager" or (metadata and metadata.protected == true)
		end
		local function selection()
			local palette = ctx.Theme:Get()
			for id, entry in pairs(rows) do
				entry.button.BackgroundColor3 = id == selected and palette.Accent or palette.SurfaceAlt
				entry.name.TextColor3 = id == selected and palette.AccentText or palette.Text
				entry.detail.TextColor3 = id == selected and palette.AccentText or palette.Muted
			end
			focusButton.Active = selected ~= nil and byId[selected] ~= nil
			endButton.Active = selected ~= nil and byId[selected] ~= nil and not protected(selected)
			focusButton.TextTransparency = focusButton.Active and 0 or 0.5
			endButton.TextTransparency = endButton.Active and 0 or 0.5
		end
		local function refreshApps()
			if destroyed then return end
			local current, seen = ctx.Apps:GetRunning(), {}
			local active = ctx.Apps:GetActive()
			byId, snapshot = {}, {}
			for _, entry in ipairs(current) do
				if not seen[entry.id] then seen[entry.id] = true; byId[entry.id] = entry; table.insert(snapshot, entry) end
			end
			table.sort(snapshot, function(a, b)
				if (a.id == active) ~= (b.id == active) then return a.id == active end
				return (a.name or a.id):lower() < (b.name or b.id):lower()
			end)
			local query, visible = filter.Text:lower(), 0
			for index, entry in ipairs(snapshot) do
				local row = rows[entry.id]
				if not row then
					local palette = ctx.Theme:Get()
					local button = UI.button(list, "", {Name = entry.id, Size = UDim2.new(1, -6, 0, 50), BackgroundColor3 = palette.SurfaceAlt})
					local name = label(button, "", UDim2.fromOffset(10, 5), UDim2.new(1, -20, 0, 20), 12)
					local detail = label(button, "", UDim2.fromOffset(10, 28), UDim2.new(1, -20, 0, 15), 10)
					row = {button = button, name = name, detail = detail}
					row.connection = button.Activated:Connect(function() selected = entry.id; selection() end)
					rows[entry.id] = row
				end
				row.button.LayoutOrder = index
				row.name.Text = entry.name or entry.id
				row.detail.Text = entry.id == active and "Active" or tostring(entry.state or "Running")
				if protected(entry.id) then row.detail.Text = row.detail.Text .. "  /  Protected" end
				row.button.Visible = query == "" or row.name.Text:lower():find(query, 1, true) ~= nil
				if row.button.Visible then visible = visible + 1 end
			end
			for id, row in pairs(rows) do if not seen[id] then row.connection:Disconnect(); row.button:Destroy(); rows[id] = nil end end
			if selected and (not byId[selected] or not rows[selected].button.Visible) then selected = nil end
			empty.Visible = visible == 0
			empty.Text = #snapshot == 0 and "No applications are running." or "No matching applications."
			heading.Text = "APPLICATIONS  /  " .. tostring(#snapshot)
			selection()
		end
		local function finite(value) return type(value) == "number" and value == value and value >= 0 and value < math.huge end
		local function stat(name)
			local ok, value = pcall(function() return Stats[name] end)
			return ok and finite(value) and value or nil
		end
		local function refreshMetrics()
			if destroyed then return end
			local ok, memory = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
			local frameTime = stat("FrameTime")
			metrics = {memory = ok and finite(memory) and memory or nil, fps = frameTime and frameTime > 0 and 1 / frameTime or nil,
				receive = stat("DataReceiveKbps"), send = stat("DataSendKbps")}
			for key, item in pairs(metricLabels) do
				local value = metrics[key]
				item.label.Text = value and string.format(key == "fps" and "%.0f %s" or "%.1f %s", value, item.unit) or "Unavailable"
			end
		end
		local controller = {Root = root, Rows = rows, Buttons = {Focus = focusButton, EndTask = endButton}}
		function controller.Select(id)
			if destroyed or not byId[id] then return false end
			selected = id; selection(); return true
		end
		function controller.FocusSelected()
			if destroyed or not selected or not byId[selected] then return false end
			local ok, err = ctx.Apps:Focus(selected)
			if ok == false then status.Text = tostring(err or "Could not focus application.") end
			return ok
		end
		function controller.EndSelected()
			if destroyed or not selected or not byId[selected] or protected(selected) then return false end
			local ok, err = ctx.Apps:Close(selected)
			if ok == false then status.Text = tostring(err or "Could not close application.") end
			return ok
		end
		function controller.Refresh() refreshApps(); refreshMetrics() end
		function controller.GetSnapshot() return {processes = snapshot, metrics = metrics, selected = selected, destroyed = destroyed} end
		function controller.Destroy()
			if destroyed then return end
			destroyed = true
			for _, connection in ipairs(connections) do connection:Disconnect() end
			for _, unsubscribe in ipairs(subscriptions) do unsubscribe() end
			for _, row in pairs(rows) do row.connection:Disconnect() end
			root:Destroy()
		end
		connect(filter:GetPropertyChangedSignal("Text"), refreshApps)
		connect(focusButton.Activated, controller.FocusSelected)
		connect(endButton.Activated, controller.EndSelected)
		connect(ui.Destroying, controller.Destroy)
		connect(game:GetService("RunService").Heartbeat, function(dt)
			elapsed = elapsed + dt
			if elapsed >= 1 then elapsed = 0; refreshMetrics() end
		end)
		table.insert(subscriptions, ctx.Apps:Subscribe(refreshApps))
		table.insert(subscriptions, ctx.Theme:Subscribe(selection))
		controller.Refresh()
		return controller
	end

	return TaskManagerApp

end
-- END COMPONENT: TaskManagerApp
-- BEGIN COMPONENT: WallpaperApp
__v3Factories["WallpaperApp"] = function()
	local WallpaperApp = {}
	local function normalized(value)
		return ({Hills = "Aurora", Blue = "Bloom", Stars = "Dusk"})[value] or value or "Aurora"
	end

	function WallpaperApp.Mount(ctx, ui, args, window, api)
		local UI = ctx.UI
		local connections, unsubscribers, cards = {}, {}, {}
		local destroyed = false
		local root = UI.scroll(ui, {Name = "WallpaperContent", Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4})
		local body = UI.frame(root, {Name = "WallpaperOptions", Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1})
		UI.pad(body, 20); UI.list(body, 14)
		local function connect(signal, callback) table.insert(connections, signal:Connect(callback)) end
		UI.text(body, "Wallpaper", {Name = "Title", Size = UDim2.new(1, 0, 0, 33), TextSize = 27, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, LayoutOrder = 1})
		local subtitle = UI.text(body, "A backdrop for your desktop and home screen.", {Name = "Subtitle", Size = UDim2.new(1, 0, 0, 36), TextSize = 12, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, LayoutOrder = 2})
		UI.bind(subtitle, {TextColor3 = "Muted"})
		local function preview(parent, properties)
			local canvas = UI.frame(parent, properties)
			canvas.BackgroundColor3 = Color3.new(1, 1, 1); canvas.ClipsDescendants = true
			UI.corner(canvas, 14)
			local gradient = UI.new("UIGradient", canvas, {Rotation = 55})
			local glows = {}
			for index = 1, 2 do
				local glow = UI.frame(canvas, {Name = "Glow" .. index, Position = index == 1 and UDim2.fromScale(0.39, -0.35) or UDim2.fromScale(-0.25, 0.48), Size = UDim2.fromScale(0.94, 1.3), BackgroundTransparency = 0.80, BorderSizePixel = 0})
				UI.corner(glow, UDim.new(1, 0)); table.insert(glows, glow)
			end
			return {frame = canvas, gradient = gradient, glows = glows}
		end
		local hero = preview(body, {Name = "CurrentWallpaper", Size = UDim2.new(1, 0, 0, 150), LayoutOrder = 3})
		local heroTitle = UI.text(hero.frame, "", {Name = "WallpaperName", Position = UDim2.fromOffset(18, 88), Size = UDim2.new(1, -36, 0, 27), Font = Enum.Font.GothamBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
		local heroSubtitle = UI.text(hero.frame, "YOUR WORKSPACE", {Name = "PreviewCaption", Position = UDim2.fromOffset(19, 120), Size = UDim2.new(1, -38, 0, 13), Font = Enum.Font.Gotham, TextSize = 8, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
		local options = UI.frame(body, {Name = "Backgrounds", Size = UDim2.new(1, 0, 0, 564), BackgroundTransparency = 1, LayoutOrder = 4})
		local grid = UI.new("UIGridLayout", options, {CellSize = UDim2.new(1, 0, 0, 132), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder})
		local definitions = {
			{id = "Aurora", title = "Aurora", description = "Soft accent light."},
			{id = "Bloom", title = "Bloom", description = "Calm, muted greens."},
			{id = "Dusk", title = "Dusk", description = "A deeper purple sky."},
			{id = "Solid", title = "Pure color", description = "Your accent, simplified."},
		}
		for index, definition in ipairs(definitions) do
			local card = UI.button(options, "", {Name = definition.id, Text = "", LayoutOrder = index, BackgroundColor3 = ctx.Theme:Get().Surface, AutoButtonColor = false})
			UI.corner(card, 16)
			local image = preview(card, {Name = "Preview", Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(84, 74)})
			local title = UI.text(card, definition.title, {Name = "Name", Position = UDim2.fromOffset(108, 14), Size = UDim2.new(1, -120, 0, 23), Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
			local description = UI.text(card, definition.description, {Name = "Description", Position = UDim2.fromOffset(108, 43), Size = UDim2.new(1, -120, 0, 42), Font = Enum.Font.Gotham, TextSize = 10, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
			UI.bind(description, {TextColor3 = "Muted"})
			local status = UI.text(card, "", {Name = "Selection", Position = UDim2.fromOffset(14, 101), Size = UDim2.new(1, -28, 0, 18), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
			cards[definition.id] = {button = card, preview = image, title = title, status = status, name = definition.title}
			connect(card.Activated, function() if not destroyed then ctx.Settings:Set("wallpaper.style", definition.id) end end)
		end
		local details = UI.button(body, "", {Name = "WallpaperDetails", Size = UDim2.new(1, 0, 0, 43), Font = Enum.Font.Gotham, TextSize = 12, LayoutOrder = 5})
		connect(details.Activated, function() if not destroyed then ctx.Settings:Set("wallpaper.pattern", ctx.Settings:Get("wallpaper.pattern", false) ~= true) end end)
		local appearance = UI.button(body, "Appearance settings", {Name = "Appearance", Size = UDim2.new(1, 0, 0, 43), Font = Enum.Font.Gotham, TextSize = 12, LayoutOrder = 6})
		connect(appearance.Activated, function()
			if destroyed or not ctx.Apps then return end
			local found = false
			for _, app in ipairs(ctx.Apps:GetRunning()) do if app.id == "Settings" then found = true; break end end
			if found then ctx.Apps:Focus("Settings") else ctx.Apps:Launch("Settings") end
		end)
		local function paint(target, id)
			local dark, accent = ctx.Theme:GetTheme() == "Dark", ctx.Theme:GetAccent()
			local top, bottom, secondary
			if id == "Solid" then top = accent:Lerp(dark and Color3.new(0, 0, 0) or Color3.new(1, 1, 1), 0.88); bottom, secondary = top, accent
			elseif id == "Bloom" then top, bottom, secondary = dark and Color3.fromRGB(12, 26, 34) or Color3.fromRGB(242, 249, 246), dark and Color3.fromRGB(22, 47, 51) or Color3.fromRGB(216, 235, 231), Color3.fromRGB(93, 182, 157)
			elseif id == "Dusk" then top, bottom, secondary = Color3.fromRGB(18, 18, 37), Color3.fromRGB(45, 33, 62), Color3.fromRGB(184, 108, 160)
			else top, bottom, secondary = dark and Color3.fromRGB(9, 15, 29) or Color3.fromRGB(241, 245, 253), dark and Color3.fromRGB(24, 33, 55) or Color3.fromRGB(214, 226, 246), Color3.fromRGB(137, 116, 204) end
			target.frame.BackgroundColor3, target.gradient.Color = Color3.new(1, 1, 1), ColorSequence.new(top, bottom)
			for index, glow in ipairs(target.glows) do glow.Visible = id ~= "Solid"; glow.BackgroundColor3 = index == 1 and accent or secondary end
			return dark or id == "Dusk"
		end
		local function refresh()
			if destroyed then return end
			local palette, selected = ctx.Theme:Get(), normalized(ctx.Settings:Get("wallpaper.style", "Aurora"))
			if not cards[selected] then selected = "Aurora" end
			for id, card in pairs(cards) do
				paint(card.preview, id)
				card.button.BackgroundColor3 = selected == id and palette.SurfaceAlt or palette.Surface
				card.status.Text = selected == id and "Selected" or "Use background"
				card.status.TextColor3 = selected == id and palette.Accent or palette.Muted
			end
			local dark = paint(hero, selected)
			heroTitle.Text = cards[selected].name
			heroTitle.TextColor3, heroSubtitle.TextColor3 = dark and Color3.fromRGB(240, 245, 252) or Color3.fromRGB(34, 48, 73), dark and Color3.fromRGB(173, 190, 217) or Color3.fromRGB(87, 106, 135)
			details.Text = "Ambient texture  /  " .. (ctx.Settings:Get("wallpaper.pattern", false) == true and "On" or "Off")
		end
		local function resize()
			if destroyed then return end
			local columns = ui.AbsoluteSize.X >= 570 and 2 or 1
			grid.CellSize = UDim2.new(1 / columns, columns == 2 and -6 or 0, 0, 132)
			options.Size = UDim2.new(1, 0, 0, math.ceil(#definitions / columns) * 144 - 12)
		end
		connect(ui:GetPropertyChangedSignal("AbsoluteSize"), resize)
		table.insert(unsubscribers, ctx.Theme:Subscribe(refresh))
		if ctx.Bus then table.insert(unsubscribers, ctx.Bus:On("settings.changed", function(change) if change and (change.key == "wallpaper.style" or change.key == "wallpaper.pattern") then refresh() end end)) end
		local controller = {}
		function controller.Destroy()
			if destroyed then return end
			destroyed = true
			for _, connection in ipairs(connections) do connection:Disconnect() end
			for _, unsubscribe in ipairs(unsubscribers) do unsubscribe() end
			root:Destroy()
		end
		connect(ui.Destroying, controller.Destroy); connect(root.Destroying, controller.Destroy)
		refresh(); resize()
		return controller
	end

	return WallpaperApp

end
-- END COMPONENT: WallpaperApp
-- BEGIN COMPONENT: HomeCustomizationApp
__v3Factories["HomeCustomizationApp"] = function()
	local HomeCustomizationApp = {}

	function HomeCustomizationApp.Mount(ctx, ui, args)
		local UI = ctx.UI
		local connections, subscriptions, sliders = {}, {}, {}
		local destroyed, selected = false, "widgets"
		local root = UI.frame(ui, {Name = "MainFrame", Size = UDim2.fromScale(1, 1)})
		local function connect(signal, callback) table.insert(connections, signal:Connect(callback)) end
		local heading = UI.text(root, "Home", {Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 30), Font = Enum.Font.GothamBold, TextSize = 21, TextXAlignment = Enum.TextXAlignment.Left})
		local tabs = UI.frame(root, {Name = "Sections", Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 0, 36), BackgroundTransparency = 1})
		local pages, buttons, titles = {}, {}, {widgets = "Add widgets", personalize = "Personalize", home = "Home settings"}
		for index, name in ipairs({"widgets", "personalize", "home"}) do
			buttons[name] = UI.button(tabs, titles[name], {Name = name, Position = UDim2.new((index - 1) / 3, 3, 0, 0), Size = UDim2.new(1 / 3, -6, 1, 0), TextSize = 12})
			local page = UI.scroll(root, {Name = name .. "Page", Position = UDim2.fromOffset(12, 94), Size = UDim2.new(1, -24, 1, -106), Visible = false})
			UI.pad(page, 6); UI.list(page, 12); pages[name] = page
		end
		local function text(parent, value)
			local label = UI.text(parent, value, {Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left})
			UI.bind(label, {TextColor3 = "Muted"})
			return label
		end
		text(pages.widgets, "Choose a widget for your home screen. Tap a clock widget to open Clock.")
		local widgetButtons = {}
		for _, spec in ipairs({{"clock", "Clock", "12:08", "Time at a glance"}, {"date", "Date", "Wednesday", "Today's date"}}) do
			local name, title = spec[1], spec[2]
			local card = UI.frame(pages.widgets, {Name = title .. "Widget", Size = UDim2.new(1, -6, 0, 114)})
			UI.bevel(card)
			UI.text(card, spec[3], {Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -132, 0, 42), Font = Enum.Font.Kalam, TextSize = 29, TextXAlignment = Enum.TextXAlignment.Left})
			local detail = UI.text(card, spec[4], {Position = UDim2.fromOffset(14, 54), Size = UDim2.new(1, -28, 0, 20), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
			UI.bind(detail, {TextColor3 = "Muted"})
			local toggle = UI.button(card, "", {Name = title .. "Toggle", Position = UDim2.new(1, -118, 0, 12), Size = UDim2.fromOffset(104, 38), TextSize = 11})
			widgetButtons[name] = toggle
			connect(toggle.Activated, function() ctx.Settings:Set("home.widget." .. name, not ctx.Settings:Get("home.widget." .. name, false)) end)
		end
		text(pages.personalize, "V3 colors work with your V2 home screen and applications.")
		local themeRow = UI.frame(pages.personalize, {Name = "ThemeChoices", Size = UDim2.new(1, -6, 0, 40), BackgroundTransparency = 1})
		local themeButtons = {}
		for index, theme in ipairs({"Dark", "Light"}) do
			local button = UI.button(themeRow, theme, {Name = theme, Position = UDim2.new((index - 1) / 2, 3, 0, 0), Size = UDim2.new(0.5, -6, 1, 0)})
			themeButtons[theme] = button
			connect(button.Activated, function() ctx.Theme:SetTheme(theme) end)
		end
		text(pages.personalize, "Accent color")
		local colors = {Color3.fromRGB(47, 118, 204), Color3.fromRGB(83, 120, 211), Color3.fromRGB(145, 92, 199), Color3.fromRGB(204, 72, 80), Color3.fromRGB(213, 126, 38), Color3.fromRGB(42, 147, 109)}
		local accents = UI.frame(pages.personalize, {Name = "AccentColors", Size = UDim2.new(1, -6, 0, 40), BackgroundTransparency = 1})
		for index, color in ipairs(colors) do
			local button = UI.button(accents, "", {Name = "Accent" .. index, Position = UDim2.new((index - 1) / #colors, 3, 0, 0), Size = UDim2.new(1 / #colors, -6, 1, 0), BackgroundColor3 = color})
			connect(button.Activated, function() ctx.Theme:SetAccent(color) end)
		end
		local wallpaper = UI.button(pages.personalize, "Wallpapers", {Name = "Wallpapers", Size = UDim2.new(1, -6, 0, 40)})
		connect(wallpaper.Activated, function() ctx.Apps:Launch("WallpaperSys") end)
		local settings = UI.button(pages.personalize, "Open appearance settings", {Name = "AppearanceSettings", Size = UDim2.new(1, -6, 0, 40)})
		connect(settings.Activated, function() ctx.Apps:Launch("Settings", {section = "appearance"}) end)
		text(pages.home, "Adjust the home screen. System utilities stay available through Settings without taking up home icon space.")
		local labels = UI.button(pages.home, "", {Name = "ShowLabels", Size = UDim2.new(1, -6, 0, 40)})
		connect(labels.Activated, function() ctx.Settings:Set("home.labels", not ctx.Settings:Get("home.labels", true)) end)
		local _, sizeSlider = UI.slider(pages.home, {Name = "IconSize", Label = "Icon size", Value = (ctx.Settings:Get("home.iconScale", 1) - 0.8) / 0.5,
			Format = function(value) return tostring(math.floor((0.8 + value * 0.5) * 100 + 0.5)) .. "%" end,
			Changed = function(value) ctx.Settings:Set("home.iconScale", 0.8 + value * 0.5) end})
		table.insert(sliders, sizeSlider)
		text(pages.home, "Icons per page row")
		local gridRow = UI.frame(pages.home, {Name = "HomeGrid", Size = UDim2.new(1, -6, 0, 40), BackgroundTransparency = 1})
		local gridButtons = {}
		for index, count in ipairs({0, 3, 4, 5, 6}) do
			local button = UI.button(gridRow, count == 0 and "Auto" or tostring(count), {Name = "Columns" .. count, Position = UDim2.new((index - 1) / 5, 2, 0, 0), Size = UDim2.new(0.2, -4, 1, 0), TextSize = 12})
			gridButtons[count] = button
			connect(button.Activated, function() ctx.Settings:Set("home.columns", count) end)
		end
		local reset = UI.button(pages.home, "Reset home layout", {Name = "ResetHome", Size = UDim2.new(1, -6, 0, 40)})
		connect(reset.Activated, function()
			for key, value in pairs({["home.labels"] = true, ["home.iconScale"] = 1, ["home.columns"] = 0, ["home.widget.clock"] = false, ["home.widget.date"] = false}) do ctx.Settings:Set(key, value) end
		end)
		local function refresh()
			if destroyed then return end
			local function highlight(button, active)
				UI.bind(button, {BackgroundColor3 = active and "Accent" or "SurfaceAlt", TextColor3 = active and "AccentText" or "Text"})
			end
			for name, button in pairs(buttons) do highlight(button, selected == name) end
			for name, button in pairs(widgetButtons) do button.Text = ctx.Settings:Get("home.widget." .. name, false) and "Remove" or "Add to Home" end
			for name, button in pairs(themeButtons) do highlight(button, ctx.Theme:GetTheme() == name) end
			for count, button in pairs(gridButtons) do highlight(button, ctx.Settings:Get("home.columns", 0) == count) end
			labels.Text = "App labels: " .. (ctx.Settings:Get("home.labels", true) and "Shown" or "Hidden")
			sizeSlider.SetValue((ctx.Settings:Get("home.iconScale", 1) - 0.8) / 0.5, true)
		end
		local controller = {}
		function controller.Navigate(section)
			section = tostring(section or "widgets"):lower():gsub("%s+", "")
			if section == "homesettings" then section = "home" end
			if not pages[section] then return false end
			selected = section; heading.Text = titles[section]
			for name, page in pairs(pages) do page.Visible = name == selected end
			refresh(); return true
		end
		for name, button in pairs(buttons) do connect(button.Activated, function() controller.Navigate(name) end) end
		function controller.Destroy()
			if destroyed then return end
			destroyed = true
			for _, connection in ipairs(connections) do connection:Disconnect() end
			for _, unsubscribe in ipairs(subscriptions) do unsubscribe() end
			for _, slider in ipairs(sliders) do slider.Destroy() end
			root:Destroy()
		end
		connect(ui.Destroying, controller.Destroy)
		table.insert(subscriptions, ctx.Theme:Subscribe(refresh))
		table.insert(subscriptions, ctx.Bus:On("settings.changed", function(change) if change.key:sub(1, 5) == "home." then refresh() end end))
		controller.Navigate(type(args) == "table" and args.section or "widgets")
		return controller
	end

	return HomeCustomizationApp

end
-- END COMPONENT: HomeCustomizationApp
-- BEGIN COMPONENT: InstallerApp
__v3Factories["InstallerApp"] = function()
	local InstallerApp = {}
	function InstallerApp.Mount(ctx, ui)
		local UI, connections, subscriptions = ctx.UI, {}, {}
		local destroyed, selected = false, nil
		local function connect(signal, callback) table.insert(connections, signal:Connect(callback)) end
		local root = UI.frame(ui, {Name = "ApplicationsRoot", Size = UDim2.fromScale(1, 1)})
		UI.text(root, "Applications", {Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 30), Font = Enum.Font.GothamBold, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left})
		local search = UI.new("TextBox", root, {Name = "Search", Position = UDim2.fromOffset(14, 50), Size = UDim2.new(1, -28, 0, 34), PlaceholderText = "Find an installed app", Text = "", TextXAlignment = Enum.TextXAlignment.Left})
		UI.pad(search, 8)
		local list = UI.scroll(root, {Name = "AppList", Position = UDim2.fromOffset(14, 94), Size = UDim2.new(1, -28, 1, -204)})
		UI.list(list, 6)
		local footer = UI.text(root, "", {Name = "Details", Position = UDim2.new(0, 14, 1, -102), Size = UDim2.new(1, -28, 0, 43), TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})
		UI.bind(footer, {TextColor3 = "Muted"})
		local open = UI.button(root, "Open", {Name = "OpenApp", Position = UDim2.new(0, 14, 1, -49), Size = UDim2.new(0.333, -15, 0, 34)})
		local toggle = UI.button(root, "Disable", {Name = "ToggleApp", Position = UDim2.new(0.333, 3, 1, -49), Size = UDim2.new(0.333, -10, 0, 34)})
		local remove = UI.button(root, "Remove", {Name = "RemoveApp", Position = UDim2.new(0.666, 7, 1, -49), Size = UDim2.new(0.334, -21, 0, 34)})
		local rows = {}
		local function selection()
			local metadata = selected and ctx.Apps:GetMetadata(selected)
			local editable = metadata and not metadata.builtin
			open.Active = metadata ~= nil and not metadata.disabled
			toggle.Active, remove.Active = not not editable, not not editable
			toggle.Text = metadata and metadata.disabled and "Enable" or "Disable"
			if metadata then
				footer.Text = metadata.description .. "\n" .. (metadata.builtin and "Included with ZolinOS 3" or (metadata.source and metadata.source ~= "" and "Imported app · " .. metadata.version or "Local application"))
			else footer.Text = "Select an application to open or manage it." end
			local palette = ctx.Theme:Get()
			for id, row in pairs(rows) do row.button.BackgroundColor3 = id == selected and palette.Accent or palette.SurfaceAlt; row.title.TextColor3 = id == selected and palette.AccentText or palette.Text end
			for _, button in ipairs({open, toggle, remove}) do button.TextColor3 = button.Active and palette.Text or palette.Muted end
		end
		local function refresh()
			if destroyed then return end
			local seen, query = {}, search.Text:lower()
			for index, meta in ipairs(ctx.Apps:List()) do
				seen[meta.id] = true
				local row = rows[meta.id]
				if not row then
					local button = UI.button(list, "", {Name = meta.id, Size = UDim2.new(1, -8, 0, 62)})
					local title = UI.text(button, meta.name, {Position = UDim2.fromOffset(10, 7), Size = UDim2.new(1, -20, 0, 23), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left})
					local subtitle = UI.text(button, "", {Position = UDim2.fromOffset(10, 33), Size = UDim2.new(1, -20, 0, 19), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
					UI.bind(subtitle, {TextColor3 = "Muted"})
					row = {button = button, title = title, subtitle = subtitle}
					row.connection = button.Activated:Connect(function() selected = meta.id; selection() end)
					rows[meta.id] = row
				end
				row.button.LayoutOrder = index
				row.button.Visible = meta.name:lower():find(query, 1, true) ~= nil
				row.title.Text = meta.name
				row.subtitle.Text = (meta.disabled and "Disabled" or (meta.builtin and "System app" or "Imported app")) .. " · " .. meta.version
			end
			for id, row in pairs(rows) do if not seen[id] then row.connection:Disconnect(); row.button:Destroy(); rows[id] = nil end end
			if selected and not seen[selected] then selected = nil end
			selection()
		end
		connect(search:GetPropertyChangedSignal("Text"), refresh)
		connect(open.Activated, function() if selected then ctx.Apps:Launch(selected) end end)
		connect(toggle.Activated, function() local meta = selected and ctx.Apps:GetMetadata(selected); if meta and not meta.builtin then ctx.Apps:SetEnabled(meta.id, meta.disabled) end end)
		local confirmId
		connect(remove.Activated, function()
			local meta = selected and ctx.Apps:GetMetadata(selected)
			if not meta or meta.builtin then return end
			if confirmId ~= meta.id then confirmId = meta.id; footer.Text = "Remove " .. meta.name .. "? Select Remove again to confirm."; return end
			confirmId = nil
			ctx.Apps:Close(meta.id)
			ctx.Settings:Set("apps." .. meta.id .. ".uninstalled", true)
			if meta.template then meta.template:Destroy() end
			if meta.module then meta.module:Destroy() end
			local entry = ctx.Gui.__Zolin.__AppsLaunchArgFolder:FindFirstChild(meta.id); if entry then entry:Destroy() end
			ctx.Apps:Unregister(meta.id); ctx.External:Refresh()
		end)
		table.insert(subscriptions, ctx.Apps:Subscribe(refresh))
		table.insert(subscriptions, ctx.Theme:Subscribe(selection))
		local controller = {}
		function controller.Destroy()
			if destroyed then return end; destroyed = true
			for _, connection in ipairs(connections) do connection:Disconnect() end
			for _, disconnect in ipairs(subscriptions) do disconnect() end
			for _, row in pairs(rows) do row.connection:Disconnect() end
			root:Destroy()
		end
		connect(ui.Destroying, controller.Destroy)
		refresh()
		return controller
	end
	return InstallerApp


end
-- END COMPONENT: InstallerApp
-- BEGIN COMPONENT: Runtime
__v3Factories["Runtime"] = function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Runtime = {Current = nil}
	local INITIATOR_URL = "https://raw.githubusercontent.com/mohammadbakon123x/Zolin-OS/refs/heads/main/Initiator2.lua"
	local function folder(parent, name)
		local found = parent:FindFirstChild(name)
		if found then return found end
		local created = Instance.new("Folder"); created.Name = name; created.Parent = parent; return created
	end
	local function event(parent, name)
		local found = parent:FindFirstChild(name)
		if found and found:IsA("BindableEvent") then return found end
		local created = Instance.new("BindableEvent"); created.Name = name; created.Parent = parent; return created
	end
	local function requireModule(root, name) return __v3Require(name) end
	function Runtime.Start(root, options)
		options = options or {}
		assert(typeof(root) == "Instance", "Runtime.Start needs the V3 library root")
		local initiator = options.Initiator
		if not initiator then
			local source = game:HttpGet(INITIATOR_URL, true)
			local compiler = loadstring
			assert(type(compiler) == "function", "This client does not expose loadstring")
			local chunk, compileError = compiler(source, "@ZolinOS3/Initiator.lua")
			assert(type(chunk) == "function", "Could not compile remote Initiator: " .. tostring(compileError))
			initiator = chunk()
		end
		assert(type(initiator) == "table" and type(initiator.Setup) == "function", "Remote Initiator must return a table with Setup(root)")
		if root:GetAttribute("InitiatorSetupVersion") == nil then initiator.Setup(root) end
		if Runtime.Current and not Runtime.Current.destroyed and Runtime.Current.Gui.Parent then return Runtime.Current end
		local player = options.Player or Players.LocalPlayer
		assert(player, "ZolinOS 3 starts in a LocalScript")
		local playerGui = player:WaitForChild("PlayerGui")
		local previous = playerGui:FindFirstChild("ZolinOS")
		if previous and previous:GetAttribute("Ready") == true and previous:GetAttribute("ZolinVersion") == "3.0.0" then
			local remotes = previous:FindFirstChild("__Zolin") and previous.__Zolin:FindFirstChild("Remotes")
			local getRuntime = remotes and remotes:FindFirstChild("GetRuntime")
			if getRuntime and getRuntime:IsA("BindableFunction") then
				local ok, getter = pcall(function() return getRuntime:Invoke() end)
				local current = ok and type(getter) == "function" and getter() or nil
				if ok and type(current) == "table" and not current.destroyed then Runtime.Current = current; return current end
			end
		end
		if previous then previous:Destroy() end
		local gui = Instance.new("ScreenGui")
		gui.Name = "ZolinOS"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.DisplayOrder = 10
		gui:SetAttribute("ZolinVersion", "3.0.0")
		local ctx = {RootFolder = root, Gui = gui, Player = player, connections = {}, destroyed = false, Version = "3.0.0",
			SourceLoader = options.SourceLoader, FetchSource = options.FetchSource, CompileSource = options.CompileSource, AppUrls = options.AppUrls or {}}
		ctx.Stop = function() Runtime.Stop(ctx, false) end
		Runtime.Current = ctx
		table.insert(ctx.connections, gui.Destroying:Connect(function() Runtime.Stop(ctx, true) end))
		ctx.Bus = requireModule(root, "SignalBus").new()
		ctx.Settings = requireModule(root, "Preferences").new(ctx)
		ctx.Theme = requireModule(root, "ThemeService").new(ctx)
		ctx.UI = requireModule(root, "UI").new(ctx)
		local zolin = folder(gui, "__Zolin")
		local remotes = folder(zolin, "Remotes")
		folder(zolin, "__AppsLaunchArgFolder")
		folder(folder(folder(zolin, "0"), "ZolinInstaller"), "__autoInstallOnInit")
		folder(gui, "AppData")
		for _, name in ipairs({"ReplicatedWindow", "ReplicatedWindow_Sys"}) do
			local templates = folder(gui, name)
			local source = root:FindFirstChild("AppTemplates")
			source = source and source:FindFirstChild(name)
			assert(source, "Initiator did not create AppTemplates." .. name)
			if source then
				for _, template in ipairs(source:GetChildren()) do
					local clone = template:Clone()
					if clone:IsA("GuiObject") then clone.Visible = false end
					for _, item in ipairs(clone:GetDescendants()) do
						if item:IsA("BaseScript") then
							if item:GetAttribute("V3OriginallyEnabled") == nil then item:SetAttribute("V3OriginallyEnabled", item.Enabled) end
							item.Enabled = false
						end
					end
					clone.Parent = templates
				end
			end
		end
		for _, name in ipairs({"MediaSoundUI", "NotificationSoundUI"}) do local group = Instance.new("SoundGroup"); group.Name = name; group.Volume = 1; group.Parent = gui end
		local function resolveMode()
			local mode = ctx.Settings:Get("display.mode", "Auto")
			if mode ~= "Auto" then return mode end
			local camera = workspace.CurrentCamera
			local width = camera and camera.ViewportSize.X or 1280
			return (width < 700 or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)) and "Mobile" or "Desktop"
		end
		ctx.Mode = resolveMode()
		ctx.Apps = requireModule(root, "AppManager").new(ctx)
		ctx.Bridge = requireModule(root, "AppBridge").new(ctx)
		gui.Parent = playerGui
		ctx.Shell = requireModule(root, "Shell").new(ctx)
		ctx.Volume = requireModule(root, "VolumeService").new(ctx)
		ctx.Notifications = requireModule(root, "NotificationService").new(ctx)
		ctx.Power = requireModule(root, "PowerService").new(ctx)
		ctx.Clock = requireModule(root, "ClockService").new(ctx)
		local function setMode(mode)
			if mode and mode ~= "Auto" and mode ~= "Desktop" and mode ~= "Mobile" then return false end
			if mode then ctx.Settings:Set("display.mode", mode) end
			local actual = resolveMode()
			if ctx.Mode ~= actual then
				ctx.Mode = actual
				ctx.Shell:SetMode(actual)
				ctx.Apps:SetMode()
				ctx.Bus:Emit("mode.changed", {mode = actual})
				gui:SetAttribute("Mode", actual)
			end
			return true
		end
		ctx.SetMode = setMode
		ctx.unsubscribeBounds = ctx.Bus:On("surface.resize", function() ctx.Apps:Resize() end)
		local function builtin(id, title, moduleName, description, icon, hiddenFromHome)
			ctx.Apps:Register({id = id, name = title, icon = icon, description = description, version = "3.0.0", system = true, builtin = true,
				hiddenFromHome = hiddenFromHome ~= false, protected = hiddenFromHome ~= false,
				render = function(ui, args, window, api)
					local module = requireModule(root, moduleName)
					return module.Mount(ctx, ui, args, window, api)
				end})
		end
		builtin("Settings", "Settings", "SettingsApp", "Appearance, sound, notifications and applications", "rbxassetid://115730300615716", false)
		builtin("Clock", "Clock", "ClockApp", "Local time, alarms and timers", "")
		builtin("TaskManager", "Task Manager", "TaskManagerApp", "Manage applications and view client performance", "")
		builtin("WallpaperSys", "Wallpaper", "WallpaperApp", "Choose your home screen background", "rbxassetid://128691285053548")
		builtin("ZolinInstaller", "ZolinInstaller", "InstallerApp", "Install URL packages and manage applications", "rbxassetid://128691285053548", false)
		builtin("HomeCustomization", "Home settings", "HomeCustomizationApp", "Widgets, personalization and home screen settings", "", true)
		ctx.External = requireModule(root, "ExternalApps").new(ctx)
		ctx.External:Refresh()
		local autoInstall = zolin["0"].ZolinInstaller.__autoInstallOnInit
		local function processAutoInstall()
			if not ctx.destroyed then ctx.External:ProcessAutoInstall() end
		end
		table.insert(ctx.connections, autoInstall.ChildAdded:Connect(function() task.defer(processAutoInstall) end))
		-- Legacy events remain usable by existing GitHub packages and applications.
		table.insert(ctx.connections, event(remotes, "updateZolinLauncher").Event:Connect(function() ctx.External:Refresh(); ctx.Shell:RefreshApps() end))
		table.insert(ctx.connections, event(remotes, "CloseAllApps").Event:Connect(function()
			local ids = {}; for _, item in ipairs(ctx.Apps:GetRunning()) do table.insert(ids, item.id) end
			for _, id in ipairs(ids) do ctx.Apps:Close(id) end
		end))
		table.insert(ctx.connections, event(remotes, "SendNotificationEvent").Event:Connect(function(data, message, appId)
			if type(data) ~= "table" then data = {title = tostring(data or "Notification"), message = tostring(message or ""), appId = appId} end
			ctx.Notifications:Push(data)
		end))
		table.insert(ctx.connections, event(remotes, "moreOptionsVolStyle").Event:Connect(function(action)
			if action == "Close" then ctx.Volume:CloseMixer() elseif action == "Open" then ctx.Volume:OpenMixer() else ctx.Volume:ToggleMixer() end
		end))
		table.insert(ctx.connections, event(remotes, "SettingsNavigateEvent").Event:Connect(function(section)
			ctx.Apps:Launch("Settings", {section = section})
		end))
		table.insert(ctx.connections, event(remotes, "ZolinModeEvent").Event:Connect(function(_, mode)
			ctx.SetMode(mode == "__safeModeDesktop" and "Desktop" or mode)
		end))
		local getAPI = Instance.new("BindableFunction")
		getAPI.Name = "GetAppAPI"; getAPI.OnInvoke = function(id) local record = ctx.Apps.windows[id]; return record and record.api end; getAPI.Parent = remotes
		local getRuntime = Instance.new("BindableFunction")
		getRuntime.Name = "GetRuntime"; getRuntime.OnInvoke = function() return function() return ctx end end; getRuntime.Parent = remotes
		local send = Instance.new("BindableFunction")
		send.Name = "AppRequest"; send.OnInvoke = function(from, to, method, payload)
			local record = ctx.Apps.windows[from]; if not record then return false, "Source app is closed" end
			return record.api.Request(to, method, payload)
		end; send.Parent = remotes
		local elapsed = 0
		table.insert(ctx.connections, RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed >= 1 then elapsed = 0; gui:SetAttribute("UptimeSeconds", math.floor(os.clock() - ctx.StartedAt)) end
		end))
		ctx.StartedAt = os.clock()
		table.insert(ctx.connections, ctx.DesktopArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() ctx.Apps:Resize(); if ctx.Settings:Get("display.mode") == "Auto" then setMode() end end))
		table.insert(ctx.connections, ctx.MobileArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if ctx.Settings:Get("display.mode") == "Auto" then setMode() end end))
		local onPreference = ctx.Bus:On("settings.changed", function(change)
			if change.key == "display.mode" then setMode() end
		end)
		ctx.unsubscribeMode = onPreference
		ctx.Shell:SetMode(ctx.Mode)
		ctx.Shell:RefreshApps(); ctx.Shell:RefreshTasks()
		gui:SetAttribute("Mode", ctx.Mode); gui:SetAttribute("Ready", true)
		Runtime.Current = ctx
		task.defer(processAutoInstall)
		return ctx
	end
	function Runtime.Stop(ctx, keepGui)
		ctx = ctx or Runtime.Current
		if not ctx or ctx.destroyed then return end
		ctx.destroyed = true
		if ctx.unsubscribeMode then ctx.unsubscribeMode() end
		if ctx.unsubscribeBounds then ctx.unsubscribeBounds() end
		for _, connection in ipairs(ctx.connections) do connection:Disconnect() end
		for _, key in ipairs({"Apps", "External", "Clock", "Notifications", "Power", "Volume", "Shell", "Bridge", "Theme", "Settings", "Bus"}) do
			local service = ctx[key]
			if service and type(service.Destroy) == "function" then
				local ok, err = pcall(service.Destroy, service); if not ok then warn("[ZolinOS cleanup " .. key .. "] " .. tostring(err)) end
			end
		end
		if not keepGui and ctx.Gui then ctx.Gui:Destroy() end
		if Runtime.Current == ctx then Runtime.Current = nil end
	end
	return Runtime


end
-- END COMPONENT: Runtime
__v3Factories["LegacyFirmware"] = function()

	if game:GetService("RunService"):IsStudio() then
		print("Studio")
		return
	end

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

	local FrameList = bootloader:FindFirstChild("FrameList")
	if not FrameList then
		warn("Bootloader: FrameList not found")
		return
	end

	local SelectionList = bootloader:FindFirstChild("SelectionList")
	if not SelectionList then
		warn("Bootloader: SelectionList not found")
		return
	end

	local LoadingUI = bootloader:FindFirstChild("LoadingUI")
	if not LoadingUI then
		warn("Bootloader: LoadingUI not found")
		return
	end

	local ImageOS_2 = LoadingUI:FindFirstChild("ImageOS_2")
	if not ImageOS_2 then
		warn("Bootloader: ImageOS_2 not found")
		return
	end

	local LoadingCircle = LoadingUI:FindFirstChild("LoadingCircle")
	if not LoadingCircle then
		warn("Bootloader: LoadingCircle not found")
		return
	end

	local MessageLabel = LoadingUI:FindFirstChild("MessageLabel")
	if not MessageLabel then
		warn("Bootloader: MessageLabel not found")
		return
	end

	-- ---- References to UI containers (template folders) ----
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

	-- ---- InfoLabel template ----
	local infoTemplate = frameListFolder:FindFirstChild("InfoLabel")
	if not infoTemplate then
		warn("Bootloader: InfoLabel template not found")
		return
	end
	infoTemplate.Visible = false  -- hide template

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

	-- ---- Build info text (as a table of lines) ----
	local function getFriendCount(userId)
		if not userId then return 0 end

		local success, friendsPage = pcall(function()
			return Players:GetFriendsAsync(userId)
		end)

		if not success or not friendsPage then
			warn("Failed to get friends for user:", userId)
			return 0
		end

		local onlineCount = 0

		-- Loop through all pages
		while true do
			local currentPage = friendsPage:GetCurrentPage()
			if not currentPage or #currentPage == 0 then
				break
			end

			for _, friend in ipairs(currentPage) do
				if friend.IsOnline then
					onlineCount = onlineCount + 1
				end
			end

			if friendsPage.IsFinished then
				break
			end

			local advanceSuccess = pcall(function()
				friendsPage:AdvanceToNextPageAsync()
			end)

			if not advanceSuccess then
				warn("Failed to advance friends page for user:", userId)
				break
			end
		end

		return onlineCount
	end

	local function getInfoLines()
		local userId = player.UserId
		local displayName = player.DisplayName
		local userName = player.Name
		local friendCount = getFriendCount(userId)
		local isOwner = isSystemOwner()
		local gameName = game.Name or "Unknown"
		local placeId = game.PlaceId or 0
		local bootMode = "Bootloader"

		return {
			"Username: " .. userName,
			"Display Name: " .. displayName,
			"User ID: " .. userId,
			"Friends Online: " .. tostring(friendCount),
			"System Owner: " .. (isOwner and "✅ Yes" or "❌ No"),
			"Game: " .. gameName,
			"Place ID: " .. placeId,
			"Current Boot: " .. bootMode,
		}
	end

	-- ---- Populate InfoLabel lines into FrameList ----
	local function populateInfoLabels()
		-- Clear existing info labels (keep template)
		for _, child in ipairs(FrameList:GetChildren()) do
			if child ~= infoTemplate then
				child:Destroy()
			end
		end

		-- Ensure FrameList has a UIListLayout
		local layout = FrameList:FindFirstChildOfClass("UIListLayout")
		if not layout then
			layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 4)
			layout.Parent = FrameList
		end

		local lines = getInfoLines()
		for order, line in ipairs(lines) do
			local label = infoTemplate:Clone()
			label.Name = "InfoLine_" .. order
			label.Visible = true
			label.Text = line
			label.LayoutOrder = order
			label.Parent = FrameList
		end
	end

	populateInfoLabels()

	-- ---- Mode options (LayoutOrder is determined by table order) ----
	local modeOptions = {
		{ label = "Boot as [Mobile Mode]",              mode = "Mobile" },
		--{ label = "Boot as [Desktop Mode]",             mode = "Desktop" },
		--{ label = "Boot as [Desktop + Safe Mode] With Command Prompt [Beta]", mode = "__safeModeDesktop" },
	}

	-- ---- Clear existing buttons (keep template) ----
	for _, child in ipairs(SelectionList:GetChildren()) do
		if child ~= buttonTemplate then
			child:Destroy()
		end
	end

	-- ---- Ensure UIListLayout exists on SelectionList ----
	local layout = SelectionList:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 10)
		layout.Parent = SelectionList
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

	if LoadingUI then
		LoadingUI.Visible = false; -- hide loading screen
	end
	for order, option in ipairs(modeOptions) do
		local btn = buttonTemplate:Clone()
		btn.Name = "ModeButton_" .. option.mode
		btn.Visible = true
		btn.Text = option.label
		btn.LayoutOrder = order
		btn.Parent = SelectionList

		btn.MouseButton1Click:Connect(function()
			local mode = option.mode
			print("[Bootloader] Selected mode:", mode)

			local evt = getZolinModeEvent()
			if evt then
				evt:Fire("boot", mode)
				print("[Bootloader] Fired ZolinModeEvent with:", mode)
			else
				warn("[Bootloader] ZolinModeEvent not found")
			end
		end)
	end

	print("[Bootloader] Ready. Waiting for mode selection...")

end
__v3Factories["Facade"] = function()
	-- Compatibility facade. Every factory returns the same V3 service adapter.
	local Runtime = __v3Require("Runtime")
	local ZolinModules = {Mode = "", ZolinVersion = "3.0.0", ZolinStarted = false, SafeMode = false,
		AppLaunchType = {Settings = "ZolinModules", Clock = "ZolinModules", TaskManager = "ZolinModules", WallpaperSys = "ZolinModules", ZolinInstaller = "ZolinModules", HomeCustomization = "ZolinModules"},
		VISIBLE_SYSTEM_APPS = {Settings = true, ZolinInstaller = true}, AppUrls = {}, RootFolder = nil}
	function ZolinModules.BindRoot(root)
		if typeof(root) ~= "Instance" then return false, "A V3 library folder is required" end
		ZolinModules.RootFolder = root
		return true
	end
	local function rootFolder()
		return ZolinModules.RootFolder or script.Parent
	end
	local lastReportedMode
	local function runtimeOptions(options)
		local result = table.clone(options or {})
		if result.AppUrls == nil then result.AppUrls = ZolinModules.AppUrls end
		return result
	end
	local function synchronize(ctx)
		ZolinModules.Mode, ZolinModules.ZolinStarted = ctx.Mode, true
		lastReportedMode = ctx.Mode
		ctx.AppUrls = type(ZolinModules.AppUrls) == "table" and ZolinModules.AppUrls or {}
		ctx.GetAppUrls = function() return type(ZolinModules.AppUrls) == "table" and ZolinModules.AppUrls or {} end
		if not ctx.facadeModeSynchronized then
			ctx.facadeModeSynchronized = true
			ctx.Bus:On("mode.changed", function(data)
				ZolinModules.Mode, lastReportedMode = data.mode, data.mode
			end)
			ctx.Bus:On("apps.changed", function(change)
				local meta = change.id and ctx.Apps:GetMetadata(change.id)
				if meta then ZolinModules.AppLaunchType[change.id] = meta.builtin and "ZolinModules" or "loadstring"
				elseif change.id then ZolinModules.AppLaunchType[change.id] = nil end
			end)
		end
		for _, meta in ipairs(ctx.Apps:List()) do ZolinModules.AppLaunchType[meta.id] = meta.builtin and "ZolinModules" or "loadstring" end
		return ctx
	end
	local function context()
		local ctx = Runtime.Start(rootFolder(), runtimeOptions())
		return synchronize(ctx)
	end
	local function adapters()
		local ctx = context()
		if ctx.adapters then return ctx.adapters end
		local a = {}
		local function exitApplication(id)
			id = id or ctx.Apps:GetActive()
			local meta = id and ctx.Apps:GetMetadata(id)
			if not meta then return false end
			return meta.protected and ctx.Apps:Close(id) or ctx.Apps:Minimize(id)
		end
		a.AppManager = {
			LaunchApplication = function(id, args)
				ctx.AppUrls = type(ZolinModules.AppUrls) == "table" and ZolinModules.AppUrls or {}
				ctx.External:Refresh()
				return ctx.Apps:Launch(id, args)
			end,
			CloseApp = function(id) return ctx.Apps:Close(id) end,
			ExitApplication = exitApplication,
			ResumeApplication = function(id) return ctx.Apps:Focus(id) end,
			GetApplication = function(id) return ctx.Apps:IsRunning(id) end,
			GetActiveApp = function() return ctx.Apps:GetActive() end,
			GetAppCount = function() return #ctx.Apps:GetRunning() end,
			GetRunningApps = function() local result = {}; for _, app in ipairs(ctx.Apps:GetRunning()) do if app.state ~= "Minimized" then table.insert(result, app.id) end end; return result end,
			GetBackgroundApps = function() local result = {}; for _, app in ipairs(ctx.Apps:GetRunning()) do if app.state == "Minimized" then table.insert(result, app.id) end end; return result end,
			GetAppHistory = function() return ctx.Apps:GetHistory() end,
			IsSystemApp = function(id) local meta = ctx.Apps:GetMetadata(id); return meta and meta.protected == true or false end,
			IsRawSystemApp = function(id) local meta = ctx.Apps:GetMetadata(id); return meta and meta.system == true or false end,
			RegisterSystemApp = function(id) local meta = ctx.Apps:GetMetadata(id); if meta then meta.system = true; meta.hiddenFromHome = not ZolinModules.VISIBLE_SYSTEM_APPS[id]; meta.protected = meta.hiddenFromHome; ctx.Apps:Register(meta) end end,
			HandleExit = function() return exitApplication() end,
			BackButton = function() return exitApplication() end,
		}
		local subscriptions = {}
		function a.AppManager.Subscribe(name, callback)
			local events = {onAppLaunched = "launched", onAppClosed = "closed", onAppBackgrounded = "minimized", onAppResumed = "focused", onActiveAppChanged = "focused"}
			if not events[name] or type(callback) ~= "function" then return false end
			subscriptions[name] = subscriptions[name] or {}
			if subscriptions[name][callback] then return true end
			subscriptions[name][callback] = ctx.Bus:On("apps.changed", function(change) if change.event == events[name] then callback(change.id) end end)
			return true
		end
		function a.AppManager.Unsubscribe(name, callback)
			local list = subscriptions[name]
			if not list or not list[callback] then return false end
			list[callback](); list[callback] = nil; return true
		end
		function a.AppManager.CloseAllApps()
			for _, app in ipairs(ctx.Apps:GetRunning()) do ctx.Apps:Close(app.id) end
		end
		function a.AppManager.ExitAllApps()
			for _, app in ipairs(ctx.Apps:GetRunning()) do exitApplication(app.id) end
		end
		a.AppManager.GoHomeScreen = a.AppManager.ExitAllApps
		a.AppLoader = {
			GetAllApps = function() local result = {}; for _, meta in ipairs(ctx.Apps:List()) do if not meta.disabled then table.insert(result, {name = meta.id, metadata = meta, enabled = true, isSystem = meta.system == true}) end end; return result end,
			GetAppMetadata = function(id) return ctx.Apps:GetMetadata(id) end,
			RegisterApp = function(id, metadata)
				local meta = ctx.Apps:GetMetadata(id) or {id = id}
				for key, value in pairs(metadata or {}) do meta[key] = value end
				if metadata and metadata.isSystem ~= nil then meta.system = metadata.isSystem == true end
				if metadata and metadata.enabled ~= nil then meta.disabled = metadata.enabled ~= true end
				meta.id = id; ctx.Apps:Register(meta)
				return true
			end,
			LoadAppIcon = function(id, image) local meta = ctx.Apps:GetMetadata(id); if meta then image.Image = meta.icon; return true end; return false end,
		}
		a.NotificationManager = {
			ShowNotification = function(data)
				if type(data) ~= "table" then data = {message = tostring(data)} end
				data = table.clone(data); data.appId = data.appId or data.appName or data.source or "System"
				data.message = data.message or data.description or data.text or ""
				return ctx.Notifications:Push(data)
			end,
			SetDoNotDisturb = function(enabled) ctx.Notifications:SetDND(enabled) end,
			GetDoNotDisturb = function() return ctx.Notifications:GetDND() end,
			OpenPanel = function() ctx.Notifications:OpenPanel() end,
			ClosePanel = function() ctx.Notifications:ClosePanel() end,
			TogglePanel = function() ctx.Notifications:TogglePanel() end,
			Initialize = function() end,
		}
		a.VolumeManager = {
			GetVolume = function() return ctx.Volume:GetVolume("master") end,
			SetVolume = function(value) ctx.Volume:SetVolume("master", value) end,
			GetMuted = function() return ctx.Volume:IsMuted("master") end,
			SetMuted = function(value) ctx.Volume:SetMuted("master", value) end,
			ToggleMute = function() ctx.Volume:SetMuted("master", not ctx.Volume:IsMuted("master")) end,
			GetNotificationVolume = function() return ctx.Volume:GetVolume("notifications") end,
			SetNotificationVolume = function(value) ctx.Volume:SetVolume("notifications", value) end,
			GetNotificationsMuted = function() return ctx.Volume:IsMuted("notifications") end,
			SetNotificationsMuted = function(value) ctx.Volume:SetMuted("notifications", value) end,
			ToggleNotificationsMute = function() ctx.Volume:SetMuted("notifications", not ctx.Volume:IsMuted("notifications")) end,
			Open = function() ctx.Volume:OpenPanel() end,
			Close = function() ctx.Volume:ClosePanel() end,
			Toggle = function() ctx.Volume:TogglePanel() end,
			IsOpen = function() return ctx.Volume:IsPanelOpen() end,
			Initialize = function() end, Cleanup = function() end,
		}
		a.VolumeStyleOptions = {Toggle = function() ctx.Volume:ToggleMixer() end, Open = function() ctx.Volume:OpenMixer() end, Close = function() ctx.Volume:CloseMixer() end, IsOpen = function() return ctx.Volume:IsMixerOpen() end, Initialize = function() end}
		a.PowerMenuManager = {Toggle = function() return ctx.Power:Toggle() end, Open = function() return ctx.Power:Open() end, Close = function() return ctx.Power:Close() end, IsOpen = function() return ctx.Power:IsOpen() end, Initialize = function() end}
		a.SettingsManager = {
			GetSetting = function(key) return ctx.Settings:Get(key) end,
			SetSetting = function(key, value) return ctx.Settings:Set(key, value) end,
			GetUserInfo = function() return {Name = ctx.Player.Name, DisplayName = ctx.Player.DisplayName, UserId = ctx.Player.UserId} end,
			GetOSInfo = function() return {Version = "3.0.0", Platform = ctx.Mode, Theme = ctx.Theme:GetTheme()} end,
			Initialize = function() end,
		}
		a.ClockManager = {Initialize = function() end, GetTime = function() return os.date("%H:%M") end}
		a.PlatformManager = {GetCurrentPlatform = function() return ctx.Mode end, Initialize = function() end}
		local cooldowns = {}
		a.CooldownManager = {CanFire = function(key, seconds) local t = os.clock(); if cooldowns[key] and t - cooldowns[key] < (seconds or 0) then return false end; cooldowns[key] = t; return true end,
		Reset = function(key) cooldowns[key] = nil end}
		a.ZIndexManager = {BringToFront = function(window) ctx.Apps:Focus(typeof(window) == "Instance" and window.Name or window) end, Register = function() end, Unregister = function() end}
		a.AnimationManager = {
			AnimateWindow = function(window, action, final)
				local id = typeof(window) == "Instance" and window.Name or window
				if final == "Destroy" then return ctx.Apps:Close(id) end
				return action == "Close" and ctx.Apps:Minimize(id) or ctx.Apps:Focus(id)
			end,
			AnimateDesktopWindowOpen = function(window, action, final)
				if final == "Destroy" then return ctx.Apps:Close(window.Name) end
				return action == "Close" and ctx.Apps:Minimize(window.Name) or ctx.Apps:Focus(window.Name)
			end,
		}
		for name, moduleName in pairs({SettingsApp = "SettingsApp", WallpaperSysApp = "WallpaperApp", TaskManager = "TaskManagerApp", Clock = "ClockApp", ZolinInstaller = "InstallerApp"}) do
			a[name] = {Init = function(ui, args, window) if not ui then return end; return __v3Require(moduleName).Mount(ctx, ui, args or {}, window) end}
		end
		a.TaskManagerApp = a.TaskManager
		a.Installer = {
			InstallFromURL = function(url) return ctx.External:InstallPackage(url) end,
			Uninstall = function(id) return ctx.External:Uninstall(id) end,
			processAutoInstallFolder = function() return ctx.External:ProcessAutoInstall() end,
			Initialize = function() return ctx.External:ProcessAutoInstall() end,
		}
		a.ZolinInstaller.InstallFromURL = a.Installer.InstallFromURL
		a.ZolinInstaller.processAutoInstallFolder = a.Installer.processAutoInstallFolder
		ctx.adapters = a
		return a
	end
	function ZolinModules.Init(options)
		if type(options) == "table" and type(options.AppUrls) == "table" then ZolinModules.AppUrls = options.AppUrls end
		local requested = ZolinModules.Mode
		local explicitMode = (requested == "Mobile" or requested == "Desktop") and requested ~= lastReportedMode
		local ctx = Runtime.Start(rootFolder(), runtimeOptions(options))
		if explicitMode then ctx.SetMode(requested) end
		return synchronize(ctx)
	end
	function ZolinModules.GetAll() return adapters() end
	ZolinModules.GetAll_Desktop = ZolinModules.GetAll
	for _, name in ipairs({"AppManager", "AppLoader", "NotificationManager", "VolumeManager", "VolumeStyleOptions", "PowerMenuManager", "SettingsManager", "ClockManager", "PlatformManager", "CooldownManager", "ZIndexManager", "AnimationManager", "SettingsApp", "WallpaperSysApp", "TaskManagerApp", "ZolinInstaller", "Installer"}) do
		ZolinModules[name] = function() return adapters()[name] end
	end
	function ZolinModules.SendNotification(data, message, appId)
		if type(data) ~= "table" then data = {title = tostring(data or "Notification"), message = tostring(message or ""), appId = appId} end
		return adapters().NotificationManager.ShowNotification(data)
	end
	function ZolinModules.NavigateTo(section) return context().Apps:Launch("Settings", {section = section}) end
	function ZolinModules.ZolinLauncher() local ctx = context(); ctx.External:Refresh(); ctx.Shell:RefreshApps() end
	function ZolinModules.ZolinListener() return context() end
	function ZolinModules.GetAppAPI(id) local record = context().Apps.windows[id]; return record and record.api end
	function ZolinModules.GetRuntime() return context() end
	function ZolinModules.ConfigureSourceLoader(loader)
		if type(loader) ~= "function" then return false, "SourceLoader must be a function" end
		context().SourceLoader = loader
		return true
	end
	function ZolinModules.RegisterApplication(id, renderer, metadata)
		if type(id) ~= "string" or (type(renderer) ~= "function" and type(renderer) ~= "table") then return false, "App id and renderer required" end
		local ctx = context()
		local info = table.clone(metadata or {})
		info.id, info.name = id, info.name or id
		info.render = function(ui, args, window, appAPI)
			if type(renderer) == "function" then return renderer(ui, args, window, appAPI) end
			if type(renderer.Mount) == "function" then return renderer.Mount(ctx, ui, args, window, appAPI) end
			assert(type(renderer.Init) == "function", "Renderer needs Init or Mount")
			return renderer.Init(ui, args, window, appAPI)
		end
		return ctx.Apps:Register(info)
	end
	function ZolinModules.Shutdown() Runtime.Stop(); ZolinModules.ZolinStarted = false end
	return ZolinModules


end
return __v3Require("Facade")
