--!strict
-- server/services/CultivationService.luau
-- AddQi is the single choke point every Qi change must go through, per CLAUDE.md.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.remotes.Remotes)
local Realms = require(Shared.config.Realms)
local Techniques = require(Shared.config.Techniques)
local Balance = require(Shared.config.Balance)
local RateLimiter = require(Shared.util.RateLimiter)

local TICK_INTERVAL = 1 -- seconds; server ticks cultivation at 1 Hz

local CultivationService = {}

function CultivationService:Init(services: { [string]: any })
	self._dataService = services.DataService
	self._stateService = services.PlayerStateService
	-- Budget caps the theoretical max rate (best technique, perfect play) plus margin,
	-- so even a bot can't out-earn a perfect human.
	self._rate = RateLimiter.new(Balance.MAX_QI_PER_CALL * Balance.QI_BUDGET_MARGIN, TICK_INTERVAL)
	self._meditateAnchor = {} :: { [Player]: Vector3 }
	self._accumulator = 0
end

function CultivationService:AddQi(player: Player, amount: number, source: string)
	local profile = self._dataService:GetProfile(player)
	if not profile then
		return
	end

	amount = math.clamp(amount, 0, Balance.MAX_QI_PER_CALL)
	if amount <= 0 then
		return
	end

	if not self._rate:Allow(player, amount) then
		warn(`[CultivationService] rate exceeded for {player.Name} from {source}`)
		return
	end

	local maxQi = Realms.Get(profile.Data.realm).qiToBreakthrough
	self._dataService:Update(player, function(data)
		data.qi = math.min(data.qi + amount, maxQi)
		data.stats.totalQi += amount
	end)
	self._stateService:SyncAttributes(player)
end

function CultivationService:_onSetMeditating(player: Player, on: boolean)
	if typeof(on) ~= "boolean" then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	if on then
		if not self._stateService:TrySetState(player, "Meditating") then
			return
		end
		self._meditateAnchor[player] = root.Position

		local profile = self._dataService:GetProfile(player)
		if profile and not profile.Data.flags.tutorialDone then
			self._dataService:Update(player, function(data)
				data.flags.tutorialDone = true
			end)
			self._stateService:SyncAttributes(player)
		end
	else
		self._stateService:TrySetState(player, "Idle")
		self._meditateAnchor[player] = nil
	end
end

function CultivationService:_tickMeditating(dt: number)
	for _, player in Players:GetPlayers() do
		if self._stateService:GetState(player) ~= "Meditating" then
			continue
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local anchor = self._meditateAnchor[player]

		if not root or not anchor or (root.Position - anchor).Magnitude > Balance.MEDITATE_MOVE_TOLERANCE then
			self._stateService:TrySetState(player, "Idle")
			self._meditateAnchor[player] = nil
			continue
		end

		local profile = self._dataService:GetProfile(player)
		if not profile then
			continue
		end

		local technique = Techniques.Get(profile.Data.equippedTechnique)
		local amount = Balance.PASSIVE_QI_PER_SEC * technique.passiveMultiplier * dt
		self:AddQi(player, amount, "passive")
	end
end

function CultivationService:Start()
	local setMeditating = Remotes.Get("SetMeditating") :: RemoteEvent
	setMeditating.OnServerEvent:Connect(function(player: Player, on: unknown)
		self:_onSetMeditating(player, on :: boolean)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._meditateAnchor[player] = nil
		self._rate:Clear(player)
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		self._accumulator += dt
		if self._accumulator < TICK_INTERVAL then
			return
		end
		local elapsed = self._accumulator
		self._accumulator = 0
		self:_tickMeditating(elapsed)
	end)

	print("[CultivationService] started")
end

return CultivationService
