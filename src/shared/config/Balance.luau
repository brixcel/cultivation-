--!strict
-- shared/config/Balance.luau
-- Starting values; tune in playtests. Phase 1 only needs passive-cultivation and
-- rate-limit numbers — active-circulation balance values arrive in Phase 2.

return {
	PASSIVE_QI_PER_SEC = 1.5,
	MAX_QI_PER_CALL = 500,
	QI_BUDGET_MARGIN = 1.15, -- 15% over theoretical max, so a perfect bot can't beat a perfect human
	MEDITATE_MOVE_TOLERANCE = 2, -- studs; moving further than this cancels meditation
}
