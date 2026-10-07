--!strict
-- shared/config/Balance.luau
-- Starting values; tune in playtests.

return {
	PASSIVE_QI_PER_SEC = 1.5,
	MAX_QI_PER_CALL = 500,
	QI_BUDGET_MARGIN = 1.15, -- 15% over theoretical max, so a perfect bot can't beat a perfect human
	MEDITATE_MOVE_TOLERANCE = 2, -- studs; moving further than this cancels meditation

	-- Active Qi circulation (Phase 2)
	ACTIVE_BASE_QI_PER_NODE = 6,
	PERFECT_WINDOW = 0.08, -- +/- seconds
	GREAT_WINDOW = 0.16,
	PERFECT_SCORE = 1.0,
	GREAT_SCORE = 0.6,
	COMBO_STEP = 0.05, -- +5% per consecutive perfect/great hit
	COMBO_MAX = 2.0,
	CYCLE_TIMEOUT = 15, -- seconds; server watchdog if a client never submits

	-- Breakthrough and tribulation (Phase 3)
	TRIBULATION_FAIL_QI_LOSS = 0.30,
	TRIBULATION_COOLDOWN = 60,
	TRIBULATION_WAVE_COUNT = 3,
	TRIBULATION_TELEGRAPH_TIME = 1.2,
	TRIBULATION_WAVE_GAP = 0.5,
	TRIBULATION_HIT_RADIUS = 5, -- studs; stand within this of the strike at impact time = hit
	TRIBULATION_MAX_HITS_TO_SURVIVE = 1, -- can take this many hits and still pass
	ATTEMPT_BREAKTHROUGH_COOLDOWN = 5, -- seconds between AttemptBreakthrough remote calls
}
