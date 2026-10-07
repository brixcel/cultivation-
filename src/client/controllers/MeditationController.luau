--!strict
-- client/controllers/MeditationController.luau
-- Sends the player's meditate intent to the server. The server owns whether Qi
-- actually rises; this controller only sends inputs and shows a simple posture cue.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.remotes.Remotes)

local WALK_SPEED = 16 -- Roblox's default Humanoid.WalkSpeed

local player = Players.LocalPlayer

local MeditationController = {}

function MeditationController:Init(_controllers: { [string]: any })
	self._meditating = false
end

function MeditationController:IsMeditating(): boolean
	return self._meditating
end

function MeditationController:_setMeditating(on: boolean)
	self._meditating = on

	local setMeditating = Remotes.Get("SetMeditating") :: RemoteEvent
	setMeditating:FireServer(on)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if on then 0 else WALK_SPEED
	end
end

function MeditationController:Toggle()
	self:_setMeditating(not self._meditating)
end

function MeditationController:Start()
	player.CharacterAdded:Connect(function()
		self._meditating = false
	end)

	print("[MeditationController] started")
end

return MeditationController
