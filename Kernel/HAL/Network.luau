--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = {}
Network.__index = Network

export type Network = typeof(setmetatable(
	{} :: {
		_remote: RemoteFunction?,
	},
	Network
))

function Network.new(): Network
	local self = setmetatable({
		_remote = nil,
	}, Network)

	-- Locate the RemoteFunction
	-- In a real boot scenario, we might wait for it, but for now we assume it exists or fail gracefully
	self._remote = ReplicatedStorage:WaitForChild("PremiumOS_Network", 5)

	if not self._remote then
		warn("[KERNEL] Network HAL: Could not find 'PremiumOS_Network' RemoteFunction!")
	end

	return self
end

function Network:Request(command: string, ...: any): (boolean, any)
	if not self._remote then
		return false, "Network Offline"
	end

	-- Security: Don't allow blocking the main thread for too long?
	-- For now, we rely on the caller (Syscalls) to handle async/yielding if needed.
	-- Since this is a HAL, we just do the low-level invoke.

	local args = { ... }
	local ok, result = pcall(function()
		return self._remote:InvokeServer(command, unpack(args))
	end)

	if not ok then
		return false, result -- Result is error message
	end

	return true, result
end

return Network
