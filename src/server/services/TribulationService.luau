--!strict
-- server/services/TribulationService.luau
-- Runs a tribulation: telegraphed lightning strikes the player must dodge. Hits are
-- decided server-side from the character's HumanoidRootPart position; the client
-- (TribulationController) only renders the storm.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.remotes.Remotes)
local Balance = require(Shared.config.Balance)

local TribulationService = {}

function TribulationService:Init(_services: { [string]: any }) end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	return character and (character:FindFirstChild("HumanoidRootPart") :: BasePart?)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

-- Returns true if the player survived.
function TribulationService:Run(player: Player): boolean
	local tribulationWave = Remotes.Get("TribulationWave") :: RemoteEvent
	local hits = 0

	for wave = 1, Balance.TRIBULATION_WAVE_COUNT do
		local root = getRoot(player)
		if not root then
			return false
		end

		local strikePosition = root.Position
		tribulationWave:FireClient(player, {
			position = strikePosition,
			telegraphTime = Balance.TRIBULATION_TELEGRAPH_TIME,
			wave = wave,
		})

		task.wait(Balance.TRIBULATION_TELEGRAPH_TIME)

		root = getRoot(player)
		if not root then
			return false
		end

		if flatDistance(root.Position, strikePosition) <= Balance.TRIBULATION_HIT_RADIUS then
			hits += 1
		end

		task.wait(Balance.TRIBULATION_WAVE_GAP)
	end

	return hits <= Balance.TRIBULATION_MAX_HITS_TO_SURVIVE
end

return TribulationService
