--!strict
-- shared/config/Auras.luau
-- Visual parameters for realm auras (Phase 5), keyed by the "aura" id Realms.luau
-- grants on breakthrough. Never hard-code these in controllers.

export type AuraId = string

export type AuraVisual = {
	color: Color3,
	particleRate: number,
}

local Auras = {}

Auras.data = {
	QiWisps = { color = Color3.fromRGB(46, 139, 87), particleRate = 12 },
	FoundationGlow = { color = Color3.fromRGB(212, 175, 55), particleRate = 20 },
} :: { [AuraId]: AuraVisual }

function Auras.Get(id: string): AuraVisual?
	return Auras.data[id]
end

return Auras
