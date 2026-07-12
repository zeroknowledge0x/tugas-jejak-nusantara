--! Signal.luau
--! Minimal typed signal (event emitter) for decoupled system communication.

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> T...,
	Destroy: (self: Signal<T...>) -> (),
	_disconnectAll: (self: Signal<T...>) -> (),
}

type Listener = {
	fn: any,
	next: Listener?,
}

local Signal = {}
Signal.__index = Signal

function Signal.new<T...>(): Signal<T...>
	local self = setmetatable({}, Signal) :: any
	self._head = nil :: Listener?
	self._yield = nil :: { (T...) -> () }?
	return self
end

function Signal:Connect(fn)
	local node = { fn = fn, next = nil } :: Listener
	if self._head == nil then
		self._head = node
	else
		local cur = self._head
		while cur.next do
			cur = cur.next
		end
		cur.next = node
	end
	local conn = {
		Disconnect = function()
			self:_remove(node)
		end,
	}
	return conn
end

function Signal:Fire(...)
	local cur = self._head
	while cur do
		(cur.fn)(...)
		cur = cur.next
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	self._yield = self._yield or {}
	table.insert(self._yield, thread)
	return coroutine.yield()
end

function Signal:_remove(node)
	local cur = self._head
	local prev: Listener? = nil
	while cur do
		if cur == node then
			if prev == nil then
				self._head = cur.next
			else
				prev.next = cur.next
			end
			return
		end
		prev = cur
		cur = cur.next
	end
end

function Signal:_disconnectAll()
	self._head = nil
	self._yield = nil
end

function Signal:Destroy()
	self:_disconnectAll()
end

return Signal
