--!strict
-- server/services/BroadcastService.luau
-- Server-wide announcements (e.g. breakthroughs).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.remotes.Remotes)

local BroadcastService = {}

function BroadcastService:Init(_services: { [string]: any }) end

function BroadcastService:Start()
	print("[BroadcastService] started")
end

function BroadcastService:Announce(text: string, style: string?)
	local announce = Remotes.Get("Announce") :: RemoteEvent
	announce:FireAllClients(text, style or "default")
end

return BroadcastService
