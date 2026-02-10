local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _RunService = game:GetService("RunService")

local Network = {}
Network.__index = Network

export type Network = {
	_remote: RemoteFunction?,
	Request: (self: Network, command: string, ...any) -> (boolean, any),
	Init: (self: Network) -> (boolean, string?),
	Shutdown: (self: Network) -> (),
}

function Network.new()
	local self = setmetatable({
		_remote = nil,
	}, Network)
	return self
end

function Network:Init()
	local self = self
	local ServerFolder = ReplicatedStorage:WaitForChild("Server", 10)
	if ServerFolder then
		self._remote = ServerFolder:WaitForChild("Bedrock_Internet", 5)
	end

	if not self._remote then
		return false, "Bedrock_Internet remote not found"
	end

	return true, nil
end

function Network:Shutdown()
	local self = self
	self._remote = nil
end

function Network:Request(command, ...)
	local remote = self._remote
	if not remote then
		return false, "Network Offline"
	end

	-- Security: Don't allow blocking the main thread for too long?
	-- For now, we rely on the caller (Syscalls) to handle async/yielding if needed.
	-- Since this is a HAL, we just do the low-level invoke.

	local args = { ... }
	local ok, result = pcall(function()
		return remote:InvokeServer(command, unpack(args))
	end)

	if not ok then
		return false, result -- Result is error message
	end

	return true, result
end

return Network
