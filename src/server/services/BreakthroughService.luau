--!strict
-- server/services/BreakthroughService.luau
-- Eligibility, outcome, and realm advancement for the breakthrough attempt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.remotes.Remotes)
local Realms = require(Shared.config.Realms)
local Balance = require(Shared.config.Balance)

local BreakthroughService = {}

function BreakthroughService:Init(services: { [string]: any })
	self._dataService = services.DataService
	self._stateService = services.PlayerStateService
	self._tribulationService = services.TribulationService
	self._broadcastService = services.BroadcastService
	self._lastAttempt = {} :: { [Player]: number }
end

local function nextRealm(currentRealm: string): string?
	local order = Realms.order
	for index, id in order do
		if id == currentRealm then
			return order[index + 1]
		end
	end
	return nil
end

function BreakthroughService:_notify(player: Player, text: string, kind: string)
	local notify = Remotes.Get("Notify") :: RemoteEvent
	notify:FireClient(player, text, kind)
end

function BreakthroughService:_attempt(player: Player)
	local now = os.clock()
	if now - (self._lastAttempt[player] or 0) < Balance.ATTEMPT_BREAKTHROUGH_COOLDOWN then
		return
	end
	self._lastAttempt[player] = now

	local profile = self._dataService:GetProfile(player)
	if not profile then
		return
	end

	local state = self._stateService:GetState(player)
	if state ~= "Idle" and state ~= "Meditating" then
		return
	end

	local realmId = profile.Data.realm
	local toRealm = nextRealm(realmId)
	if not toRealm then
		self:_notify(player, "There is no realm beyond this one yet.", "error")
		return
	end

	local maxQi = Realms.Get(realmId).qiToBreakthrough
	if profile.Data.qi < maxQi then
		self:_notify(player, "Your Qi is not yet full.", "error")
		return
	end

	if not self._stateService:TrySetState(player, "InTribulation") then
		return
	end

	local tribulationResult = Remotes.Get("TribulationResult") :: RemoteEvent
	local survived = self._tribulationService:Run(player)

	profile = self._dataService:GetProfile(player)
	if not profile then
		return
	end

	if survived then
		local realmData = Realms.Get(toRealm)
		self._dataService:Update(player, function(data)
			data.realm = toRealm
			data.qi = 0
			data.stats.tribulationsPassed += 1
		end)
		player:SetAttribute("Title", realmData.title)
		player:SetAttribute("Aura", realmData.aura)
		self._stateService:TrySetState(player, "Idle")
		self._stateService:SyncAttributes(player)
		tribulationResult:FireClient(player, true, toRealm)
		self._broadcastService:Announce(
			`{player.Name} survived the Heavenly Tribulation and reached {realmData.display}!`
		)
	else
		self._dataService:Update(player, function(data)
			data.qi = math.floor(data.qi * (1 - Balance.TRIBULATION_FAIL_QI_LOSS))
			data.stats.tribulationsFailed += 1
		end)
		self._stateService:TrySetState(player, "Cooldown")
		self._stateService:SyncAttributes(player)
		tribulationResult:FireClient(player, false)

		task.delay(Balance.TRIBULATION_COOLDOWN, function()
			if self._stateService:GetState(player) == "Cooldown" then
				self._stateService:TrySetState(player, "Idle")
			end
		end)
	end
end

function BreakthroughService:Start()
	local attemptBreakthrough = Remotes.Get("AttemptBreakthrough") :: RemoteEvent
	attemptBreakthrough.OnServerEvent:Connect(function(player: Player)
		self:_attempt(player)
	end)

	print("[BreakthroughService] started")
end

return BreakthroughService
