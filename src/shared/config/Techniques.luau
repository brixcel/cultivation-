--!strict
-- shared/config/Techniques.luau
-- Balance numbers for cultivation techniques. Never hard-code these in services.

export type TechniqueId = string

export type TechniqueData = {
	display: string,
	pattern: { string },
	tempo: number,
	activeMultiplier: number,
	passiveMultiplier: number,
}

local Techniques = {}

Techniques.data = {
	BasicQiGathering = {
		display = "Basic Qi Gathering Technique",
		pattern = { "Dantian", "Core", "Head", "Core", "Dantian" },
		tempo = 1.0,
		activeMultiplier = 1.0,
		passiveMultiplier = 1.0,
	},
} :: { [TechniqueId]: TechniqueData }

function Techniques.Get(id: string): TechniqueData
	local data = Techniques.data[id]
	assert(data, `Techniques.Get: unknown technique "{id}"`)
	return data
end

return Techniques
