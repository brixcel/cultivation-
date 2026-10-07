--!strict
-- Server bootstrap: require every service, then Init all, then Start all.
local services = script.services

local order = {
	"HelloService", -- Phase 0 smoke test; remove in Phase 1
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
