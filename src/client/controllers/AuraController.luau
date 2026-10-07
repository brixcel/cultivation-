--!strict
-- client/controllers/AuraController.luau
-- Shows every player's realm/title above their head and a particle aura once they
-- have one, so others can see your progress. Reads only from Player attributes the
-- server already syncs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Auras = require(ReplicatedStorage.Shared.config.Auras)

local AuraController = {}

function AuraController:Init(_controllers: { [string]: any }) end

local function attachAuraParticles(root: BasePart): ParticleEmitter
	local attachment = Instance.new("Attachment")
	attachment.Name = "AuraAttachment"
	attachment.Parent = root

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AuraParticles"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(1, 2)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.3)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = attachment

	return emitter
end

local function attachPresence(player: Player, character: Model)
	local head = character:WaitForChild("Head", 5) :: BasePart?
	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not head or not root then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RealmBillboard"
	billboard.Size = UDim2.fromOffset(160, 36)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(212, 175, 55)
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.Parent = billboard

	local auraEmitter = attachAuraParticles(root)

	local function refresh()
		local title = player:GetAttribute("Title")
		local realm = player:GetAttribute("Realm")
		label.Text = tostring(if title ~= nil then title else (if realm ~= nil then realm else ""))

		local auraId = player:GetAttribute("Aura")
		local visual = typeof(auraId) == "string" and Auras.Get(auraId) or nil
		if visual then
			auraEmitter.Color = ColorSequence.new(visual.color)
			auraEmitter.Rate = visual.particleRate
		else
			auraEmitter.Rate = 0
		end
	end

	player.AttributeChanged:Connect(refresh)
	refresh()
end

function AuraController:Start()
	local function onPlayer(player: Player)
		if player.Character then
			attachPresence(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character: Model)
			attachPresence(player, character)
		end)
	end

	for _, existingPlayer in Players:GetPlayers() do
		onPlayer(existingPlayer)
	end
	Players.PlayerAdded:Connect(onPlayer)

	print("[AuraController] started")
end

return AuraController
