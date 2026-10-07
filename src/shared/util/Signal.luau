--!strict
-- shared/util/Signal.luau
-- Minimal Connect/Fire signal, used where a BindableEvent would be overkill.

export type Connection = {
	Disconnect: (Connection) -> (),
}

export type Signal = {
	Connect: (Signal, fn: (...any) -> ()) -> Connection,
	Fire: (Signal, ...any) -> (),
}

local Signal = {}
Signal.__index = Signal

function Signal.new(): Signal
	return setmetatable({
		_handlers = {} :: { (...any) -> () },
	}, Signal) :: any
end

function Signal:Connect(fn: (...any) -> ()): Connection
	local handlers = self._handlers
	table.insert(handlers, fn)

	local connection = {}
	function connection.Disconnect()
		local index = table.find(handlers, fn)
		if index then
			table.remove(handlers, index)
		end
	end

	return connection :: any
end

function Signal:Fire(...: any)
	for _, fn in self._handlers do
		task.spawn(fn, ...)
	end
end

return Signal
