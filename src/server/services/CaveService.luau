--!strict
-- server/services/CaveService.luau
-- Hidden cave: any CollectionService-tagged "CaveFormation" entrance, gated by
-- realm, grants the cave technique once per player. Never hard-code instance
-- paths; tag whatever formation geometry gets placed in Studio.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.remotes.Remotes)
local Realms = require(Shared.config.Realms)
local Techniques = require(Shared.config.Techniques)

local FORMATION_TAG = "CaveFormation"
local MIN_REALM = "QiCondensation"
local CAVE_TECHNIQUE = "BlackSwordBreath"

local CaveService = {}

function CaveService:Init(services: { [string]: any })
	self._dataService = services.DataService
end

function CaveService:_notify(player: Player, text: string, kind: string)
	local notify = Remotes.Get("Notify") :: RemoteEvent
	notify:FireClient(player, text, kind)
end

local function realmIndex(realmId: string): number
	for index, id in Realms.order do
		if id == realmId then
			return index
		end
	end
	return 1
end

function CaveService:_onChannel(player: Player, formation: BasePart, maxDistance: number)
	local profile = self._dataService:GetProfile(player)
	if not profile then
		return
	end

	-- Defense-in-depth: don't rely solely on ProximityPrompt's own range enforcement.
	local character = player.Character
	local root = character and (character:FindFirstChild("HumanoidRootPart") :: BasePart?)
	if not root or (root.Position - formation.Position).Magnitude > maxDistance then
		return
	end

	if realmIndex(profile.Data.realm) < realmIndex(MIN_REALM) then
		self:_notify(player, "Your foundation is too weak. The formation repels you.", "error")
		return
	end

	if profile.Data.flags.caveFound then
		self:_notify(player, "The tomb is silent; you have already claimed what it offered.", "info")
		return
	end

	self._dataService:Update(player, function(data)
		data.flags.caveFound = true
		if not table.find(data.techniques, CAVE_TECHNIQUE) then
			table.insert(data.techniques, CAVE_TECHNIQUE)
		end
		data.equippedTechnique = CAVE_TECHNIQUE
	end)

	self:_notify(player, "You have entered the Tomb of the Black Sword Ancestor...", "success")
	self:_notify(player, `Technique learned: {Techniques.Get(CAVE_TECHNIQUE).display}`, "success")
end

function CaveService:_attachFormation(formation: Instance)
	local prompt = formation:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Channel Qi"
		prompt.ObjectText = "Hidden Formation"
		prompt.HoldDuration = 1.5
		prompt.MaxActivationDistance = 10
		prompt.Parent = formation :: any
	end
	local activePrompt = prompt :: ProximityPrompt

	local anchorPart = formation:IsA("BasePart") and formation or formation:FindFirstChildWhichIsA("BasePart")
	if not anchorPart then
		return
	end

	activePrompt.Triggered:Connect(function(player: Player)
		self:_onChannel(player, anchorPart :: BasePart, activePrompt.MaxActivationDistance)
	end)
end

-- Placeholder entrance so the gate/grant logic is testable before the real
-- waterfall/tomb geometry exists; Phase 5 replaces the part, not the tag.
local function createPlaceholderFormation()
	if CollectionService:GetTagged(FORMATION_TAG)[1] then
		return
	end

	local part = Instance.new("Part")
	part.Name = "CaveFormationPlaceholder"
	part.Size = Vector3.new(6, 8, 2)
	part.Position = Vector3.new(20, 4, -15)
	part.Anchored = true
	part.Color = Color3.fromRGB(46, 139, 87)
	part.Material = Enum.Material.Rock
	part.Parent = workspace
	CollectionService:AddTag(part, FORMATION_TAG)
end

function CaveService:Start()
	createPlaceholderFormation()

	for _, formation in CollectionService:GetTagged(FORMATION_TAG) do
		self:_attachFormation(formation)
	end
	CollectionService:GetInstanceAddedSignal(FORMATION_TAG):Connect(function(formation: Instance)
		self:_attachFormation(formation)
	end)

	print("[CaveService] started")
end

return CaveService
