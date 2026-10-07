--!strict
-- server/services/PlayerStateService.luau
-- One authoritative state per player. Every other service checks state before acting.
-- Later phases add InTribulation, Cooldown, and InCave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Realms = require(ReplicatedStorage.Shared.config.Realms)

export type State = "Loading" | "Idle" | "Meditating" | "Circulating"

local ALLOWED_TRANSITIONS: { [State]: { [State]: boolean } } = {
	Idle = { Meditating = true },
	Meditating = { Idle = true, Circulating = true },
	Circulating = { Meditating = true },
}

local PlayerStateService = {}

function PlayerStateService:Init(services: { [string]: any })
	self._dataService = services.DataService
	self._states = {} :: { [Player]: State }
end

function PlayerStateService:Start()
	self._dataService.OnLoaded:Connect(function(player: Player)
		self._states[player] = "Idle"
		self:SyncAttributes(player)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		self._states[player] = "Loading"
		player:SetAttribute("State", "Loading")
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._states[player] = nil
	end)

	print("[PlayerStateService] started")
end

function PlayerStateService:GetState(player: Player): State
	return self._states[player] or "Loading"
end

function PlayerStateService:TrySetState(player: Player, to: State): boolean
	local from = self:GetState(player)
	if from == to then
		return true
	end

	local allowed = ALLOWED_TRANSITIONS[from]
	if not allowed or not allowed[to] then
		return false
	end

	self._states[player] = to
	player:SetAttribute("State", to)
	return true
end

function PlayerStateService:SyncAttributes(player: Player)
	local profile = self._dataService:GetProfile(player)
	if not profile then
		return
	end

	local data = profile.Data
	player:SetAttribute("Realm", data.realm)
	player:SetAttribute("Qi", data.qi)
	player:SetAttribute("QiMax", Realms.Get(data.realm).qiToBreakthrough)
	player:SetAttribute("State", self:GetState(player))
end

return PlayerStateService
