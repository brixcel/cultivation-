--!strict
-- server/services/DataService.luau
-- Owns every player's ProfileStore profile. This is the only module that may call
-- into ProfileStore; everyone else goes through GetProfile/Update/OnLoaded.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(script.Parent.Parent.packages.ProfileStore)
local Signal = require(ReplicatedStorage.Shared.util.Signal)

local SCHEMA_VERSION = 1

local TEMPLATE = {
	schemaVersion = SCHEMA_VERSION,
	realm = "Mortal",
	qi = 0,
	techniques = { "BasicQiGathering" },
	equippedTechnique = "BasicQiGathering",
	flags = { caveFound = false, tutorialDone = false },
	stats = {
		totalQi = 0,
		playSeconds = 0,
		cyclesCompleted = 0,
		perfectHits = 0,
		tribulationsPassed = 0,
		tribulationsFailed = 0,
	},
}

-- MIGRATIONS[fromVersion] upgrades data from fromVersion to fromVersion + 1.
-- Never rename or delete a field without adding a migration here.
local MIGRATIONS: { [number]: (any) -> any } = {}

local DataService = {}

function DataService:Init(_services: { [string]: any })
	self._store = ProfileStore.New("PlayerData", TEMPLATE)
	self._profiles = {} :: { [Player]: any }
	self.OnLoaded = Signal.new()
end

function DataService:_migrate(data: any): any
	while data.schemaVersion < SCHEMA_VERSION do
		local migrate = MIGRATIONS[data.schemaVersion]
		if not migrate then
			break
		end
		data = migrate(data)
	end
	return data
end

function DataService:_load(player: Player)
	local profile = self._store:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		player:Kick("Could not load your save. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile.Data = self:_migrate(profile.Data)

	profile.OnSessionEnd:Connect(function()
		self._profiles[player] = nil
		player:Kick("Your data session ended. Please rejoin.")
	end)

	if player.Parent ~= Players then
		-- Player left while the session was loading.
		profile:EndSession()
		return
	end

	self._profiles[player] = profile
	self.OnLoaded:Fire(player)
end

function DataService:Start()
	Players.PlayerAdded:Connect(function(player: Player)
		self:_load(player)
	end)
	for _, player in Players:GetPlayers() do
		self:_load(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		local profile = self._profiles[player]
		if profile then
			profile:EndSession()
		end
	end)

	game:BindToClose(function()
		for _, profile in self._profiles do
			profile:EndSession()
		end
	end)

	print("[DataService] started")
end

function DataService:GetProfile(player: Player): any
	return self._profiles[player]
end

-- The only sanctioned way to mutate a player's saved data.
function DataService:Update(player: Player, fn: (data: any) -> ())
	local profile = self._profiles[player]
	if not profile then
		return
	end
	fn(profile.Data)
end

return DataService
