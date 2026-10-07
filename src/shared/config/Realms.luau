--!strict
-- shared/config/Realms.luau
-- Balance numbers for realm Qi thresholds. Never hard-code these in services.

export type RealmId = "Mortal" | "QiCondensation" | "FoundationEstablishment"

export type RealmData = {
	display: string,
	qiToBreakthrough: number,
	tribulation: string?,
	aura: string?,
	title: string?,
}

local Realms = {}

Realms.order = { "Mortal", "QiCondensation", "FoundationEstablishment" } :: { RealmId }

Realms.data = {
	Mortal = {
		display = "Mortal",
		qiToBreakthrough = 1500,
		tribulation = "Minor",
	},
	QiCondensation = {
		display = "Qi Condensation",
		qiToBreakthrough = 7500,
		tribulation = "Lesser",
		aura = "QiWisps",
		title = "Qi Condensation Cultivator",
	},
	FoundationEstablishment = {
		display = "Foundation Establishment",
		qiToBreakthrough = math.huge,
		aura = "FoundationGlow",
		title = "Foundation Establishment Cultivator",
	},
} :: { [RealmId]: RealmData }

function Realms.Get(realmId: string): RealmData
	local data = (Realms.data :: { [string]: RealmData })[realmId]
	assert(data, `Realms.Get: unknown realm "{realmId}"`)
	return data
end

return Realms
