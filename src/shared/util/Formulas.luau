--!strict
-- shared/util/Formulas.luau
-- Pure math for cultivation scoring. No instances, no side effects, unit-testable.

local Formulas = {}

-- Score a single tap offset (seconds early/late) against the timing windows.
function Formulas.ScoreHit(
	offsetSeconds: number,
	perfectWindow: number,
	greatWindow: number,
	perfectScore: number,
	greatScore: number
): number
	local absOffset = math.abs(offsetSeconds)
	if absOffset <= perfectWindow then
		return perfectScore
	elseif absOffset <= greatWindow then
		return greatScore
	end
	return 0
end

-- Combo multiplier for the NEXT node: grows on a perfect/great hit, resets on a miss.
function Formulas.NextCombo(currentCombo: number, hitScore: number, comboStep: number, comboMax: number): number
	if hitScore <= 0 then
		return 1
	end
	return math.min(currentCombo + comboStep, comboMax)
end

function Formulas.ActiveQiForNode(
	hitScore: number,
	comboMultiplier: number,
	activeMultiplier: number,
	baseQiPerNode: number
): number
	return baseQiPerNode * hitScore * comboMultiplier * activeMultiplier
end

return Formulas
