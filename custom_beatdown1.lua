return {
	id = "my_custom_beatdown",
	name = "My Custom Beatdown",
	description = "A cool custom model.",
	color = Color3.fromRGB(138, 0, 176),
	fireColor = Color3.fromRGB(204, 123, 255),
	material = Enum.Material.Neon,
	icon = "rbxassetid://1234567890",
	iconColor = Color3.fromRGB(93, 35, 126),
	soundSpeed = 0.75,
	customSounds = {
		["Nukem"] = { speed = 0.68, soundId = "rbxassetid://6478272893" },
		["Yell"] = 0.6,                              -- only speed
		["Implosion"] = { speed = 0.65, soundId = "rbxassetid://123456789" },
		["Male Scream Short Yelling Bursts Death Cries (SFX)"] = 0.76,
	},
	specialEffects = function(parts)
		-- add effects
		-- example, galaxa beatdown:
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
			local rightArm = standModel:FindFirstChild("Right Arm")
			if not rightArm then return end

			local GlovePart = rightArm:FindFirstChild("Glove")
			if GlovePart then
				print("Found Glove, replacing with Sword...")

				-- Check if Sword already exists BEFORE destroying Glove
				if rightArm:FindFirstChild("Sword") then
					print("Sword already exists.")
					return
				end

				GlovePart:Destroy()

				local Sword = Instance.new("MeshPart")
				Sword.Name = "Sword"
				Sword.Size = Vector3.new(0.819, 7.285, 0.247)
				Sword.Color = Color3.fromRGB(255, 84, 246)
				Sword.Material = Enum.Material.Neon
				Sword.Massless = true
				Sword.CanCollide = false
				Sword.Anchored = false
				Sword.MeshId = "rbxassetid://13696156138"
				Sword.Reflectance = 1
				Sword.Parent = rightArm

				-- Weld
				local Weld = Instance.new("Weld")
				Weld.Part0 = Sword
				Weld.Part1 = rightArm
				Weld.C0 = CFrame.new(-1, -3, 0) * CFrame.Angles(math.rad(90), math.rad(-90), 0)
				Weld.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), 0)
				Weld.Parent = Sword

				-- ============================================================
				-- PARTICLE 1: ItemHighlight
				-- ============================================================
				local ItemHighlight = Instance.new("ParticleEmitter")
				ItemHighlight.Name = "ItemHighlight"
				ItemHighlight.Brightness = 1
				ItemHighlight.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(184, 6, 255)),
					ColorSequenceKeypoint.new(0.734, Color3.fromRGB(184, 6, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 221, 255))
				})
				ItemHighlight.LightEmission = 1
				ItemHighlight.LightInfluence = 5
				ItemHighlight.Orientation = Enum.ParticleOrientation.FacingCamera
				ItemHighlight.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 3.69, 1.43),
					NumberSequenceKeypoint.new(1, 1.54, 0)
				})
				ItemHighlight.Texture = "http://www.roblox.com/asset/?id=1847258023"
				ItemHighlight.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1, 0),
					NumberSequenceKeypoint.new(0.502, 0.929, 0),
					NumberSequenceKeypoint.new(1, 1, 0),
				})
				ItemHighlight.ZOffset = 1
				ItemHighlight.EmissionDirection = Enum.NormalId.Top
				ItemHighlight.Enabled = true
				ItemHighlight.Lifetime = 1
				ItemHighlight.Rate = 100
				ItemHighlight.Rotation = 0
				ItemHighlight.RotSpeed = 0
				ItemHighlight.Speed = 0.01
				ItemHighlight.SpreadAngle = Vector2.new(0, 0)
				ItemHighlight.Shape = Enum.ParticleEmitterShape.Box
				ItemHighlight.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
				ItemHighlight.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume  -- ✅ Fixed
				ItemHighlight.Acceleration = Vector3.new(0, 0, 0)
				ItemHighlight.Drag = 0
				ItemHighlight.LockedToPart = true
				ItemHighlight.TimeScale = 1
				ItemHighlight.VelocityInheritance = 0
				ItemHighlight.WindAffectsDrag = false
				ItemHighlight.Parent = Sword

				-- ============================================================
				-- PARTICLE 2: SideSmoke
				-- ============================================================
				local SideSmoke = Instance.new("ParticleEmitter")
				SideSmoke.Name = "SideSmoke"
				SideSmoke.Brightness = 5
				SideSmoke.Color = ColorSequence.new(Color3.fromRGB(144, 87, 255))  -- ✅ Fixed
				SideSmoke.LightEmission = 1
				SideSmoke.LightInfluence = 0
				SideSmoke.Orientation = Enum.ParticleOrientation.FacingCamera
				SideSmoke.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.62, 0.836),
					NumberSequenceKeypoint.new(1, 1.62, 0.836)
				})
				SideSmoke.Texture = "rbxassetid://9139094373"
				SideSmoke.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.253, 0.148),
					NumberSequenceKeypoint.new(0.711, 0.186, 0.0692),
					NumberSequenceKeypoint.new(1, 0.989, 0.011),
				})
				SideSmoke.ZOffset = -1
				SideSmoke.EmissionDirection = Enum.NormalId.Right
				SideSmoke.Enabled = true
				SideSmoke.Lifetime = NumberRange.new(1.5, 2.5)
				SideSmoke.Rate = 20
				SideSmoke.Rotation = NumberRange.new(-180, 180)
				SideSmoke.RotSpeed = 0
				SideSmoke.Speed = 0.139
				SideSmoke.SpreadAngle = Vector2.new(0, 360)
				SideSmoke.Shape = Enum.ParticleEmitterShape.Box
				SideSmoke.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
				SideSmoke.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume  -- ✅ Fixed
				SideSmoke.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8
				SideSmoke.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
				SideSmoke.FlipbookBlendFrames = true
				SideSmoke.Acceleration = Vector3.new(0, -0.815, 0)
				SideSmoke.Drag = 8
				SideSmoke.LockedToPart = true
				SideSmoke.TimeScale = 1
				SideSmoke.VelocityInheritance = 0
				SideSmoke.WindAffectsDrag = false
				SideSmoke.Parent = Sword

				-- ============================================================
				-- PARTICLE 3: TextureParticle3
				-- ============================================================
				local TextureParticle3 = Instance.new("ParticleEmitter")
				TextureParticle3.Name = "TextureParticle3"
				TextureParticle3.Brightness = 10
				TextureParticle3.Color = ColorSequence.new(Color3.fromRGB(248, 46, 255))  -- ✅ Fixed
				TextureParticle3.LightEmission = 1
				TextureParticle3.LightInfluence = 0
				TextureParticle3.Orientation = Enum.ParticleOrientation.FacingCamera
				TextureParticle3.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.75, 0.75),
					NumberSequenceKeypoint.new(1, 0.25, 0)
				})
				TextureParticle3.Texture = "rbxassetid://9139094373"
				TextureParticle3.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0, 0),
					NumberSequenceKeypoint.new(0.508, 0, 0),
					NumberSequenceKeypoint.new(1, 1, 0),
				})
				TextureParticle3.ZOffset = 0
				TextureParticle3.EmissionDirection = Enum.NormalId.Front
				TextureParticle3.Enabled = true
				TextureParticle3.Lifetime = 1
				TextureParticle3.Rate = 20
				TextureParticle3.Rotation = NumberRange.new(-180, 180)
				TextureParticle3.RotSpeed = NumberRange.new(-30, 30)
				TextureParticle3.Speed = 0.5
				TextureParticle3.SpreadAngle = Vector2.new(180, 90)
				TextureParticle3.Shape = Enum.ParticleEmitterShape.Box
				TextureParticle3.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
				TextureParticle3.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume  -- ✅ Fixed
				TextureParticle3.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8
				TextureParticle3.FlipbookBlendFrames = true
				TextureParticle3.FlipbookFramerate = NumberRange.new(20, 40)  -- ✅ Fixed
				TextureParticle3.FlipbookMode = Enum.ParticleFlipbookMode.Loop
				TextureParticle3.FlipbookStartRandom = true
				TextureParticle3.Acceleration = Vector3.new(0, 1, 0)
				TextureParticle3.Drag = 0
				TextureParticle3.LockedToPart = true
				TextureParticle3.TimeScale = 1
				TextureParticle3.VelocityInheritance = 0
				TextureParticle3.WindAffectsDrag = false
				TextureParticle3.Parent = Sword

				print("Sword created successfully!")
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
	end,
	customHandler = function(s, StandModel, CurrentPlayer, lpr, Camera, modelData)
		-- do stuff with the stand model
		-- example, i want to make the camera follow the victim's head just like SMT_Beatdown
		local victimHead = s and s.Parent and s.Parent.Parent and s.Parent.Parent:FindFirstChild("Head")
		local CutsenseCamPos = StandModel:FindFirstChild("CutsceneCameraPart")
		if CutsenseCamPos then
			CutsenseCamPos:Destroy()
		end
		if victimHead then
			Camera.CFrame = victimHead.CFrame
		end
		-- END
	end,
	enabled = false,
}
