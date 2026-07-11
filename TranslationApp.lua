local TranslationApp = {}
-- Library Stands
function TranslationApp.Init(ui, launchArgs, appFolder)
	local AppName = "Library Stands"
	local l__TweenService__5 = game:GetService("TweenService");
	local UIS = game:GetService("UserInputService");
	local u6 = game:GetService("RunService")
	local BuildVersion = "3.21.8"
	local versionLabel = "v"..BuildVersion;
	local SettingsScript = {
		DisplayLogs = true,
		KickPlayerAfterCutsenceBD = false,
	}
	local PlayerCurrentData = {
		["LastPos"] = nil,
		["IsTeleported"] = false,  -- Track if player is currently teleported
		["TeleportPending"] = false,  -- Prevent multiple teleports
		["CutsceneActive"] = false,  -- Track if cutscene is active
		["ReturnTimer"] = nil,
		["Init"] = false,
	}
	local ReplicatedStorage = game:GetService("ReplicatedStorage");
	local updateCustomBeatdownEvent = Instance.new("BindableEvent")
	local lpr = game.Players.LocalPlayer;
	local Character = lpr.Character or lpr.CharacterAdded:Wait();
	local l__Humanoid__8 = Character:FindFirstChildOfClass("Humanoid");
	local l__HumanoidRootPart__9 = Character:WaitForChild("HumanoidRootPart", 5);
	local copyrightLabel
	local CustomHitbox = Vector3.new(32, 32, 32) -- beatdown custom hitbox size
	local TeleportUI = nil;
	local TeleportData = {
		UpdateInterval = 5,
		LastUpdate = 0,
		AutoUpdate = true,
		Players = {},
		UIInitialized = false
	}
	local SlapBattlesSettings = {
		ForceOverwriteBeatdown = false,
		BiggerHitbox = false,
	};
	local originalSkybox = {}
	local originalLighting = {}
	--[ Custom Beatdown Var
	local CustomBeatdownUI = nil
	local CustomBeatdownModels = {
		{
			id = "evil_beatdown",
			name = "Evil Beatdown",
			description = "Black-themed beatdown stand with red fire effects. Makes your stand appear sinister and powerful. This evil beatdown is first born version 1.0 of TranslationUI",
			color = Color3.fromRGB(0, 0, 0),
			fireColor = Color3.fromRGB(85, 0, 0),
			material = Enum.Material.Neon,
			icon = "rbxassetid://5912368763",
			iconColor = Color3.fromRGB(113, 84, 255),
			soundSpeed = 0.7,
			customSounds = {
				["Nukem"] = 0.7,
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 0.8,
				["explosion2"] = 0.7,
				["Gun1"] = 0.7,
				["Gun2"] = 0.7,
				["Yell"] = 0.8,
				["Hit"] = 0.75,
				["Implosion"] = 0.7,
			},
			enabled = false,
			specialEffects = function(parts)
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						local pointLight = Instance.new("PointLight")
						pointLight.Color = Color3.fromRGB(85, 0, 0)
						pointLight.Range = 5
						pointLight.Brightness = 0.3
						pointLight.Enabled = true
						pointLight.Parent = part
					end
				end
			end
		},
		{
			id = "ghost_beatdown",
			name = "Ghost Beatdown",
			description = "Transparent ghost-like stand with blue fire. Appears ethereal and haunting.",
			color = Color3.fromRGB(144, 159, 200),
			fireColor = Color3.fromRGB(0, 150, 255),
			material = Enum.Material.Glass,
			transparency = 0.5,
			icon = "rbxassetid://5912387865",
			iconColor = Color3.fromRGB(150, 200, 255),
			soundSpeed = 0.8,
			customSounds = {
				["Nukem"] = 0.8,
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 0.82,
				["explosion2"] = 0.8,
				["Gun1"] = 0.8,
				["Gun2"] = 0.82,
				["Yell"] = 0.8,
				["Hit"] = 0.7,
				["Implosion"] = 0.8,
			},
			enabled = false,
			specialEffects = function(parts)
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						if part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0.5
							local trail = Instance.new("Trail")
							trail.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
							trail.Lifetime = 0.5
							trail.Transparency = NumberSequence.new(0.7)
							trail.Parent = part
						end
					end
				end
			end
		},
		{
			id = "golden_beatdown",
			name = "Golden Beatdown",
			description = "Golden stand with flex fire effects. Looks majestic and divine.",
			color = Color3.fromRGB(255, 215, 0),
			fireColor = Color3.fromRGB(255, 255, 200),
			material = Enum.Material.Neon,
			icon = "rbxassetid://5912404487",
			iconColor = Color3.fromRGB(255, 215, 0),
			soundSpeed = 0.9,
			enabled = false,
			specialEffects = function(parts)
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						local sparkles = part:FindFirstChild("Sparkles") or Instance.new("Sparkles")
						sparkles.SparkleColor = Color3.fromRGB(255, 215, 0)
						sparkles.Parent = part
					end
				end
			end
		},
		{
			id = "angelic_beatdown",
			name = "King Dracule Beatdown",
			description = "Pure white angelic stand with glowing white fire effects. Features clothing elements and a divine appearance that radiates holiness and purity.",
			color = Color3.fromRGB(255, 255, 255),
			fireColor = Color3.fromRGB(255, 255, 255),
			material = Enum.Material.SmoothPlastic,
			transparency = 0.1,
			icon = "rbxassetid://5912420913",
			iconColor = Color3.fromRGB(255, 255, 255),
			soundSpeed = 0.76,
			customSounds = {
				["Nukem"] = 0.825,
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 0.76,
				["explosion2"] = 0.87,
				["Gun1"] = 0.75,
				["Gun2"] = 0.75,
				["Yell"] = 0.8,
				["Hit"] = 0.7,
				["Implosion"] = 0.8,
			},
			enabled = false,
			specialEffects = function(parts)
				local meshesToRemove = {}
				local rigParts = {}
				local headPart = nil
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						part.Color = Color3.fromRGB(255, 255, 255)
						if part.Name == "Head" then
							headPart = part
						end
						if part.Name == "Torso" or part.Name == "Left Leg" or part.Name == "Right Leg" or 
							part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Head" then
							table.insert(rigParts, part)
						end
						if part.Name == "Torso" or part.Name:find("Leg") or part.Name:find("Arm") then
							for _, child in ipairs(part:GetChildren()) do
								if child:IsA("SpecialMesh") then
									table.insert(meshesToRemove, child)
								end
							end
						end
						if part:FindFirstChild("PointLight") then return end
						local pointLight = Instance.new("PointLight")
						pointLight.Color = Color3.fromRGB(255, 255, 255)
						pointLight.Range = 8
						pointLight.Brightness = 1
						pointLight.Shadows = true
						pointLight.Enabled = true
						pointLight.Parent = part
						if part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0.1
							part.Material = Enum.Material.Neon
						end
					end
				end
				for _, mesh in ipairs(meshesToRemove) do
					mesh:Destroy()
				end
				if #rigParts > 0 then
					spawn(function()
						for _, rigPart in ipairs(rigParts) do
							rigPart.Color = Color3.fromRGB(255, 255, 255)
							rigPart.Material = Enum.Material.Neon
						end
					end)
				end
				local function addTopHatToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("RCap") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "RCap" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "RCap"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(0, -0.05, 0.11)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1, 1, 1)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "http://www.roblox.com/asset/?id=417373422"
					specialMesh.TextureId = "http://www.roblox.com/asset/?id=417371021"
					specialMesh.Scale = Vector3.new(0.52, 0.52, 0.52)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(0, 0.05, 0.11) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(255, 255, 255)
					end
					return hatAccessory
				end
				local function addClothingToStand(standModel)
					if not standModel then return end
					local torso = standModel:FindFirstChild("Torso")
					if not torso then return end
					if standModel:FindFirstChild("AngelicShirt") then return end
					local shirt = Instance.new("Shirt")
					shirt.Name = "AngelicShirt"
					shirt.ShirtTemplate = "rbxassetid://2811372947"
					local shirtGraphic = Instance.new("ShirtGraphic")
					shirtGraphic.Name = "AngelicShirtGraphic"
					shirtGraphic.Color3 = Color3.fromRGB(255, 255, 255)
					shirtGraphic.Graphic = ""
					local pants = Instance.new("Pants")
					pants.Name = "AngelicPants"
					pants.PantsTemplate = "rbxassetid://10506397424"
					shirt.Parent = standModel
					shirtGraphic.Parent = standModel
					pants.Parent = standModel
					local shirtPart = Instance.new("Part")
					shirtPart.Name = "ShirtVisual"
					shirtPart.Size = Vector3.new(2.2, 1.8, 1.2)
					shirtPart.Position = torso.Position
					shirtPart.Color = Color3.fromRGB(240, 240, 255)
					shirtPart.Material = Enum.Material.Neon
					shirtPart.Transparency = 0.3
					shirtPart.CanCollide = false
					shirtPart.Anchored = false
					local weld = Instance.new("Weld")
					weld.Part0 = torso
					weld.Part1 = shirtPart
					weld.C0 = CFrame.new(0, 0, 0)
					weld.Parent = shirtPart
					shirtPart.Parent = standModel
				end
				if parts[1] and parts[1].Parent then
					if headPart then
						addTopHatToHead(headPart)
					end
					addClothingToStand(parts[1].Parent)
				end
			end
		},
		{
			id = "Uncle_beatdown",
			name = "Your_Uncle Beatdown",
			description = "A long time Your_Uncle is banned, finally we got some old and the most OP skin of Your_Uncle that terrified everyone on Slap Battles with the Main Glove BEATDDOWN!",
			color = Color3.fromRGB(0, 0, 0),
			fireColor = Color3.fromRGB(255, 0, 0),
			material = Enum.Material.SmoothPlastic,
			transparency = 0,
			icon = "rbxassetid://5912420913",
			iconColor = Color3.fromRGB(0, 0, 0),
			soundSpeed = 0.7,
			customSounds = {
				["Nukem"] = 0.7, --0.7 -- 1
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 0.75,
				["explosion2"] = 0.7,
				["Gun1"] = 0.7,
				["Gun2"] = 0.75,
				["Yell"] = 0.7,
				["Hit"] = 0.5,
				["Implosion"] = 0.7,
			},
			enabled = false,
			specialEffects = function(parts)
				local meshesToRemove = {}
				local rigParts = {}
				local headPart = nil
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						part.Color = Color3.fromRGB(0, 0, 0)
						if part.Name == "Head" then
							headPart = part
						end
						if part.Name == "Torso" or part.Name == "Left Leg" or part.Name == "Right Leg" or 
							part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Head" then
							table.insert(rigParts, part)
						end
						if part.Name == "Torso" or part.Name:find("Leg") or part.Name:find("Arm") then
							for _, child in ipairs(part:GetChildren()) do
								if child:IsA("SpecialMesh") then
									table.insert(meshesToRemove, child)
								end
							end
						end
						if part:FindFirstChild("PointLight") then return end
						local pointLight = Instance.new("PointLight")
						pointLight.Color = Color3.fromRGB(255, 0, 0)
						pointLight.Range = 8
						pointLight.Brightness = 2.5
						pointLight.Shadows = true
						pointLight.Enabled = true
						pointLight.Parent = part
						if part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0
							part.Material = Enum.Material.Neon
						end
					end
				end
				for _, mesh in ipairs(meshesToRemove) do
					mesh:Destroy()
				end
				if #rigParts > 0 then
					spawn(function()
						for _, rigPart in ipairs(rigParts) do
							rigPart.Color = Color3.fromRGB(0, 0, 0)
							rigPart.Material = Enum.Material.Neon
						end
					end)
				end
				local function addTopHatToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("HatMeshPartAccessory") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "HatMeshPartAccessory" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "HatMeshPartAccessory"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(0.003, -0.304, 0.009)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1.5, 1.5, 1.5)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://5029193842"
					specialMesh.TextureId = "http://www.roblox.com/asset/?id=5029175990"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(0.003, -0.304, 0.009) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 0, 0)
					end
					return hatAccessory
				end
				local function addRedEyeHandleToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("MeshPartAccessory") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "MeshPartAccessory" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "MeshPartAccessory"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(-0, -0.34, -0)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1, 1, 1)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://6002625087"
					specialMesh.TextureId = "rbxassetid://6002608052"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(-0, -0.34, -0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 0, 0)
					end
					return hatAccessory
				end

				local function addClothingToStand(standModel)
					if not standModel then return end
					local torso = standModel:FindFirstChild("Torso")
					if not torso then return end
					if standModel:FindFirstChild("UncleShirt") then return end
					local shirt = Instance.new("Shirt")
					shirt.Name = "UncleShirt"
					shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=8450171902"
					local pants = Instance.new("Pants")
					pants.Name = "UncleShirt"
					pants.PantsTemplate = "http://www.roblox.com/asset/?id=8427781292"
					shirt.Parent = standModel
					pants.Parent = standModel
				end
				if parts[1] and parts[1].Parent then
					if headPart then
						addTopHatToHead(headPart);
						addRedEyeHandleToHead(headPart);
					end
					addClothingToStand(parts[1].Parent)
				end
			end
		},
		{
			id = "SMT_beatdown",
			name = "SMT Beatdown",
			description = "a huge Change for SMT's beatdown acts, Sky Attacker prefer SMT's Beatdown because it's has custom cutsence beating anyone with's his FOV or the beatdown itself. 06/07/2026 added Custom preloaded cutsence <{!}> |   he passed away at: 07/04/2026",
			color = Color3.fromRGB(0, 3, 172),
			fireColor = Color3.fromRGB(26, 49, 255),
			material = Enum.Material.Glacier,
			transparency = 0.4,
			icon = "rbxassetid://5912420913",
			iconColor = Color3.fromRGB(15, 24, 199),
			soundSpeed = 0.7,
			customSounds = {
				["Nukem"] = 0.7, --1,
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 0.9,
				["explosion2"] = 0.7,
				["Gun1"] = 0.7,
				["Gun2"] = 0.7,
				["Yell"] = 1,
				["Hit"] = 0.5,
				["Implosion"] = 0.7,
			},
			enabled = false,
			specialEffects = function(parts)
				local meshesToRemove = {}
				local rigParts = {}
				local headPart = nil
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						part.Color = Color3.fromRGB(0, 0, 0)
						if part.Name == "Head" then
							headPart = part
						end
						if part.Name == "Torso" or part.Name == "Left Leg" or part.Name == "Right Leg" or 
							part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Head" then
							table.insert(rigParts, part)
						end
						if part.Name == "Torso" or part.Name:find("Leg") or part.Name:find("Arm") then
							for _, child in ipairs(part:GetChildren()) do
								if child:IsA("SpecialMesh") then
									table.insert(meshesToRemove, child)
								end
							end
						end
						if part:FindFirstChild("PointLight") then return end
						local pointLight = Instance.new("PointLight")
						pointLight.Color = Color3.fromRGB(0, 81, 255)
						pointLight.Range = 8
						pointLight.Brightness = 2.5
						pointLight.Shadows = true
						pointLight.Enabled = true
						pointLight.Parent = part
						if part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0
							part.Material = Enum.Material.Glacier
						end
					end
				end
				for _, mesh in ipairs(meshesToRemove) do
					mesh:Destroy()
				end
				if #rigParts > 0 then
					spawn(function()
						for _, rigPart in ipairs(rigParts) do
							rigPart.Color = Color3.fromRGB(0, 3, 172)
							rigPart.Material = Enum.Material.Glacier
						end
					end)
				end
				local function addGlassesToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("NerdGlasses") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "NerdGlasses" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "NerdGlasses"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(0, -0.2, -0.4)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1.33, 1, 1.7)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "http://www.roblox.com/asset/?id=304115907"
					specialMesh.TextureId = "http://www.roblox.com/asset/?id=304115997"
					specialMesh.Scale = Vector3.new(0.5, 0.5, 0.5)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(0, -0.2, -0.4) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0, -0.6) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 3, 172)
					end
					return hatAccessory
				end
				local function addMessyHairToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("MessyHair") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "MessyHair" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "MessyHair"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(0, 0.23, 0.031)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1, 1, 1)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "http://www.roblox.com/asset/?id=319337852"
					specialMesh.TextureId = "http://www.roblox.com/asset/?id=307179698"
					specialMesh.Scale = Vector3.new(0.55, 0.55, 0.55)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(0, 0.23, 0.031) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 3, 172)
					end
					return hatAccessory
				end
				local function addHeadsetToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("Headset") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "Headset" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "Headset"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(-0, 0.287, -0.001)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1, 1, 1)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://8067916440"
					specialMesh.TextureId = "rbxassetid://7676070311"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(-0, 0.287, -0.001) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 3, 172)
					end
					return hatAccessory
				end
				local function addClothingToStand(standModel)
					if not standModel then return end
					local torso = standModel:FindFirstChild("Torso")
					if not torso then return end
					if standModel:FindFirstChild("UncleShirt") then return end
					local shirt = Instance.new("Shirt")
					shirt.Name = "UncleShirt"
					shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=10634595316"
					local pants = Instance.new("Pants")
					pants.Name = "UncleShirt"
					pants.PantsTemplate = "http://www.roblox.com/asset/?id=11936234746"
					shirt.Parent = standModel
					pants.Parent = standModel
				end
				if parts[1] and parts[1].Parent then
					if headPart then
						addGlassesToHead(headPart);
						addHeadsetToHead(headPart);
						addMessyHairToHead(headPart);
					end
					addClothingToStand(parts[1].Parent)
				end
			end
		},
		{
			id = "sm_Beatdown",
			name = "Small Beatdown",
			description = "Small and Golden stand with flex fire effects. Looks majestic and divine.",
			color = Color3.fromRGB(0, 180, 159),
			fireColor = Color3.fromRGB(0, 255, 225),
			material = Enum.Material.Neon,
			icon = "rbxassetid://5912404487",
			iconColor = Color3.fromRGB(0, 180, 159),
			soundSpeed = 0.75,
			enabled = false,
			specialEffects = function(parts)
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						local sparkles = part:FindFirstChild("Sparkles") or Instance.new("Sparkles")
						sparkles.SparkleColor = Color3.fromRGB(0, 180, 159)
						sparkles.Parent = part
					end
				end
				for _, Model in ipairs(parts) do
					if Model.Parent:IsA("Model") then
						Model.Parent:ScaleTo(0.5);
					end
				end
			end
		},
		{
			id = "mhe_beatdown",
			name = "Your_MHE",
			description = "imagine mhe being Your_MHE?",
			color = Color3.fromRGB(221, 139, 46),
			fireColor = Color3.fromRGB(255, 191, 43),
			material = Enum.Material.Glacier,
			transparency = 0.25,
			icon = "rbxassetid://5912420913",
			iconColor = Color3.fromRGB(199, 147, 26),
			soundSpeed = 0.7,
			customSounds = {
				["Nukem"] = 1, --0.7,
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 1,
				["explosion2"] = 0.7,
				["Gun1"] = 0.8,
				["Gun2"] = 0.7,
				["Yell"] = 1,
				["Hit"] = 0.5,
				["Implosion"] = 0.7,
			},
			enabled = false,
			specialEffects = function(parts)
				local meshesToRemove = {}
				local rigParts = {}
				local headPart = nil;
				local torsoPart = nil;
				local characterPart = nil;
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						part.Color = Color3.fromRGB(0, 0, 0)
						if part.Name == "Head" then
							headPart = part
						end
						if part.Name == "Torso" then
							torsoPart = part
						end
						if part.Parent:IsA("Model") and game.Players:FindFirstChild(part.Parent.Name) then
							characterPart = part
						end
						if part.Name == "Torso" or part.Name == "Left Leg" or part.Name == "Right Leg" or 
							part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Head" then
							table.insert(rigParts, part)
						end
						if part.Name == "Torso" or part.Name:find("Leg") or part.Name:find("Arm") then
							for _, child in ipairs(part:GetChildren()) do
								if child:IsA("SpecialMesh") then
									table.insert(meshesToRemove, child)
								end
							end
						end
						if part:FindFirstChild("PointLight") then return end
						local pointLight = Instance.new("PointLight")
						pointLight.Color = Color3.fromRGB(221, 139, 46)
						pointLight.Range = 1
						pointLight.Brightness = 2.5
						pointLight.Shadows = true
						pointLight.Enabled = true
						pointLight.Parent = part
						if part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0
							part.Material = Enum.Material.Glacier
						end
					end
				end
				for _, mesh in ipairs(meshesToRemove) do
					mesh:Destroy()
				end
				if #rigParts > 0 then
					spawn(function()
						for _, rigPart in ipairs(rigParts) do
							rigPart.Color = Color3.fromRGB(221, 139, 46)
							rigPart.Material = Enum.Material.Glacier
						end
					end)
				end
				local function addBegToTorso(torso)
					if not torso then return end
					if torso.Parent:FindFirstChild("BagAccessory") then return end
					for _, child in ipairs(torso.Parent:GetChildren()) do
						if child.Name == "BagAccessory" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "BagAccessory"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(-0, -0.282, -0.367)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1, 1, 1)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://4375179897"
					specialMesh.TextureId = "rbxassetid://4375179965"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle 
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = torso
					accessoryWeld.C0 = CFrame.new(-0, -0.282, -0.367) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0, 0.5) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = torso.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(172, 172, 172)
					end
					return hatAccessory
				end
				local function addHatToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("HatAccessory") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "HatAccessory" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "HatAccessory"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(-0, -0.236, -0.049)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1, 1, 1)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://4375179036"
					specialMesh.TextureId = "rbxassetid://4375179106"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(-0, -0.236, -0.049) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 3, 172)
					end
					return hatAccessory
				end
				local function addSpecialMeshToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("Mesh") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "Mesh" then
							child:Destroy()
						end
					end
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "https://assetdelivery.roblox.com/v1/asset/?id=12724327566"
					specialMesh.TextureId = "https://www.roblox.com/asset/?id=4374872751"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = head
				end
				local function addCharactersMesh(characterModel)
					if not characterModel then print("No character model found") return end
					if not (characterModel:FindFirstChild("CharacterMesh1") and characterModel:FindFirstChild("CharacterMesh2") and characterModel:FindFirstChild("CharacterMesh3") and characterModel:FindFirstChild("CharacterMesh4") and characterModel:FindFirstChild("CharacterMesh5")) then
						local CharMesh_1 = Instance.new("CharacterMesh")
						CharMesh_1.Name = "CharacterMesh1";
						CharMesh_1.BodyPart = Enum.BodyPart.Torso;
						CharMesh_1.BaseTextureId = 0;
						CharMesh_1.MeshId = 4374868886;
						CharMesh_1.OverlayTextureId = 4374869950;
						CharMesh_1.Parent = characterModel;
						local CharMesh_2 = Instance.new("CharacterMesh");
						CharMesh_2.Name = "CharacterMesh2";
						CharMesh_2.BodyPart = Enum.BodyPart.RightArm;
						CharMesh_2.BaseTextureId = 0;
						CharMesh_2.MeshId = 4374867449;
						CharMesh_2.OverlayTextureId = 4374869950;
						CharMesh_2.Parent = characterModel;
						local CharMesh_3 = Instance.new("CharacterMesh");
						CharMesh_3.Name = "CharacterMesh3";
						CharMesh_3.BodyPart = Enum.BodyPart.LeftArm;
						CharMesh_3.BaseTextureId = 0;
						CharMesh_3.MeshId = 4374865848;
						CharMesh_3.OverlayTextureId = 4374869950;
						CharMesh_3.Parent = characterModel;
						local CharMesh_4 = Instance.new("CharacterMesh");
						CharMesh_4.Name = "CharacterMesh4";
						CharMesh_4.BodyPart = Enum.BodyPart.LeftLeg;
						CharMesh_4.BaseTextureId = 0;
						CharMesh_4.MeshId = 4374866631;
						CharMesh_4.OverlayTextureId = 4374869950;
						CharMesh_4.Parent = characterModel;
						local CharMesh_5 = Instance.new("CharacterMesh");
						CharMesh_5.Name = "CharacterMesh5";
						CharMesh_5.BodyPart = Enum.BodyPart.RightLeg;
						CharMesh_5.BaseTextureId = 0;
						CharMesh_5.MeshId = 4374868090;
						CharMesh_5.OverlayTextureId = 4374869950;
						CharMesh_5.Parent = characterModel;
						print("CharacterMesh")
					end
				end
				local function addHumanoidToModel(characterModel)
					if not characterModel then print("No character model found") return end
					local humanoid = characterModel:FindFirstChild("Humanoid");
					if not humanoid then
						humanoid = Instance.new("Humanoid")
						humanoid.Name = "Humanoid"
						humanoid.Parent = characterModel
						humanoid.Health = 100
						humanoid.MaxHealth = 100
						humanoid.BreakJointsOnDeath = false
						humanoid.EvaluteStateMachine = false
						humanoid.RequiresNeck = false
						humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
						humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
						humanoid.NameDisplayDistance = 0
						humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion
						print("Humanoid")
					else
						print("No Humanoid, Already")
					end
				end
				if parts[1] and parts[1].Parent then
					if headPart then
						addHatToHead(headPart);
						addSpecialMeshToHead(headPart);
					end
					if torsoPart then
						addBegToTorso(torsoPart);
					end
					if parts[1].Parent then
						addCharactersMesh(parts[1].Parent);
						--addHumanoidToModel(parts[1].Parent);
					else
						print("Character model not found or invalid")
					end
				end
			end
		},
		--[[
		{
			id = "Uncle_beatdown2",
			name = "HUSSAN Beatdown ",
			description = "known as Your_Uncle before, on this version: 3.19.2 Changed his name to HUSSAN",
			color = Color3.fromRGB(0, 0, 0),
			fireColor = Color3.fromRGB(255, 0, 0),
			material = Enum.Material.SmoothPlastic,
			transparency = 0,
			icon = "rbxassetid://5912420913",
			iconColor = Color3.fromRGB(0, 0, 0),
			soundSpeed = 0.7,
			customSounds = {
				["Nukem"] = 1, --0.7 -- 1
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 0.75,
				["explosion2"] = 0.7,
				["Gun1"] = 0.7,
				["Gun2"] = 0.75,
				["Yell"] = 0.7,
				["Hit"] = 0.5,
				["Implosion"] = 0.7,
			},
			enabled = false,
			specialEffects = function(parts)
				local meshesToRemove = {}
				local rigParts = {}
				local headPart = nil
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						part.Color = Color3.fromRGB(0, 0, 0)
						if part.Name == "Head" then
							headPart = part
						end
						if part.Name == "Torso" or part.Name == "Left Leg" or part.Name == "Right Leg" or 
							part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Head" then
							table.insert(rigParts, part)
						end
						if part.Name == "Torso" or part.Name:find("Leg") or part.Name:find("Arm") then
							for _, child in ipairs(part:GetChildren()) do
								if child:IsA("SpecialMesh") then
									table.insert(meshesToRemove, child)
								end
							end
						end
						if part:FindFirstChild("PointLight") then return end
						local pointLight = Instance.new("PointLight")
						pointLight.Color = Color3.fromRGB(255, 0, 0)
						pointLight.Range = 8
						pointLight.Brightness = 2.5
						pointLight.Shadows = true
						pointLight.Enabled = true
						pointLight.Parent = part
						if part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0
							part.Material = Enum.Material.Neon
						end
					end
				end
				for _, mesh in ipairs(meshesToRemove) do
					mesh:Destroy()
				end
				if #rigParts > 0 then
					spawn(function()
						for _, rigPart in ipairs(rigParts) do
							rigPart.Color = Color3.fromRGB(0, 0, 0)
							rigPart.Material = Enum.Material.Neon
						end
					end)
				end
				local function addTopHatToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("HatMeshPartAccessory") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "HatMeshPartAccessory" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "HatMeshPartAccessory"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(0.003, -0.304, 0.009)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1.5, 1.5, 1.5)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://5029193842"
					specialMesh.TextureId = "http://www.roblox.com/asset/?id=5029175990"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(0.003, -0.304, 0.009) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 0, 0)
					end
					return hatAccessory
				end
				local function addRedEyeHandleToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("MeshPartAccessory") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "MeshPartAccessory" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "MeshPartAccessory"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(-0, -0.34, -0)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1, 1, 1)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://6002625087"
					specialMesh.TextureId = "rbxassetid://6002608052"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(-0, -0.34, -0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 0, 0)
					end
					return hatAccessory
				end

				local function addClothingToStand(standModel)
					if not standModel then return end
					local torso = standModel:FindFirstChild("Torso")
					if not torso then return end
					if standModel:FindFirstChild("UncleShirt") then return end
					local shirt = Instance.new("Shirt")
					shirt.Name = "UncleShirt"
					shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=8450171902"
					local pants = Instance.new("Pants")
					pants.Name = "UncleShirt"
					pants.PantsTemplate = "http://www.roblox.com/asset/?id=8427781292"
					shirt.Parent = standModel
					pants.Parent = standModel
				end
				if parts[1] and parts[1].Parent then
					if headPart then
						addTopHatToHead(headPart);
						addRedEyeHandleToHead(headPart);
					end
					addClothingToStand(parts[1].Parent)
				end
			end
		},
		--]]
		{
			id = "refraif_beatdown",
			name = "Your_King Beatdown",
			description = "Ahh... free at last... o, mhe Now dawns thy reckoning, and thy gore shall glisten before the temples of man. Creature of ah ya doctor, my gratitude upon thee for my freedom. But the crimes thy kind have committed against humanity are NOT forgotten, and the punishment... IS BEATDOWN!",
			color = Color3.fromRGB(0, 0, 0),
			fireColor = Color3.fromRGB(255, 76, 76),
			material = Enum.Material.SmoothPlastic,
			transparency = 0,
			icon = "rbxassetid://5912420913",
			iconColor = Color3.fromRGB(0, 0, 0),
			soundSpeed = 0.7,
			customSounds = {
				["Nukem"] = 1, --0.7 -- 1
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 1,
				["explosion2"] = 1,
				["Gun1"] = 1,
				["Gun2"] = 1,
				["Yell"] = 1,
				["Hit"] = 1,
				["Implosion"] = 1,
			},
			enabled = false,
			specialEffects = function(parts)
				local meshesToRemove = {}
				local rigParts = {}
				local headPart = nil
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						part.Color = Color3.fromRGB(0, 0, 0)
						if part.Name == "Head" then
							headPart = part
						end
						if part.Name == "Torso" or part.Name == "Left Leg" or part.Name == "Right Leg" or 
							part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Head" then
							table.insert(rigParts, part)
						end
						if part.Name == "Torso" or part.Name:find("Leg") or part.Name:find("Arm") then
							for _, child in ipairs(part:GetChildren()) do
								if child:IsA("SpecialMesh") then
									table.insert(meshesToRemove, child)
								end
							end
						end
						if part:FindFirstChild("PointLight") then return end
						local pointLight = Instance.new("PointLight")
						pointLight.Color = Color3.fromRGB(68, 68, 68)
						pointLight.Range = 8
						pointLight.Brightness = 2.5
						pointLight.Shadows = true
						pointLight.Enabled = true
						pointLight.Parent = part
						if part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0
							part.Material = Enum.Material.Neon
						end
					end
				end
				for _, mesh in ipairs(meshesToRemove) do
					mesh:Destroy()
				end
				if #rigParts > 0 then
					spawn(function()
						for _, rigPart in ipairs(rigParts) do
							rigPart.Color = Color3.fromRGB(0, 0, 0)
							rigPart.Material = Enum.Material.Neon
						end
					end)
				end
				local function addTopHatToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("Retopo_PlaneAccessory") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "Retopo_PlaneAccessory" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "Retopo_PlaneAccessory"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(0.175, 0.475, 0)
					attachment.Orientation = Vector3.new(0, 90, -0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("MeshPart")
					handle.Name = "Handle"
					handle.Size = Vector3.new(2.538, 2.027, 1.867)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.MeshId = "rbxassetid://78740393045607";
					handle.MeshContent = "rbxassetid://78740393045607"
					handle.TextureContent = "rbxassetid://132664806494550"
					handle.TextureID = "rbxassetid://132664806494550"
					handle.Parent = hatAccessory
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(0.175, 0.475, 0) * CFrame.Angles(0, 0, 0);
					accessoryWeld.C0.Orientation = Vector3.new(0, 90, -0);
					accessoryWeld.C1 = CFrame.new(0, 0.494, 0) * CFrame.Angles(0, 0, 0);
					accessoryWeld.Enabled = true;
					accessoryWeld.Parent = handle;
					hatAccessory.Parent = head.Parent;
					return hatAccessory
				end
				if parts[1] and parts[1].Parent then
					if headPart then
						addTopHatToHead(headPart);
					end
					-- refraif other stuff rig
				end
			end
		},
		{
			id = "Uncle_beatdown3",
			name = "Your_Uncle Beatdown CoolOutfit",
			description = "ahh, the last time Your_Uncle has taken much power and taking them down, ha! we got a cool outfit for him, Welcome Your_Uncle, you will lead the game entire, and everyone They will cower in fear and terror and will not resist you. And whoever disobeys, he will suffer a deadly punishment! . but there's a problem, Your_Uncle can't see normal colors as we see, because his eyes are colorblinded, only see red & black : (",
			color = Color3.fromRGB(0, 0, 0),
			fireColor = Color3.fromRGB(255, 0, 0),
			material = Enum.Material.SmoothPlastic,
			transparency = 0,
			icon = "rbxassetid://5912420913",
			iconColor = Color3.fromRGB(0, 0, 0),
			soundSpeed = 0.7,
			customSounds = {
				["Nukem"] = 0.82, --0.7 -- 1
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 1,
				["explosion2"] = 1,
				["Gun1"] = 0.6,
				["Gun2"] = 0.9,
				["Yell"] = 1,
				["Hit"] = 0.5,
				["Implosion"] = 0.7,
			},
			enabled = false,
			specialEffects = function(parts)
				local meshesToRemove = {}
				local rigParts = {}
				local headPart = nil
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") then
						part.Color = Color3.fromRGB(0, 0, 0)
						if part.Name == "Head" then
							headPart = part
						end
						if part.Name == "Torso" or part.Name == "Left Leg" or part.Name == "Right Leg" or 
							part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Head" then
							table.insert(rigParts, part)
						end
						if part.Name == "Torso" or part.Name:find("Leg") or part.Name:find("Arm") then
							for _, child in ipairs(part:GetChildren()) do
								if child:IsA("SpecialMesh") then
									table.insert(meshesToRemove, child)
								end
							end
						end
						if part:FindFirstChild("PointLight") then return end
						local pointLight = Instance.new("PointLight")
						pointLight.Color = Color3.fromRGB(255, 0, 0)
						pointLight.Range = 8
						pointLight.Brightness = 2.5
						pointLight.Shadows = true
						pointLight.Enabled = true
						pointLight.Parent = part
						if part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0
							part.Material = Enum.Material.Neon
						end
					end
				end
				for _, mesh in ipairs(meshesToRemove) do
					mesh:Destroy()
				end
				if #rigParts > 0 then
					spawn(function()
						for _, rigPart in ipairs(rigParts) do
							rigPart.Color = Color3.fromRGB(0, 0, 0)
							rigPart.Material = Enum.Material.Neon
						end
					end)
				end
				local function addTopHatToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("HatMeshPartAccessory") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "HatMeshPartAccessory" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "HatMeshPartAccessory"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(0.003, -0.304, 0.009)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1.5, 1.5, 1.5)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://5029193842"
					specialMesh.TextureId = "http://www.roblox.com/asset/?id=5029175990"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(0.003, -0.304, 0.009) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 0, 0)
					end
					return hatAccessory
				end
				local function addRedEyeHandleToHead(head)
					if not head then return end
					if head.Parent:FindFirstChild("MeshPartAccessory") then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == "MeshPartAccessory" then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = "MeshPartAccessory"
					local attachment = Instance.new("Attachment")
					attachment.Name = "AccessoryWeld"
					attachment.Position = Vector3.new(-0, -0.34, -0)
					attachment.Orientation = Vector3.new(0, 0, 0)
					attachment.Parent = hatAccessory
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1, 1, 1)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://6002625087"
					specialMesh.TextureId = "rbxassetid://6002608052"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(-0, -0.34, -0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 0, 0)
					end
					return hatAccessory
				end
				
				local function AddFakeHumanoidRigToStand(standModel)
					if not standModel then return end
					local standModelReal = lpr.Character:FindFirstChild("Stand");
					if not standModelReal then return end
					if standModelReal:FindFirstChild("FakeRig") then return end
					print("Adding Fake Rig")

					-- Define required parts that MUST exist
					local requiredParts = {
						Head = {"Head", "head", "HEAD", "Skull", "HumanoidHead"},
						Torso = {"Torso", "torso", "TORSO", "UpperTorso", "Body", "Chest", "TorsoPart"},
						LeftArm = {"Left Arm", "LeftArm", "Left_Arm", "L_Arm", "LeftHand", "LArm", "Left ArmPart"},
						RightArm = {"Right Arm", "RightArm", "Right_Arm", "R_Arm", "RightHand", "RArm", "Right ArmPart"},
						LeftLeg = {"Left Leg", "LeftLeg", "Left_Leg", "L_Leg", "LeftFoot", "LLeg", "Left LegPart"},
						RightLeg = {"Right Leg", "RightLeg", "Right_Leg", "R_Leg", "RightFoot", "RLeg", "Right LegPart"}
					}

					-- Function to find a part by multiple name variations
					local function findPart(partKey)
						local nameVariations = requiredParts[partKey]
						if not nameVariations then return nil end

						for _, name in ipairs(nameVariations) do
							local part = standModelReal:FindFirstChild(name)
							if part and (part:IsA("Part") or part:IsA("MeshPart") or part:IsA("BasePart")) then
								return part
							end
						end
						return nil
					end

					-- Function to wait for all required parts to exist
					local function waitForAllParts(timeout)
						local startTime = tick()
						local timeoutSeconds = timeout or 5  -- Default 5 second timeout
						local foundParts = {}

						print("Waiting for all stand parts to load...")

						-- Keep trying until all parts are found or timeout
						while tick() - startTime < timeoutSeconds do
							local allFound = true
							local missingParts = {}

							for partKey in pairs(requiredParts) do
								if not foundParts[partKey] then
									local part = findPart(partKey)
									if part then
										foundParts[partKey] = part
										print("Found: " .. partKey .. " (" .. part.Name .. ")")
									else
										allFound = false
										table.insert(missingParts, partKey)
									end
								end
							end

							if allFound then
								print("All required parts found!")
								return foundParts
							end

							-- Wait before checking again
							task.wait(0.1)
						end

						-- Timeout reached, show which parts are missing
						print("Timeout waiting for parts! Missing parts:")
						for partKey in pairs(requiredParts) do
							if not foundParts[partKey] then
								print("  - " .. partKey)
							end
						end

						return foundParts
					end

					-- Wait for all parts (max 5 seconds)
					local foundParts = waitForAllParts(5)

					-- Check if we have all required parts
					local missingCount = 0
					for partKey in pairs(requiredParts) do
						if not foundParts[partKey] then
							missingCount = missingCount + 1
						end
					end

					if missingCount > 0 then
						print("Cannot create Fake Rig: Missing " .. missingCount .. " required parts")
						return nil
					end

					-- Create Fake Rig Model
					local FakeRigModel = Instance.new("Model")
					FakeRigModel.Name = "FakeRig"

					-- Add Humanoid
					local humanoid = Instance.new("Humanoid")
					humanoid.Name = "Humanoid"
					humanoid.Parent = FakeRigModel

					-- Clone all found parts
					local clonedParts = {}
					for partKey, originalPart in pairs(foundParts) do
						local clonePart = originalPart:Clone()
						clonePart.Parent = FakeRigModel
						clonePart.Massless = true
						clonePart.Transparency = 0  -- Make fake rig visible
						clonePart.Anchored = false  -- Don't anchor, let it follow
						clonePart.CanCollide = false  -- Disable collision
						clonePart.CanQuery = false  -- Prevent raycasting
						clonePart.CanTouch = false  -- Prevent touching

						-- Store original transparency and save it
						originalPart.Transparency = 1  -- Hide original part
						originalPart.CanCollide = false  -- Disable collision on original too
						originalPart.CanQuery = false
						originalPart.CanTouch = false

						clonedParts[partKey] = clonePart
						print("Cloned part: " .. partKey .. " (Original: " .. originalPart.Name .. ")")
					end

					-- Add BodyColors
					local NewBodyColors = Instance.new("BodyColors")
					NewBodyColors.Parent = FakeRigModel
					NewBodyColors.HeadColor3 = Color3.fromRGB(234, 184, 146)
					NewBodyColors.LeftArmColor3 = Color3.fromRGB(234, 184, 146)
					NewBodyColors.RightArmColor3 = Color3.fromRGB(234, 184, 146)
					NewBodyColors.LeftLegColor3 = Color3.fromRGB(255, 204, 153)
					NewBodyColors.RightLegColor3 = Color3.fromRGB(255, 204, 153)
					NewBodyColors.TorsoColor3 = Color3.fromRGB(234, 184, 146)

					-- Add Highlight
					local NewHighlight = Instance.new("Highlight")
					NewHighlight.Parent = FakeRigModel
					NewHighlight.FillColor = Color3.fromRGB(0, 0, 0)
					NewHighlight.FillTransparency = 1
					NewHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
					NewHighlight.OutlineTransparency = 0
					NewHighlight.Enabled = true
					NewHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

					-- Clone clothing if exists
					local clothingTypes = {"UncleShirt", "AngelicShirt", "Shirt", "Pants", "UnclePants", "AngelicPants"}
					for _, clothingName in ipairs(clothingTypes) do
						local clothing = standModel:FindFirstChild(clothingName)
						if clothing then
							local newClothing = clothing:Clone()
							newClothing.Parent = FakeRigModel
						end
					end

					-- Set primary part (Torso preferred, then Head, then any part)
					if clonedParts["Torso"] then
						FakeRigModel.PrimaryPart = clonedParts["Torso"]
					elseif clonedParts["Head"] then
						FakeRigModel.PrimaryPart = clonedParts["Head"]
					else
						for _, part in pairs(clonedParts) do
							FakeRigModel.PrimaryPart = part
							break
						end
					end

					FakeRigModel.Parent = standModelReal

					print("Fake Rig created successfully with all " .. #clonedParts .. " parts!")
					return FakeRigModel
				end

				local function AnimateFakeRig(standModel)
					if not standModel then return end
					local standModelReal = lpr.Character:FindFirstChild("Stand")
					if not standModelReal then return end

					local FakeRigModel = standModelReal:FindFirstChild("FakeRig")
					if not FakeRigModel then
						FakeRigModel = AddFakeHumanoidRigToStand(standModel)
						if not FakeRigModel then 
							print("Failed to create Fake Rig - missing required parts")
							return 
						end
					end

					-- If already following, don't create another
					if FakeRigModel:FindFirstChild("FollowConnection") then
						print("Fake rig already following")
						return
					end

					print("Starting CFrame follow for fake rig...")

					-- Define part mappings
					local partMappings = {
						Head = {"Head", "head", "HEAD", "Skull"},
						Torso = {"Torso", "torso", "TORSO", "UpperTorso", "Body", "Chest"},
						LeftArm = {"Left Arm", "LeftArm", "Left_Arm", "L_Arm", "LeftHand", "LArm"},
						RightArm = {"Right Arm", "RightArm", "Right_Arm", "R_Arm", "RightHand", "RArm"},
						LeftLeg = {"Left Leg", "LeftLeg", "Left_Leg", "L_Leg", "LeftFoot", "LLeg"},
						RightLeg = {"Right Leg", "RightLeg", "Right_Leg", "R_Leg", "RightFoot", "RLeg"}
					}

					-- Store original and fake part references
					local partPairs = {}

					for partKey, nameVariations in pairs(partMappings) do
						local originalPart = nil
						local fakePart = nil

						-- Find original part
						for _, name in ipairs(nameVariations) do
							originalPart = standModelReal:FindFirstChild(name)
							if originalPart then break end
						end

						-- Find fake part
						fakePart = FakeRigModel:FindFirstChild(partKey)
						if not fakePart then
							for _, name in ipairs(nameVariations) do
								fakePart = FakeRigModel:FindFirstChild(name)
								if fakePart then break end
							end
						end

						if originalPart and fakePart then
							-- Ensure original part is hidden and collision disabled
							originalPart.Transparency = 1
							originalPart.CanCollide = false
							originalPart.CanQuery = false
							originalPart.CanTouch = false

							-- Ensure fake part is visible and collision disabled
							fakePart.Transparency = 0
							fakePart.CanCollide = false
							fakePart.CanQuery = false
							fakePart.CanTouch = false
							fakePart.Anchored = false

							table.insert(partPairs, {
								original = originalPart,
								fake = fakePart,
								name = partKey
							})
							print("Tracking: " .. partKey)
						end
					end

					-- Handle HumanoidRootPart
					local originalHRP = standModelReal:FindFirstChild("HumanoidRootPart")
					local fakeHRP = FakeRigModel:FindFirstChild("HumanoidRootPart")
					if originalHRP and fakeHRP then
						originalHRP.Transparency = 1
						fakeHRP.Transparency = 0
						fakeHRP.CanCollide = false
						fakeHRP.CanQuery = false
						fakeHRP.CanTouch = false

						table.insert(partPairs, {
							original = originalHRP,
							fake = fakeHRP,
							name = "HumanoidRootPart"
						})
						print("Tracking: HumanoidRootPart")
					end

					if #partPairs == 0 then
						print("No parts to track!")
						return
					end

					print("Tracking " .. #partPairs .. " parts with CFrame...")

					-- Flag to track if we should continue
					local isFollowing = true

					-- CFrame follow loop using RenderStepped
					local followConnection
					followConnection = game:GetService("RunService").RenderStepped:Connect(function()
						-- Check if we should stop
						if not isFollowing then
							if followConnection then followConnection:Disconnect() end
							return
						end

						-- Check if stand still exists
						if not standModelReal or not standModelReal.Parent then
							print("Stand destroyed, stopping fake rig follow")
							isFollowing = false
							if followConnection then followConnection:Disconnect() end

							-- Clean up fake rig
							if FakeRigModel then
								FakeRigModel:Destroy()
							end
							return
						end

						-- Check if fake rig still exists
						if not FakeRigModel or not FakeRigModel.Parent then
							print("Fake rig destroyed, stopping follow")
							isFollowing = false
							if followConnection then followConnection:Disconnect() end
							return
						end

						-- Update each part's CFrame
						for _, pair in ipairs(partPairs) do
							-- Check if both parts still exist
							if pair.original and pair.original.Parent and pair.fake and pair.fake.Parent then
								-- Update fake part position to match original
								pair.fake.CFrame = pair.original.CFrame

								-- Ensure properties stay correct (in case something changes them)
								if pair.fake.Transparency ~= 0 then
									pair.fake.Transparency = 0
								end
								if pair.fake.CanCollide ~= false then
									pair.fake.CanCollide = false
								end
								if pair.original.Transparency ~= 1 then
									pair.original.Transparency = 1
								end
								if pair.original.CanCollide ~= false then
									pair.original.CanCollide = false
								end
							else
								-- If any part is missing, stop following
								print("Part missing: " .. pair.name .. ", stopping follow")
								isFollowing = false
								if followConnection then followConnection:Disconnect() end

								-- Clean up fake rig
								if FakeRigModel then
									FakeRigModel:Destroy()
								end
								return
							end
						end
					end)

					-- Store connection reference for cleanup
					local connectionRef = Instance.new("ObjectValue")
					connectionRef.Name = "FollowConnection"
					connectionRef.Value = followConnection
					connectionRef.Parent = FakeRigModel

					-- Also monitor stand destruction via AncestryChanged
					local destructionConnection
					destructionConnection = standModelReal.AncestryChanged:Connect(function(_, parent)
						if not parent then
							print("Stand was destroyed!")
							isFollowing = false
							if followConnection then followConnection:Disconnect() end
							if destructionConnection then destructionConnection:Disconnect() end

							if FakeRigModel then
								FakeRigModel:Destroy()
							end
						end
					end)

					-- Store destruction connection
					local destructionRef = Instance.new("ObjectValue")
					destructionRef.Name = "DestructionConnection"
					destructionRef.Value = destructionConnection
					destructionRef.Parent = FakeRigModel

					print("CFrame follow active for fake rig! Will auto-stop when stand is destroyed.")

					-- Return functions for manual control if needed
					return {
						stop = function()
							isFollowing = false
							if followConnection then followConnection:Disconnect() end
							if destructionConnection then destructionConnection:Disconnect() end
							if FakeRigModel then FakeRigModel:Destroy() end
							print("CFrame follow stopped manually")
						end,
						isActive = function()
							return isFollowing and FakeRigModel and FakeRigModel.Parent ~= nil
						end
					}
				end
				local function addClothingToStand(standModel)
					if not standModel then return end
					local torso = standModel:FindFirstChild("Torso")
					if not torso then return end
					if standModel:FindFirstChild("UncleShirt") and standModel:FindFirstChild("UnclePants") then return end
					local shirt = Instance.new("Shirt")
					shirt.Name = "UncleShirt"
					shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=8450171902"
					local pants = Instance.new("Pants")
					pants.Name = "UnclePants"
					pants.PantsTemplate = "http://www.roblox.com/asset/?id=8427781292"
					shirt.Parent = standModel
					pants.Parent = standModel
				end
				if parts[1] and parts[1].Parent then
					if headPart then
						addTopHatToHead(headPart);
						addRedEyeHandleToHead(headPart);
					end
					addClothingToStand(parts[1].Parent)
					--AnimateFakeRig(parts[1].Parent);
				end
			end
		},
		{
			id = "Galaxa_beatdown",
			name = "Galaxa Beatdown",
			description = "galaxa is a newborn with super ultra instinct flowing his blood, a two souls are fused into one who has galaxy body , Your_Uncle & King_Dracule ",
			color = Color3.fromRGB(128, 0, 255),
			fireColor = Color3.fromRGB(128, 0, 255),
			material = Enum.Material.Glass,
			transparency = 0,
			icon = "rbxassetid://5912420913",
			iconColor = Color3.fromRGB(128, 0, 255),
			soundSpeed = 0.7,
			customSounds = {
				["Nukem"] = 1, --0.7 -- 1
				["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 0.67,
				["explosion2"] = 1,
				["Gun1"] = 0.7,
				["Gun2"] = 0.9,
				["Yell"] = 1,
				["Hit"] = 0.5,
				["Implosion"] = 0.7,
			},
			enabled = false,
			specialEffects = function(parts)
				local meshesToRemove = {}
				local rigParts = {}
				local headPart = nil
				local RightArmPart = nil
				local textureId = "rbxassetid://84895530574833"
				local faces = {
					Enum.NormalId.Top,
					Enum.NormalId.Bottom,
					Enum.NormalId.Front,
					Enum.NormalId.Back,
					Enum.NormalId.Right,
					Enum.NormalId.Left
				}
				local function addClothingToStand(standModel)
					if not standModel then return end
					local torso = standModel:FindFirstChild("Torso")
					if not torso then return end
					-- galaxy texture
					if torso then
						if (torso:FindFirstChild("SoulFrame") and torso:FindFirstChild("SoulFrame2")) then return end
						local newParticle = Instance.new("ParticleEmitter", torso);
						newParticle.Color = ColorSequence.new(Color3.fromRGB(128, 0, 255));
						newParticle.LightEmission = 0.86;
						newParticle.LightInfluence = 0;
						newParticle.Orientation = Enum.ParticleOrientation.FacingCamera;
						newParticle.Size = NumberSequence.new(0.938, 0);
						newParticle.Squash = 0;
						newParticle.Texture = "rbxassetid://241594419";
						newParticle.Transparency = NumberSequence.new(0.5, 1);
						newParticle.Brightness = 1;
						newParticle.ZOffset = 0;
						newParticle.EmissionDirection = Enum.NormalId.Top;
						newParticle.Lifetime = NumberRange.new(0, 1);
						newParticle.Rate = 70;
						newParticle.Rotation = NumberRange.new(4, 9);
						newParticle.RotSpeed = NumberRange.new(5, 9);
						newParticle.Speed = 0;
						newParticle.SpreadAngle = Vector2.new(28, 28);
						newParticle.Shape = Enum.ParticleEmitterShape.Box;
						newParticle.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward;
						newParticle.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume;
						newParticle.Acceleration = Vector3.new(0, 6, 0);
						newParticle.Drag = 0;
						newParticle.LockedToPart = false;
						newParticle.VelocityInheritance = 0;
						newParticle.TimeScale = 1;
						newParticle.Enabled = true;
						newParticle.Name = "SoulFrame";
						local newParticle2 = Instance.new("ParticleEmitter", torso);
						newParticle2.Color = ColorSequence.new(Color3.fromRGB(55, 0, 165));
						newParticle2.LightEmission = 0;
						newParticle2.LightInfluence = 0;
						newParticle2.Orientation = Enum.ParticleOrientation.FacingCamera;
						newParticle2.Size = NumberSequence.new(0.938, 0);
						newParticle2.Squash = 0;
						newParticle2.Texture = "rbxassetid://241594419";
						newParticle2.Transparency = NumberSequence.new(0.5, 1);
						newParticle2.Brightness = 13;
						newParticle2.ZOffset = 0;
						newParticle2.EmissionDirection = Enum.NormalId.Top;
						newParticle2.Lifetime = NumberRange.new(0, 1);
						newParticle2.Rate = 70;
						newParticle2.Rotation = NumberRange.new(4, 9);
						newParticle2.RotSpeed = NumberRange.new(5, 9);
						newParticle2.Speed = 0;
						newParticle2.SpreadAngle = Vector2.new(28, 28);
						newParticle2.Shape = Enum.ParticleEmitterShape.Box;
						newParticle2.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward;
						newParticle2.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume;
						newParticle2.Acceleration = Vector3.new(0, 6, 0);
						newParticle2.Drag = 0;
						newParticle2.LockedToPart = false;
						newParticle2.VelocityInheritance = 0;
						newParticle2.TimeScale = 1;
						newParticle2.Enabled = true;
						newParticle2.Name = "SoulFrame2";
						local att = torso:FindFirstChild("att");
						if att then
							local Sprial = att:FindFirstChild("Sprial");
							if Sprial then
								Sprial.Color = ColorSequence.new(Color3.fromRGB(162, 0, 255));
								Sprial.Orientation = Enum.ParticleOrientation.VelocityParallel;
							end
						end
					end
				end
				local function replaceGloveWithSword(standModel)
					local rightArm = standModel:FindFirstChild("Right Arm");
					if not rightArm then return end
					local GlovePart = rightArm:FindFirstChild("Glove");
					if GlovePart then
						print("Found Glove, replacing with Sword...")
						GlovePart:Destroy();
						if rightArm:FindFirstChild("Sword") then print("Sword already exists.") return end
						local Sword = Instance.new("MeshPart");
						Sword.Name = "Sword";
						Sword.Size = Vector3.new(0.819, 7.285, 0.247);
						Sword.Color = Color3.fromRGB(255, 84, 246);
						Sword.Material = Enum.Material.Neon;
						Sword.Massless = true;
						Sword.CanCollide = false;
						Sword.Anchored = false;
						Sword.MeshId = "rbxassetid://13696156138";
						Sword.Reflectance = 1;
						Sword.Parent = rightArm;

						local Weld = Instance.new("Weld");
						Weld.Part0 = Sword;
						Weld.Part1 = rightArm;

						Weld.C0 = CFrame.new(-1, -3, 0) * CFrame.Angles(math.rad(90), math.rad(-90), 0);
						Weld.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), 0);
						Weld.Parent = Sword;

						local ItemHighlight = Instance.new("ParticleEmitter")
						ItemHighlight.Name = "ItemHighlight"

						-- Create a ColorSequence with multiple keypoints
						ItemHighlight.Brightness = 1;
						ItemHighlight.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(184, 6, 255)),     -- Red at start
							ColorSequenceKeypoint.new(0.734, Color3.fromRGB(184, 6, 255)),   -- Green at middle
							ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 221, 255))      -- Blue at end
						})
						ItemHighlight.LightEmission = 1
						ItemHighlight.LightInfluence = 5
						ItemHighlight.Orientation = Enum.ParticleOrientation.FacingCamera;

						ItemHighlight.Size = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 3.69, 1.43),  -- Time 0: Value 3.69, Envelope 1.43
							NumberSequenceKeypoint.new(1, 1.54, 0)      -- Time 1: Value 1.54, Envelope 0
						})
						ItemHighlight.Texture = "http://www.roblox.com/asset/?id=1847258023";

						ItemHighlight.Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1, 0),  -- Time 0: Value 0
							NumberSequenceKeypoint.new(0.502, 0.929, 0),      -- Time 1: Value 1
							NumberSequenceKeypoint.new(1, 1, 0),  -- Time 0: Value 0
						})
						ItemHighlight.ZOffset = 1;

						ItemHighlight.EmissionDirection = Enum.NormalId.Top;
						ItemHighlight.Enabled = true;
						ItemHighlight.Lifetime = 1;
						ItemHighlight.Rate = 100;
						ItemHighlight.Rotation = 0;
						ItemHighlight.RotSpeed = 0;
						ItemHighlight.Speed = 0.01;
						ItemHighlight.SpreadAngle = Vector2.new(0, 0);

						ItemHighlight.Shape = Enum.ParticleEmitterShape.Box;
						ItemHighlight.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward;
						ItemHighlight.Shape = Enum.ParticleEmitterShapeStyle.Volume;

						ItemHighlight.Acceleration = Vector3.new(0, 0, 0);
						ItemHighlight.Drag = 0;
						ItemHighlight.LockedToPart = true;
						ItemHighlight.TimeScale = 1;
						ItemHighlight.VelocityInheritance = 0;
						ItemHighlight.WindAffectsDrag = false;
						ItemHighlight.Parent = Sword;

						-- TEXTURE PARTICLE 2

						local SideSmoke = Instance.new("ParticleEmitter")
						SideSmoke.Name = "SideSmoke"

						-- Create a ColorSequence one
						SideSmoke.Brightness = 5
						SideSmoke.Color = Color3.fromRGB(144, 87, 255)
						SideSmoke.LightEmission = 1
						SideSmoke.LightInfluence = 0
						SideSmoke.Orientation = Enum.ParticleOrientation.FacingCamera;

						SideSmoke.Size = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1.62, 0.836),  -- Time 0: Value 3.69, Envelope 1.43
							NumberSequenceKeypoint.new(1, 1.62, 0.836)      -- Time 1: Value 1.54, Envelope 0
						})
						SideSmoke.Texture = "rbxassetid://9139094373";

						SideSmoke.Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0.253, 0.148),  -- Time 0: Value 0
							NumberSequenceKeypoint.new(0.711, 0.186, 0.0692),      -- Time 1: Value 1
							NumberSequenceKeypoint.new(1, 0.989, 0.011),  -- Time 0: Value 0
						})
						SideSmoke.ZOffset = -1;

						SideSmoke.EmissionDirection = Enum.NormalId.Right;
						SideSmoke.Enabled = true;
						SideSmoke.Lifetime = Vector2.new(1.5, 2.5);
						SideSmoke.Rate = 20;
						SideSmoke.Rotation = Vector2.new(-180, 180);
						SideSmoke.RotSpeed = 0;
						SideSmoke.Speed = 0.139;
						SideSmoke.SpreadAngle = Vector2.new(0, 360);

						SideSmoke.Shape = Enum.ParticleEmitterShape.Box;
						SideSmoke.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward;
						SideSmoke.Shape = Enum.ParticleEmitterShapeStyle.Volume;

						SideSmoke.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8;
						SideSmoke.FlipbookMode = Enum.ParticleFlipbookMode.OneShot;
						SideSmoke.FlipbookBlendFrames = true;

						SideSmoke.Acceleration = Vector3.new(0, -0.815, 0);
						SideSmoke.Drag = 8;
						SideSmoke.LockedToPart = true;
						SideSmoke.TimeScale = 1;
						SideSmoke.VelocityInheritance = 0;
						SideSmoke.WindAffectsDrag = false;
						SideSmoke.Parent = Sword;

						-- TEXTURE PARTICLE 3

						local TextureParticle3 = Instance.new("ParticleEmitter")
						TextureParticle3.Name = "TextureParticle3"

						-- Create a ColorSequence one
						TextureParticle3.Brightness = 10
						TextureParticle3.Color = Color3.fromRGB(248, 46, 255)
						TextureParticle3.LightEmission = 1
						TextureParticle3.LightInfluence = 0
						TextureParticle3.Orientation = Enum.ParticleOrientation.FacingCamera;

						TextureParticle3.Size = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0.75, 0.75),  -- Time 0: Value 3.69, Envelope 1.43
							NumberSequenceKeypoint.new(1, 0.25, 0)      -- Time 1: Value 1.54, Envelope 0
						})
						TextureParticle3.Texture = "rbxassetid://9139094373";

						TextureParticle3.Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0, 0),  -- Time 0: Value 0
							NumberSequenceKeypoint.new(0.508, 0, 0),      -- Time 1: Value 1
							NumberSequenceKeypoint.new(1, 1, 0),  -- Time 0: Value 0
						})
						TextureParticle3.ZOffset = 0;

						TextureParticle3.EmissionDirection = Enum.NormalId.Front;
						TextureParticle3.Enabled = true;
						TextureParticle3.Lifetime = 1;
						TextureParticle3.Rate = 20;
						TextureParticle3.Rotation = Vector2.new(-180, 180);
						TextureParticle3.RotSpeed = Vector2.new(-30, 30);
						TextureParticle3.Speed = 0.5;
						TextureParticle3.SpreadAngle = Vector2.new(180, 90);

						TextureParticle3.Shape = Enum.ParticleEmitterShape.Box;
						TextureParticle3.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward;
						TextureParticle3.Shape = Enum.ParticleEmitterShapeStyle.Volume;

						TextureParticle3.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8;
						TextureParticle3.FlipbookBlendFrames = true
						TextureParticle3.FlipbookFramerate = Vector2.new(20, 40)
						TextureParticle3.FlipbookMode = Enum.ParticleFlipbookMode.Loop;
						TextureParticle3.FlipbookStartRandom = true;

						TextureParticle3.Acceleration = Vector3.new(0, 1, 0);
						TextureParticle3.Drag = 0;
						TextureParticle3.LockedToPart = true;
						TextureParticle3.TimeScale = 1;
						TextureParticle3.VelocityInheritance = 0;
						TextureParticle3.WindAffectsDrag = false;
						TextureParticle3.Parent = Sword
					end
				end
				for _, part in ipairs(parts) do
					if part:IsA("BasePart") or (part:IsA("Part") and part.Name ~= "HumanoidRootPart") then
						part.Color = Color3.fromRGB(0, 0, 0)
						for _, face in ipairs(faces) do
							if part.Name ~= "Head" then
							local faceName = tostring(face):match("%.(.+)$") or tostring(face)
							local textureName = "Texture_" .. faceName
							local existingTexture = part:FindFirstChild(textureName)
							if not existingTexture then
								for _, child in ipairs(part:GetChildren()) do
									if child:IsA("Texture") and child.Face == face then
										existingTexture = child
										break
									end
								end
							end
							if not existingTexture then
								local texture = Instance.new("Texture")
									texture.Name = textureName
									texture.Texture = textureId
									texture.Face = face
									texture.StudsPerTileU = 5
									texture.StudsPerTileV = 5
									texture.Transparency = 0.12
									texture.ZIndex = 1
									texture.Parent = part
								end
							end
						end
						if part.Name == "Head" then
							headPart = part
						end
						if part.Name == "Right Arm" then
							RightArmPart = part
						end
						if part.Name == "Torso" or part.Name == "Left Leg" or part.Name == "Right Leg" or 
							part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Head" then
							table.insert(rigParts, part)
						end
						if part.Name == "Torso" or part.Name:find("Leg") or part.Name:find("Arm") then
							for _, child in ipairs(part:GetChildren()) do
								if child:IsA("SpecialMesh") and child.Name ~= "Sword" then
									table.insert(meshesToRemove, child)
								end
							end
						end
						if part:FindFirstChild("PointLight") then return end
						local pointLight = Instance.new("PointLight")
						pointLight.Color = Color3.fromRGB(128, 0, 255)
						pointLight.Range = 8
						pointLight.Brightness = 2.5
						pointLight.Shadows = true
						pointLight.Enabled = true
						pointLight.Parent = part
						if part.Name ~= "HumanoidRootPart" then
							part.Transparency = 0
							part.Material = Enum.Material.Glass
						end
					end
				end
				for _, mesh in ipairs(meshesToRemove) do
					mesh:Destroy()
				end
				if #rigParts > 0 then
					spawn(function()
						for _, rigPart in ipairs(rigParts) do
							rigPart.Color = Color3.fromRGB(0, 0, 0)
							rigPart.Material = Enum.Material.Glass
						end
					end)
				end
					-- we will continue this later | 07/07/2026 | 07:02 AM
					-- hala 04:02 PM
				local function addTopHatToHead(head)
					if not head then return end
					local Name = "HatMeshPartAccessory"
					if head.Parent:FindFirstChild(Name) then return end
					for _, child in ipairs(head.Parent:GetChildren()) do
						if child.Name == Name then
							child:Destroy()
						end
					end
					local hatAccessory = Instance.new("Accessory")
					hatAccessory.Name = Name
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.Size = Vector3.new(1.5, 1.5, 1.5)
					handle.CanCollide = false
					handle.Transparency = 0
					handle.Massless = true
					handle.Parent = hatAccessory
					local specialMesh = Instance.new("SpecialMesh")
					specialMesh.MeshId = "rbxassetid://6097992548"
					specialMesh.TextureId = "rbxassetid://5355543242"
					specialMesh.Scale = Vector3.new(1, 1, 1)
					specialMesh.VertexColor = Vector3.new(1, 1, 1)
					specialMesh.MeshType = Enum.MeshType.FileMesh
					specialMesh.Parent = handle
					local accessoryWeld = Instance.new("Weld")
					accessoryWeld.Name = "AccessoryWeld"
					accessoryWeld.Part0 = handle
					accessoryWeld.Part1 = head
					accessoryWeld.C0 = CFrame.new(0, -0.9, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
					accessoryWeld.Enabled = true
					accessoryWeld.Parent = handle
					hatAccessory.Parent = head.Parent
					
					local face = head:FindFirstChild("face")
					if face and face:IsA("Decal") then
						if face.Texture ~= "rbxassetid://73005811414616" then
						face.Texture = "rbxassetid://73005811414616" -- Set face texture
						print("Set face Event.")
						end
					end
					if specialMesh then
						handle.Color = Color3.fromRGB(0, 0, 0)
					end
					return hatAccessory
				end
				if parts[1] and parts[1].Parent then
					if headPart then
						addTopHatToHead(headPart);
					end
					if RightArmPart then
						replaceGloveWithSword(RightArmPart);
					end
					addClothingToStand(parts[1].Parent)
				end
			end
		},
	}
	-- LIGHTING:
	local function saveCurrentSettings()
		local lighting = game:GetService("Lighting")

		-- Save lighting properties
		originalLighting.Brightness = lighting.Brightness
		originalLighting.ClockTime = lighting.ClockTime
		originalLighting.ExposureCompensation = lighting.ExposureCompensation
		originalLighting.Ambient = lighting.Ambient
		originalLighting.OutdoorAmbient = lighting.OutdoorAmbient
		originalLighting.ShadowSoftness = lighting.ShadowSoftness
		originalLighting.GlobalShadows = lighting.GlobalShadows
		originalLighting.FogEnd = lighting.FogEnd
		originalLighting.FogStart = lighting.FogStart

		-- Save skybox properties
		local sky = lighting:FindFirstChild("Sky")
		if sky then
			originalSkybox.SkyboxBk = sky.SkyboxBk
			originalSkybox.SkyboxDn = sky.SkyboxDn
			originalSkybox.SkyboxFt = sky.SkyboxFt
			originalSkybox.SkyboxLf = sky.SkyboxLf
			originalSkybox.SkyboxRt = sky.SkyboxRt
			originalSkybox.SkyboxUp = sky.SkyboxUp
			originalSkybox.MoonAngularSize = sky.MoonAngularSize
			originalSkybox.MoonTextureId = sky.MoonTextureId
			originalSkybox.StarCount = sky.StarCount
			originalSkybox.CelestialBodiesShown = sky.CelestialBodiesShown
		end
	end

	-- Function to apply night sky
	local function applyNightSky()
		local lighting = game:GetService("Lighting")

		-- Create or get Sky
		local sky = lighting:FindFirstChild("Sky")
		if not sky then
			sky = Instance.new("Sky")
			sky.Parent = lighting
		end

		-- Apply night skybox from your image
		sky.SkyboxBk = "rbxassetid://159454299"
		sky.SkyboxDn = "rbxassetid://159454296"
		sky.SkyboxFt = "rbxassetid://159454293"
		sky.SkyboxLf = "rbxassetid://159454286"
		sky.SkyboxRt = "rbxassetid://159454300"
		sky.SkyboxUp = "rbxassetid://159454288"
		sky.MoonAngularSize = 11
		sky.MoonTextureId = "rbxasset://sky/moon.jpg"
		sky.StarCount = 5000
		sky.CelestialBodiesShown = true
	end

	-- Function to restore original sky
	local function restoreSky()
		local lighting = game:GetService("Lighting")
		local sky = lighting:FindFirstChild("Sky")

		if sky and next(originalSkybox) then
			sky.SkyboxBk = originalSkybox.SkyboxBk
			sky.SkyboxDn = originalSkybox.SkyboxDn
			sky.SkyboxFt = originalSkybox.SkyboxFt
			sky.SkyboxLf = originalSkybox.SkyboxLf
			sky.SkyboxRt = originalSkybox.SkyboxRt
			sky.SkyboxUp = originalSkybox.SkyboxUp
			sky.MoonAngularSize = originalSkybox.MoonAngularSize
			sky.MoonTextureId = originalSkybox.MoonTextureId
			sky.StarCount = originalSkybox.StarCount
			sky.CelestialBodiesShown = originalSkybox.CelestialBodiesShown
		end
	end

	-- Function to tween to night
	local function tweenToNight(duration)
		duration = duration or 5 -- Default 5 seconds

		local lighting = game:GetService("Lighting")
		local TweenService = game:GetService("TweenService")

		-- Save current settings first
		saveCurrentSettings()

		-- Apply night sky immediately
		applyNightSky()

		-- Create tween info
		local tweenInfo = TweenInfo.new(
			duration,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut
		)

		-- Create goals for lighting
		local goals = {
			Brightness = 0.2,
			ClockTime = 21, -- 9 PM
			ExposureCompensation = -1,
			Ambient = Color3.fromRGB(30, 30, 40),
			OutdoorAmbient = Color3.fromRGB(40, 40, 60),
			ShadowSoftness = 1,
			GlobalShadows = true,
			FogEnd = 500,
			FogStart = 100
		}

		-- Create and play tween
		local tween = TweenService:Create(lighting, tweenInfo, goals)
		tween:Play()

		return tween
	end

	-- Function to revert back to original settings
	local function revertToDay(duration)
		duration = duration or 5

		local lighting = game:GetService("Lighting")
		local TweenService = game:GetService("TweenService")

		-- Restore original skybox
		restoreSky()

		-- Create tween info
		local tweenInfo = TweenInfo.new(
			duration,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut
		)

		-- Restore original lighting settings
		local goals = {
			Brightness = originalLighting.Brightness or 1,
			ClockTime = originalLighting.ClockTime or 14,
			ExposureCompensation = originalLighting.ExposureCompensation or 0,
			Ambient = originalLighting.Ambient or Color3.fromRGB(127, 127, 127),
			OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.fromRGB(127, 127, 127),
			ShadowSoftness = originalLighting.ShadowSoftness or 0.3,
			GlobalShadows = originalLighting.GlobalShadows or true,
			FogEnd = originalLighting.FogEnd or 1000,
			FogStart = originalLighting.FogStart or 0
		}

		-- Create and play tween
		local tween = TweenService:Create(lighting, tweenInfo, goals)
		tween:Play()

		return tween
	end
	local isNight = false
	local isTransitioning = false
	
	local function setDayNight(enableNight)
		-- Prevent spam
		if isTransitioning then
			return
		end

		-- Already in this state
		if enableNight == isNight then
			return
		end

		isTransitioning = true
		isNight = enableNight

		local tween
		if isNight then
			tween = tweenToNight(3)
			print("Switched to night")
		else
			tween = revertToDay(3)
			print("Switched to day")
		end

		-- Allow switching again after tween completes
		if tween then
			tween.Completed:Connect(function()
				isTransitioning = false
			end)
		end
	end
	
	-- STRIKE LIGHTNING:
	local function Draw(p1, p2, Parent, LifeTime)
		LifeTime = LifeTime or 1
		local Dist = (p2.Position - p1.Position).Magnitude
		local Part = Instance.new("Part", Parent);
		Part.Anchored = true
		Part.CanCollide = false
		Part.Material = Enum.Material.Neon
		Part.Color = Color3.fromRGB(187, 14, 255)
		Part.Size = Vector3.new(0.8, 0.8, Dist)
		Part.CFrame = CFrame.new(p1.Position, p2.Position) * CFrame.new(0, 0, -Dist / 2)
		game.Debris:AddItem(Part, LifeTime)
		return Part
	end
	
	local function CreateLightning(StartPosition, EndPosition, TotalDuration)
		TotalDuration = TotalDuration or 1.8

		local Model = Instance.new("Model", game.Workspace);
		local Parts = {};
		local TweenService = game:GetService("TweenService")
		local runService = game:GetService("RunService")
		local isRotating = true

		-- Create a single lightning bolt (straight line with slight randomness)
		local points = {}
		local numSegments = 9

		for i = 0, numSegments do
			local progress = i / numSegments
			local pos = StartPosition:Lerp(EndPosition, progress)

			-- Add random offset (more in the middle, less at ends)
			local offsetAmount = math.sin(progress * math.pi) * 3
			local Offset = Vector3.new(
				math.random(-offsetAmount, offsetAmount),
				math.random(-offsetAmount * 0.5, offsetAmount * 0.5),
				math.random(-offsetAmount, offsetAmount)
			)

			if i == 0 or i == numSegments then
				Offset = Vector3.new(0, 0, 0)
			end

			local Part = Instance.new("Part", Model);
			Part.Anchored = true
			Part.CanCollide = false
			Part.Material = Enum.Material.Neon
			Part.Color = Color3.fromRGB(187, 14, 255)
			Part.Size = Vector3.new(0.8, 0.8, 0.8)
			Part.Transparency = 1
			Part.Position = pos + Offset
			table.insert(points, Part)
		end

		-- Create segments between points
		for i = 1, #points - 1 do
			local p1 = points[i]
			local p2 = points[i + 1]
			local Dist = (p2.Position - p1.Position).Magnitude
			local segment = Instance.new("Part", Model)
			segment.Anchored = true
			segment.CanCollide = false
			segment.Material = Enum.Material.Neon
			segment.Color = Color3.fromRGB(187, 14, 255)
			segment.Size = Vector3.new(0.8, 0.8, Dist)
			segment.CFrame = CFrame.new(p1.Position, p2.Position) * CFrame.new(0, 0, -Dist / 2)
			segment.Transparency = 1
			game.Debris:AddItem(segment, TotalDuration + 0.5)
			table.insert(Parts, segment)
		end

		-- Create point light for flickering
		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(187, 14, 255)
		pointLight.Brightness = 0
		pointLight.Range = 30
		pointLight.Parent = Model
		local attachment = Instance.new("Attachment")
		attachment.Parent = Model
		pointLight.Parent = attachment
		attachment.WorldPosition = (StartPosition + EndPosition) / 2

		-- Flash on once
		local function flashOn()
			-- Flash main bolt
			for _, part in ipairs(Parts) do
				local tween = TweenService:Create(part, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
					Transparency = 0
				})
				tween:Play()
			end

			-- Flash point parts
			for _, point in ipairs(points) do
				local tween = TweenService:Create(point, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
					Transparency = 0
				})
				tween:Play()
			end

			-- Flash light on
			local lightTween = TweenService:Create(pointLight, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
				Brightness = math.random(20, 40)
			})
			lightTween:Play()
		end

		-- Rotation function
		local function rotateLightning()
			local rotationSpeed = 5
			local elapsed = 0

			while isRotating and elapsed < TotalDuration do
				local dt = runService.Heartbeat:Wait()
				elapsed = elapsed + dt

				-- Rotate the entire model
				local angle = dt * rotationSpeed
				local pivot = (StartPosition + EndPosition) / 2

				for i = 1, #points do
					local point = points[i]
					local offset = point.Position - pivot
					local newX = offset.X * math.cos(angle) - offset.Z * math.sin(angle)
					local newZ = offset.X * math.sin(angle) + offset.Z * math.cos(angle)
					point.Position = pivot + Vector3.new(newX, offset.Y, newZ)
				end

				-- Update segment positions
				for i = 1, #points - 1 do
					if points[i + 1] and Parts[i] then
						local p1 = points[i]
						local p2 = points[i + 1]
						local Dist = (p2.Position - p1.Position).Magnitude
						Parts[i].Size = Vector3.new(1, 1, Dist)
						Parts[i].CFrame = CFrame.new(p1.Position, p2.Position) * CFrame.new(0, 0, -Dist / 2)
					end
				end

				-- Flicker the light based on time
				local flicker = math.random() * 0.1 + 0.1
				pointLight.Brightness = 7 + math.sin(elapsed * 30) * 3 + math.random() * 2
				pointLight.Range = 50 + math.sin(elapsed * 20) * 5 + math.random() * 3
			end
		end

		-- Start
		local function startLightning()
			flashOn()
			local newSoundThunder = Instance.new("Sound");
			newSoundThunder.SoundId = "rbxassetid://114778516343256"
			local newAttach = Instance.new("Attachment");
			newAttach.Parent = workspace;
			newAttach.WorldPosition = EndPosition + Vector3.new(0, 10, 0)
			newSoundThunder:Play()
			newSoundThunder.Volume = 2;
			newSoundThunder.RollOffMaxDistance = 150;
			newSoundThunder.RollOffMinDistance = 10;
			newSoundThunder.RollOffMode = Enum.RollOffMode.LinearSquare;
			newSoundThunder.Parent = newAttach;
			newSoundThunder.Ended:Connect(function()
				newAttach:Destroy();
				newSoundThunder:Destroy();
			end)
			task.spawn(rotateLightning)

			task.wait(TotalDuration)
			isRotating = false

			-- Fade out
			for _, part in ipairs(Parts) do
				local tween = TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
					Transparency = 1
				})
				tween:Play()
			end
			for _, point in ipairs(points) do
				local tween = TweenService:Create(point, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
					Transparency = 1
				})
				tween:Play()
			end

			-- Fade light out
			local lightTween = TweenService:Create(pointLight, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
				Brightness = 0
			})
			lightTween:Play()

			task.wait(0.6)
			Model:Destroy()
		end

		task.spawn(startLightning)
		return Model
	end

	local SelectedBeatdownModel = "uncle_beatdown"
	local ViewportCamera = nil
	local ViewportModel = nil
	local ViewOtherCustomStands = {
		Enabled = false, -- Default enabled
		FriendStandsOnly = true, -- Option to only see friends' custom stands
		RefreshRate = 0.1, -- How often to check for other players' stands (in seconds)
		stand = nil,
		ActiveChecks = {} -- Track which players we're monitoring
	};
	local PlayedActionLIGHT = false;
	--[
	local CustomCutsenseUncle3 = true;
	local CamPos1 = false -- CamPos1 -> VictimHead
	local CamPos2 = false -- CamPos2 -> AttackerHead
	local CamPos1_timer = 2.2;
	local CamPos2_timer = 1.3;
	local FinalCamPos = false -- FinalCamPos -> VictimHead
	local CamPosActive = false
	--]]
	local ColorCorrectionSystem = {
		activeEffects = {},
		globalColorCorrection = nil,
		startTween = nil,
		endTween = nil,
	}
	local Button_Slap1
	--]]
	local GameDetection = {
		IsSlapBattles = (game.PlaceId == 6403373529),
		CurrentGameName = "Unknown"
	}
	if GameDetection.IsSlapBattles then
		GameDetection.CurrentGameName = "Slap Battles"
		if SettingsScript.DisplayLogs then
			print("Detected: Slap Battles")
		end
	else
		GameDetection.CurrentGameName = "Other Game"
		if SettingsScript.DisplayLogs then
			print("Detected: Other Game")
		end
	end
	local TranslationUI = game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS").__ScreenFrame.Applications:FindFirstChild(AppName) or game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZolinOS").__ZolinDesktop.__ScreenFrame.Applications:FindFirstChild(AppName) or ui or nil;
	if not TranslationUI then
		warn(tostring(AppName).." not found in PlayerGui")
		return
	end
	local MainFrame = TranslationUI:WaitForChild("MainFrame");
	local SideButtons = Instance.new("Frame", TranslationUI);
	SideButtons.Name = "SideButtons";
	SideButtons.AnchorPoint = Vector2.new(0.1, 0.5);
	SideButtons.Position = UDim2.new(0, 0, 0.35, 50);
	SideButtons.Size = UDim2.new(0.1, 50, 0.4, 0);
	SideButtons.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	SideButtons.ZIndex = 6;
	SideButtons.Visible = true;
	SideButtons.Transparency = 1;
	local UIAspectRatio = Instance.new("UIAspectRatioConstraint", SideButtons);
	UIAspectRatio.AspectRatio = 1;
	UIAspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize;
	UIAspectRatio.DominantAxis = Enum.DominantAxis.Width;
	local UIListLayout = Instance.new("UIListLayout", SideButtons);
	UIListLayout.Padding = UDim.new(0, 8);
	UIListLayout.FillDirection = Enum.FillDirection.Vertical;
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top;
	UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.None;
	UIListLayout.VerticalFlex = Enum.UIFlexAlignment.None;
	UIListLayout.ItemLineAlignment = Enum.ItemLineAlignment.Automatic;
	--[ Custom Beatdown Model Settings
	local ButtonCustomBeatdown = Instance.new("TextButton", SideButtons)
	ButtonCustomBeatdown.AnchorPoint = Vector2.new(0.05, 0.5)
	ButtonCustomBeatdown.AutoButtonColor = true
	ButtonCustomBeatdown.Active = true
	ButtonCustomBeatdown.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	ButtonCustomBeatdown.BackgroundTransparency = 0.3
	ButtonCustomBeatdown.Name = "ButtonCustomBeatdown"
	ButtonCustomBeatdown.Size = UDim2.new(0.42, 0, 0.3, 0)
	ButtonCustomBeatdown.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ButtonCustomBeatdown.ZIndex = 6
	ButtonCustomBeatdown.Visible = GameDetection.IsSlapBattles -- Only show in Slap Battles
	ButtonCustomBeatdown.Font = Enum.Font.Oswald
	ButtonCustomBeatdown.Text = ""
	ButtonCustomBeatdown.TextColor3 = Color3.fromRGB(255, 255, 189)
	ButtonCustomBeatdown.TextScaled = true
	ButtonCustomBeatdown.TextSize = 14
	ButtonCustomBeatdown.TextYAlignment = Enum.TextYAlignment.Center
	ButtonCustomBeatdown.TextXAlignment = Enum.TextXAlignment.Left
	ButtonCustomBeatdown.TextWrapped = true
	ButtonCustomBeatdown.LayoutOrder = 1
	local UICorner_ButtonCustomBeatdown = Instance.new("UICorner", ButtonCustomBeatdown)
	UICorner_ButtonCustomBeatdown.CornerRadius = UDim.new(0.15, 0)
	local UIPaddding_ButtonCustomBeatdown = Instance.new("UIPadding", ButtonCustomBeatdown)
	UIPaddding_ButtonCustomBeatdown.PaddingLeft = UDim.new(0.05, 0)
	UIPaddding_ButtonCustomBeatdown.PaddingRight = UDim.new(0.05, 0)
	UIPaddding_ButtonCustomBeatdown.PaddingTop = UDim.new(0, 0)
	UIPaddding_ButtonCustomBeatdown.PaddingBottom = UDim.new(0, 0)
	local UIStroke_ButtonCustomBeatdown = Instance.new("UIStroke", ButtonCustomBeatdown)
	UIStroke_ButtonCustomBeatdown.Color = Color3.fromRGB(157, 157, 157)
	UIStroke_ButtonCustomBeatdown.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke_ButtonCustomBeatdown.Thickness = 3
	UIStroke_ButtonCustomBeatdown.LineJoinMode = Enum.LineJoinMode.Round
	UIStroke_ButtonCustomBeatdown.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	UIStroke_ButtonCustomBeatdown.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	UIStroke_ButtonCustomBeatdown.Transparency = 0
	local ImageLabel_ButtonCustomBeatdown = Instance.new("ImageLabel", ButtonCustomBeatdown)
	ImageLabel_ButtonCustomBeatdown.AnchorPoint = Vector2.new(1, 0.5)
	ImageLabel_ButtonCustomBeatdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageLabel_ButtonCustomBeatdown.BackgroundTransparency = 1
	ImageLabel_ButtonCustomBeatdown.BorderColor3 = Color3.fromRGB(27, 42, 53)
	ImageLabel_ButtonCustomBeatdown.Position = UDim2.new(1, 0, 0.5, 0)
	ImageLabel_ButtonCustomBeatdown.Size = UDim2.new(1, 0, 0.7, 0)
	ImageLabel_ButtonCustomBeatdown.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ImageLabel_ButtonCustomBeatdown.ZIndex = 6
	ImageLabel_ButtonCustomBeatdown.Visible = true
	ImageLabel_ButtonCustomBeatdown.Image = "rbxassetid://122044888299593"
	ImageLabel_ButtonCustomBeatdown.ImageColor3 = Color3.fromRGB(113, 84, 255)
	ImageLabel_ButtonCustomBeatdown.ScaleType = Enum.ScaleType.Fit
	--]]
	local ButtonSettings = Instance.new("TextButton", SideButtons);
	ButtonSettings.AnchorPoint = Vector2.new(0.05, 0.5);
	ButtonSettings.AutoButtonColor = true;
	ButtonSettings.Active = true;
	ButtonSettings.BackgroundColor3 = Color3.fromRGB(38, 38, 38);
	ButtonSettings.BackgroundTransparency = 0.3;
	ButtonSettings.Name = "ButtonSettings";
	ButtonSettings.Size = UDim2.new(0.42, 0, 0.3, 0);
	ButtonSettings.SizeConstraint = Enum.SizeConstraint.RelativeYY;
	ButtonSettings.ZIndex = 6;
	ButtonSettings.Visible = true;
	ButtonSettings.Font = Enum.Font.Oswald
	ButtonSettings.Text = "";
	ButtonSettings.TextColor3 = Color3.fromRGB(255, 255, 189);
	ButtonSettings.TextScaled = true;
	ButtonSettings.TextSize = 14;
	ButtonSettings.TextYAlignment = Enum.TextYAlignment.Center;
	ButtonSettings.TextXAlignment = Enum.TextXAlignment.Left;
	ButtonSettings.TextWrapped = true;
	ButtonSettings.LayoutOrder = 0;
	local UICorner_ButtonSettings = Instance.new("UICorner", ButtonSettings);
	UICorner_ButtonSettings	.CornerRadius = UDim.new(0.15, 0);
	local UIPaddding_ButtonSettings = Instance.new("UIPadding", ButtonSettings);
	UIPaddding_ButtonSettings.PaddingLeft = UDim.new(0.05, 0);
	UIPaddding_ButtonSettings.PaddingRight = UDim.new(0.05, 0);
	UIPaddding_ButtonSettings.PaddingTop = UDim.new(0, 0);
	UIPaddding_ButtonSettings.PaddingBottom = UDim.new(0, 0);
	local UIStroke_ButtonSettings = Instance.new("UIStroke", ButtonSettings);
	UIStroke_ButtonSettings.Color = Color3.fromRGB(157, 157, 157);
	UIStroke_ButtonSettings.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	UIStroke_ButtonSettings.Thickness = 3;
	UIStroke_ButtonSettings.LineJoinMode = Enum.LineJoinMode.Round;
	UIStroke_ButtonSettings.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize;
	UIStroke_ButtonSettings.BorderStrokePosition = Enum.BorderStrokePosition.Outer;
	UIStroke_ButtonSettings.ZIndex = 6;
	UIStroke_ButtonSettings.Transparency = 0;
	local ImageLabel_ButtonSettings = Instance.new("ImageLabel", ButtonSettings);
	ImageLabel_ButtonSettings.AnchorPoint = Vector2.new(1, 0.5);
	ImageLabel_ButtonSettings.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	ImageLabel_ButtonSettings.BackgroundTransparency = 1;
	ImageLabel_ButtonSettings.BorderColor3 = Color3.fromRGB(27, 42, 53);
	ImageLabel_ButtonSettings.Position = UDim2.new(1, 0, 0.5, 0);
	ImageLabel_ButtonSettings.Size = UDim2.new(1, 0, 0.7, 0);
	ImageLabel_ButtonSettings.SizeConstraint = Enum.SizeConstraint.RelativeYY;
	ImageLabel_ButtonSettings.ZIndex = 2
	ImageLabel_ButtonSettings.Visible = true
	ImageLabel_ButtonSettings.Image = "rbxassetid://5912368763";
	ImageLabel_ButtonSettings.ImageColor3 = Color3.fromRGB(48, 48, 48);
	ImageLabel_ButtonSettings.ScaleType = Enum.ScaleType.Fit;
	
	--[
	local ButtonTeleport = Instance.new("TextButton", SideButtons)
	ButtonTeleport.AnchorPoint = Vector2.new(0.05, 0.5)
	ButtonTeleport.AutoButtonColor = true
	ButtonTeleport.Active = true
	ButtonTeleport.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	ButtonTeleport.BackgroundTransparency = 0.3
	ButtonTeleport.Name = "ButtonTeleport"
	ButtonTeleport.Size = UDim2.new(0.42, 0, 0.3, 0)
	ButtonTeleport.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ButtonTeleport.ZIndex = 6
	ButtonTeleport.Visible = true
	ButtonTeleport.Font = Enum.Font.Oswald
	ButtonTeleport.Text = ""
	ButtonTeleport.TextColor3 = Color3.fromRGB(255, 255, 189)
	ButtonTeleport.TextScaled = true
	ButtonTeleport.TextSize = 14
	ButtonTeleport.TextYAlignment = Enum.TextYAlignment.Center
	ButtonTeleport.TextXAlignment = Enum.TextXAlignment.Left
	ButtonTeleport.TextWrapped = true
	local UICorner_ButtonTeleport = Instance.new("UICorner", ButtonTeleport)
	UICorner_ButtonTeleport.CornerRadius = UDim.new(0.15, 0)
	local UIPaddding_ButtonTeleport = Instance.new("UIPadding", ButtonTeleport)
	UIPaddding_ButtonTeleport.PaddingLeft = UDim.new(0.05, 0)
	UIPaddding_ButtonTeleport.PaddingRight = UDim.new(0.05, 0)
	UIPaddding_ButtonTeleport.PaddingTop = UDim.new(0, 0)
	UIPaddding_ButtonTeleport.PaddingBottom = UDim.new(0, 0)
	local UIStroke_ButtonTeleport = Instance.new("UIStroke", ButtonTeleport)
	UIStroke_ButtonTeleport.Color = Color3.fromRGB(157, 157, 157)
	UIStroke_ButtonTeleport.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke_ButtonTeleport.Thickness = 3
	UIStroke_ButtonTeleport.LineJoinMode = Enum.LineJoinMode.Round
	UIStroke_ButtonTeleport.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
	UIStroke_ButtonTeleport.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	UIStroke_ButtonTeleport.ZIndex = 6
	UIStroke_ButtonTeleport.Transparency = 0
	local ImageLabel_ButtonTeleport = Instance.new("ImageLabel", ButtonTeleport)
	ImageLabel_ButtonTeleport.AnchorPoint = Vector2.new(1, 0.5)
	ImageLabel_ButtonTeleport.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageLabel_ButtonTeleport.BackgroundTransparency = 1
	ImageLabel_ButtonTeleport.BorderColor3 = Color3.fromRGB(27, 42, 53)
	ImageLabel_ButtonTeleport.Position = UDim2.new(1, 0, 0.5, 0)
	ImageLabel_ButtonTeleport.Size = UDim2.new(1, 0, 0.7, 0)
	ImageLabel_ButtonTeleport.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ImageLabel_ButtonTeleport.ZIndex = 2
	ImageLabel_ButtonTeleport.Visible = true
	ImageLabel_ButtonTeleport.Image = "rbxassetid://113257385064264"
	ImageLabel_ButtonTeleport.ImageColor3 = Color3.fromRGB(255, 255, 255)
	ImageLabel_ButtonTeleport.ScaleType = Enum.ScaleType.Fit
	--]]
	local Settings = Instance.new("ScrollingFrame", MainFrame);
	Settings.AnchorPoint = Vector2.new(0.5, 0.5);
	Settings.BackgroundTransparency = 0.15;
	Settings.BackgroundColor3 = Color3.fromRGB(17, 17, 38);
	Settings.Active = true;
	Settings.BorderColor3 = Color3.fromRGB(41, 27, 53);
	Settings.LayoutOrder = 3;
	Settings.Position = UDim2.new(0.5, 0, 0.5, 0);
	Settings.Size = UDim2.new(0.6, 50, 0.5, 50);
	Settings.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	Settings.ZIndex = 6;
	Settings.Visible = false;
	Settings.ClipsDescendants = true;
	Settings.AutomaticCanvasSize = Enum.AutomaticSize.X;
	Settings.CanvasSize = UDim2.new(0, 0, 2, 0);
	Settings.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable;
	Settings.ScrollingDirection = Enum.ScrollingDirection.Y;
	Settings.ScrollBarImageColor3 = Color3.fromRGB(182, 146, 244);
	Settings.ScrollBarThickness = 12;
	Settings.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right;
	Settings.ScrollingEnabled = true
	Settings.Name = "Settings";
	local UICorner_Settings = Instance.new("UICorner", Settings);
	UICorner_Settings.CornerRadius = UDim.new(0, 10);
	local UIPadding_Settings = Instance.new("UIPadding", Settings);
	UIPadding_Settings.PaddingBottom = UDim.new(0.025, 0);
	UIPadding_Settings.PaddingLeft = UDim.new(0.02, 0);
	UIPadding_Settings.PaddingRight = UDim.new(0.02, 0);
	UIPadding_Settings.PaddingTop = UDim.new(0.025, 0);
	local UIStroke_Settings = Instance.new("UIStroke", Settings);
	UIStroke_Settings.Color = Color3.fromRGB(85, 93, 255);
	UIStroke_Settings.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	UIStroke_Settings.BorderStrokePosition = Enum.BorderStrokePosition.Outer;
	UIStroke_Settings.LineJoinMode = Enum.LineJoinMode.Round;
	UIStroke_Settings.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize;
	UIStroke_Settings.Thickness = 4.3;
	UIStroke_Settings.Transparency = 0.33;
	UIStroke_Settings.ZIndex = 6;
	
	local function isFriend(Friend)
		if Friend == lpr then return end
		local success, isFriends = pcall(function()
			if lpr:IsFriendsWithAsync(Friend.UserId) then
				if SettingsScript.DisplayLogs then
					print("Is Friend [true]")
				end
				return true
			else
				return false
			end
		end)
		return success and isFriends
	end
	--[
	local function createTeleportUI()
		if TeleportData.UIInitialized and TeleportUI ~= nil then return end
		TeleportUI = Instance.new("Frame", MainFrame)
		TeleportUI.AnchorPoint = Vector2.new(0.5, 0.5)
		TeleportUI.BackgroundTransparency = 0.15
		TeleportUI.BackgroundColor3 = Color3.fromRGB(17, 17, 38)
		TeleportUI.Active = true
		TeleportUI.BorderColor3 = Color3.fromRGB(41, 27, 53)
		TeleportUI.LayoutOrder = 3
		TeleportUI.Position = UDim2.new(0.5, 0, 0.5, 0)
		TeleportUI.Size = UDim2.new(0.5, 0, 0.7, 0) -- Made taller
		TeleportUI.SizeConstraint = Enum.SizeConstraint.RelativeXY
		TeleportUI.ZIndex = 6
		TeleportUI.Visible = false
		TeleportUI.ClipsDescendants = true
		TeleportUI.Name = "TeleportUI"
		local UICorner_TeleportUI = Instance.new("UICorner", TeleportUI)
		UICorner_TeleportUI.CornerRadius = UDim.new(0, 10)
		local UIPadding_TeleportUI = Instance.new("UIPadding", TeleportUI)
		UIPadding_TeleportUI.PaddingBottom = UDim.new(0.025, 0)
		UIPadding_TeleportUI.PaddingLeft = UDim.new(0.02, 0)
		UIPadding_TeleportUI.PaddingRight = UDim.new(0.02, 0)
		UIPadding_TeleportUI.PaddingTop = UDim.new(0.025, 0)
		local UIStroke_TeleportUI = Instance.new("UIStroke", TeleportUI)
		UIStroke_TeleportUI.Color = Color3.fromRGB(85, 93, 255)
		UIStroke_TeleportUI.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		UIStroke_TeleportUI.BorderStrokePosition = Enum.BorderStrokePosition.Outer
		UIStroke_TeleportUI.LineJoinMode = Enum.LineJoinMode.Round
		UIStroke_TeleportUI.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
		UIStroke_TeleportUI.Thickness = 4.3
		UIStroke_TeleportUI.Transparency = 0.33
		UIStroke_TeleportUI.ZIndex = 6
		local TeleportTitle = Instance.new("TextLabel", TeleportUI)
		TeleportTitle.AnchorPoint = Vector2.new(0.5, 0)
		TeleportTitle.Active = true
		TeleportTitle.LayoutOrder = 3
		TeleportTitle.Name = "Title"
		TeleportTitle.Position = UDim2.new(0.5, 0, 0, 0)
		TeleportTitle.Size = UDim2.new(1, 0, 0.08, 0)
		TeleportTitle.SizeConstraint = Enum.SizeConstraint.RelativeXY
		TeleportTitle.Visible = true
		TeleportTitle.ZIndex = 6
		TeleportTitle.Font = Enum.Font.Oswald
		TeleportTitle.Text = "TELEPORT TO PLAYER"
		TeleportTitle.TextColor3 = Color3.fromRGB(113, 84, 255)
		TeleportTitle.TextScaled = true
		TeleportTitle.TextWrapped = true
		TeleportTitle.TextXAlignment = Enum.TextXAlignment.Center
		TeleportTitle.TextYAlignment = Enum.TextYAlignment.Center
		TeleportTitle.BackgroundTransparency = 1
		local PlayersListContainer = Instance.new("Frame", TeleportUI)
		PlayersListContainer.Name = "PlayersListContainer"
		PlayersListContainer.Position = UDim2.new(0, 0, 0.1, 0)
		PlayersListContainer.Size = UDim2.new(1, 0, 0.9, 0)
		PlayersListContainer.BackgroundTransparency = 1
		PlayersListContainer.ClipsDescendants = true
		local PlayerCountLabel = Instance.new("TextLabel", PlayersListContainer)
		PlayerCountLabel.Name = "PlayerCount"
		PlayerCountLabel.Size = UDim2.new(1, 0, 0.08, 0)
		PlayerCountLabel.Position = UDim2.new(0, 0, 0, 0)
		PlayerCountLabel.BackgroundTransparency = 1
		PlayerCountLabel.Text = "Players: 0"
		PlayerCountLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
		PlayerCountLabel.TextSize = 14
		PlayerCountLabel.Font = Enum.Font.Gotham
		PlayerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
		PlayerCountLabel.ZIndex = 6
		local PlayersScrollFrame = Instance.new("ScrollingFrame", PlayersListContainer)
		PlayersScrollFrame.Name = "PlayersScrollFrame"
		PlayersScrollFrame.Position = UDim2.new(0, 0, 0.08, 0)
		PlayersScrollFrame.Size = UDim2.new(1, 0, 0.92, 0)
		PlayersScrollFrame.BackgroundTransparency = 1
		PlayersScrollFrame.ScrollBarThickness = 6
		PlayersScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(182, 146, 244)
		PlayersScrollFrame.ScrollBarImageTransparency = 0.5
		PlayersScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		PlayersScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		PlayersScrollFrame.ClipsDescendants = true
		PlayersScrollFrame.BorderSizePixel = 0
		local PlayersListLayout = Instance.new("UIListLayout", PlayersScrollFrame)
		PlayersListLayout.Padding = UDim.new(0, 5)
		PlayersListLayout.FillDirection = Enum.FillDirection.Vertical
		PlayersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PlayersListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		PlayersListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		local PlayersScrollPadding = Instance.new("UIPadding", PlayersScrollFrame)
		PlayersScrollPadding.PaddingTop = UDim.new(0, 5)
		PlayersScrollPadding.PaddingBottom = UDim.new(0, 5)
		PlayersScrollPadding.PaddingLeft = UDim.new(0, 5)
		PlayersScrollPadding.PaddingRight = UDim.new(0, 5)
		TeleportData.UIInitialized = true
		TeleportData.TeleportUI = TeleportUI
		TeleportData.PlayersScrollFrame = PlayersScrollFrame
		TeleportData.PlayerCountLabel = PlayerCountLabel
	end
	local function teleportToPlayerInstant(targetPlayer)
		local character = lpr.Character and Character;
		local targetCharacter = targetPlayer.Character
		if not character or not targetCharacter then
			if SettingsScript.DisplayLogs then
				warn("Character not found!")
			end
			return false
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart or not targetRootPart then
			if SettingsScript.DisplayLogs then
				warn("HumanoidRootPart not found!")
			end
			return false
		end
		local lookVector = targetRootPart.CFrame.LookVector
		local teleportPosition = targetRootPart.Position + lookVector  + Vector3.new(0, 1, 0)
		humanoidRootPart.CFrame = CFrame.new(teleportPosition, teleportPosition + lookVector)
		local teleportEffect = character:FindFirstChild("TeleportSound") or Instance.new("Sound", character);
		teleportEffect.Name = "TeleportSound";
		teleportEffect.SoundId = "rbxassetid://98917176503098";
		teleportEffect.Volume = 0.3;
		teleportEffect:Play();
		if teleportEffect:IsA("Sound") then
		teleportEffect.Ended:Connect(function()
			teleportEffect:Destroy()
		end)
		end
		game.Debris:AddItem(teleportEffect, 2);
		if SettingsScript.DisplayLogs then
			print("Instantly teleported to " .. targetPlayer.Name)
		end
		return true
	end
	local function createPlayerButton2(player)
		local isSelf = player == lpr
		local isFriendPlayer = isFriend(player)
		local playerButton = Instance.new("TextButton")
		playerButton.Name = "PlayerBtn_" .. player.Name
		playerButton.Size = UDim2.new(1, -10, 0, isFriendPlayer and 60 or 50)
		playerButton.BackgroundColor3 = isSelf and Color3.fromRGB(45, 45, 65) or isFriendPlayer and Color3.fromRGB(45, 65, 45) or Color3.fromRGB(35, 31, 59)
		playerButton.BackgroundTransparency = 0
		playerButton.AutoButtonColor = true
		playerButton.Text = ""
		playerButton.ZIndex = 6
		local UICorner = Instance.new("UICorner", playerButton)
		UICorner.CornerRadius = UDim.new(0, 8)
		local UIStroke = Instance.new("UIStroke", playerButton)
		UIStroke.Color = isSelf and Color3.fromRGB(100, 100, 100) or isFriendPlayer and Color3.fromRGB(84, 255, 113) or Color3.fromRGB(85, 93, 255)
		UIStroke.Thickness = isFriendPlayer and 3 or 2
		local infoContainer = Instance.new("Frame", playerButton)
		infoContainer.Size = UDim2.new(1, 0, 1, 0)
		infoContainer.BackgroundTransparency = 1
		infoContainer.Visible = true
		local statusIcon = Instance.new("ImageLabel", infoContainer)
		statusIcon.ZIndex = 6
		statusIcon.Name = "StatusIcon"
		statusIcon.Size = UDim2.new(0, 30, 0, 30)
		statusIcon.Position = UDim2.new(0, 10, 0.5, -15)
		statusIcon.BackgroundTransparency = 1
		statusIcon.Image = ""
		statusIcon.ImageColor3 = isSelf and Color3.fromRGB(100, 200, 255) or isFriendPlayer and Color3.fromRGB(113, 255, 84) or Color3.fromRGB(200, 200, 200)
		if isFriendPlayer and not isSelf then
			local friendBadge = Instance.new("ImageLabel", infoContainer)
			friendBadge.Name = "FriendBadge"
			friendBadge.Size = UDim2.new(0, 20, 0, 20)
			friendBadge.Position = UDim2.new(0, 45, 0, 5)
			friendBadge.BackgroundTransparency = 1
			friendBadge.Image = ""
			friendBadge.ImageColor3 = Color3.fromRGB(84, 255, 113)
			friendBadge.ScaleType = Enum.ScaleType.Fit
			friendBadge.ZIndex = 6
		end
		spawn(function()
			local userId = player.UserId
			local thumbType = Enum.ThumbnailType.HeadShot
			local thumbSize = Enum.ThumbnailSize.Size48x48
			local success, content, isReady = pcall(function()
				return game:GetService("Players"):GetUserThumbnailAsync(userId, thumbType, thumbSize)
			end)
			if success and content and isReady then
				statusIcon.Image = content
				statusIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			else
				if SettingsScript.DisplayLogs then
					print("Could not load headshot for " .. player.Name)
				end
			end
		end)
		local nameLabel = Instance.new("TextLabel", infoContainer)
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		nameLabel.Position = UDim2.new(0, isFriendPlayer and 70 or 45, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = player.DisplayName
		nameLabel.TextColor3 = isSelf and Color3.fromRGB(100, 200, 255) or isFriendPlayer and Color3.fromRGB(113, 255, 84) or Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.ZIndex = 6
		local displayLabel = Instance.new("TextLabel", infoContainer)
		displayLabel.Name = "DisplayLabel"
		displayLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		displayLabel.Position = UDim2.new(0, isFriendPlayer and 70 or 45, 0.5, -5)
		displayLabel.BackgroundTransparency = 1
		displayLabel.Text = "@" .. player.Name
		displayLabel.TextColor3 = isSelf and Color3.fromRGB(150, 200, 255) or isFriendPlayer and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(180, 180, 180)
		displayLabel.TextSize = 12
		displayLabel.Font = Enum.Font.Gotham
		displayLabel.TextXAlignment = Enum.TextXAlignment.Left
		displayLabel.TextTruncate = Enum.TextTruncate.AtEnd
		displayLabel.ZIndex = 6
		local actionFrame = Instance.new("Frame", infoContainer)
		actionFrame.Name = "ActionFrame"
		actionFrame.Size = UDim2.new(0.3, 0, 1, 0)
		actionFrame.Position = UDim2.new(0.7, 0, 0, 0)
		actionFrame.BackgroundTransparency = 1
		actionFrame.Visible = true;
		if isSelf then
			local selfLabel = Instance.new("TextLabel", actionFrame)
			selfLabel.Size = UDim2.new(1, -10, 0.7, 0)
			selfLabel.Position = UDim2.new(0, 5, 0.15, 0)
			selfLabel.BackgroundColor3 = Color3.fromRGB(65, 65, 85)
			selfLabel.Text = "YOU"
			selfLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			selfLabel.TextSize = 12
			selfLabel.Font = Enum.Font.GothamBold
			selfLabel.TextScaled = true
			local selfCorner = Instance.new("UICorner", selfLabel)
			selfCorner.CornerRadius = UDim.new(0, 6)
			selfLabel.ZIndex = 6
		elseif isFriendPlayer then
			local friendText = Instance.new("TextLabel", infoContainer)
			friendText.Name = "FriendText"
			friendText.Size = UDim2.new(0, 60, 0, 20)
			friendText.Position = UDim2.new(0.7, 0, 0.1, 0)
			friendText.BackgroundColor3 = Color3.fromRGB(45, 65, 45)
			friendText.BackgroundTransparency = 0.3
			friendText.Text = "FRIEND"
			friendText.TextColor3 = Color3.fromRGB(84, 255, 113)
			friendText.TextSize = 10
			friendText.Font = Enum.Font.GothamBold
			friendText.TextScaled = true
			friendText.ZIndex = 6
			local friendCorner = Instance.new("UICorner", friendText)
			friendCorner.CornerRadius = UDim.new(0, 4)
		end
		local teleportBtn = Instance.new("TextButton", actionFrame)
		teleportBtn.Name = "TeleportBtn"
		teleportBtn.Size = UDim2.new(1, -10, 0.7, 0)
		teleportBtn.Position = UDim2.new(0, 5, 0.15, 0)
		teleportBtn.BackgroundColor3 = Color3.fromRGB(85, 93, 255)
		teleportBtn.Text = "TP"
		teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		teleportBtn.TextSize = 11
		teleportBtn.Font = Enum.Font.GothamBold
		teleportBtn.AutoButtonColor = false
		teleportBtn.ZIndex = 6
		if not isSelf then
			teleportBtn.Visible = true
		else
			teleportBtn.Visible = false
		end
		local teleportCorner = Instance.new("UICorner", teleportBtn)
		teleportCorner.CornerRadius = UDim.new(0, 6)
		teleportBtn.MouseEnter:Connect(function()
			teleportBtn.BackgroundColor3 = Color3.fromRGB(100, 110, 255)
		end)
		teleportBtn.MouseLeave:Connect(function()
			teleportBtn.BackgroundColor3 = Color3.fromRGB(85, 93, 255)
		end)
		teleportBtn.MouseButton1Click:Connect(function()
			teleportBtn.BackgroundColor3 = Color3.fromRGB(113, 255, 84)
			teleportBtn.Text = "✓"
			local success = teleportToPlayerInstant(player)
			task.wait(0.5)
			teleportBtn.BackgroundColor3 = Color3.fromRGB(85, 93, 255)
			teleportBtn.Text = "TP"
		end)
		return playerButton
	end
	local function updatePlayerList2()
		if not TeleportData.TeleportUI or not TeleportData.TeleportUI.Visible then
			return
		end
		local players = game.Players:GetPlayers()
		local scrollFrame = TeleportData.PlayersScrollFrame
		if not scrollFrame then return end
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then
				child:Destroy()
			end
		end
		table.sort(players, function(a, b)
			if a == lpr then return true end
			if b == lpr then return false end
			local aIsFriend = isFriend(a)
			local bIsFriend = isFriend(b)
			if aIsFriend and not bIsFriend then return true end
			if not aIsFriend and bIsFriend then return false end
			return a.Name:lower() < b.Name:lower()
		end)
		for _, player in ipairs(players) do
			local playerButton = createPlayerButton2(player)
			playerButton.Parent = scrollFrame
		end
		if TeleportData.PlayerCountLabel then
			TeleportData.PlayerCountLabel.Text = "Players Online: " .. #players
		end
		TeleportData.LastUpdate = tick()
	end
	local function startAutoUpdate()
		spawn(function()
			while TeleportData.AutoUpdate do
				if TeleportData.TeleportUI and TeleportData.TeleportUI.Visible then
					updatePlayerList2()
				end
				task.wait(TeleportData.UpdateInterval)
			end
		end)
	end
	local function toggleTeleportUI()
		createTeleportUI()
		TeleportData.TeleportUI.Visible = not TeleportData.TeleportUI.Visible
		if Settings.Visible then
			Settings.Visible = false
		end
		if CustomBeatdownUI ~= nil and CustomBeatdownUI.Visible then
			CustomBeatdownUI.Visible = false;
		end
		if TeleportData.TeleportUI.Visible then
			updatePlayerList2()
		end
	end
	local function closeTeleportUI()
		if TeleportData.TeleportUI then
			TeleportData.TeleportUI.Visible = false
		end
	end
	--]]
	local Desclabel = Instance.new("TextLabel", Settings);
	Desclabel.AnchorPoint = Vector2.new(0.5, 1);
	Desclabel.Active = true;
	Desclabel.Position = UDim2.new(0.5, 0, 0.35, 0);
	Desclabel.Size = UDim2.new(1, 0, 0.6, 0);
	Desclabel.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	Desclabel.ZIndex = 6;
	Desclabel.Visible = true
	Desclabel.Font = Enum.Font.Oswald;
	Desclabel.RichText = true;
	Desclabel.Text = "";
	Desclabel.TextColor3 = Color3.fromRGB(255, 255, 189);
	Desclabel.TextScaled = true;
	Desclabel.TextXAlignment = Enum.TextXAlignment.Left;
	Desclabel.TextWrapped = true;
	Desclabel.TextYAlignment = Enum.TextYAlignment.Center;
	Desclabel.Name = "Desc";
	Desclabel.BackgroundTransparency = 1;
	local UIListLayoutDesc = Instance.new("UIListLayout", Desclabel);
	UIListLayoutDesc.Padding = UDim.new(0.1, 0);
	UIListLayoutDesc.FillDirection = Enum.FillDirection.Vertical;
	UIListLayoutDesc.SortOrder = Enum.SortOrder.LayoutOrder;
	UIListLayoutDesc.Wraps = false;
	UIListLayoutDesc.HorizontalAlignment = Enum.HorizontalAlignment.Left;
	UIListLayoutDesc.HorizontalFlex = Enum.UIFlexAlignment.None;
	UIListLayoutDesc.ItemLineAlignment = Enum.ItemLineAlignment.Automatic;
	UIListLayoutDesc.VerticalAlignment = Enum.VerticalAlignment.Top;
	UIListLayoutDesc.VerticalFlex = Enum.UIFlexAlignment.None;
	local UIPadding_Desc = Instance.new("UIPadding", Desclabel);
	UIPadding_Desc.PaddingBottom = UDim.new(0.05, 0);
	UIPadding_Desc.PaddingLeft = UDim.new(0.05, 0);
	UIPadding_Desc.PaddingRight = UDim.new(0.05, 0);
	UIPadding_Desc.PaddingTop = UDim.new(0.05, 0);
	
	--[ Add after SliderSelection4
	local SliderSelection5 = Instance.new("Frame", Desclabel);
	SliderSelection5.AnchorPoint = Vector2.new(0.5, 0.5);
	SliderSelection5.Active = true;
	SliderSelection5.BackgroundColor3 = Color3.fromRGB(35, 31, 59);
	SliderSelection5.BackgroundTransparency = 0;
	SliderSelection5.Size = UDim2.new(1, 0, 0.2, 0);
	SliderSelection5.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	SliderSelection5.Visible = true
	SliderSelection5.ZIndex = 6;
	SliderSelection5.LayoutOrder = 6;
	local UICorner_Slider5 = Instance.new("UICorner", SliderSelection5);
	UICorner_Slider5.CornerRadius = UDim.new(0, 5);
	local Title_Slider5 = Instance.new("TextLabel", SliderSelection5);
	Title_Slider5.AnchorPoint = Vector2.new(0.5, 0);
	Title_Slider5.BackgroundTransparency = 1;
	Title_Slider5.LayoutOrder = 3;
	Title_Slider5.Position = UDim2.new(0.5, 0, 0, 0);
	Title_Slider5.Size = UDim2.new(1, 0, 1, 0);
	Title_Slider5.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	Title_Slider5.Visible = true;
	Title_Slider5.ZIndex = 6;
	Title_Slider5.RichText = true;
	Title_Slider5.Text = "  Enable Auto Kick Player after cutsence beatdown :"
	Title_Slider5.TextColor3 = Color3.fromRGB(194, 194, 194);
	Title_Slider5.TextScaled = false;
	Title_Slider5.TextSize = 29;
	Title_Slider5.TextWrapped = true;
	Title_Slider5.TextXAlignment = Enum.TextXAlignment.Left;
	Title_Slider5.TextYAlignment = Enum.TextYAlignment.Center;
	local UIStroke_Title_Slider5 = Instance.new("UIStroke", Title_Slider5);
	UIStroke_Title_Slider5.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	UIStroke_Title_Slider5.BorderStrokePosition = Enum.BorderStrokePosition.Outer;
	UIStroke_Title_Slider5.Thickness = 2.9;
	UIStroke_Title_Slider5.Color = Color3.fromRGB(103, 92, 150);
	UIStroke_Title_Slider5.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize;
	UIStroke_Title_Slider5.LineJoinMode = Enum.LineJoinMode.Round;
	UIStroke_Title_Slider5.ZIndex = 6;
	UIStroke_Title_Slider5.Transparency = 0;
	UIStroke_Title_Slider5.Enabled = false;
	local UIPadding_TitleSlider5 = Instance.new("UIPadding", Title_Slider5);
	UIPadding_TitleSlider5.PaddingBottom = UDim.new(-0.2, 0);
	UIPadding_TitleSlider5.PaddingLeft = UDim.new(0, 0);
	UIPadding_TitleSlider5.PaddingRight = UDim.new(0, 0);
	UIPadding_TitleSlider5.PaddingTop = UDim.new(-0.2, 0);
	local Button_Slider5 = Instance.new("TextButton", Title_Slider5);
	Button_Slider5.Active = true;
	Button_Slider5.AutoButtonColor = true;
	Button_Slider5.AnchorPoint = Vector2.new(0.5, 0.5);
	Button_Slider5.BackgroundColor3 = Color3.fromRGB(70, 60, 95);
	Button_Slider5.BackgroundTransparency = 0.55;
	Button_Slider5.Position = UDim2.new(0.85, 0, 0.5, 0);
	Button_Slider5.Size = UDim2.new(0, 200, 0, 31);
	Button_Slider5.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	Button_Slider5.Visible = true;
	Button_Slider5.ZIndex = 6;
	Button_Slider5.Name = "EnableAutoKickPlayerOnBeatdown";
	Button_Slider5.Font = Enum.Font.Oswald;
	Button_Slider5.FontFace.Weight = Enum.FontWeight.Bold
	Button_Slider5.FontFace.Style = Enum.FontStyle.Italic
	Button_Slider5.Text = "OFF";
	Button_Slider5.TextColor3 = Color3.fromRGB(214, 214, 214);
	Button_Slider5.RichText = true;
	Button_Slider5.TextScaled = true;
	Button_Slider5.TextWrapped = true;
	Button_Slider5.TextXAlignment = Enum.TextXAlignment.Center;
	Button_Slider5.TextYAlignment = Enum.TextYAlignment.Center;
	local UICorner_TitleSlider5 = Instance.new("UICorner", Button_Slider5);
	UICorner_TitleSlider5.CornerRadius = UDim.new(0, 5);
	local UIStroke_TitleSlider5 = Instance.new("UIStroke", Button_Slider5);
	UIStroke_TitleSlider5.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	UIStroke_TitleSlider5.BorderStrokePosition = Enum.BorderStrokePosition.Outer;
	UIStroke_TitleSlider5.Thickness = 2.9;
	UIStroke_TitleSlider5.Color = Color3.fromRGB(103, 92, 150);
	UIStroke_TitleSlider5.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize;
	UIStroke_TitleSlider5.LineJoinMode = Enum.LineJoinMode.Round;
	UIStroke_TitleSlider5.ZIndex = 6;
	UIStroke_TitleSlider5.Transparency = 0;
	--]]
	
	local SlapSetting2 = Instance.new("Frame", Desclabel);
	SlapSetting2.Name = "SlapSetting2";
	SlapSetting2.AnchorPoint = Vector2.new(0.5, 0.5);
	SlapSetting2.Active = true;
	SlapSetting2.BackgroundColor3 = Color3.fromRGB(35, 31, 59);
	SlapSetting2.BackgroundTransparency = 0;
	SlapSetting2.Size = UDim2.new(1, 0, 0.2, 0);
	SlapSetting2.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	if GameDetection.IsSlapBattles then
		SlapSetting2.Visible = true;
	else
		SlapSetting2.Visible = false;
	end
	SlapSetting2.ZIndex = 6;
	SlapSetting2.LayoutOrder = 5;
	local UICorner_Slap2 = Instance.new("UICorner", SlapSetting2);
	UICorner_Slap2.CornerRadius = UDim.new(0, 5);
	local Title_Slap2 = Instance.new("TextLabel", SlapSetting2);
	Title_Slap2.AnchorPoint = Vector2.new(0.5, 0);
	Title_Slap2.BackgroundTransparency = 1;
	Title_Slap2.Position = UDim2.new(0.5, 0, 0, 0);
	Title_Slap2.Size = UDim2.new(1, 0, 1, 0);
	Title_Slap2.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	Title_Slap2.Visible = true;
	Title_Slap2.ZIndex = 6;
	Title_Slap2.RichText = true;
	Title_Slap2.Text = "  Beatdown Bigger Hitbox Ability:";
	Title_Slap2.TextColor3 = Color3.fromRGB(194, 194, 194);
	Title_Slap2.TextScaled = false;
	Title_Slap2.TextSize = 18;
	Title_Slap2.TextWrapped = true;
	Title_Slap2.TextXAlignment = Enum.TextXAlignment.Left;
	Title_Slap2.TextYAlignment = Enum.TextYAlignment.Center;
	local UIPadding_TitleSlap2 = Instance.new("UIPadding", Title_Slap2);
	UIPadding_TitleSlap2.PaddingBottom = UDim.new(-0.2, 0);
	UIPadding_TitleSlap2.PaddingLeft = UDim.new(0, 0);
	UIPadding_TitleSlap2.PaddingRight = UDim.new(0, 0);
	UIPadding_TitleSlap2.PaddingTop = UDim.new(-0.2, 0);
	local Button_Slap2 = Instance.new("TextButton", Title_Slap2);
	Button_Slap2.Name = "BiggerHitbox";
	Button_Slap2.Active = true;
	Button_Slap2.AutoButtonColor = true;
	Button_Slap2.AnchorPoint = Vector2.new(0.5, 0.5);
	Button_Slap2.BackgroundColor3 = Color3.fromRGB(70, 60, 95);
	Button_Slap2.BackgroundTransparency = 0.55;
	Button_Slap2.Position = UDim2.new(0.85, 0, 0.5, 0);
	Button_Slap2.Size = UDim2.new(0, 200, 0, 31);
	Button_Slap2.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	Button_Slap2.Visible = true;
	Button_Slap2.ZIndex = 6;
	Button_Slap2.Font = Enum.Font.Oswald;
	Button_Slap2.FontFace.Weight = Enum.FontWeight.Bold;
	Button_Slap2.FontFace.Style = Enum.FontStyle.Italic;
	Button_Slap2.Text = "Disabled";
	Button_Slap2.TextColor3 = Color3.fromRGB(214, 214, 214);
	Button_Slap2.RichText = true;
	Button_Slap2.TextScaled = true;
	Button_Slap2.TextWrapped = true;
	Button_Slap2.TextXAlignment = Enum.TextXAlignment.Center;
	Button_Slap2.TextYAlignment = Enum.TextYAlignment.Center;
	local UICorner_ButtonSlap2 = Instance.new("UICorner", Button_Slap2);
	UICorner_ButtonSlap2.CornerRadius = UDim.new(0, 5);
	local UIStroke_ButtonSlap2 = Instance.new("UIStroke", Button_Slap2);
	UIStroke_ButtonSlap2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	UIStroke_ButtonSlap2.BorderStrokePosition = Enum.BorderStrokePosition.Outer;
	UIStroke_ButtonSlap2.Thickness = 2.9;
	UIStroke_ButtonSlap2.Color = Color3.fromRGB(103, 92, 150);
	UIStroke_ButtonSlap2.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize;
	UIStroke_ButtonSlap2.LineJoinMode = Enum.LineJoinMode.Round;
	UIStroke_ButtonSlap2.Transparency = 0;
	--]]

	--[ Slap Battles Settings
	if GameDetection.IsSlapBattles then
		local Separator = Instance.new("Frame", Desclabel);
		Separator.Name = "Separator";
		Separator.AnchorPoint = Vector2.new(0.5, 0.5);
		Separator.BackgroundColor3 = Color3.fromRGB(113, 84, 255);
		Separator.BackgroundTransparency = 0.3;
		Separator.Size = UDim2.new(1, -20, 0.01, 0);
		Separator.SizeConstraint = Enum.SizeConstraint.RelativeXY;
		Separator.Visible = true;
		Separator.ZIndex = 6;
		Separator.LayoutOrder = 2;
		local UICorner_Separator = Instance.new("UICorner", Separator);
		UICorner_Separator.CornerRadius = UDim.new(0, 5);
		local SectionTitle = Instance.new("TextLabel", Desclabel);
		SectionTitle.Name = "SectionTitle";
		SectionTitle.AnchorPoint = Vector2.new(0, 0);
		SectionTitle.BackgroundTransparency = 1;
		SectionTitle.Position = UDim2.new(0, 0, 0, 0);
		SectionTitle.Size = UDim2.new(1, 0, 0.1, 20);
		SectionTitle.SizeConstraint = Enum.SizeConstraint.RelativeXY;
		SectionTitle.Visible = true;
		SectionTitle.ZIndex = 6;
		SectionTitle.LayoutOrder = 3;
		SectionTitle.Font = Enum.Font.Oswald;
		SectionTitle.Text = "  Slap Battles Features:";
		SectionTitle.TextColor3 = Color3.fromRGB(113, 84, 255);
		SectionTitle.TextScaled = true;
		SectionTitle.TextWrapped = true;
		SectionTitle.TextXAlignment = Enum.TextXAlignment.Left;
		SectionTitle.TextYAlignment = Enum.TextYAlignment.Center;
		local SlapSetting1 = Instance.new("Frame", Desclabel);
		SlapSetting1.Name = "SlapSetting1";
		SlapSetting1.AnchorPoint = Vector2.new(0.5, 0.5);
		SlapSetting1.Active = true;
		SlapSetting1.BackgroundColor3 = Color3.fromRGB(35, 31, 59);
		SlapSetting1.BackgroundTransparency = 0;
		SlapSetting1.Size = UDim2.new(1, 0, 0.2, 0);
		SlapSetting1.SizeConstraint = Enum.SizeConstraint.RelativeXY;
		SlapSetting1.Visible = true;
		SlapSetting1.ZIndex = 6;
		SlapSetting1.LayoutOrder = 4;
		local UICorner_Slap1 = Instance.new("UICorner", SlapSetting1);
		UICorner_Slap1.CornerRadius = UDim.new(0, 5);
		local Title_Slap1 = Instance.new("TextLabel", SlapSetting1);
		Title_Slap1.AnchorPoint = Vector2.new(0.5, 0);
		Title_Slap1.BackgroundTransparency = 1;
		Title_Slap1.Position = UDim2.new(0.5, 0, 0, 0);
		Title_Slap1.Size = UDim2.new(1, 0, 1, 0);
		Title_Slap1.SizeConstraint = Enum.SizeConstraint.RelativeXY;
		Title_Slap1.Visible = true;
		Title_Slap1.ZIndex = 6;
		Title_Slap1.RichText = true;
		Title_Slap1.Text = " Custom Beatdown Stand:"
		Title_Slap1.TextColor3 = Color3.fromRGB(194, 194, 194);
		Title_Slap1.TextScaled = false;
		Title_Slap1.TextSize = 18;
		Title_Slap1.TextWrapped = true;
		Title_Slap1.TextXAlignment = Enum.TextXAlignment.Left;
		Title_Slap1.TextYAlignment = Enum.TextYAlignment.Center;
		local UIPadding_TitleSlap1 = Instance.new("UIPadding", Title_Slap1);
		UIPadding_TitleSlap1.PaddingBottom = UDim.new(-0.2, 0);
		UIPadding_TitleSlap1.PaddingLeft = UDim.new(0, 0);
		UIPadding_TitleSlap1.PaddingRight = UDim.new(0, 0);
		UIPadding_TitleSlap1.PaddingTop = UDim.new(-0.2, 0);
		Button_Slap1 = Instance.new("TextButton", Title_Slap1);
		Button_Slap1.Name = "BeatdownOverwrite";
		Button_Slap1.Active = true;
		Button_Slap1.AutoButtonColor = true;
		Button_Slap1.AnchorPoint = Vector2.new(0.5, 0.5);
		Button_Slap1.BackgroundColor3 = Color3.fromRGB(70, 60, 95);
		Button_Slap1.BackgroundTransparency = 0.55;
		Button_Slap1.Position = UDim2.new(0.85, 0, 0.5, 0);
		Button_Slap1.Size = UDim2.new(0, 200, 0, 31);
		Button_Slap1.SizeConstraint = Enum.SizeConstraint.RelativeXY;
		Button_Slap1.Visible = true;
		Button_Slap1.ZIndex = 6;
		Button_Slap1.Font = Enum.Font.Oswald;
		Button_Slap1.FontFace.Weight = Enum.FontWeight.Bold;
		Button_Slap1.FontFace.Style = Enum.FontStyle.Italic;
		Button_Slap1.Text = "Disabled";
		Button_Slap1.TextColor3 = Color3.fromRGB(214, 214, 214);
		Button_Slap1.RichText = true;
		Button_Slap1.TextScaled = true;
		Button_Slap1.TextWrapped = true;
		Button_Slap1.TextXAlignment = Enum.TextXAlignment.Center;
		Button_Slap1.TextYAlignment = Enum.TextYAlignment.Center;
		local UICorner_ButtonSlap1 = Instance.new("UICorner", Button_Slap1);
		UICorner_ButtonSlap1.CornerRadius = UDim.new(0, 5);
		local UIStroke_ButtonSlap1 = Instance.new("UIStroke", Button_Slap1);
		UIStroke_ButtonSlap1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
		UIStroke_ButtonSlap1.BorderStrokePosition = Enum.BorderStrokePosition.Outer;
		UIStroke_ButtonSlap1.Thickness = 2.9;
		UIStroke_ButtonSlap1.Color = Color3.fromRGB(103, 92, 150);
		UIStroke_ButtonSlap1.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize;
		UIStroke_ButtonSlap1.LineJoinMode = Enum.LineJoinMode.Round;
		UIStroke_ButtonSlap1.ZIndex = 6;
		UIStroke_ButtonSlap1.Transparency = 0;
	end
	--]]
	local TitleDesc = Instance.new("TextLabel", Settings);
	TitleDesc.AnchorPoint = Vector2.new(0.5, 0);
	TitleDesc.Active = true;
	TitleDesc.LayoutOrder = 3;
	TitleDesc.Name = "Title";
	TitleDesc.Position = UDim2.new(0.5, 0, 0, 0);
	TitleDesc.Size = UDim2.new(1, 0, 0.1, 15);
	TitleDesc.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	TitleDesc.Visible = true;
	TitleDesc.ZIndex = 6;
	TitleDesc.Font = Enum.Font.Oswald;
	TitleDesc.Text = "Settings";
	TitleDesc.TextColor3 = Color3.fromRGB(113, 84, 255);
	TitleDesc.TextScaled = true;
	TitleDesc.TextWrapped = true;
	TitleDesc.TextXAlignment = Enum.TextXAlignment.Left;
	TitleDesc.TextYAlignment = Enum.TextYAlignment.Center;
	TitleDesc.BackgroundTransparency = 1;
	local UIPadding_Title = Instance.new("UIPadding", TitleDesc);
	UIPadding_Title.PaddingBottom = UDim.new(-0.2, 0);
	UIPadding_Title.PaddingLeft = UDim.new(0, 0);
	UIPadding_Title.PaddingRight = UDim.new(0, 0);
	UIPadding_Title.PaddingTop = UDim.new(-0.2, 0);
	local TitleDescInfo = Instance.new("TextLabel", Settings);
	TitleDescInfo.AnchorPoint = Vector2.new(0.5, 0);
	TitleDescInfo.Active = true;
	TitleDescInfo.LayoutOrder = 3;
	TitleDescInfo.Name = "DescInfo";
	TitleDescInfo.Position = UDim2.new(0.5, 0, 0.94, 0);
	TitleDescInfo.Size = UDim2.new(1.021, 0, 0.15, 15);
	TitleDescInfo.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	TitleDescInfo.Visible = true;
	TitleDescInfo.ZIndex = 6;
	TitleDescInfo.Font = Enum.Font.Oswald;
	TitleDescInfo.TextScaled = true;
	TitleDescInfo.TextXAlignment = Enum.TextXAlignment.Left;
	TitleDescInfo.TextYAlignment = Enum.TextYAlignment.Center;
	if lpr.UserId == 1913241216 then
		TitleDescInfo.Text = "Credits to Sky_Attacker for making best script and the most OverPower for Dracule |  Version: "..tostring(BuildVersion);
	elseif lpr.UserId == 4314696588 then
		TitleDescInfo.Text = "Credits to Your Uncle for Amazing ideas and apply them to Real Tweaking SB |  Version: "..tostring(BuildVersion);
	else
		TitleDescInfo.Text = "Made By Sky_Attacker. Version: "..tostring(BuildVersion);
		TitleDescInfo.TextScaled = false;
		TitleDescInfo.TextSize = 48;
		TitleDescInfo.TextXAlignment = Enum.TextXAlignment.Center;
		TitleDescInfo.TextYAlignment = Enum.TextYAlignment.Bottom
	end
	TitleDescInfo.TextColor3 = Color3.fromRGB(113, 84, 255);
	TitleDescInfo.TextWrapped = true;
	TitleDescInfo.BackgroundTransparency = 1;
	local UIPadding_TitleInfo = Instance.new("UIPadding", TitleDescInfo);
	UIPadding_TitleInfo.PaddingBottom = UDim.new(-0.2, 0);
	UIPadding_TitleInfo.PaddingLeft = UDim.new(0, 0);
	UIPadding_TitleInfo.PaddingRight = UDim.new(0, 0);
	UIPadding_TitleInfo.PaddingTop = UDim.new(-0.2, 0);
	copyrightLabel = Instance.new("TextLabel")
	copyrightLabel.Size = UDim2.new(0, 200, 0, 20)
	copyrightLabel.Position = UDim2.new(1, -210, 1, -30)
	copyrightLabel.BackgroundTransparency = 1
	copyrightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyrightLabel.TextScaled = true
	if lpr.UserId == 4314696588 then
		copyrightLabel.Text = "Made By Sky_Attacker | "..tostring(versionLabel)
		copyrightLabel.TextScaled = false;
	elseif lpr.UserId == 1913241216 then
		copyrightLabel.Text = "Credits To King_Dracule"
	else
		copyrightLabel.Text = "Made Specially For KING_DRACULE"
	end
	copyrightLabel.ZIndex = 6250
	copyrightLabel.Parent = TranslationUI
	local Camera = game.Workspace.Camera

	-- [ Custom Camera Cutsence For Refraif:
	local function InstanceBeatdownCamPosToRepStorage()
		local Assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
		local Beatdown = Assets and Assets:FindFirstChild("Beatdown")
		local BeatdownStand = Beatdown and Beatdown:FindFirstChild("Stand")
		if not BeatdownStand then
			warn("Beatdown Stand not found in ReplicatedStorage!")
			return false
		end
		local AttachmentHolder = BeatdownStand:FindFirstChild("CameraAttachments") or Instance.new("Model")
		AttachmentHolder.Name = "CameraAttachments"
		AttachmentHolder.Parent = BeatdownStand
		local rootAttachment = BeatdownStand:FindFirstChild("RootAttachment") or Instance.new("Attachment")
		rootAttachment.Name = "RootAttachment"
		rootAttachment.Parent = BeatdownStand:FindFirstChild("HumanoidRootPart") or BeatdownStand:FindFirstChildWhichIsA("BasePart")
		local Attach1 = AttachmentHolder:FindFirstChild("CamAttach1")
		local Attach2 = AttachmentHolder:FindFirstChild("CamAttach2")
		local Attach3 = AttachmentHolder:FindFirstChild("CamAttach3")
		local Attach4 = AttachmentHolder:FindFirstChild("CamAttach4")
		local Attach5 = AttachmentHolder:FindFirstChild("CamAttach5")
		local Attach6 = AttachmentHolder:FindFirstChild("CamAttach6")
		local Attach7 = AttachmentHolder:FindFirstChild("CamAttach7")
		local Attach8 = AttachmentHolder:FindFirstChild("CamAttach8")
		local Attach9 = AttachmentHolder:FindFirstChild("CamAttach9")
		local Attach10 = AttachmentHolder:FindFirstChild("CamAttach10")
		local Attach11 = AttachmentHolder:FindFirstChild("CamAttach11")
		local Attach12 = AttachmentHolder:FindFirstChild("CamAttach12")
		local Attach13 = AttachmentHolder:FindFirstChild("CamAttach13")
		if not (Attach1 and Attach2 and Attach3 and Attach4 and Attach5 and Attach6 and Attach7 and Attach8 and Attach9 and Attach10 and Attach11 and Attach12 and Attach13) then
			if SettingsScript and SettingsScript.DisplayLogs then
				warn("Creating custom Camera Attachments for Beatdown in ReplicatedStorage!")
			end
			for i = 1, 13 do
				local existing = AttachmentHolder:FindFirstChild("CamAttach" .. i)
				if existing then
					existing:Destroy()
				end
			end
			local attachmentData = {
				{pos = Vector3.new(76.384, 4.617, 433.754), rot = Vector3.new(-3.197, -15.144, 0.481)},
				{pos = Vector3.new(85.458, 4.942, 428.867), rot = Vector3.new(-2.66, 37.874, 0)},
				{pos = Vector3.new(85.844, 6.175, 409.104), rot = Vector3.new(-3.54, 69.392, -2.047)},
				{pos = Vector3.new(91.316, 4.447, 418.794), rot = Vector3.new(-3.008, 89.298, 0)},
				{pos = Vector3.new(91.395, 4.439, 414.2), rot = Vector3.new(-2.792, 87.713, 0)},
				{pos = Vector3.new(91.56, 4.402, 418.296), rot = Vector3.new(-1.279, 89.439, 0)},
				{pos = Vector3.new(91.61, 4.391, 413.21), rot = Vector3.new(-0.955, 89.439, 0)},
				{pos = Vector3.new(91.558, 4.391, 418.524), rot = Vector3.new(-0.955, 89.439, 0)},
				{pos = Vector3.new(91.606, 4.391, 412.604), rot = Vector3.new(-0.951, 94.44, -0.083)},
				{pos = Vector3.new(89.398, 4.355, 423.068), rot = Vector3.new(-0.897, 109.442, -0.327)},
				{pos = Vector3.new(88.688, 4.344, 426.087), rot = Vector3.new(-0.897, 69.436, 0.327)},
				{pos = Vector3.new(73.728, 4.484, 421.339), rot = Vector3.new(-87.519, 33.425, 14.581)},
				{pos = Vector3.new(81.294, 5.902, 411.681), rot = Vector3.new(-85.648, 49.982, -60.239)}
			}
			local basePos = attachmentData[1].pos
			for i, data in ipairs(attachmentData) do
				local attachment = Instance.new("Attachment")
				attachment.Name = "CamAttach" .. i
				local relativePos = data.pos - basePos
				attachment.Position = relativePos
				local rotRad = Vector3.new(math.rad(data.rot.X), math.rad(data.rot.Y), math.rad(data.rot.Z))
				local rotCF = CFrame.Angles(rotRad.X, rotRad.Y, rotRad.Z)
				attachment.Orientation = rotCF.LookVector
				attachment.Axis = rotCF.LookVector
				attachment.SecondaryAxis = rotCF.UpVector
				attachment.Visible = true
				attachment.Parent = AttachmentHolder
			end

			if SettingsScript and SettingsScript.DisplayLogs then
				print("All Camera Attachments created successfully in ReplicatedStorage")
			end
			return true
		else
			if SettingsScript and SettingsScript.DisplayLogs then
				print("All Camera Attachments already exist in ReplicatedStorage")
			end
			return true
		end
	end

	local function CloneAttachmentsToStand(stand)
		if not stand then
			warn("Stand is nil. Cannot clone Attachments.")
			return false
		end
		local success = InstanceBeatdownCamPosToRepStorage()
		if not success then
			warn("Failed to create attachments in ReplicatedStorage")
			return false
		end
		local Assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
		local BeatdownFolder = Assets and Assets:FindFirstChild("Beatdown")
		local BeatdownStand = BeatdownFolder and BeatdownFolder:FindFirstChild("Stand")
		local sourceAttachmentHolder = BeatdownStand and BeatdownStand:FindFirstChild("CameraAttachments")
		if not sourceAttachmentHolder then
			warn("CameraAttachments not found in ReplicatedStorage")
			return false
		end
		local basePart = stand:FindFirstChild("HumanoidRootPart") or stand:FindFirstChildWhichIsA("BasePart")
		if not basePart then
			warn("No BasePart found in stand to parent attachments")
			return false
		end
		local attachmentFolder = stand:FindFirstChild("CameraAttachments")
		if not attachmentFolder then
			attachmentFolder = Instance.new("Folder")
			attachmentFolder.Name = "CameraAttachments"
			attachmentFolder.Parent = stand
		end
		for i = 1, 13 do
			local existing = attachmentFolder:FindFirstChild("CamAttach" .. i)
			if existing then
				existing:Destroy()
			end
		end
		local rootAttachment = basePart:FindFirstChild("RootAttachment")
		if not rootAttachment then
			rootAttachment = Instance.new("Attachment")
			rootAttachment.Name = "RootAttachment"
			rootAttachment.Parent = basePart
		end
		for i = 1, 13 do
			local sourceAttach = sourceAttachmentHolder:FindFirstChild("CamAttach" .. i)
			if sourceAttach and sourceAttach:IsA("Attachment") then
				local clonedAttach = sourceAttach:Clone()
				clonedAttach.Name = "CamAttach" .. i
				clonedAttach.Parent = basePart
				local reference = Instance.new("ObjectValue")
				reference.Name = "CamAttachRef" .. i
				reference.Value = clonedAttach
				reference.Parent = attachmentFolder
			else
				warn("CamAttach" .. i .. " not found in ReplicatedStorage")
			end
		end

		print("Camera Attachments cloned and parented to base part successfully")
		return true
	end

	-- Update the GetCameraCFrameFromAttachment function
	local function GetCameraCFrameFromAttachment(stand, attachName)
		for _, descendant in ipairs(stand:GetDescendants()) do
			if descendant:IsA("Attachment") and descendant.Name == attachName then
				return descendant.WorldCFrame
			end
		end
		local attachmentFolder = stand:FindFirstChild("CameraAttachments")
		if attachmentFolder then
			local ref = attachmentFolder:FindFirstChild("CamAttachRef" .. attachName:match("%d+"))
			if ref and ref:IsA("ObjectValue") and ref.Value then
				return ref.Value.WorldCFrame
			end
		end

		return nil
	end

	-- CutsenceRefraifPos
	local CutsenceRefraifPosActive = false
	--]]

	--[ FUNCTIONS
	-- Beatdown Functions:
	local function periodicCleanup()
		local colorCorrectionCount = 0
		local colorCorrectionEffects = {}
		for _, child in ipairs(game.Lighting:GetChildren()) do
			if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
				colorCorrectionCount = colorCorrectionCount + 1
				table.insert(colorCorrectionEffects, child)
			end
		end
		if colorCorrectionCount > 1 then
			print("Found", colorCorrectionCount, "ColorCorrection effects. Cleaning up extras...")
			for i = 2, #colorCorrectionEffects do
				colorCorrectionEffects[i]:Destroy()
				if SettingsScript.DisplayLogs then
					print("Cleanup ColorCorrectionEffect")
				end
			end
			if #colorCorrectionEffects > 0 and colorCorrectionEffects[1].Parent then
				ColorCorrectionSystem.globalColorCorrection = colorCorrectionEffects[1]
			end
		end
	end
	-- White
	local function initializeColorCorrection()
		-- First, check for ALL existing ColorCorrection effects and clean them up
		for _, child in ipairs(game.Lighting:GetChildren()) do
			if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
				child:Destroy()
			end
		end

		-- Clean up any existing tweens
		if ColorCorrectionSystem.startTween then
			ColorCorrectionSystem.startTween:Cancel()
			ColorCorrectionSystem.startTween = nil
		end
		if ColorCorrectionSystem.endTween then
			ColorCorrectionSystem.endTween:Cancel()
			ColorCorrectionSystem.endTween = nil
		end

		-- Create new ColorCorrection effect
		ColorCorrectionSystem.globalColorCorrection = Instance.new("ColorCorrectionEffect", game.Lighting)
		ColorCorrectionSystem.globalColorCorrection.Name = "CutsenseJoJo_Kebaited_Global"
		ColorCorrectionSystem.globalColorCorrection.Saturation = 0
		ColorCorrectionSystem.globalColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
		ColorCorrectionSystem.globalColorCorrection.Enabled = true

		-- Create new tweens
		ColorCorrectionSystem.startTween = l__TweenService__5:Create(ColorCorrectionSystem.globalColorCorrection, TweenInfo.new(
			1.5, -- Duration
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = -1,
				Brightness = -0.25,
				Contrast = 1,
				TintColor = Color3.fromRGB(255, 255, 255)
			})

		ColorCorrectionSystem.endTween = l__TweenService__5:Create(ColorCorrectionSystem.globalColorCorrection, TweenInfo.new(
			1.5, -- Duration
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0,
				Brightness = 0,
				Contrast = 0,
				TintColor = Color3.fromRGB(255, 255, 255)
			})

		--print("ColorCorrection initialized -> ", tostring(ColorCorrectionSystem.globalColorCorrection))
		return ColorCorrectionSystem.globalColorCorrection
	end

	local function startColorCorrectionEffect()
		-- Check for existing ColorCorrection effects FIRST
		local existingEffects = {}
		for _, child in ipairs(game.Lighting:GetChildren()) do
			if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
				table.insert(existingEffects, child)
			end
		end

		-- If multiple exist, destroy all and create fresh
		if #existingEffects > 1 then
			for _, effect in ipairs(existingEffects) do
				effect:Destroy()
			end
			-- Force reinitialization
			ColorCorrectionSystem.globalColorCorrection = nil
		end

		-- If no global reference or effect is destroyed, initialize
		if not ColorCorrectionSystem.globalColorCorrection or not ColorCorrectionSystem.globalColorCorrection.Parent then
			initializeColorCorrection()
		else
			-- Reset to initial state
			ColorCorrectionSystem.globalColorCorrection.Saturation = 0
			ColorCorrectionSystem.globalColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
		end

		PlayedActionLIGHT = true
		--print("PlayedActionLIGHT -> true")
		-- Cancel any running tweens
		if ColorCorrectionSystem.startTween and ColorCorrectionSystem.startTween.PlaybackState == Enum.PlaybackState.Playing then
			ColorCorrectionSystem.startTween:Cancel()
		end
		if ColorCorrectionSystem.endTween and ColorCorrectionSystem.endTween.PlaybackState == Enum.PlaybackState.Playing then
			ColorCorrectionSystem.endTween:Cancel()
		end

		-- Create new tweens to ensure they're fresh
		ColorCorrectionSystem.startTween = l__TweenService__5:Create(ColorCorrectionSystem.globalColorCorrection, TweenInfo.new(
			1.5,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = -1,
				Brightness = -0.25,
				Contrast = 1,
				TintColor = Color3.fromRGB(255, 255, 255)
			})

		ColorCorrectionSystem.startTween:Play()
		--print("ColorCorrection effect started (Nukem SOUND)")
	end

	local function endColorCorrectionEffect()
		if not PlayedActionLIGHT then
			--print("Requested")
			for _, child in ipairs(game.Lighting:GetChildren()) do
				if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
					child:Destroy()
					if SettingsScript.DisplayLogs then
						print("Destroyed stray ColorCorrection effect | FAKE")
					end
				end
			end
			--print("Unexpected return | because using Function endColorCorrectionEffect(); and PlayedActionLIGHT set to false. ")
			return 
		end
		local actualColorCorrection = game.Lighting:FindFirstChild("CutsenseJoJo_Kebaited_Global")
		if not actualColorCorrection then
			for _, child in ipairs(game.Lighting:GetChildren()) do
				if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
					actualColorCorrection = child
					--print("Found stray ColorCorrection effect")
					break
				end
			end
		end

		if not actualColorCorrection then
			PlayedActionLIGHT = false
			--print("No ColorCorrection effect found")
			return
		end

		-- Update global reference
		ColorCorrectionSystem.globalColorCorrection = actualColorCorrection

		-- Cancel start tween if playing
		if ColorCorrectionSystem.startTween and ColorCorrectionSystem.startTween.PlaybackState == Enum.PlaybackState.Playing then
			ColorCorrectionSystem.startTween:Cancel()
			if SettingsScript.DisplayLogs then
				print("Cancelled start tween")
			end
		end
		ColorCorrectionSystem.endTween = l__TweenService__5:Create(actualColorCorrection, TweenInfo.new(
			1.5,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0,
				Brightness = 0,
				Contrast = 0,
				TintColor = Color3.fromRGB(255, 255, 255)
			})
		--print("Playing end tween...")
		ColorCorrectionSystem.endTween:Play()
		ColorCorrectionSystem.endTween.Completed:Connect(function()
			task.wait(0.1)
			for _, child in ipairs(game.Lighting:GetChildren()) do
				if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo_Kebaited_Global") then
					child:Destroy()
				end
			end
			ColorCorrectionSystem.globalColorCorrection = nil
			ColorCorrectionSystem.startTween = nil
			ColorCorrectionSystem.endTween = nil
			PlayedActionLIGHT = false
			spawn(function()
				periodicCleanup()
			end)
			--print("ColorCorrection cleanup completed")
		end)

		--print("ColorCorrection effect ended (Scream)")
	end
	-- Red
	local function initializeColorCorrectionUncle()
		-- First, check for ALL existing ColorCorrection effects and clean them up
		for _, child in ipairs(game.Lighting:GetChildren()) do
			if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
				child:Destroy()
			end
		end

		-- Clean up any existing tweens
		if ColorCorrectionSystem.startTween then
			ColorCorrectionSystem.startTween:Cancel()
			ColorCorrectionSystem.startTween = nil
		end
		if ColorCorrectionSystem.endTween then
			ColorCorrectionSystem.endTween:Cancel()
			ColorCorrectionSystem.endTween = nil
		end

		-- Create new ColorCorrection effect
		ColorCorrectionSystem.globalColorCorrection = Instance.new("ColorCorrectionEffect", game.Lighting)
		ColorCorrectionSystem.globalColorCorrection.Name = "CutsenseJoJo_Kebaited_Global"
		ColorCorrectionSystem.globalColorCorrection.Saturation = 0
		ColorCorrectionSystem.globalColorCorrection.TintColor = Color3.fromRGB(255, 0, 0)
		ColorCorrectionSystem.globalColorCorrection.Enabled = true

		-- Create new tweens
		ColorCorrectionSystem.startTween = l__TweenService__5:Create(ColorCorrectionSystem.globalColorCorrection, TweenInfo.new(
			1.5, -- Duration
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0.1,
				Brightness = -0.25,
				Contrast = 1.03,
				TintColor = Color3.fromRGB(255, 0, 0)
			})

		ColorCorrectionSystem.endTween = l__TweenService__5:Create(ColorCorrectionSystem.globalColorCorrection, TweenInfo.new(
			1.5, -- Duration
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0,
				Brightness = 0,
				Contrast = 0,
				TintColor = Color3.fromRGB(255, 255, 255)
			})

		--print("ColorCorrection initialized -> ", tostring(ColorCorrectionSystem.globalColorCorrection))
		return ColorCorrectionSystem.globalColorCorrection
	end

	local function startColorCorrectionEffectUncle()
		-- Check for existing ColorCorrection effects FIRST
		local existingEffects = {}
		for _, child in ipairs(game.Lighting:GetChildren()) do
			if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
				table.insert(existingEffects, child)
			end
		end

		-- If multiple exist, destroy all and create fresh
		if #existingEffects > 1 then
			for _, effect in ipairs(existingEffects) do
				effect:Destroy()
			end
			-- Force reinitialization
			ColorCorrectionSystem.globalColorCorrection = nil
		end

		-- If no global reference or effect is destroyed, initialize
		if not ColorCorrectionSystem.globalColorCorrection or not ColorCorrectionSystem.globalColorCorrection.Parent then
			initializeColorCorrectionUncle()
		else
			-- Reset to initial state
			ColorCorrectionSystem.globalColorCorrection.Saturation = 0
			ColorCorrectionSystem.globalColorCorrection.TintColor = Color3.fromRGB(255, 0, 0)
		end

		PlayedActionLIGHT = true
		--print("PlayedActionLIGHT -> true")
		-- Cancel any running tweens
		if ColorCorrectionSystem.startTween and ColorCorrectionSystem.startTween.PlaybackState == Enum.PlaybackState.Playing then
			ColorCorrectionSystem.startTween:Cancel()
		end
		if ColorCorrectionSystem.endTween and ColorCorrectionSystem.endTween.PlaybackState == Enum.PlaybackState.Playing then
			ColorCorrectionSystem.endTween:Cancel()
		end

		-- Create new tweens to ensure they're fresh
		ColorCorrectionSystem.startTween = l__TweenService__5:Create(ColorCorrectionSystem.globalColorCorrection, TweenInfo.new(
			1.5, -- Duration
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0.1,
				Brightness = -0.25,
				Contrast = 1.03,
				TintColor = Color3.fromRGB(255, 0, 0)
			})

		ColorCorrectionSystem.startTween:Play()
		--print("ColorCorrection effect started (Nukem SOUND)")
	end

	local function endColorCorrectionEffectUncle()
		if not PlayedActionLIGHT then
			--print("Requested")
			for _, child in ipairs(game.Lighting:GetChildren()) do
				if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
					child:Destroy()
					if SettingsScript.DisplayLogs then
						print("Destroyed stray ColorCorrection effect | FAKE")
					end
				end
			end
			--print("Unexpected return | because using Function endColorCorrectionEffect(); and PlayedActionLIGHT set to false. ")
			return 
		end
		local actualColorCorrection = game.Lighting:FindFirstChild("CutsenseJoJo_Kebaited_Global")
		if not actualColorCorrection then
			for _, child in ipairs(game.Lighting:GetChildren()) do
				if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
					actualColorCorrection = child
					--print("Found stray ColorCorrection effect")
					break
				end
			end
		end

		if not actualColorCorrection then
			PlayedActionLIGHT = false
			--print("No ColorCorrection effect found")
			return
		end

		-- Update global reference
		ColorCorrectionSystem.globalColorCorrection = actualColorCorrection

		-- Cancel start tween if playing
		if ColorCorrectionSystem.startTween and ColorCorrectionSystem.startTween.PlaybackState == Enum.PlaybackState.Playing then
			ColorCorrectionSystem.startTween:Cancel()
			if SettingsScript.DisplayLogs then
				print("Cancelled start tween")
			end
		end
		ColorCorrectionSystem.endTween = l__TweenService__5:Create(actualColorCorrection, TweenInfo.new(
			1.5,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0,
				Brightness = 0,
				Contrast = 0,
				TintColor = Color3.fromRGB(255, 255, 255)
			})
		--print("Playing end tween...")
		ColorCorrectionSystem.endTween:Play()
		ColorCorrectionSystem.endTween.Completed:Connect(function()
			task.wait(0.1)
			for _, child in ipairs(game.Lighting:GetChildren()) do
				if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo_Kebaited_Global") then
					child:Destroy()
				end
			end
			ColorCorrectionSystem.globalColorCorrection = nil
			ColorCorrectionSystem.startTween = nil
			ColorCorrectionSystem.endTween = nil
			PlayedActionLIGHT = false
			spawn(function()
				periodicCleanup()
			end)
			--print("ColorCorrection cleanup completed")
		end)

		--print("ColorCorrection effect ended (Scream)")
	end
	
	-- Red
	local function initializeColorCorrectionGalaxy()
		-- First, check for ALL existing ColorCorrection effects and clean them up
		for _, child in ipairs(game.Lighting:GetChildren()) do
			if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
				child:Destroy()
			end
		end

		-- Clean up any existing tweens
		if ColorCorrectionSystem.startTween then
			ColorCorrectionSystem.startTween:Cancel()
			ColorCorrectionSystem.startTween = nil
		end
		if ColorCorrectionSystem.endTween then
			ColorCorrectionSystem.endTween:Cancel()
			ColorCorrectionSystem.endTween = nil
		end

		-- Create new ColorCorrection effect
		ColorCorrectionSystem.globalColorCorrection = Instance.new("ColorCorrectionEffect", game.Lighting)
		ColorCorrectionSystem.globalColorCorrection.Name = "CutsenseJoJo_Kebaited_Global"
		ColorCorrectionSystem.globalColorCorrection.Saturation = 0
		ColorCorrectionSystem.globalColorCorrection.TintColor = Color3.fromRGB(209, 209, 209)
		ColorCorrectionSystem.globalColorCorrection.Enabled = true

		-- Create new tweens
		ColorCorrectionSystem.startTween = l__TweenService__5:Create(ColorCorrectionSystem.globalColorCorrection, TweenInfo.new(
			1.5, -- Duration
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0.1,
				Brightness = 0.1,
				Contrast = 1.03,
				TintColor = Color3.fromRGB(163, 29, 161)
			})

		ColorCorrectionSystem.endTween = l__TweenService__5:Create(ColorCorrectionSystem.globalColorCorrection, TweenInfo.new(
			1.5, -- Duration
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0,
				Brightness = 0,
				Contrast = 0,
				TintColor = Color3.fromRGB(255, 255, 255)
			})

		--print("ColorCorrection initialized -> ", tostring(ColorCorrectionSystem.globalColorCorrection))
		return ColorCorrectionSystem.globalColorCorrection
	end

	local function startColorCorrectionEffectGalaxy()
		-- Check for existing ColorCorrection effects FIRST
		local existingEffects = {}
		for _, child in ipairs(game.Lighting:GetChildren()) do
			if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
				table.insert(existingEffects, child)
			end
		end

		-- If multiple exist, destroy all and create fresh
		if #existingEffects > 1 then
			for _, effect in ipairs(existingEffects) do
				effect:Destroy()
			end
			-- Force reinitialization
			ColorCorrectionSystem.globalColorCorrection = nil
		end

		-- If no global reference or effect is destroyed, initialize
		if not ColorCorrectionSystem.globalColorCorrection or not ColorCorrectionSystem.globalColorCorrection.Parent then
			initializeColorCorrectionGalaxy()
		else
			-- Reset to initial state
			ColorCorrectionSystem.globalColorCorrection.Saturation = 0
			ColorCorrectionSystem.globalColorCorrection.TintColor = Color3.fromRGB(163, 29, 161)
		end

		PlayedActionLIGHT = true
		--print("PlayedActionLIGHT -> true")
		-- Cancel any running tweens
		if ColorCorrectionSystem.startTween and ColorCorrectionSystem.startTween.PlaybackState == Enum.PlaybackState.Playing then
			ColorCorrectionSystem.startTween:Cancel()
		end
		if ColorCorrectionSystem.endTween and ColorCorrectionSystem.endTween.PlaybackState == Enum.PlaybackState.Playing then
			ColorCorrectionSystem.endTween:Cancel()
		end

		-- Create new tweens to ensure they're fresh
		ColorCorrectionSystem.startTween = l__TweenService__5:Create(ColorCorrectionSystem.globalColorCorrection, TweenInfo.new(
			1.5, -- Duration
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0.1,
				Brightness = 0.1,
				Contrast = 1.03,
				TintColor = Color3.fromRGB(163, 29, 161)
			})

		ColorCorrectionSystem.startTween:Play()
		--print("ColorCorrection effect started (Nukem SOUND)")
	end

	local function endColorCorrectionEffectGalaxy()
		if not PlayedActionLIGHT then
			--print("Requested")
			for _, child in ipairs(game.Lighting:GetChildren()) do
				if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
					child:Destroy()
					if SettingsScript.DisplayLogs then
						print("Destroyed stray ColorCorrection effect | FAKE")
					end
				end
			end
			--print("Unexpected return | because using Function endColorCorrectionEffect(); and PlayedActionLIGHT set to false. ")
			return 
		end
		local actualColorCorrection = game.Lighting:FindFirstChild("CutsenseJoJo_Kebaited_Global")
		if not actualColorCorrection then
			for _, child in ipairs(game.Lighting:GetChildren()) do
				if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo") then
					actualColorCorrection = child
					--print("Found stray ColorCorrection effect")
					break
				end
			end
		end

		if not actualColorCorrection then
			PlayedActionLIGHT = false
			--print("No ColorCorrection effect found")
			return
		end

		-- Update global reference
		ColorCorrectionSystem.globalColorCorrection = actualColorCorrection

		-- Cancel start tween if playing
		if ColorCorrectionSystem.startTween and ColorCorrectionSystem.startTween.PlaybackState == Enum.PlaybackState.Playing then
			ColorCorrectionSystem.startTween:Cancel()
			if SettingsScript.DisplayLogs then
				print("Cancelled start tween")
			end
		end
		ColorCorrectionSystem.endTween = l__TweenService__5:Create(actualColorCorrection, TweenInfo.new(
			1.5,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
			), {
				Saturation = 0,
				Brightness = 0,
				Contrast = 0,
				TintColor = Color3.fromRGB(255, 255, 255)
			})
		--print("Playing end tween...")
		ColorCorrectionSystem.endTween:Play()
		ColorCorrectionSystem.endTween.Completed:Connect(function()
			task.wait(0.1)
			for _, child in ipairs(game.Lighting:GetChildren()) do
				if child:IsA("ColorCorrectionEffect") and child.Name:find("CutsenseJoJo_Kebaited_Global") then
					child:Destroy()
				end
			end
			ColorCorrectionSystem.globalColorCorrection = nil
			ColorCorrectionSystem.startTween = nil
			ColorCorrectionSystem.endTween = nil
			PlayedActionLIGHT = false
			spawn(function()
				periodicCleanup()
			end)
			--print("ColorCorrection cleanup completed")
		end)

		--print("ColorCorrection effect ended (Scream)")
	end
	
	local function loadModelIntoViewport(modelId)
		if not CustomBeatdownUI then return end
		local viewport = CustomBeatdownUI:FindFirstChild("ContentContainer"):FindFirstChild("ModelPreviewContainer"):FindFirstChild("ViewportFrame")
		if not viewport then return end
		for _, child in ipairs(viewport:GetChildren()) do
			if child:IsA("Model") or child:IsA("BasePart") then
				child:Destroy()
			end
		end
		local selectedModelData = nil
		for _, model in ipairs(CustomBeatdownModels) do
			if model.id == modelId then
				selectedModelData = model
				break
			end
		end
		if not selectedModelData then return end
		local standModel = Instance.new("Model")
		standModel.Name = "PreviewStand"
		local bodyParts = {
			{Name = "Head", Size = Vector3.new(2, 1, 1), Position = Vector3.new(0, 1.5, 0)},
			{Name = "Torso", Size = Vector3.new(2, 2, 1), Position = Vector3.new(0, 0, 0)},
			{Name = "Left Arm", Size = Vector3.new(1, 2, 1), Position = Vector3.new(-1.5, 0, 0)},
			{Name = "Right Arm", Size = Vector3.new(1, 2, 1), Position = Vector3.new(1.5, 0, 0)},
			{Name = "Left Leg", Size = Vector3.new(1, 2, 1), Position = Vector3.new(-0.5, -2, 0)},
			{Name = "Right Leg", Size = Vector3.new(1, 2, 1), Position = Vector3.new(0.5, -2, 0)}
		}
		for _, partData in ipairs(bodyParts) do
			local part = Instance.new("Part")
			part.Name = partData.Name
			part.Size = partData.Size
			part.Position = partData.Position
			part.Anchored = true
			part.CanCollide = false
			part.Color = selectedModelData.color
			part.Material = selectedModelData.material
			if selectedModelData.transparency then
				part.Transparency = selectedModelData.transparency
			end
			if selectedModelData.id == "angelic_beatdown" then
				part.Color = Color3.fromRGB(255, 255, 255)
				part.Material = Enum.Material.Neon
				part.Transparency = 0.1
				if part.Name == "Torso" or part.Name:find("Leg") or part.Name:find("Arm") then
				end
			end
			if part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Head" then
				local fire = Instance.new("Fire")
				fire.Color = selectedModelData.fireColor
				fire.SecondaryColor = selectedModelData.fireColor
				fire.Size = 2.5
				fire.Heat = 5
				fire.Parent = part
				fire.Name = "FireEffect"
			end
			part.Parent = standModel
		end
		local rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Position = Vector3.new(0, 0, 0)
		rootPart.Anchored = true
		rootPart.CanCollide = false
		rootPart.Transparency = 1
		rootPart.Parent = standModel
		standModel.PrimaryPart = rootPart
		standModel.Parent = viewport
		if not ViewportCamera then
			ViewportCamera = Instance.new("Camera")
			ViewportCamera.Parent = viewport
			viewport.CurrentCamera = ViewportCamera
		end
		ViewportCamera.CFrame = CFrame.new(Vector3.new(0, 1, 8), Vector3.new(0, 1, 0))
		if selectedModelData.specialEffects then
			pcall(function()
				selectedModelData.specialEffects(standModel:GetChildren())
			end)
		end
		ViewportModel = standModel
	end
	local function createCustomBeatdownUI()
		if CustomBeatdownUI then return CustomBeatdownUI end
		CustomBeatdownUI = Instance.new("Frame", MainFrame)
		CustomBeatdownUI.Name = "CustomBeatdownUI"
		CustomBeatdownUI.AnchorPoint = Vector2.new(0.5, 0.5)
		CustomBeatdownUI.BackgroundTransparency = 0.15
		CustomBeatdownUI.BackgroundColor3 = Color3.fromRGB(17, 17, 38)
		CustomBeatdownUI.Active = true
		CustomBeatdownUI.BorderColor3 = Color3.fromRGB(41, 27, 53)
		CustomBeatdownUI.LayoutOrder = 4
		CustomBeatdownUI.Position = UDim2.new(0.5, 0, 0.5, 0)
		CustomBeatdownUI.Size = UDim2.new(0.8, 0, 0.85, 0)
		CustomBeatdownUI.SizeConstraint = Enum.SizeConstraint.RelativeXY
		CustomBeatdownUI.ZIndex = 6
		CustomBeatdownUI.Visible = false
		CustomBeatdownUI.ClipsDescendants = true
		local UICorner_CustomBeatdownUI = Instance.new("UICorner", CustomBeatdownUI)
		UICorner_CustomBeatdownUI.CornerRadius = UDim.new(0, 15)
		local UIPadding_CustomBeatdownUI = Instance.new("UIPadding", CustomBeatdownUI)
		UIPadding_CustomBeatdownUI.PaddingBottom = UDim.new(0.025, 0)
		UIPadding_CustomBeatdownUI.PaddingLeft = UDim.new(0.02, 0)
		UIPadding_CustomBeatdownUI.PaddingRight = UDim.new(0.02, 0)
		UIPadding_CustomBeatdownUI.PaddingTop = UDim.new(0.02, 0)
		local UIStroke_CustomBeatdownUI = Instance.new("UIStroke", CustomBeatdownUI)
		UIStroke_CustomBeatdownUI.Color = Color3.fromRGB(113, 84, 255)
		UIStroke_CustomBeatdownUI.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		UIStroke_CustomBeatdownUI.BorderStrokePosition = Enum.BorderStrokePosition.Outer
		UIStroke_CustomBeatdownUI.Thickness = 4.3
		UIStroke_CustomBeatdownUI.Transparency = 0.33
		local Title = Instance.new("TextLabel", CustomBeatdownUI)
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0, 0)
		Title.Size = UDim2.new(1, 0, 0.07, 0)
		Title.Font = Enum.Font.Oswald
		Title.Text = "CUSTOM BEATDOWN MODELS"
		Title.TextColor3 = Color3.fromRGB(113, 84, 255)
		Title.TextScaled = true
		Title.TextWrapped = true
		Title.TextXAlignment = Enum.TextXAlignment.Center
		Title.ZIndex = 6
		local Subtitle = Instance.new("TextLabel", CustomBeatdownUI)
		Subtitle.Name = "Subtitle"
		Subtitle.AnchorPoint = Vector2.new(0.5, 0)
		Subtitle.BackgroundTransparency = 1
		Subtitle.Position = UDim2.new(0.5, 0, 0.07, 0)
		Subtitle.Size = UDim2.new(1, 0, 0.04, 0)
		Subtitle.Font = Enum.Font.Gotham
		Subtitle.Text = "Select your custom beatdown stand model"
		Subtitle.TextColor3 = Color3.fromRGB(180, 180, 255)
		Subtitle.TextScaled = true
		Subtitle.TextTransparency = 0.3
		Subtitle.TextWrapped = true
		Subtitle.TextXAlignment = Enum.TextXAlignment.Center
		Subtitle.ZIndex = 6
		local ContentContainer = Instance.new("Frame", CustomBeatdownUI)
		ContentContainer.Name = "ContentContainer"
		ContentContainer.AnchorPoint = Vector2.new(0.5, 0)
		ContentContainer.BackgroundTransparency = 1
		ContentContainer.Position = UDim2.new(0.5, 0, 0.12, 0)
		ContentContainer.Size = UDim2.new(1, 0, 0.88, 0)
		ContentContainer.ZIndex = 6
		local ModelListContainer = Instance.new("Frame", ContentContainer)
		ModelListContainer.Name = "ModelListContainer"
		ModelListContainer.AnchorPoint = Vector2.new(0, 0)
		ModelListContainer.BackgroundTransparency = 1
		ModelListContainer.Position = UDim2.new(0, 0, 0, 0)
		ModelListContainer.Size = UDim2.new(0.35, 0, 1, 0)
		ModelListContainer.ZIndex = 6
		local ModelListTitle = Instance.new("TextLabel", ModelListContainer)
		ModelListTitle.Name = "ModelListTitle"
		ModelListTitle.BackgroundTransparency = 1
		ModelListTitle.Position = UDim2.new(0, 0, 0, 0)
		ModelListTitle.Size = UDim2.new(1, 0, 0.06, 0)
		ModelListTitle.Font = Enum.Font.Oswald
		ModelListTitle.Text = "AVAILABLE MODELS"
		ModelListTitle.TextColor3 = Color3.fromRGB(194, 194, 194)
		ModelListTitle.TextScaled = true
		ModelListTitle.TextWrapped = true
		ModelListTitle.TextXAlignment = Enum.TextXAlignment.Left
		ModelListTitle.ZIndex = 6
		local ModelsScrollFrame = Instance.new("ScrollingFrame", ModelListContainer)
		ModelsScrollFrame.Name = "ModelsScrollFrame"
		ModelsScrollFrame.Position = UDim2.new(0, 0, 0.06, 0)
		ModelsScrollFrame.Size = UDim2.new(1, 0, 0.94, 0)
		ModelsScrollFrame.BackgroundTransparency = 1
		ModelsScrollFrame.ScrollBarThickness = 8
		ModelsScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(113, 84, 255)
		ModelsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		ModelsScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ModelsScrollFrame.ClipsDescendants = true
		ModelsScrollFrame.ZIndex = 6
		local ModelsListLayout = Instance.new("UIListLayout", ModelsScrollFrame)
		ModelsListLayout.Padding = UDim.new(0, 8)
		ModelsListLayout.FillDirection = Enum.FillDirection.Vertical
		ModelsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		local ModelsScrollPadding = Instance.new("UIPadding", ModelsScrollFrame)
		ModelsScrollPadding.PaddingTop = UDim.new(0, 8)
		ModelsScrollPadding.PaddingBottom = UDim.new(0, 8)
		ModelsScrollPadding.PaddingLeft = UDim.new(0, 5)
		ModelsScrollPadding.PaddingRight = UDim.new(0, 5)
		local ModelPreviewContainer = Instance.new("Frame", ContentContainer)
		ModelPreviewContainer.Name = "ModelPreviewContainer"
		ModelPreviewContainer.AnchorPoint = Vector2.new(1, 0)
		ModelPreviewContainer.BackgroundTransparency = 1
		ModelPreviewContainer.Position = UDim2.new(1, 0, 0, 0)
		ModelPreviewContainer.Size = UDim2.new(0.64, 0, 1, 0)
		ModelPreviewContainer.ZIndex = 6
		local PreviewTitle = Instance.new("TextLabel", ModelPreviewContainer)
		PreviewTitle.Name = "PreviewTitle"
		PreviewTitle.BackgroundTransparency = 1
		PreviewTitle.Position = UDim2.new(0, 0, 0, 0)
		PreviewTitle.Size = UDim2.new(1, 0, 0.06, 0)
		PreviewTitle.Font = Enum.Font.Oswald
		PreviewTitle.Text = "MODEL PREVIEW"
		PreviewTitle.TextColor3 = Color3.fromRGB(194, 194, 194)
		PreviewTitle.TextScaled = true
		PreviewTitle.TextWrapped = true
		PreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
		PreviewTitle.ZIndex = 6
		local ViewportFrame = Instance.new("ViewportFrame", ModelPreviewContainer)
		ViewportFrame.Name = "ViewportFrame"
		ViewportFrame.Position = UDim2.new(0, 0, 0.06, 0)
		ViewportFrame.Size = UDim2.new(1, 0, 0.5, 0)
		ViewportFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
		ViewportFrame.BackgroundTransparency = 0
		ViewportFrame.BorderSizePixel = 0
		ViewportFrame.ZIndex = 6
		local UICorner_Viewport = Instance.new("UICorner", ViewportFrame)
		UICorner_Viewport.CornerRadius = UDim.new(0, 10)
		local UIStroke_Viewport = Instance.new("UIStroke", ViewportFrame)
		UIStroke_Viewport.Color = Color3.fromRGB(85, 93, 255)
		UIStroke_Viewport.Thickness = 2
		local ModelNameLabel = Instance.new("TextLabel", ModelPreviewContainer)
		ModelNameLabel.Name = "ModelName"
		ModelNameLabel.Position = UDim2.new(0, 0, 0.56, 0)
		ModelNameLabel.Size = UDim2.new(1, 0, 0.08, 0)
		ModelNameLabel.BackgroundTransparency = 1
		ModelNameLabel.Font = Enum.Font.Oswald
		ModelNameLabel.Text = "MODEL NAME"
		ModelNameLabel.TextColor3 = Color3.fromRGB(255, 255, 189)
		ModelNameLabel.TextScaled = true
		ModelNameLabel.TextWrapped = true
		ModelNameLabel.TextXAlignment = Enum.TextXAlignment.Center
		ModelNameLabel.ZIndex = 6
		local ModelIdLabel = Instance.new("TextLabel", ModelPreviewContainer)
		ModelIdLabel.Name = "ModelId"
		ModelIdLabel.Position = UDim2.new(0, 0, 0.64, 0)
		ModelIdLabel.Size = UDim2.new(1, 0, 0.04, 0)
		ModelIdLabel.BackgroundTransparency = 1
		ModelIdLabel.Font = Enum.Font.Gotham
		ModelIdLabel.Text = "ID: NO MODEL SELECTED"
		ModelIdLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		ModelIdLabel.TextScaled = true
		ModelIdLabel.TextWrapped = true
		ModelIdLabel.TextXAlignment = Enum.TextXAlignment.Center
		ModelIdLabel.ZIndex = 6
		local DescriptionFrame = Instance.new("Frame", ModelPreviewContainer)
		DescriptionFrame.Name = "DescriptionFrame"
		DescriptionFrame.Position = UDim2.new(0, 0, 0.68, 0)
		DescriptionFrame.Size = UDim2.new(1, 0, 0.32, 0)
		DescriptionFrame.BackgroundColor3 = Color3.fromRGB(30, 26, 54)
		DescriptionFrame.BackgroundTransparency = 0
		DescriptionFrame.ZIndex = 6
		local UICorner_Desc = Instance.new("UICorner", DescriptionFrame)
		UICorner_Desc.CornerRadius = UDim.new(0, 10)
		local UIStroke_Desc = Instance.new("UIStroke", DescriptionFrame)
		UIStroke_Desc.Color = Color3.fromRGB(85, 93, 255)
		UIStroke_Desc.Thickness = 2
		local DescriptionLabel = Instance.new("TextLabel", DescriptionFrame)
		DescriptionLabel.Name = "Description"
		DescriptionLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		DescriptionLabel.BackgroundTransparency = 1
		DescriptionLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		DescriptionLabel.Size = UDim2.new(0.96, 0, 0.96, 0)
		DescriptionLabel.Font = Enum.Font.Gotham
		DescriptionLabel.Text = "NO DESCRIPTION AVAILABLE"
		DescriptionLabel.TextColor3 = Color3.fromRGB(214, 214, 214)
		DescriptionLabel.TextScaled = true
		DescriptionLabel.TextWrapped = true
		DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
		DescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
		DescriptionLabel.ZIndex = 6
		local UIPadding_Desc = Instance.new("UIPadding", DescriptionLabel)
		UIPadding_Desc.PaddingLeft = UDim.new(0.03, 0)
		UIPadding_Desc.PaddingRight = UDim.new(0.03, 0)
		UIPadding_Desc.PaddingTop = UDim.new(0.03, 0)
		UIPadding_Desc.PaddingBottom = UDim.new(0.03, 0)
		local function createModelButton(modelData)
			local button = Instance.new("TextButton")
			button.Name = "ModelBtn_" .. modelData.id
			button.Size = UDim2.new(1, -10, 0, 60)
			button.BackgroundColor3 = Color3.fromRGB(35, 31, 59)
			button.BackgroundTransparency = 0
			button.AutoButtonColor = true
			button.Text = modelData.name
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.Font = Enum.Font.Oswald
			button.TextSize = 24
			button.ZIndex = 6
			local UICorner = Instance.new("UICorner", button)
			UICorner.CornerRadius = UDim.new(0, 8)
			local UIStroke = Instance.new("UIStroke", button)
			UIStroke.Color = Color3.fromRGB(85, 93, 255)
			UIStroke.Thickness = 1.25
			if modelData.id == SelectedBeatdownModel then
				UIStroke.Color = Color3.fromRGB(80, 255, 61)
				button.BackgroundColor3 = Color3.fromRGB(58, 53, 103)
			end
			local contentFrame = Instance.new("Frame", button)
			contentFrame.Size = UDim2.new(1, 0, 1, 0)
			contentFrame.BackgroundTransparency = 1
			local modelIcon = Instance.new("ImageLabel", contentFrame)
			modelIcon.Name = "Icon"
			modelIcon.Size = UDim2.new(0, 45, 0, 45)
			modelIcon.Position = UDim2.new(0, 8, 0.5, -22.5)
			modelIcon.BackgroundTransparency = 1
			modelIcon.Image = modelData.icon or "rbxassetid://5912368763"
			modelIcon.ImageColor3 = modelData.iconColor or Color3.fromRGB(113, 84, 255)
			modelIcon.ScaleType = Enum.ScaleType.Fit
			local nameLabel = Instance.new("TextLabel", contentFrame)
			nameLabel.Name = "Name"
			nameLabel.Size = UDim2.new(1, -60, 0.6, 0)
			nameLabel.Position = UDim2.new(0, 58, 0, 5)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = modelData.name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 18
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			local statusContainer = Instance.new("Frame", contentFrame)
			statusContainer.Name = "StatusContainer"
			statusContainer.Size = UDim2.new(1, -60, 0.4, 0)
			statusContainer.Position = UDim2.new(0, 58, 0.6, -5)
			statusContainer.BackgroundTransparency = 1
			local statusLabel = Instance.new("TextLabel", statusContainer)
			statusLabel.Name = "Status"
			statusLabel.Size = UDim2.new(0.5, 0, 1, 0)
			statusLabel.BackgroundTransparency = 1
			statusLabel.Text = modelData.enabled and "ENABLED" or "DISABLED"
			statusLabel.TextColor3 = modelData.enabled and Color3.fromRGB(84, 255, 113) or Color3.fromRGB(255, 100, 100)
			statusLabel.TextSize = 12
			statusLabel.Font = Enum.Font.GothamBold
			statusLabel.TextXAlignment = Enum.TextXAlignment.Left
			local selectLabel = Instance.new("TextLabel", statusContainer)
			selectLabel.Name = "SelectLabel"
			selectLabel.Size = UDim2.new(0.5, 0, 1, 0)
			selectLabel.Position = UDim2.new(0.5, 0, 0, 0)
			selectLabel.BackgroundTransparency = 1
			selectLabel.Text = modelData.id == SelectedBeatdownModel and "✓ SELECTED" or "CLICK TO SELECT"
			selectLabel.TextColor3 = modelData.id == SelectedBeatdownModel and Color3.fromRGB(113, 255, 84) or Color3.fromRGB(180, 180, 255)
			selectLabel.TextSize = 11
			selectLabel.Font = Enum.Font.Gotham
			selectLabel.TextXAlignment = Enum.TextXAlignment.Right
			button.MouseButton1Click:Connect(function()
				SelectedBeatdownModel = modelData.id
				ModelNameLabel.Text = modelData.name
				ModelIdLabel.Text = "ID: " .. modelData.id
				DescriptionLabel.Text = modelData.description
				loadModelIntoViewport(modelData.id)
				if updateCustomBeatdownEvent ~= nil then
					updateCustomBeatdownEvent:Fire();
					print("Sending Signals to update CustomBeatdown handler...");
				end
				for _, child in ipairs(ModelsScrollFrame:GetChildren()) do
					if child:IsA("TextButton") then
						local stroke = child:FindFirstChild("UIStroke")
						if stroke then
							if child.Name == "ModelBtn_" .. modelData.id then
								stroke.Color = Color3.fromRGB(113, 255, 84)
								child.BackgroundColor3 = Color3.fromRGB(45, 41, 79)
								if child:FindFirstChild("SelectLabel") ~= nil then
									local selectLabel = child.SelectLabel
									selectLabel.Text = "✓ SELECTED"
									selectLabel.TextColor3 = Color3.fromRGB(113, 255, 84)
								end
							else
								stroke.Color = Color3.fromRGB(85, 93, 255)
								if child:FindFirstChild("SelectLabel") ~= nil then
									local selectLabel = child.SelectLabel
									child.BackgroundColor3 = Color3.fromRGB(35, 31, 59)
									selectLabel.Text = "CLICK TO SELECT"
									selectLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
								end
							end
						end
					end
				end
				if SettingsScript.DisplayLogs then
					print("Selected beatdown model: " .. modelData.name .. " (" .. modelData.id .. ")")
				end
			end)
			return button
		end
		for _, model in ipairs(CustomBeatdownModels) do
			local button = createModelButton(model)
			button.Parent = ModelsScrollFrame
		end
		spawn(function()
			wait(0.1)
			loadModelIntoViewport(SelectedBeatdownModel)
		end)
		return CustomBeatdownUI
	end
	local function toggleCustomBeatdownUI()
		createCustomBeatdownUI()
		CustomBeatdownUI.Visible = not CustomBeatdownUI.Visible
		Settings.Visible = false
		if TeleportData.TeleportUI then
			TeleportData.TeleportUI.Visible = false
		end
		if CustomBeatdownUI.Visible then
			CustomBeatdownUI.ZIndex = 6
			loadModelIntoViewport(SelectedBeatdownModel)
			if SettingsScript.DisplayLogs then
				print("Custom Beatdown UI opened - " .. #CustomBeatdownModels .. " models available")
			end
		end
	end
	local function modifyStandHitbox()
		if not lpr.Character then return end
		local stand = lpr.Character:FindFirstChild("Stand")
		if not stand then return end
		local hitbox = stand:FindFirstChild("Hitbox")
		if not hitbox then
			for _, child in ipairs(stand:GetChildren()) do
				if child:IsA("BasePart") and child.Name:lower():find("hitbox") then
					hitbox = child
					break
				end
			end
		end
		if hitbox and hitbox:IsA("BasePart") then
			if SlapBattlesSettings.BiggerHitbox then
				hitbox.Size = CustomHitbox
				hitbox.Transparency = 1
				hitbox.Color = Color3.fromRGB(255, 0, 0)
				if SettingsScript.DisplayLogs then
					print("Hitbox modified to: " .. tostring(CustomHitbox))
				end
			else
				hitbox.Size = Vector3.new(4, 5, 6)
				hitbox.Transparency = 1
			end
		else
			--print("No hitbox found in stand")
		end
	end
	local function GetStandModel(Stand)
		if Stand == nil then return false end
		local StandModel = lpr.Character:FindFirstChild(Stand);
		if not StandModel then return false end
		return true;
	end;
	local function ApplyCustomBeatdownModel(StandModel, modelData, CurrentPlayer)
		if not StandModel or not modelData then return end
		for _, child in ipairs(StandModel:GetChildren()) do
			--[[
			if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
				child:Destroy()
			end
			--]]
			if child.Name == "ShirtVisual" or child.Name == "LeftPantsVisual" or child.Name == "RightPantsVisual" then
				child:Destroy()
			end
		end
		for _, parts in ipairs(StandModel:GetChildren()) do
			if parts:IsA("BasePart") then
				parts.Color = modelData.color
				parts.Material = modelData.material
				if modelData.transparency then
					if parts.Name ~= "HumanoidRootPart" then
						parts.Transparency = modelData.transparency
					end
				end

				-- Special handling for Angelic model
				if modelData.id == "angelic_beatdown" then
					if parts.Name == "Torso" or parts.Name:find("Leg") or parts.Name:find("Arm") then
						for _, child in ipairs(parts:GetChildren()) do
							if child:IsA("SpecialMesh") then
								child:Destroy()
							end
						end
					end

					-- Set all body parts to white
					if parts.Name == "Torso" or parts.Name == "Left Leg" or parts.Name == "Right Leg" or 
						parts.Name == "Left Arm" or parts.Name == "Right Arm" or parts.Name == "Head" then
						parts.Color = Color3.fromRGB(255, 255, 255)
					end
				elseif modelData.id == "Uncle_Beatdown" then
					if parts.Name == "Torso" or parts.Name:find("Leg") or parts.Name:find("Arm") then
						for _, child in ipairs(parts:GetChildren()) do
							if child:IsA("SpecialMesh") then
								child:Destroy()
							end
						end
					end

					-- Set all body parts to black
					if parts.Name == "Torso" or parts.Name == "Left Leg" or parts.Name == "Right Leg" or 
						parts.Name == "Left Arm" or parts.Name == "Right Arm" or parts.Name == "Head" then
						parts.Color = Color3.fromRGB(0, 0, 0)
					end
				elseif  modelData.id == "SMT_Beatdown" then
					if parts.Name == "Torso" or parts.Name:find("Leg") or parts.Name:find("Arm") then
						for _, child in ipairs(parts:GetChildren()) do
							if child:IsA("SpecialMesh") then
								child:Destroy()
							end
						end
					end
					-- Set all body parts to dark blue
					if parts.Name == "Torso" or parts.Name == "Left Leg" or parts.Name == "Right Leg" or 
						parts.Name == "Left Arm" or parts.Name == "Right Arm" or parts.Name == "Head" then
						parts.Color = Color3.fromRGB(0, 3, 172)
					end
				end

				if parts.Name == "Left Arm" or parts.Name == "Right Arm" or 
					parts.Name == "Left Leg" or parts.Name == "Right Leg" or 
					parts.Name == "Head" then
					local fire = parts:FindFirstChild("fire")
					local fire2 = parts:FindFirstChild("fire2")
					local fire3 = parts:FindFirstChild("fire3")
					local fire4 = parts:FindFirstChild("fire4")

					if fire then
						fire.Color = ColorSequence.new(modelData.fireColor)
					end
					if fire2 then
						fire2.Color = ColorSequence.new(modelData.fireColor)
					end
					if fire3 then
						fire3.Color = ColorSequence.new(modelData.fireColor)
					end
					if fire4 then
						fire4.Color = ColorSequence.new(modelData.fireColor)
					end
				end
			end
		end

		if modelData.specialEffects then
			pcall(function()
				modelData.specialEffects(StandModel:GetChildren())
			end)
		end
		local activeEffects = {}
		for _, p in ipairs(game.Players:GetPlayers()) do
			if p ~= lpr and p.Character then
				local LSB = p.Character:FindFirstChild("LastSlappedBy")
				if LSB and LSB.Value == CurrentPlayer.Name then
					local torso = p.Character:FindFirstChild("Torso")
					local head = p.Character:FindFirstChild("Head");
					local beatdownHead = StandModel:FindFirstChild("Head") or p.Character:FindFirstChild("Stand").Head;
					if torso and head then
						for _, s in ipairs(torso:GetChildren()) do
							if s:IsA("Sound") then
								local soundName = s.Name
								if modelData.id == "angelic_beatdown" then
									if soundName == "Nukem" and s.IsPlaying then
										if not s:FindFirstChildOfClass("ReverbSoundEffect") then
											for _, child in ipairs(game.Lighting:GetChildren()) do
												if not child.Name:find("CutsenseJoJo") then
													if CurrentPlayer == lpr then
														initializeColorCorrection();
													end
													game:GetService("SoundService").AmbientReverb = Enum.ReverbType.Quarry
													game:GetService("SoundService"):FindFirstChild("Timestop"):Play();
													game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 4;
													game:GetService("SoundService"):FindFirstChild("Clock"):Play();
													game:GetService("SoundService"):FindFirstChild("Clock").Volume = 2.5;
													print("Send Signal")
													break
												end
											end
											if CurrentPlayer == lpr then
												startColorCorrectionEffect();
											end
											local CustomReverb = Instance.new("ReverbSoundEffect", s)
											CustomReverb.DecayTime = 3.682
											CustomReverb.Density = 1
											CustomReverb.Diffusion = 0
											CustomReverb.DryLevel = 0
											CustomReverb.Priority = 1
											CustomReverb.WetLevel = -1
											CustomReverb.Enabled = true
											spawn(function()
												task.wait(1);
												local Muda = Instance.new("Sound", s);
												Muda.Name = "CutsenceMuda";
												Muda.SoundId = "rbxassetid://3778359790";
												Muda.Volume = 2;
												Muda.PlaybackSpeed = 0.88;
												Muda.RollOffMode = Enum.RollOffMode.Inverse;
												Muda.RollOffMaxDistance = 100;
												Muda.RollOffMinDistance = 10;
												local CustomReverb2 = Instance.new("ReverbSoundEffect", Muda);
												if CustomReverb2:IsA("ReverbSoundEffect") ~= nil then
													CustomReverb2.DecayTime = 3.085
													CustomReverb2.Density = 1;
													CustomReverb2.Diffusion = 1;
													CustomReverb2.DryLevel = 0;
													CustomReverb2.Priority = 1;
													CustomReverb2.WetLevel = 1;
													CustomReverb2.Enabled = true;
												else
													if SettingsScript.DisplayLogs then
														warn("Failed to Create ReverbSoundEffect")
													end
												end
												Muda:Play();
											end)
										end
									end
									if modelData.customSounds and modelData.customSounds[soundName] then
										if s.Name == "Yell" or s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
											if CurrentPlayer == lpr then
												spawn(function()
													task.wait(1);
													endColorCorrectionEffect();
												end)
											end
											spawn(function()
												task.wait(0.76);
												game:GetService("SoundService").AmbientReverb = Enum.ReverbType.NoReverb
												game:GetService("SoundService"):FindFirstChild("Timeresume"):Play();
												game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 0.5;
												game:GetService("SoundService"):FindFirstChild("Timeresume").Volume = 2.5;
												game:GetService("SoundService"):FindFirstChild("Clock"):Stop();
												game:GetService("SoundService"):FindFirstChild("Clock").Volume = 0.5;
											end)
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										else
											--print("Failed to Send Signal")
											s.PlaybackSpeed = modelData.customSounds[soundName]
											--print(tostring(modelData.customSounds[soundName]))
											--print(tostring(soundName))
										end
										--s.PlaybackSpeed = modelData.customSounds[soundName]
									else
										if s.Name == "Yell" or "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name ~= "explosion2" and s.Name ~= "Hit" and 
											soundName ~= "Implosion" and soundName ~= "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										end
									end
								elseif modelData.id == "Uncle_beatdown" then
									if soundName == "Nukem" and s.IsPlaying then
										if not s:FindFirstChildOfClass("ReverbSoundEffect") then
											for _, child in ipairs(game.Lighting:GetChildren()) do
												if not child.Name:find("CutsenseJoJo") then
													if CurrentPlayer == lpr then
														initializeColorCorrectionUncle();
													end
													--[[
													s.SoundId = "rbxassetid://82486699740831"
													s.TimePosition = 7.97
													s.PlaybackSpeed = 1
													--]]
													game:GetService("SoundService").AmbientReverb = Enum.ReverbType.Quarry
													game:GetService("SoundService"):FindFirstChild("Timestop"):Play();
													game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 4;
													if SettingsScript.DisplayLogs then
														print("Send Signal")
													end
													break
												end
											end
											if CurrentPlayer == lpr then
												startColorCorrectionEffectUncle();
											end
											local CustomReverb = Instance.new("ReverbSoundEffect", s)
											CustomReverb.DecayTime = 3.682
											CustomReverb.Density = 1
											CustomReverb.Diffusion = 0
											CustomReverb.DryLevel = 0
											CustomReverb.Priority = 1
											CustomReverb.WetLevel = -0.5
											CustomReverb.Enabled = true
											spawn(function()
												task.wait(1);
												local Muda = Instance.new("Sound", s);
												Muda.Name = "CutsenceMuda";
												Muda.SoundId = "rbxassetid://3778359790";
												Muda.Volume = 2;
												Muda.PlaybackSpeed = 0.88;
												Muda.RollOffMode = Enum.RollOffMode.Inverse;
												Muda.RollOffMaxDistance = 100;
												Muda.RollOffMinDistance = 10;
												local CustomReverb2 = Instance.new("ReverbSoundEffect", Muda);
												if CustomReverb2:IsA("ReverbSoundEffect") ~= nil then
													CustomReverb2.DecayTime = 3.085
													CustomReverb2.Density = 1;
													CustomReverb2.Diffusion = 1;
													CustomReverb2.DryLevel = 0;
													CustomReverb2.Priority = 1;
													CustomReverb2.WetLevel = 1;
													CustomReverb2.Enabled = true;
												else
													if SettingsScript.DisplayLogs then
														warn("Failed to Create ReverbSoundEffect")
													end
												end
												Muda:Play();
											end)
											-- set player fully invisible
											local function makePlayerInvisible()
												local character = lpr.Character
												if not character then return end

												for _, v in pairs(character:GetDescendants()) do
													-- Skip the "Stand" model completely (and all its children)
													if v:IsA("Model") and v.Name == "Stand" then
														continue  -- Skip this entire model
													end

													if v:IsA("BasePart") and not v:IsDescendantOf(character:FindFirstChild("Stand")) then
														if v.Name ~= "HumanoidRootPart" then
														v.Transparency = 1
														--v.CanCollide = false
														end
													end

													if v:IsA("Decal") or v:IsA("Texture") then
														v.Transparency = 1
													end

													if v:IsA("ParticleEmitter") or v:IsA("Trail") then
														v.Enabled = false
													end

													if v:IsA("BillboardGui") then
														v.Enabled = false
													end

													-- Handle accessories (but also check if they're inside Stand)
													if v:IsA("Accessory") then
														-- Check if this Accessory is inside the Stand model
														local isInStand = false
														local parent = v.Parent
														while parent do
															if parent:IsA("Model") and parent.Name == "Stand" then
																isInStand = true
																break
															end
															parent = parent.Parent
														end

														if not isInStand then
															for _, child in pairs(v:GetDescendants()) do
																if child:IsA("BasePart") and not v:IsDescendantOf(character:FindFirstChild("Stand")) then
																	if child.Name ~= "HumanoidRootPart" then
																	child.Transparency = 1
																	--child.CanCollide = false
																	end
																end
															end
														end
													end
												end
											end
											makePlayerInvisible()
										end
									end
									if modelData.customSounds and modelData.customSounds[soundName] then
										if s.Name == "Yell" or s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.SoundId = "rbxassetid://127016684446185"
											s.TimePosition = 0.1
											s.PlaybackSpeed = modelData.soundSpeed
											if CurrentPlayer == lpr then
												spawn(function()
													task.wait(1);
													endColorCorrectionEffectUncle();
												end)
											end
											spawn(function()
												task.wait(0.76);
												game:GetService("SoundService").AmbientReverb = Enum.ReverbType.NoReverb
												game:GetService("SoundService"):FindFirstChild("Timeresume"):Play();
												game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 0.5;
												game:GetService("SoundService"):FindFirstChild("Timeresume").Volume = 2.5;
												
												-- restore the player's visibility
												local function restorePlayerVisibility()
													local lpr = game:GetService("Players").LocalPlayer
													local character = lpr.Character
													if not character then return end

													for _, v in pairs(character:GetDescendants()) do
														-- Skip the "Stand" model
														if v:IsA("Model") and v.Name == "Stand" then
															continue
														end

														if v:IsA("BasePart") then
															if v.Name ~= "HumanoidRootPart" then
															v.Transparency = 0
															--v.CanCollide = true
														end
													end
														if v:IsA("Decal") or v:IsA("Texture") then
															v.Transparency = 0
														end

														if v:IsA("ParticleEmitter") or v:IsA("Trail") then
															v.Enabled = true
														end

														if v:IsA("BillboardGui") then
															v.Enabled = true
														end

														if v:IsA("Accessory") then
															local isInStand = false
															local parent = v.Parent
															while parent do
																if parent:IsA("Model") and parent.Name == "Stand" then
																	isInStand = true
																	break
																end
																parent = parent.Parent
															end

															if not isInStand then
																for _, child in pairs(v:GetDescendants()) do
																	if child:IsA("BasePart") then
																		if child.Name ~= "HumanoidRootPart" then
																		child.Transparency = 0
																		--child.CanCollide = true
																		end
																	end
																end
															end
														end
													end
												end
												restorePlayerVisibility();
											end)
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										else
											s.PlaybackSpeed = modelData.customSounds[soundName]
										end
									else
										if s.Name == "Yell" or "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name ~= "explosion2" and s.Name ~= "Hit" and 
											soundName ~= "Implosion" and soundName ~= "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										end
									end
								elseif modelData.id == "Uncle_beatdown2" then
									if soundName == "Nukem" and s.IsPlaying then
										if not s:FindFirstChildOfClass("ReverbSoundEffect") then
											for _, child in ipairs(game.Lighting:GetChildren()) do
												if not child.Name:find("CutsenseJoJo") then
													if CurrentPlayer == lpr then
														initializeColorCorrectionUncle();
													end
													--[
													s.SoundId = "rbxassetid://82486699740831"
													s.TimePosition = 7.97
													--]]
													game:GetService("SoundService").AmbientReverb = Enum.ReverbType.Quarry
													game:GetService("SoundService"):FindFirstChild("Timestop"):Play();
													game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 4;
													if SettingsScript.DisplayLogs then
														print("Send Signal")
													end
													break
												end
											end
											if CurrentPlayer == lpr then
												startColorCorrectionEffectUncle();
											end
											local CustomReverb = Instance.new("ReverbSoundEffect", s)
											CustomReverb.DecayTime = 3.682
											CustomReverb.Density = 1
											CustomReverb.Diffusion = 0
											CustomReverb.DryLevel = 0
											CustomReverb.Priority = 1
											CustomReverb.WetLevel = -0.5
											CustomReverb.Enabled = true
											spawn(function()
												task.wait(1);
												local Muda = Instance.new("Sound", s);
												Muda.Name = "CutsenceMuda";
												Muda.SoundId = "rbxassetid://3778359790";
												Muda.Volume = 2;
												Muda.PlaybackSpeed = 0.88;
												Muda.RollOffMode = Enum.RollOffMode.Inverse;
												Muda.RollOffMaxDistance = 100;
												Muda.RollOffMinDistance = 10;
												local CustomReverb2 = Instance.new("ReverbSoundEffect", Muda);
												if CustomReverb2:IsA("ReverbSoundEffect") ~= nil then
													CustomReverb2.DecayTime = 3.085
													CustomReverb2.Density = 1;
													CustomReverb2.Diffusion = 1;
													CustomReverb2.DryLevel = 0;
													CustomReverb2.Priority = 1;
													CustomReverb2.WetLevel = 1;
													CustomReverb2.Enabled = true;
												else
													if SettingsScript.DisplayLogs then
														warn("Failed to Create ReverbSoundEffect")
													end
												end
												Muda:Play();
											end)
										end
									end
									if modelData.customSounds and modelData.customSounds[soundName] then
										if s.Name == "Yell" or s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.SoundId = "rbxassetid://127016684446185"
											s.TimePosition = 0.1
											s.PlaybackSpeed = modelData.soundSpeed
											if CurrentPlayer == lpr then
												spawn(function()
													task.wait(1);
													endColorCorrectionEffectUncle();
												end)
											end
											spawn(function()
												task.wait(0.76);
												game:GetService("SoundService").AmbientReverb = Enum.ReverbType.NoReverb
												game:GetService("SoundService"):FindFirstChild("Timeresume"):Play();
												game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 0.5;
												game:GetService("SoundService"):FindFirstChild("Timeresume").Volume = 2.5;
											end)
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										else
											s.PlaybackSpeed = modelData.customSounds[soundName]
										end
									else
										if s.Name == "Yell" or "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name ~= "explosion2" and s.Name ~= "Hit" and 
											soundName ~= "Implosion" and soundName ~= "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										end
									end
								elseif modelData.id == "SMT_beatdown" then
									if soundName == "Nukem" and s.IsPlaying then
										local CutsenseCamPos = StandModel:FindFirstChild("CutsceneCameraPart")
										if CutsenseCamPos then
											CutsenseCamPos:Destroy()
										end

										if CurrentPlayer == lpr then
											-- handle it here !!
											if s.Parent.Parent:FindFirstChild("Head") then
												Camera.CFrame = s.Parent.Parent.Head.CFrame
											end
										end

										if not s:FindFirstChildOfClass("ReverbSoundEffect") then
											for _, child in ipairs(game.Lighting:GetChildren()) do
												if not child.Name:find("CutsenseJoJo") then
												--[[
												if CurrentPlayer == lpr then
													initializeColorCorrectionSMT();
												end
												--]]
													s.SoundId = "rbxassetid://112686550007032"
													s.PlaybackSpeed = modelData.soundSpeed
													if not s.IsLoaded then
														if s.SoundId ~= "rbxassetid://6478272893" and s.SoundId == "rbxassetid://112686550007032" then
															print("Fallback to Nukem")
															s.SoundId = "rbxassetid://6478272893"
															s.PlaybackSpeed = modelData.soundSpeed
															local SoundReverb = Instance.new("ReverbSoundEffect", s)
															SoundReverb.DryLevel = 0
															SoundReverb.WetLevel = 0
															SoundReverb.DecayTime = 0 
															SoundReverb.Enabled = false
														end
													end
													break
												end
											end
										--[[
										if CurrentPlayer == lpr then
											startColorCorrectionEffectSMT();
										end
										--]]
										end
									end
									if modelData.customSounds and modelData.customSounds[soundName] then
										if s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.SoundId = "rbxassetid://139694892021582"
											s.PlaybackSpeed = modelData.soundSpeed
										--[[
										if CurrentPlayer == lpr then
											spawn(function()
												task.wait(1);
												endColorCorrectionEffectSMT();
											end)
										end
										--]]
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										elseif s.Name == "Yell" then
											s.SoundId = "rbxassetid://122927445997178"
											s.PlaybackSpeed = modelData.soundSpeed
										--[[
										if CurrentPlayer == lpr then
											spawn(function()
												task.wait(1);
												endColorCorrectionEffectSMT();
											end)
										end
										--]]
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										elseif s.Name == "Gun1" then
											s.SoundId = "rbxassetid://8255306220";
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name == "Gun2" then
											s.SoundId = "rbxassetid://4513231858"
											s.PlaybackSpeed = modelData.soundSpeed
										else
											s.PlaybackSpeed = modelData.customSounds[soundName]
										end
									else
										if s.Name ~= "explosion2" and s.Name ~= "Hit" and 
											soundName ~= "Implosion" and soundName ~= "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										end
									end
								elseif modelData.id == "refraif_beatdown" then
									if soundName == "Nukem" and s.IsPlaying then
										--[[
										local CutsenseCamPos = StandModel:FindFirstChild("CutsceneCameraPart")
										if CutsenseCamPos then
											CutsenseCamPos:Destroy()
										end
										
										-- =============================================
										-- CUTSENCE TRIGGERED BEFORE SOUND MODIFICATIONS (FIXED VERSION)
										-- =============================================
										if CurrentPlayer == lpr then
											if s.Parent.Parent:FindFirstChild("Head") then
												if not CutsenceRefraifPosActive then
													local cloneSuccess = CloneAttachmentsToStand(StandModel)
													if cloneSuccess then
														spawn(function()
															if CutsenceRefraifPosActive then
																print("Cutsence already active")
																return
															end
															if not StandModel then
																warn("Stand is nil")
																return
															end
															CutsenceRefraifPosActive = true
															local attachmentHolder = StandModel:FindFirstChild("CameraAttachments")
															if not attachmentHolder then
																print("CameraAttachments missing in stand, cloning...")
																local cloneSuccess = CloneAttachmentsToStand(StandModel)
																if not cloneSuccess then
																	warn("Failed to clone attachments to stand")
																	CutsenceRefraifPosActive = false
																	return
																end
																attachmentHolder = StandModel:FindFirstChild("CameraAttachments")
															end
															local hasAttach = attachmentHolder:FindFirstChild("CamAttach1") and attachmentHolder:FindFirstChild("CamAttach13")
															if not hasAttach then
																print("Attachments missing in stand, cloning...")
																local cloneSuccess = CloneAttachmentsToStand(StandModel)
																if not cloneSuccess then
																	warn("Failed to clone attachments to stand")
																	CutsenceRefraifPosActive = false
																	return
																end
															end
															task.wait(0.1)
															local Cam1 = GetCameraCFrameFromAttachment(StandModel, "CamAttach1")
															local Cam2 = GetCameraCFrameFromAttachment(StandModel, "CamAttach2")
															local Cam3 = GetCameraCFrameFromAttachment(StandModel, "CamAttach3")
															local Cam4 = GetCameraCFrameFromAttachment(StandModel, "CamAttach4")
															local Cam5 = GetCameraCFrameFromAttachment(StandModel, "CamAttach5")
															local Cam6 = GetCameraCFrameFromAttachment(StandModel, "CamAttach6")
															local Cam7 = GetCameraCFrameFromAttachment(StandModel, "CamAttach7")
															local Cam8 = GetCameraCFrameFromAttachment(StandModel, "CamAttach8")
															local Cam9 = GetCameraCFrameFromAttachment(StandModel, "CamAttach9")
															local Cam10 = GetCameraCFrameFromAttachment(StandModel, "CamAttach10")
															local Cam11 = GetCameraCFrameFromAttachment(StandModel, "CamAttach11")
															local Cam12 = GetCameraCFrameFromAttachment(StandModel, "CamAttach12")
															local Cam13 = GetCameraCFrameFromAttachment(StandModel, "CamAttach13")
															if not (Cam1 and Cam2 and Cam3 and Cam4 and Cam5 and Cam6 and Cam7 and Cam8 and Cam9 and Cam10 and Cam11 and Cam12 and Cam13) then
																warn("Some camera attachments are missing")
																CutsenceRefraifPosActive = false
																return
															end
															print("Starting smooth cutsence animation")
															local originalCFrame = Camera.CFrame
															Camera.CameraType = Enum.CameraType.Scriptable
															local randomOffset = CFrame.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))
															local segments = {
																{from = originalCFrame, to = Cam1, duration = 1, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.InOut},
																{from = Cam1, to = Cam2, duration = 1, style = Enum.EasingStyle.Exponential, direction = Enum.EasingDirection.In},
																{from = Cam3, to = Cam4, duration = 1.24, style = Enum.EasingStyle.Linear, direction = Enum.EasingDirection.In},
																{from = Cam5, to = Cam6, duration = 0.8, style = Enum.EasingStyle.Linear, direction = Enum.EasingDirection.Out},
																{from = Cam7, to = Cam8, duration = 0.36, style = Enum.EasingStyle.Linear, direction = Enum.EasingDirection.InOut},
																{from = Cam9, to = Cam10, duration = 0.25, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.InOut},
																{from = Cam11, to = Cam12, duration = 0.14, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.InOut},
																{from = Cam12, to = Cam13, duration = 1.25, style = Enum.EasingStyle.Quart, direction = Enum.EasingDirection.InOut}
															}
															local runService = game:GetService("RunService")
															local connection = nil
															local currentSegment = 1
															local segmentStartTime = tick()
															connection = runService.RenderStepped:Connect(function(dt)
																if currentSegment > #segments then
																	connection:Disconnect()
																	task.wait();
																	Camera.CameraType = Enum.CameraType.Custom
																	Camera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid;
																	CutsenceRefraifPosActive = false
																	print("Cutsence completed")
																	return
																end
																local seg = segments[currentSegment]
																local elapsed = tick() - segmentStartTime
																if elapsed >= seg.duration then
																	Camera.CFrame = seg.to * randomOffset
																	currentSegment = currentSegment + 1
																	segmentStartTime = tick()
																else
																	local alpha = elapsed / seg.duration
																	local tweenAlpha = l__TweenService__5:GetValue(alpha, seg.style, seg.direction)
																	Camera.CFrame = seg.from:Lerp(seg.to, tweenAlpha) * randomOffset
																end
															end)
														end)
													else
														warn("Failed to clone attachments for cutsence")
													end
												end
											end
										end
										-- =============================================
										-- END OF CUTSENCE
										-- =============================================
										--]]
										if not s:FindFirstChildOfClass("ReverbSoundEffect") then
											for _, child in ipairs(game.Lighting:GetChildren()) do
												if not child.Name:find("CutsenseJoJo") then
													s.SoundId = "rbxassetid://89498716177477"
													s.PlaybackSpeed = modelData.soundSpeed
													if not s.IsLoaded then
														if s.SoundId ~= "rbxassetid://6478272893" and s.SoundId == "rbxassetid://89498716177477" then
															print("Fallback to Nukem")
															s.SoundId = "rbxassetid://6478272893"
															s.PlaybackSpeed = modelData.soundSpeed
															local SoundReverb = Instance.new("ReverbSoundEffect", s)
															SoundReverb.DryLevel = 0
															SoundReverb.WetLevel = 0
															SoundReverb.DecayTime = 0 
															SoundReverb.Enabled = false
														end
													end
													break
												end
											end
										end
									end
									--[[
									spawn(function()
										wait(0.76);
										-- freeze stand's body
										
										-- im listening to Cha################
										
										-- hhhhhhh, fellin' like drinking some ice cold lemonade on a hot day & feelin' alright ...
										
										-- ########################################################################################
										
										-- They see me rollin'
										-- They hatin'
										-- Patrollin' and tryna catch me ridin' dirty
										
										
										for i, v in pairs(StandModel:GetDescendants()) do
											if v:IsA("BasePart") then
												if v.Name ~= "CutsceneCameraPart" then
												v.Anchored = true
												end
											end
										end
									end)
									--]]
									if modelData.customSounds and modelData.customSounds[soundName] then
										if s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.SoundId = "rbxassetid://4880611384"
											s.PlaybackSpeed = modelData.soundSpeed
											--[[
											spawn(function()
												wait(0.05);

												-- unfreeze stand's body

												-- im listening to Cha################

												-- hhhhhhh, fellin' like drinking some ice cold lemonade on a hot day & feelin' alright ...

												-- ########################################################################################

												-- They see me rollin'
												-- They hatin'
												-- Patrollin' and tryna catch me ridin' dirty


												for i, v in pairs(StandModel:GetDescendants()) do
													if v:IsA("BasePart") then
														if v.Name ~= "CutsceneCameraPart" then
														v.Anchored = false
														end
													end
												end
											end)
											--]]
										elseif s.Name == "Yell" then
											s.SoundId = "rbxassetid://2778713081"
											s.PlaybackSpeed = modelData.soundSpeed
											--[[
											spawn(function()
												wait(0.05);
												
												-- unfreeze stand's body

												-- im listening to Cha################

												-- hhhhhhh, fellin' like drinking some ice cold lemonade on a hot day & feelin' alright ...

												-- ########################################################################################

												-- They see me rollin'
												-- They hatin'
												-- Patrollin' and tryna catch me ridin' dirty


												for i, v in pairs(StandModel:GetDescendants()) do
													if v:IsA("BasePart") then
														if v.Name ~= "CutsceneCameraPart" then
														v.Anchored = false
														end
													end
												end
											end)
											--]]
										elseif s.Name == "Gun1" then
											s.SoundId = "rbxassetid://8789851536";
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name == "Gun2" then
											s.SoundId = "rbxassetid://132427239577856"
											s.PlaybackSpeed = modelData.soundSpeed
										else
											s.PlaybackSpeed = modelData.customSounds[soundName]
										end
									else
										if s.Name ~= "explosion2" and s.Name ~= "Hit" and 
											soundName ~= "Implosion" and soundName ~= "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										end
									end 	
								elseif modelData.id == "Uncle_beatdown3" then
									if soundName == "Nukem" and s.IsPlaying then
										local CutsenseCamPos = StandModel:FindFirstChild("CutsceneCameraPart")
										if CutsenseCamPos then
											CutsenseCamPos:Destroy()
										end
										
										if CurrentPlayer == lpr then
											spawn(function()
											if CustomCutsenseUncle3 and not CamPosActive then
												CamPosActive = true
												PlayerCurrentData["CutsceneActive"] = true

												-- Define timers for camera positions
												local CamPos1_timer = 1.5  -- Switch to beatdown head at 1.5 seconds
												local CamPos2_timer = 3.5  -- Switch back to victim head at 3.5 seconds
												local totalDuration = 7    -- Total cutscene duration

												-- Reset flags
												local CamPos1 = false
												local CamPos2 = false
												local FinalCamPos = false

												-- Store original camera settings
												local originalCameraType = Camera.CameraType
												Camera.CameraType = Enum.CameraType.Scriptable

												local startTime = tick()
												print("Starting unified cutscene loop")

												-- Single loop handling both timer and camera updates
												while CamPosActive and (tick() - startTime) < totalDuration do
													local elapsedTime = tick() - startTime

													-- Update timer flags
													if not CamPos1 and elapsedTime >= CamPos1_timer then
														CamPos1 = true
														print("CamPos1 triggered at " .. string.format("%.2f", elapsedTime) .. "s")
													end

													if not CamPos2 and elapsedTime >= CamPos2_timer then
														CamPos2 = true
														print("CamPos2 triggered at " .. string.format("%.2f", elapsedTime) .. "s")
													end

													if not FinalCamPos and elapsedTime >= totalDuration then
														FinalCamPos = true
														print("FinalCamPos triggered at " .. string.format("%.2f", elapsedTime) .. "s")
													end

													-- Get target parts
													local victimHead = s and s.Parent and s.Parent.Parent and s.Parent.Parent:FindFirstChild("Head")
													local beatdownHeadPart = beatdownHead
													local camOffset = Vector3.new(0, -0.2, -1) -- a little bit fornt
													-- Camera positioning based on current flags
													if not CamPos1 and not CamPos2 and not FinalCamPos then
														-- Initial position: Victim Head
														if victimHead then
															Camera.CFrame = victimHead.CFrame
														end
													elseif CamPos1 and not CamPos2 and not FinalCamPos then
														-- Position 1: Beatdown Stand Head
														if beatdownHeadPart and beatdownHeadPart.Parent then
															Camera.CFrame = beatdownHeadPart.CFrame * CFrame.new(camOffset)
														elseif victimHead then
															-- Fallback to victim head
															Camera.CFrame = victimHead.CFrame
														end
													elseif CamPos1 and CamPos2 and not FinalCamPos then
														-- Position 2: Back to Victim Head
														if victimHead then
															Camera.CFrame = victimHead.CFrame
														end
													elseif CamPos1 and CamPos2 and FinalCamPos then
														-- Final position: Beatdown Head
														if beatdownHeadPart and beatdownHeadPart.Parent then
															Camera.CFrame = beatdownHeadPart.CFrame * CFrame.new(camOffset)
														elseif victimHead then
															-- Fallback to victim head
															Camera.CFrame = victimHead.CFrame
														end
													else
														-- Default fallback
														if victimHead then
															Camera.CFrame = victimHead.CFrame
														end
													end

													game:GetService("RunService").RenderStepped:Wait()
												end
												CamPosActive = false
												PlayerCurrentData["CutsceneActive"] = false
												spawn(function()
														-- Handle return after cutscene with proper timing
														if SettingsScript.KickPlayerAfterCutsenceBD and PlayerCurrentData["IsTeleported"] then
															-- Calculate remaining time for proper timing
															local returnDelay = 0.1  -- Delay before return

															-- Check if we need to wait for Implosion to finish
															if PlayerCurrentData["ReturnTimer"] then
																local elapsedSinceTeleport = tick() - PlayerCurrentData["ReturnTimer"]
																if elapsedSinceTeleport < returnDelay then
																	local waitTime = returnDelay - elapsedSinceTeleport
																	if waitTime > 0 then
																		task.wait(waitTime)
																	end
																end
															else
																task.wait(returnDelay)
															end

															-- Return player
															if lpr and lpr.Character and PlayerCurrentData["LastPos"] then
																local playerHRP = lpr.Character:FindFirstChild("HumanoidRootPart")
																if playerHRP then
																	playerHRP.CFrame = PlayerCurrentData["LastPos"]
																	warn("Returned " .. lpr.DisplayName .. " to last position: " .. tostring(PlayerCurrentData["LastPos"]))

																	PlayerCurrentData["LastPos"] = nil
																	PlayerCurrentData["IsTeleported"] = false
																	PlayerCurrentData["ReturnTimer"] = nil
																	PlayerCurrentData["Init"] = false
																	PlayerCurrentData["TeleportPending"] = false
																end
															end
														end
												end)
													print("Cutscene completed")
												end
											end)
										end

										if not s:FindFirstChildOfClass("ReverbSoundEffect") then
											for _, child in ipairs(game.Lighting:GetChildren()) do
												if not child.Name:find("CutsenseJoJo") then
												--[[
												if CurrentPlayer == lpr then
													initializeColorCorrectionSMT();
												end
												--]]
													s.SoundId = "rbxassetid://120951886226574" -- Show me what you got :>
													s.PlaybackSpeed = modelData.soundSpeed
													if not s.IsLoaded then
														if s.SoundId ~= "rbxassetid://6478272893" and s.SoundId == "rbxassetid://112686550007032" then
															print("Fallback to Nukem")
															s.SoundId = "rbxassetid://6478272893"
															s.PlaybackSpeed = modelData.soundSpeed
															local SoundReverb = Instance.new("ReverbSoundEffect", s)
															SoundReverb.DryLevel = 0
															SoundReverb.WetLevel = 0
															SoundReverb.DecayTime = 0 
															SoundReverb.Enabled = false
														end
													end
													break
												end
											end
										--[[
										if CurrentPlayer == lpr then
											startColorCorrectionEffectSMT();
										end
										--]]

										end
									end
									if modelData.customSounds and modelData.customSounds[soundName] then
										if s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.SoundId = "rbxassetid://128298841397286"
											s.PlaybackSpeed = modelData.soundSpeed
										--[[
										if CurrentPlayer == lpr then
											spawn(function()
												task.wait(1);
												endColorCorrectionEffectSMT();
											end)
										end
										--]]
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										elseif s.Name == "Yell" then
											s.SoundId = "rbxassetid://130301204112009"
											s.PlaybackSpeed = modelData.soundSpeed
										--[[
										if CurrentPlayer == lpr then
											spawn(function()
												task.wait(1);
												endColorCorrectionEffectSMT();
											end)
										end
										--]]
										elseif s.Name == "Implosion" then
											s.PlaybackSpeed = modelData.soundSpeed
											--[ Teleport player on Implosion
											if SettingsScript.KickPlayerAfterCutsenceBD and not PlayerCurrentData["IsTeleported"] and not PlayerCurrentData["TeleportPending"] and not PlayerCurrentData["Init"] then
												PlayerCurrentData["TeleportPending"] = true
												if lpr and lpr.Character then
													local playerHRP = lpr.Character:FindFirstChild("HumanoidRootPart")
													if playerHRP then
														if PlayerCurrentData["Init"] then return end
														-- Save position and timestamp
														PlayerCurrentData["LastPos"] = playerHRP.CFrame
														PlayerCurrentData["ReturnTimer"] = tick()  -- Track when teleport happened
														--print("Saved YOUR position at: " .. tostring(PlayerCurrentData["ReturnTimer"]))

														local teleportPos = CFrame.new(
															Vector3.new(17944.895, -122.285, -3547.704)
														) * CFrame.Angles(
															math.rad(-0.592),
															math.rad(0.895),
															math.rad(0)
														)

														playerHRP.CFrame = teleportPos
														PlayerCurrentData["IsTeleported"] = true
														PlayerCurrentData["Init"] = true
														--print("Teleported " .. lpr.DisplayName .. " to: " .. tostring(teleportPos))
													end
												end

												PlayerCurrentData["TeleportPending"] = false
											end
											--]]
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										elseif s.Name == "Gun1" then
											s.SoundId = "rbxassetid://122905623131328";
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name == "Gun2" then
											s.SoundId = "rbxassetid://124883416643368"
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name == "explosion2" then
											s.SoundId = "rbxassetid://7244661974"
											s.PlaybackSpeed = modelData.soundSpeed
										else
											s.PlaybackSpeed = modelData.customSounds[soundName]
										end
									else
										if s.Name ~= "explosion2" and s.Name ~= "Hit" and 
											soundName ~= "Implosion" and soundName ~= "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										end
									end
								elseif modelData.id == "Galaxa_beatdown" then
									if soundName == "Nukem" and s.IsPlaying then
										if not s:FindFirstChildOfClass("ReverbSoundEffect") then
											for _, child in ipairs(game.Lighting:GetChildren()) do
												if not child.Name:find("CutsenseJoJo") then
													if CurrentPlayer == lpr then
														initializeColorCorrectionGalaxy();
													end
													--[
													s.SoundId = "105105608518242"
													s.TimePosition = 2.19
													s.PlaybackSpeed = 1
													
													--]]
													game:GetService("SoundService").AmbientReverb = Enum.ReverbType.Quarry
													game:GetService("SoundService"):FindFirstChild("Timestop"):Play();
													game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 4;
													if SettingsScript.DisplayLogs then
														print("Send Signal")
													end
													-- hook event if standModel destroyed
													local connection = nil
													if StandModel then
													connection = StandModel.Destroying:Connect(function()
														if CurrentPlayer == lpr then
														endColorCorrectionEffectGalaxy();
														setDayNight(false);
														game:GetService("SoundService").AmbientReverb = Enum.ReverbType.NoReverb
														game:GetService("SoundService"):FindFirstChild("Timeresume"):Play();
														game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 0.5;
														game:GetService("SoundService"):FindFirstChild("Timeresume").Volume = 2.5;
														connection:Disconnect()
														end
													end)
													else
														if CurrentPlayer == lpr then
															endColorCorrectionEffectGalaxy();
															setDayNight(false);
															game:GetService("SoundService").AmbientReverb = Enum.ReverbType.NoReverb
															game:GetService("SoundService"):FindFirstChild("Timeresume"):Play();
															game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 0.5;
															game:GetService("SoundService"):FindFirstChild("Timeresume").Volume = 2.5;
															warn("StandModel is nil")
														end
													end
													break
												end
											end
											if CurrentPlayer == lpr then
												startColorCorrectionEffectGalaxy();
												setDayNight(true)
												spawn(function()
													if StandModel and StandModel:FindFirstChild("Torso") then
														local rootPart = StandModel.Torso
														-- Lightning from sky to player
														local startPos = rootPart.Position + Vector3.new(0, 90, 0)
														local endPos = rootPart.Position + Vector3.new(0, -10, 0)
														-- Create the lightning
														CreateLightning(startPos, endPos, 3.5)
													end
												end)
											end
											local CustomReverb = Instance.new("ReverbSoundEffect", s)
											CustomReverb.DecayTime = 3.682
											CustomReverb.Density = 1
											CustomReverb.Diffusion = 0
											CustomReverb.DryLevel = 0
											CustomReverb.Priority = 1
											CustomReverb.WetLevel = -0.5
											CustomReverb.Enabled = true
											spawn(function()
												task.wait(1);
												local Muda = Instance.new("Sound", s);
												Muda.Name = "CutsenceMuda";
												Muda.SoundId = "rbxassetid://92536405916305";
												Muda.Volume = 0.55;
												Muda.PlaybackSpeed = 0.87;
												Muda.TimePosition = 1.13;
												Muda.RollOffMode = Enum.RollOffMode.Inverse;
												Muda.RollOffMaxDistance = 100;
												Muda.RollOffMinDistance = 10;
												local CustomReverb = Instance.new("ReverbSoundEffect", Muda);
												if CustomReverb:IsA("ReverbSoundEffect") ~= nil then
													CustomReverb.DecayTime = 3.085
													CustomReverb.Density = 1;
													CustomReverb.Diffusion = 1;
													CustomReverb.DryLevel = 0;
													CustomReverb.Priority = 1;
													CustomReverb.WetLevel = 1;
													CustomReverb.Enabled = true;
												else
													if SettingsScript.DisplayLogs then
														warn("Failed to Create ReverbSoundEffect")
													end
												end
												Muda:Play();
											end)
										end
									end
									if modelData.customSounds and modelData.customSounds[soundName] then
										if s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.SoundId = "rbxassetid://139005512098246"
											s.PlaybackSpeed = modelData.soundSpeed
											if CurrentPlayer == lpr then
												spawn(function()
													task.wait(1);
													endColorCorrectionEffectGalaxy();
												end)
											end
											spawn(function()
												task.wait(0.76);
												setDayNight(false);
												game:GetService("SoundService").AmbientReverb = Enum.ReverbType.NoReverb
												game:GetService("SoundService"):FindFirstChild("Timeresume"):Play();
												game:GetService("SoundService"):FindFirstChild("Timestop").Volume = 0.5;
												game:GetService("SoundService"):FindFirstChild("Timeresume").Volume = 2.5;
											end)
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										elseif s.Name == "Yell" then
											s.SoundId = "rbxassetid://6191764144";
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name == "Gun1" then
											s.SoundId = "rbxassetid://116210184916893"
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name == "Gun2" then
											s.SoundId = "rbxassetid://124883416643368";
											s.PlaybackSpeed = modelData.soundSpeed
										else
											s.PlaybackSpeed = modelData.customSounds[soundName]
										end
									else
										if s.Name ~= "explosion2" and s.Name ~= "Hit" and 
											soundName ~= "Implosion" and soundName ~= "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										end
									end
								elseif modelData.id == "mhe_beatdown" then
									if soundName == "Nukem" and s.IsPlaying then
										if not s:FindFirstChildOfClass("ReverbSoundEffect") then
											for _, child in ipairs(game.Lighting:GetChildren()) do
												s.SoundId = "rbxassetid://134933306082078"
												s.PlaybackSpeed = modelData.soundSpeed
												if not s.IsLoaded then
													if s.SoundId ~= "rbxassetid://6478272893" and s.SoundId == "rbxassetid://112686550007032" then
														print("Fallback to Nukem")
														s.SoundId = "rbxassetid://6478272893"
														s.PlaybackSpeed = modelData.soundSpeed
														local SoundReverb = Instance.new("ReverbSoundEffect", s)
														SoundReverb.DryLevel = 0
														SoundReverb.WetLevel = 0
														SoundReverb.DecayTime = 0 
														SoundReverb.Enabled = false
													end
												end
												break
											end
										end
									end
									if modelData.customSounds and modelData.customSounds[soundName] then
										if s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.SoundId = "rbxassetid://1939827707"
											s.PlaybackSpeed = modelData.soundSpeed
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										elseif s.Name == "Yell" then
											s.SoundId = "rbxassetid://7553397015"
											s.PlaybackSpeed = modelData.soundSpeed
											--print("Send Signal | ColorCorrectionEffect FadeOut")
										elseif s.Name == "Gun1" then
											s.SoundId = "rbxassetid://8255306220";
											s.PlaybackSpeed = modelData.soundSpeed
										elseif s.Name == "Gun2" then
											s.SoundId = "rbxassetid://75350494050797"
											s.PlaybackSpeed = modelData.soundSpeed
										else
											s.PlaybackSpeed = modelData.customSounds[soundName]
										end
									else
										if s.Name ~= "explosion2" and s.Name ~= "Hit" and 
											soundName ~= "Implosion" and soundName ~= "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										end
									end
								else
									if modelData.customSounds and modelData.customSounds[soundName] then
										s.PlaybackSpeed = modelData.customSounds[soundName]
									else
										if soundName == "Yell" or "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										elseif soundName ~= "explosion2" and soundName ~= "Hit" and 
											soundName ~= "Implosion" and soundName ~= "Male Scream Short Yelling Bursts Death Cries (SFX)" then
											s.PlaybackSpeed = modelData.soundSpeed
										end
									end
								end
							end
						end
					end
				end
			end
		end
		--print("Applied custom beatdown model: " .. modelData.name)
	end
	local function WriteStandModel(Stand)
		local character = lpr.Character;
		if not character then return end;
		local StandModel = character:FindFirstChild(Stand);
		if not StandModel then return end;
		if SlapBattlesSettings.ForceOverwriteBeatdown then
			for _, model in ipairs(CustomBeatdownModels) do
				if model.id == SelectedBeatdownModel and model.enabled then
					ApplyCustomBeatdownModel(StandModel, model, lpr)
					return
				end
			end
			for _, model in ipairs(CustomBeatdownModels) do
				if model.id == "evil_beatdown" then
					ApplyCustomBeatdownModel(StandModel, model, lpr)
					return
				end
			end
		end
		for v1, parts in ipairs(StandModel:GetChildren()) do
			if parts:IsA("BasePart") then
				if parts.Name == "Left Arm" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
				if parts.Name == "Right Arm" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
				if parts.Name == "Left Leg" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
				if parts.Name == "Right Leg" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
				if parts.Name == "Torso" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
				end;
				if parts.Name == "Head" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
			end;
		end;
		for _, p in ipairs(game.Players:GetPlayers()) do
			if p ~= lpr and p.Character then
				local LSB = p.Character:FindFirstChild("LastSlappedBy");
				if LSB and LSB.Value == lpr.Name then
					local torso = p.Character:FindFirstChild("Torso");
					if torso then
						for _, s in ipairs(torso:GetChildren()) do
							if s:IsA("Sound") then
								if s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
									s.PlaybackSpeed = 0.8;
								end;
								if s.Name ~= "explosion2" and "Hit" and "Implosion" and "Male Scream Short Yelling Bursts Death Cries (SFX)" then
									s.PlaybackSpeed = 0.7;
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end;
	local function WriteStandModelOther(Stand, PlayerId)
		local CurrentPlayer = game.Players:GetPlayerByUserId(PlayerId);
		if not CurrentPlayer then return end;
		local character = CurrentPlayer.Character;
		if not character then return end;
		local StandModel = character:FindFirstChild(Stand);
		if not StandModel then return end;
		if SlapBattlesSettings.ForceOverwriteBeatdown then
			for _, model in ipairs(CustomBeatdownModels) do
				if model.id == SelectedBeatdownModel and model.enabled then
					ApplyCustomBeatdownModel(StandModel, model, CurrentPlayer)
					return
				end
			end
			for _, model in ipairs(CustomBeatdownModels) do
				if model.id == "evil_beatdown" then
					ApplyCustomBeatdownModel(StandModel, model, CurrentPlayer)
					return
				end
			end
		end
		for v1, parts in ipairs(StandModel:GetChildren()) do
			if parts:IsA("BasePart") then
				if parts.Name == "Left Arm" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
				if parts.Name == "Right Arm" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
				if parts.Name == "Left Leg" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
				if parts.Name == "Right Leg" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
				if parts.Name == "Torso" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
				end;
				if parts.Name == "Head" then
					parts.Color = Color3.fromRGB(0, 0, 0);
					parts.Material = Enum.Material.Neon;
					if parts:FindFirstChild("fire") then
						parts:FindFirstChild("fire").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire2") then
						parts:FindFirstChild("fire2").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire3") then
						parts:FindFirstChild("fire3").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
					if parts:FindFirstChild("fire4") then
						parts:FindFirstChild("fire4").Color = ColorSequence.new(Color3.fromRGB(85, 0, 0));
					end
				end;
			end;
		end;
		for _, p in ipairs(game.Players:GetPlayers()) do
			if p ~= lpr and p.Character then
				local LSB = p.Character:FindFirstChild("LastSlappedBy");
				if LSB and LSB.Value == CurrentPlayer.Name then
					local torso = p.Character:FindFirstChild("Torso");
					if torso then
						for _, s in ipairs(torso:GetChildren()) do
							if s:IsA("Sound") then
								if s.Name == "Male Scream Short Yelling Bursts Death Cries (SFX)" then
									s.PlaybackSpeed = 0.8;
								end;
								if s.Name ~= "explosion2" and "Hit" and "Implosion" and "Male Scream Short Yelling Bursts Death Cries (SFX)" then
									s.PlaybackSpeed = 0.7;
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end;
	local function applyCustomStandToOtherPlayer(otherPlayer, modelData)
		if not otherPlayer or not otherPlayer.Character then return false end
		local standmodel = otherPlayer.Character:FindFirstChild("Stand")
		if not standmodel then return false end
		ApplyCustomBeatdownModel(standmodel, modelData, otherPlayer)
		if not ViewOtherCustomStands.ActiveChecks[otherPlayer] then
			ViewOtherCustomStands.ActiveChecks[otherPlayer] = {}
		end
		ViewOtherCustomStands.ActiveChecks[otherPlayer].appliedModel = modelData.id
		if standmodel == nil then return end
		if otherPlayer == nil then return end
		return true
	end
	local function restoreOriginalStand(player)
		if not player or not ViewOtherCustomStands.ActiveChecks[player] then return end
		local data = ViewOtherCustomStands.ActiveChecks[player]
		if player.Character then
			local stand = player.Character:FindFirstChild("Stand")
			if stand then
				WriteStandModelOther("Stand", player.UserId)
				ViewOtherCustomStands.ActiveChecks[player] = nil
			end
		end
	end

	local function startMonitoringOtherStands()
		if not ViewOtherCustomStands.Enabled then return end
		local function monitorPlayer(player)
			if player == lpr then return end
			if ViewOtherCustomStands.FriendStandsOnly and not isFriend(player) then
				return
			end
			local function setupCharacterMonitoring(character)
				if not character then return end
				local monitorConnection
				monitorConnection = game:GetService("RunService").Heartbeat:Connect(function()
					if not ViewOtherCustomStands.Enabled then
						if monitorConnection then
							monitorConnection:Disconnect()
						end
						return
					end
					local stand = character:FindFirstChild("Stand")
					if stand then
						local currentData = ViewOtherCustomStands.ActiveChecks[player]
						if not currentData or currentData.appliedModel ~= SelectedBeatdownModel then
							for _, model in ipairs(CustomBeatdownModels) do
								if model.id == SelectedBeatdownModel then
									applyCustomStandToOtherPlayer(player, model)
									break
								end
							end
						end
					else
						if ViewOtherCustomStands.ActiveChecks[player] then
							ViewOtherCustomStands.ActiveChecks[player] = nil
						end
					end
				end)
				if not ViewOtherCustomStands.ActiveChecks[player] then
					ViewOtherCustomStands.ActiveChecks[player] = {}
				end
				ViewOtherCustomStands.ActiveChecks[player].connection = monitorConnection
				character.AncestryChanged:Connect(function(_, parent)
					if not parent then
						if monitorConnection then
							monitorConnection:Disconnect()
						end
						if ViewOtherCustomStands.ActiveChecks[player] then
							ViewOtherCustomStands.ActiveChecks[player] = nil
						end
					end
				end)
			end
			if player.Character then
				setupCharacterMonitoring(player.Character)
			end
			player.CharacterAdded:Connect(function(character)
				setupCharacterMonitoring(character)
			end)
		end
		for _, player in ipairs(game.Players:GetPlayers()) do
			monitorPlayer(player)
		end
		game.Players.PlayerAdded:Connect(function(player)
			if ViewOtherCustomStands.Enabled then
				monitorPlayer(player)
			end
		end)
		if SettingsScript.DisplayLogs then
			print("Started monitoring other players' stands")
		end
	end
	local function stopMonitoringOtherStands()
		for player, data in pairs(ViewOtherCustomStands.ActiveChecks) do
			if data.connection then
				data.connection:Disconnect()
			end
			restoreOriginalStand(player)
		end
		ViewOtherCustomStands.ActiveChecks = {}
		if SettingsScript.DisplayLogs then
			print("Stopped monitoring other players' stands")
		end
	end
	local function addViewOtherStandsSetting()
		local ViewStandsSetting = Instance.new("Frame", Desclabel)
		ViewStandsSetting.Name = "ViewStandsSetting"
		ViewStandsSetting.AnchorPoint = Vector2.new(0.5, 0.5)
		ViewStandsSetting.Active = true
		ViewStandsSetting.BackgroundColor3 = Color3.fromRGB(35, 31, 59)
		ViewStandsSetting.BackgroundTransparency = 0
		ViewStandsSetting.Size = UDim2.new(1, 0, 0.2, 0)
		ViewStandsSetting.SizeConstraint = Enum.SizeConstraint.RelativeXY
		if GameDetection.IsSlapBattles then
			ViewStandsSetting.Visible = true
		else
			ViewStandsSetting.Visible = false
		end
		ViewStandsSetting.ZIndex = 6
		ViewStandsSetting.LayoutOrder = 9
		local UICorner_ViewStands = Instance.new("UICorner", ViewStandsSetting)
		UICorner_ViewStands.CornerRadius = UDim.new(0, 5)
		local Title_ViewStands = Instance.new("TextLabel", ViewStandsSetting)
		Title_ViewStands.AnchorPoint = Vector2.new(0.5, 0)
		Title_ViewStands.BackgroundTransparency = 1
		Title_ViewStands.Position = UDim2.new(0.5, 0, 0, 0)
		Title_ViewStands.Size = UDim2.new(1, 0, 1, 0)
		Title_ViewStands.SizeConstraint = Enum.SizeConstraint.RelativeXY
		Title_ViewStands.Visible = true
		Title_ViewStands.ZIndex = 6
		Title_ViewStands.RichText = true
		Title_ViewStands.Text = "  View Others' Custom Stands:"
		Title_ViewStands.TextColor3 = Color3.fromRGB(194, 194, 194)
		Title_ViewStands.TextScaled = false
		Title_ViewStands.TextSize = 18
		Title_ViewStands.TextWrapped = true
		Title_ViewStands.TextXAlignment = Enum.TextXAlignment.Left
		Title_ViewStands.TextYAlignment = Enum.TextYAlignment.Center
		local UIPadding_TitleViewStands = Instance.new("UIPadding", Title_ViewStands)
		UIPadding_TitleViewStands.PaddingBottom = UDim.new(-0.2, 0)
		UIPadding_TitleViewStands.PaddingLeft = UDim.new(0, 0)
		UIPadding_TitleViewStands.PaddingRight = UDim.new(0, 0)
		UIPadding_TitleViewStands.PaddingTop = UDim.new(-0.2, 0)
		local Button_ViewStands = Instance.new("TextButton", Title_ViewStands)
		Button_ViewStands.Name = "ViewOtherStands"
		Button_ViewStands.Active = true
		Button_ViewStands.AutoButtonColor = true
		Button_ViewStands.AnchorPoint = Vector2.new(0.5, 0.5)
		Button_ViewStands.BackgroundColor3 = Color3.fromRGB(70, 60, 95)
		Button_ViewStands.BackgroundTransparency = 0.55
		Button_ViewStands.Position = UDim2.new(0.85, 0, 0.5, 0)
		Button_ViewStands.Size = UDim2.new(0, 200, 0, 31)
		Button_ViewStands.SizeConstraint = Enum.SizeConstraint.RelativeXY
		Button_ViewStands.Visible = true
		Button_ViewStands.ZIndex = 6
		Button_ViewStands.Font = Enum.Font.Oswald
		Button_ViewStands.FontFace.Weight = Enum.FontWeight.Bold
		Button_ViewStands.FontFace.Style = Enum.FontStyle.Italic
		Button_ViewStands.Text = "Disabled"
		Button_ViewStands.TextColor3 = Color3.fromRGB(214, 214, 214)
		Button_ViewStands.RichText = true
		Button_ViewStands.TextScaled = true
		Button_ViewStands.TextWrapped = true
		Button_ViewStands.TextXAlignment = Enum.TextXAlignment.Center
		Button_ViewStands.TextYAlignment = Enum.TextYAlignment.Center
		local UICorner_ButtonViewStands = Instance.new("UICorner", Button_ViewStands)
		UICorner_ButtonViewStands.CornerRadius = UDim.new(0, 5)
		local UIStroke_ButtonViewStands = Instance.new("UIStroke", Button_ViewStands)
		UIStroke_ButtonViewStands.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		UIStroke_ButtonViewStands.BorderStrokePosition = Enum.BorderStrokePosition.Outer
		UIStroke_ButtonViewStands.Thickness = 2.9
		UIStroke_ButtonViewStands.Color = Color3.fromRGB(103, 92, 150)
		UIStroke_ButtonViewStands.StrokeSizingMode = Enum.StrokeSizingMode.FixedSize
		UIStroke_ButtonViewStands.LineJoinMode = Enum.LineJoinMode.Round
		UIStroke_ButtonViewStands.Transparency = 0
		Button_ViewStands.MouseButton1Click:Connect(function()
			ViewOtherCustomStands.Enabled = not ViewOtherCustomStands.Enabled
			if ViewOtherCustomStands.Enabled then
				Button_ViewStands.Text = "Enabled"
				Button_ViewStands.BackgroundColor3 = Color3.fromRGB(84, 255, 113)
				if SettingsScript.DisplayLogs then
					print("View Other Custom Stands: Enabled")
				end
				startMonitoringOtherStands()
			else
				Button_ViewStands.Text = "Disabled"
				Button_ViewStands.BackgroundColor3 = Color3.fromRGB(70, 60, 95)
				if SettingsScript.DisplayLogs then
					print("View Other Custom Stands: Disabled")
				end
				stopMonitoringOtherStands()
			end
		end)
		return ViewStandsSetting, Button_ViewStands
	end
	--// RUN SERVICES
	u6.RenderStepped:Connect(function()
		if SlapBattlesSettings.ForceOverwriteBeatdown == true then
			if GetStandModel("Stand") == true then
				WriteStandModel("Stand")
			end
		end
		if SlapBattlesSettings.BiggerHitbox then
			if lpr.Character then
				local stand = lpr.Character:FindFirstChild("Stand")
				if stand then
					local hitbox = stand:FindFirstChild("Hitbox")
					if hitbox and hitbox:IsA("BasePart") then
						if hitbox.Size ~= CustomHitbox then
							modifyStandHitbox();
						end
					end
				end
			end
		end
	end)
	--// BUTTONS
	ButtonSettings.MouseButton1Click:Connect(function()
		if Settings.Visible == false then
			Settings.Visible = true
		else
			Settings.Visible = false
		end
		if TeleportUI and TeleportUI.Visible then
			TeleportUI.Visible = false
		end
		if CustomBeatdownUI and CustomBeatdownUI.Visible then
			CustomBeatdownUI.Visible = false
		end
	end)
	Button_Slider5.MouseButton1Click:Connect(function()
		SettingsScript.KickPlayerAfterCutsenceBD = not SettingsScript.KickPlayerAfterCutsenceBD
		if SettingsScript.KickPlayerAfterCutsenceBD then
			Button_Slider5.Text = "ON"
			Button_Slider5.BackgroundColor3 = Color3.fromRGB(84, 255, 113)
			if SettingsScript.DisplayLogs then
				print("SettingsScript.KickPlayerAfterCutsenceBD: Enabled")
			end
		else
			Button_Slider5.Text = "OFF"
			Button_Slider5.BackgroundColor3 = Color3.fromRGB(70, 60, 95)
			if SettingsScript.DisplayLogs then
				print("SettingsScript.KickPlayerAfterCutsenceBD: Disabled")
			end
		end
	end)
	

	-- // DETECTORS
	UIS.InputBegan:Connect(function(p6, p7)
		if p6.UserInputType == Enum.UserInputType.MouseButton1 or p6.UserInputType == Enum.UserInputType.Touch then
			if p7 then
				return;
			end;
		end;
		-- handle anything u want
	end);
	if GameDetection.IsSlapBattles then
		local function updateCustomModelsStatus()
			for _, model in ipairs(CustomBeatdownModels) do
				if model.id == SelectedBeatdownModel then
					model.enabled = SlapBattlesSettings.ForceOverwriteBeatdown
				else
					model.enabled = false
				end
			end
		end
		Button_Slap1.MouseButton1Click:Connect(function()
			SlapBattlesSettings.ForceOverwriteBeatdown = not SlapBattlesSettings.ForceOverwriteBeatdown
			if SlapBattlesSettings.ForceOverwriteBeatdown then
				Button_Slap1.Text = "Enabled"
				Button_Slap1.BackgroundColor3 = Color3.fromRGB(84, 255, 113)
				updateCustomModelsStatus()
				ButtonCustomBeatdown.Visible = true
				if SettingsScript.DisplayLogs then
					print("Force Overwrite Beatdown Model: Enabled - Using: " .. SelectedBeatdownModel)
				end
			else
				Button_Slap1.Text = "Disabled"
				Button_Slap1.BackgroundColor3 = Color3.fromRGB(70, 60, 95)
				updateCustomModelsStatus()
				if CustomBeatdownUI and CustomBeatdownUI.Visible then
					CustomBeatdownUI.Visible = false
				end
				if SettingsScript.DisplayLogs then
					print("Force Overwrite Beatdown Model: Disabled")
				end
			end
		end)
		Button_Slap2.MouseButton1Click:Connect(function()
			SlapBattlesSettings.BiggerHitbox = not SlapBattlesSettings.BiggerHitbox
			if SlapBattlesSettings.BiggerHitbox then
				Button_Slap2.Text = "Enabled"
				Button_Slap2.BackgroundColor3 = Color3.fromRGB(84, 255, 113)
				if SettingsScript.DisplayLogs then
					print("Bigger Hitbox: Enabled")
				end
				modifyStandHitbox()

			else
				Button_Slap2.Text = "Disabled"
				Button_Slap2.BackgroundColor3 = Color3.fromRGB(70, 60, 95)
				if SettingsScript.DisplayLogs then
					print("Bigger Hitbox: Disabled")
				end
				modifyStandHitbox()
			end
		end)
		addViewOtherStandsSetting();
		spawn(function()
			task.wait(0.25);
			startMonitoringOtherStands()
		end)
		if SettingsScript.DisplayLogs then
			print("View Other Custom Stands system initialized")
		end
		updateCustomBeatdownEvent.Event:Connect(function()
			updateCustomModelsStatus()
		end)
	end
	--// CONSTANTS
	ButtonTeleport.MouseButton1Click:Connect(toggleTeleportUI)
	ButtonCustomBeatdown.MouseButton1Click:Connect(toggleCustomBeatdownUI)
	game.Players.PlayerAdded:Connect(function(player)
		task.wait(0.5)
		if TeleportData.TeleportUI and TeleportData.TeleportUI.Visible then
			updatePlayerList2()
		end
	end)
	game.Players.PlayerRemoving:Connect(function(player)
		if TeleportData.TeleportUI and TeleportData.TeleportUI.Visible then
			updatePlayerList2()
		end
	end)
	
	-- AUTO CLEANUP ON DESTROY APP
	local appConnection = nil
	appConnection = TranslationUI.Destroying:Connect(function()
		if appConnection then
			stopMonitoringOtherStands();
			SettingsScript.KickPlayerAfterCutsenceBD = false
			SlapBattlesSettings.ForceOverwriteBeatdown = false
			SlapBattlesSettings.BiggerHitbox = false
			ViewOtherCustomStands.Enabled = false
			SelectedBeatdownModel = "uncle_beatdown" -- reset to default
			print("Bye Bye")
			appConnection:Disconnect()
			appConnection = nil
		end
	end)

	--// INITIALIZE
	startAutoUpdate()
	createTeleportUI()
	print("Running on version:" ..tostring(BuildVersion));
	return TranslationApp;

end

-- // AUTO INITIALIZE \\ --

TranslationApp.Init();
