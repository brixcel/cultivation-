--!strict
-- shared/types/Types.luau
-- Shared type definitions. Bump schemaVersion and add a migration when this shape changes.

export type PlayerData = {
	schemaVersion: number,
	realm: string,
	qi: number,
	techniques: { string },
	equippedTechnique: string,
	flags: {
		caveFound: boolean,
		tutorialDone: boolean,
	},
	stats: {
		totalQi: number,
		playSeconds: number,
		cyclesCompleted: number,
		perfectHits: number,
		tribulationsPassed: number,
		tribulationsFailed: number,
	},
}

local Types = {}

return Types
