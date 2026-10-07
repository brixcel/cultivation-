--!strict
-- Server bootstrap: require every service, then Init all, then Start all.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local services = script.services

-- Create every remote up front so a client's WaitForChild never races a service
-- that only calls Remotes.Get lazily deep inside a conditional path.
require(ReplicatedStorage.Shared.remotes.Remotes).CreateAll()

local order = {
	"DataService",
	"PlayerStateService",
	"BroadcastService",
	"CultivationService",
	"CirculationService",
	"TribulationService",
	"BreakthroughService",
	"CaveService",
}

local loaded = {}
for _, name in order do
	loaded[name] = require(services[name]) :: any
end
for _, name in order do
	if loaded[name].Init then
		loaded[name]:Init(loaded)
	end
end
for _, name in order do
	if loaded[name].Start then
		task.spawn(loaded[name].Start, loaded[name])
	end
end
