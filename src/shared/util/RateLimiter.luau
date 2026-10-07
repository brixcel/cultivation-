--!strict
-- shared/util/RateLimiter.luau
-- Fixed-window per-player budget limiter. Allow(player, amount) returns false once the
-- player has used up their budget for the current window.

export type RateLimiter = {
	Allow: (RateLimiter, player: Player, amount: number) -> boolean,
	Clear: (RateLimiter, player: Player) -> (),
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(budgetPerWindow: number, windowSeconds: number?): RateLimiter
	return setmetatable({
		_windowSeconds = windowSeconds or 1,
		_budgetPerWindow = budgetPerWindow,
		_usage = {} :: { [Player]: { amount: number, windowStart: number } },
	}, RateLimiter) :: any
end

function RateLimiter:Allow(player: Player, amount: number): boolean
	local now = os.clock()
	local entry = self._usage[player]
	if not entry or now - entry.windowStart >= self._windowSeconds then
		entry = { amount = 0, windowStart = now }
		self._usage[player] = entry
	end

	if entry.amount + amount > self._budgetPerWindow then
		return false
	end

	entry.amount += amount
	return true
end

function RateLimiter:Clear(player: Player)
	self._usage[player] = nil
end

return RateLimiter
