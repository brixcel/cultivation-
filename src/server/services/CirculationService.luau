--!strict
-- server/services/CirculationService.luau
-- Issues and scores active Qi circulation cycles. The server sets the pattern and
-- tempo and measures real elapsed time itself, so a client can't fake speed or combos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.remotes.Remotes)
local Techniques = require(Shared.config.Techniques)
local Balance = require(Shared.config.Balance)
local Formulas = require(Shared.util.Formulas)

type Cycle = {
	id: string,
	pattern: { string },
	tempo: number,
	issuedAt: number,
}

local CirculationService = {}

function CirculationService:Init(services: { [string]: any })
	self._dataService = services.DataService
	self._stateService = services.PlayerStateService
	self._cultivationService = services.CultivationService
	self._cycles = {} :: { [Player]: Cycle }
end

function CirculationService:_requestCycle(player: Player): any
	if self._stateService:GetState(player) ~= "Meditating" then
		return nil
	end
	if self._cycles[player] then
		return nil
	end

	local profile = self._dataService:GetProfile(player)
	if not profile then
		return nil
	end

	local technique = Techniques.Get(profile.Data.equippedTechnique)
	local cycle: Cycle = {
		id = HttpService:GenerateGUID(false),
		pattern = technique.pattern,
		tempo = technique.tempo,
		issuedAt = os.clock(),
	}

	if not self._stateService:TrySetState(player, "Circulating") then
		return nil
	end

	self._cycles[player] = cycle

	task.delay(Balance.CYCLE_TIMEOUT, function()
		if self._cycles[player] == cycle then
			self._cycles[player] = nil
			self._stateService:TrySetState(player, "Meditating")
		end
	end)

	return { cycleId = cycle.id, pattern = cycle.pattern, tempo = cycle.tempo }
end

function CirculationService:_submitCycle(player: Player, cycleId: unknown, hits: unknown): any
	local cycle = self._cycles[player]
	if not cycle or cycleId ~= cycle.id then
		return nil
	end

	self._cycles[player] = nil
	self._stateService:TrySetState(player, "Meditating")

	if typeof(hits) ~= "table" then
		return nil
	end

	local profile = self._dataService:GetProfile(player)
	if not profile then
		return nil
	end
	local technique = Techniques.Get(profile.Data.equippedTechnique)

	-- Can't have legitimately finished the pattern faster than 90% of its nominal duration.
	local elapsed = os.clock() - cycle.issuedAt
	local minDuration = #cycle.pattern * cycle.tempo * 0.9
	local hitsTable = (if elapsed >= minDuration then hits else {}) :: { any }

	local combo = 1
	local totalQi = 0
	local perfectCount = 0
	local breakdown = {}

	for index = 1, #cycle.pattern do
		local raw = hitsTable[index]
		local offset = if typeof(raw) == "number" then raw - (index - 1) * cycle.tempo else math.huge
		local hitScore = Formulas.ScoreHit(
			offset,
			Balance.PERFECT_WINDOW,
			Balance.GREAT_WINDOW,
			Balance.PERFECT_SCORE,
			Balance.GREAT_SCORE
		)
		combo = Formulas.NextCombo(combo, hitScore, Balance.COMBO_STEP, Balance.COMBO_MAX)
		local qi =
			Formulas.ActiveQiForNode(hitScore, combo, technique.activeMultiplier, Balance.ACTIVE_BASE_QI_PER_NODE)
		totalQi += qi
		if hitScore >= Balance.PERFECT_SCORE then
			perfectCount += 1
		end
		table.insert(breakdown, { score = hitScore, combo = combo })
	end

	self._dataService:Update(player, function(data)
		data.stats.cyclesCompleted += 1
		data.stats.perfectHits += perfectCount
	end)

	self._cultivationService:AddQi(player, totalQi, "active")

	return { breakdown = breakdown, combo = combo, qiGained = totalQi }
end

function CirculationService:Start()
	local requestCycle = Remotes.Get("RequestCycle") :: RemoteFunction
	requestCycle.OnServerInvoke = function(player: Player)
		return self:_requestCycle(player)
	end

	local submitCycle = Remotes.Get("SubmitCycle") :: RemoteFunction
	submitCycle.OnServerInvoke = function(player: Player, cycleId: unknown, hits: unknown)
		return self:_submitCycle(player, cycleId, hits)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		self._cycles[player] = nil
	end)

	print("[CirculationService] started")
end

return CirculationService
