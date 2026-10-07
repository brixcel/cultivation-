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
}
