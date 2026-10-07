--!strict
-- client/controllers/MeditationController.luau
-- Sends the player's meditate intent to the server. The server owns whether Qi
-- actually rises; this controller only sends inputs and shows a simple posture cue.
--
-- WalkSpeed is driven by the server-synced "State" attribute, not a self-tracked
-- flag: a flag that's only updated optimistically on click can desync from the
-- server (e.g. a SetMeditating(true) sent while already Meditating/Circulating is
-- correctly rejected server-side but was still "accepted" locally) and, worse, can
-- leave WalkSpeed stuck at 0 into a tribulation the player then can't dodge.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.remotes.Remotes)

local WALK_SPEED = 16 -- Roblox's default Humanoid.WalkSpeed

local player = Players.LocalPlayer

local MeditationController = {}

function MeditationController:Init(_controllers: { [string]: any }) end

function MeditationController:IsMeditating(): boolean
	return player:GetAttribute("State") == "Meditating"
end

local function applyWalkSpeedForState()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = if player:GetAttribute("State") == "Meditating" then 0 else WALK_SPEED
end

function MeditationController:Toggle()
	local setMeditating = Remotes.Get("SetMeditating") :: RemoteEvent
	setMeditating:FireServer(not self:IsMeditating())
end

function MeditationController:Start()
	player.AttributeChanged:Connect(function(attribute: string)
		if attribute == "State" then
			applyWalkSpeedForState()
		end
	end)

	player.CharacterAdded:Connect(function()
		task.defer(applyWalkSpeedForState)
	end)

	print("[MeditationController] started")
end

return MeditationController
