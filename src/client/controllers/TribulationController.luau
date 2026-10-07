--!strict
-- client/controllers/TribulationController.luau
-- Visual-only: sky darkens, lightning telegraphs and strikes, breakthrough result
-- banner. The server decides who gets hit; this never computes outcomes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.remotes.Remotes)

local player = Players.LocalPlayer

local NORMAL_AMBIENT = Lighting.Ambient
local NORMAL_BRIGHTNESS = Lighting.Brightness
local STORM_AMBIENT = Color3.fromRGB(10, 10, 20)
local STORM_BRIGHTNESS = 0.5

type WaveData = { position: Vector3, telegraphTime: number, wave: number }

local TribulationController = {}

function TribulationController:Init(_controllers: { [string]: any }) end

local function strikeAt(position: Vector3, telegraphTime: number)
	local ring = Instance.new("Part")
	ring.Name = "TribulationTelegraph"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(235, 70, 70)
	ring.Size = Vector3.new(0.2, 8, 8)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.4
	ring.Parent = workspace

	TweenService:Create(ring, TweenInfo.new(telegraphTime), { Transparency = 0.9 }):Play()

	task.delay(telegraphTime, function()
		ring:Destroy()

		local bolt = Instance.new("Part")
		bolt.Name = "LightningBolt"
		bolt.Anchored = true
		bolt.CanCollide = false
		bolt.Material = Enum.Material.Neon
		bolt.Color = Color3.fromRGB(255, 255, 255)
		bolt.Size = Vector3.new(1, 40, 1)
		bolt.CFrame = CFrame.new(position + Vector3.new(0, 20, 0))
		bolt.Parent = workspace

		local impactAttachment = Instance.new("Attachment")
		impactAttachment.WorldPosition = position + Vector3.new(0, 0.5, 0)
		impactAttachment.Parent = workspace.Terrain

		local burst = Instance.new("ParticleEmitter")
		burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		burst.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		burst.Lifetime = NumberRange.new(0.3, 0.6)
		burst.Speed = NumberRange.new(8, 14)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Size = NumberSequence.new(0.6)
		burst.Rate = 0
		burst.Parent = impactAttachment
		burst:Emit(30)

		task.delay(0.15, function()
			bolt:Destroy()
		end)
		task.delay(0.8, function()
			impactAttachment:Destroy()
		end)
	end)
end

function TribulationController:Start()
	local screen = Instance.new("ScreenGui")
	screen.Name = "TribulationBanner"
	screen.ResetOnSpawn = false
	screen.Parent = player:WaitForChild("PlayerGui")

	local banner = Instance.new("TextLabel")
	banner.Size = UDim2.fromOffset(500, 60)
	banner.Position = UDim2.new(0.5, -250, 0.35, 0)
	banner.BackgroundTransparency = 1
	banner.Font = Enum.Font.GothamBold
	banner.TextSize = 32
	banner.TextColor3 = Color3.fromRGB(235, 240, 245)
	banner.TextStrokeTransparency = 0.3
	banner.Text = ""
	banner.Visible = false
	banner.Parent = screen

	local wave = Remotes.Get("TribulationWave") :: RemoteEvent
	wave.OnClientEvent:Connect(function(data: WaveData)
		if data.wave == 1 then
			TweenService:Create(Lighting, TweenInfo.new(0.5), { Brightness = STORM_BRIGHTNESS }):Play()
			Lighting.Ambient = STORM_AMBIENT
		end
		strikeAt(data.position, data.telegraphTime)
	end)

	local result = Remotes.Get("TribulationResult") :: RemoteEvent
	result.OnClientEvent:Connect(function(success: boolean, _newRealm: string?)
		TweenService:Create(Lighting, TweenInfo.new(1), { Brightness = NORMAL_BRIGHTNESS }):Play()
		Lighting.Ambient = NORMAL_AMBIENT

		banner.Text = if success then "Tribulation survived!" else "Tribulation failed..."
		banner.TextColor3 = if success then Color3.fromRGB(46, 200, 120) else Color3.fromRGB(220, 70, 70)
		banner.Visible = true

		task.delay(3, function()
			banner.Visible = false
		end)
	end)

	print("[TribulationController] started")
end

return TribulationController
