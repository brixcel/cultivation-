--!strict
-- Client bootstrap: require every controller, then Init all, then Start all.
local controllers = script.controllers

local order: { string } = {
	"UIController",
	"MeditationController",
}

local loaded = {}
for _, name in order do
	loaded[name] = require(controllers:WaitForChild(name)) :: any
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

print("[Client] started")
