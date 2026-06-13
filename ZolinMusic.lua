-- ============================================================
-- ZolinMusic – Music Player Logic
-- ============================================================
local ZolinApp = {}

function ZolinApp.Init(ui, launchArgs, appFolder)
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local MarketplaceService = game:GetService("MarketplaceService")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local player = Players.LocalPlayer

	-- Locate UI elements
	local nowPlayingLabel = ui:FindFirstChild("NowPlayingLabel", true)
	local timeLabel = ui:FindFirstChild("TimeLabel", true)
	local seekBarBg = ui:FindFirstChild("SeekBarBg", true)
	local seekBarFill = seekBarBg and seekBarBg:FindFirstChild("SeekBarFill")
	local playBtn = ui:FindFirstChild("PlayButton", true)
	local prevBtn = ui:FindFirstChild("PrevButton", true)
	local nextBtn = ui:FindFirstChild("NextButton", true)
	local loopBtn = ui:FindFirstChild("LoopButton", true)
	local searchBar = ui:FindFirstChild("SearchBar", true)
	local addBtn = ui:FindFirstChild("AddButton", true)
	local playlist = ui:FindFirstChild("Playlist", true)
	local volumeBarBg = ui:FindFirstChild("VolumeBarBg", true)
	local volumeBarFill = volumeBarBg and volumeBarBg:FindFirstChild("VolumeBarFill")
	local MainUI = ui:FindFirstAncestorWhichIsA("ScreenGui");
	if not MainUI then
		return error("ZolinMusic: MainUI not found")		
	end
	local CurrentSoundGroup = MainUI and MainUI:FindFirstChild("MediaSoundUI");
	if not CurrentSoundGroup then
		return error("ZolinMusic: CurrentSoundGroup <-> MediaSoundUI not found")	
	end
	if not playBtn or not playlist then
		warn("ZolinMusic: UI elements missing")
		return
	end

	-- State
	local currentSound = nil
	local currentIndex = 0
	local isPlaying = false
	local isLooping = false
	local tracks = {}
	local trackDataFolder = appFolder and appFolder:FindFirstChild("MusicData")

	-- Helper to format time
	local function formatTime(seconds)
		local mins = math.floor(seconds / 60)
		local secs = math.floor(seconds % 60)
		return string.format("%d:%02d", mins, secs)
	end

	-- Volume control
	local currentVolume = 0.5

	local function setVolume(vol)
		currentVolume = math.clamp(vol, 0, 1)
		if currentSound then
			currentSound.Volume = currentVolume
		end
		if volumeBarFill then
			volumeBarFill.Size = UDim2.new(currentVolume, 0, 1, 0)
		end
	end

	-- Click volume bar to seek
	volumeBarBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mousePos = UserInputService:GetMouseLocation()
			local barPos = volumeBarBg.AbsolutePosition
			local barSize = volumeBarBg.AbsoluteSize
			local relX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
			setVolume(relX)
		end
	end)

	-- Seek bar clicking
	seekBarBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and currentSound then
			local mousePos = UserInputService:GetMouseLocation()
			local barPos = seekBarBg.AbsolutePosition
			local barSize = seekBarBg.AbsoluteSize
			local relX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
			currentSound.TimePosition = relX * currentSound.TimeLength
		end
	end)

	-- Loop toggle
	local function toggleLoop()
		isLooping = not isLooping
		loopBtn.Text = isLooping and "🔁 On" or "🔁 Off"
		loopBtn.BackgroundColor3 = isLooping and Color3.fromRGB(34, 255, 255) or Color3.fromRGB(50, 50, 60)
		if currentSound then
			currentSound.Looped = isLooping
		end
	end
	loopBtn.MouseButton1Click:Connect(toggleLoop)

	-- Update UI progress
	local function updateProgress()
		if currentSound and isPlaying then
			local current = currentSound.TimePosition
			local total = currentSound.TimeLength
			timeLabel.Text = formatTime(current) .. " / " .. formatTime(total)
			if total > 0 then
				seekBarFill.Size = UDim2.new(current / total, 0, 1, 0)
			end
		end
	end

	-- Stop current sound
	local function stopSound()
		if currentSound then
			currentSound:Stop()
			currentSound:Destroy()
			currentSound = nil
		end
		isPlaying = false
		playBtn.Text = "▶"
	end

	-- Play a track by index
	local function playTrack(index)
		if index < 1 or index > #tracks then
			stopSound()
			nowPlayingLabel.Text = "Now Playing: None"
			timeLabel.Text = "0:00 / 0:00"
			seekBarFill.Size = UDim2.new(0, 0, 1, 0)
			return
		end

		stopSound()
		local track = tracks[index]
		currentIndex = index

		local sound = Instance.new("Sound")
		sound.Name = "CurrentSoundPlaying"
		sound.SoundId = "rbxassetid://" .. track.id
		sound.Volume = currentVolume
		sound.Looped = isLooping
		sound.Parent = ui.Parent -- Parent to UI so it gets destroyed when app closes
		sound.SoundGroup = CurrentSoundGroup;
		sound.Loaded:Connect(function()
			nowPlayingLabel.Text = "Now Playing: " .. track.name
			sound:Play()
			isPlaying = true
			playBtn.Text = "⏸"
		end)

		sound.Ended:Connect(function()
			if isLooping then return end
			-- Play next track
			playTrack(currentIndex + 1)
		end)

		currentSound = sound
		nowPlayingLabel.Text = "Now Playing: " .. track.name .. " (Loading...)"
	end

	-- Play/Pause
	local function togglePlay()
		if not currentSound then
			if #tracks > 0 then
				playTrack(1)
			end
			return
		end
		if isPlaying then
			currentSound:Pause()
			isPlaying = false
			playBtn.Text = "▶"
		else
			currentSound:Resume()
			isPlaying = true
			playBtn.Text = "⏸"
		end
	end
	playBtn.MouseButton1Click:Connect(togglePlay)

	-- Next / Previous
	nextBtn.MouseButton1Click:Connect(function()
		if #tracks == 0 then return end
		local nextIndex = currentIndex + 1
		if nextIndex > #tracks then nextIndex = 1 end
		playTrack(nextIndex)
	end)

	prevBtn.MouseButton1Click:Connect(function()
		if #tracks == 0 then return end
		local prevIndex = currentIndex - 1
		if prevIndex < 1 then prevIndex = #tracks end
		playTrack(prevIndex)
	end)

	-- Refresh playlist UI
	local function refreshPlaylist(filter)
		for _, child in ipairs(playlist:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		for i, track in ipairs(tracks) do
			if filter and filter ~= "" and not track.name:lower():find(filter:lower()) then
				continue
			end

			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -10, 0, 30)
			row.BackgroundColor3 = currentIndex == i and Color3.fromRGB(34, 255, 255, 0.3) or Color3.fromRGB(40, 40, 50)
			row.BorderSizePixel = 0
			row.Parent = playlist
			row.ZIndex = playlist.ZIndex + 1

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 5)
			rowCorner.Parent = row

			-- Track number
			local numLabel = Instance.new("TextLabel")
			numLabel.Size = UDim2.new(0, 25, 1, 0)
			numLabel.BackgroundTransparency = 1
			numLabel.Text = tostring(i)
			numLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			numLabel.Font = Enum.Font.Gotham
			numLabel.TextSize = 11
			numLabel.ZIndex = row.ZIndex + 1
			numLabel.Parent = row

			-- Track name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, -35, 1, 0)
			nameLabel.Position = UDim2.new(0, 30, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = track.name
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 11
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.ZIndex = row.ZIndex + 1
			nameLabel.Parent = row

			-- Remove button
			local removeBtn = Instance.new("TextButton")
			removeBtn.Size = UDim2.new(0, 50, 0, 20)
			removeBtn.Position = UDim2.new(1, -55, 0.5, -10)
			removeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			removeBtn.Text = "✕"
			removeBtn.TextColor3 = Color3.new(1, 1, 1)
			removeBtn.Font = Enum.Font.GothamBold
			removeBtn.TextSize = 12
			removeBtn.ZIndex = row.ZIndex + 1
			removeBtn.Parent = row

			local removeCorner = Instance.new("UICorner")
			removeCorner.CornerRadius = UDim.new(0, 4)
			removeCorner.Parent = removeBtn

			-- Click to play
			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					playTrack(i)
				end
			end)

			removeBtn.MouseButton1Click:Connect(function()
				if currentIndex == i then
					stopSound()
					nowPlayingLabel.Text = "Now Playing: None"
					timeLabel.Text = "0:00 / 0:00"
					seekBarFill.Size = UDim2.new(0, 0, 1, 0)
					currentIndex = 0
				elseif currentIndex > i then
					currentIndex = currentIndex - 1
				end
				table.remove(tracks, i)

				-- Remove from storage
				if trackDataFolder then
					local stored = trackDataFolder:FindFirstChild(track.id)
					if stored then stored:Destroy() end
				end

				refreshPlaylist(searchBar.Text)
			end)
		end
	end

	-- Add track by Asset ID
	local function addTrack(assetId)
		assetId = assetId:match("%d+") -- Extract just numbers
		if not assetId then return end

		-- Check if already in playlist
		for _, track in ipairs(tracks) do
			if track.id == assetId then
				playTrack(_) -- index variable not available here, just search
				for i, t in ipairs(tracks) do
					if t.id == assetId then
						playTrack(i)
						break
					end
				end
				return
			end
		end

		-- Get asset info
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(tonumber(assetId))
		end)

		local trackName = "Unknown Track"
		if success and info then
			trackName = info.Name or "Track " .. assetId
		end

		local track = { id = assetId, name = trackName }
		table.insert(tracks, track)

		-- Store in MusicData
		if trackDataFolder then
			local stored = Instance.new("StringValue")
			stored.Name = assetId
			stored.Value = trackName
			stored.Parent = trackDataFolder
		end

		refreshPlaylist(searchBar.Text)
		if #tracks == 1 then
			playTrack(1)
		end
	end

	addBtn.MouseButton1Click:Connect(function()
		local input = searchBar.Text
		if input ~= "" then
			addTrack(input)
			searchBar.Text = ""
		end
	end)

	searchBar.FocusLost:Connect(function(enterPressed)
		if enterPressed and searchBar.Text ~= "" then
			addTrack(searchBar.Text)
			searchBar.Text = ""
		end
	end)

	-- Search filter
	searchBar:GetPropertyChangedSignal("Text"):Connect(function()
		refreshPlaylist(searchBar.Text)
	end)

	-- Load saved tracks from MusicData
	if trackDataFolder then
		for _, stored in ipairs(trackDataFolder:GetChildren()) do
			if stored:IsA("StringValue") then
				table.insert(tracks, { id = stored.Name, name = stored.Value })
			end
		end
		refreshPlaylist()
	end

	-- Progress update loop
	RunService.Heartbeat:Connect(function()
		if isPlaying and currentSound then
			updateProgress()
		end
	end)

	setVolume(0.5)
	print("ZolinMusic initialized!")
end

return ZolinApp
