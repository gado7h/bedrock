local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Network Physical Component
-- Bridges to Bedrock_Internet RemoteFunction.

local Network = {}
Network.__index = Network

function Network.new()
	local self = setmetatable({
		_remote = nil,
        OnActivity = nil :: (() -> ())?,
	}, Network)
	return self
end

function Network:Connect()
	local host = ReplicatedStorage:WaitForChild("Bedrock_Host", 10)
	if host then
		self._remote = host:WaitForChild("Bedrock_Internet", 5) :: RemoteFunction?
	end
	return self._remote ~= nil
end

function Network:Invoke(command: string, ...: any)
	if not self._remote then return false, "Network Offline" end
    
    if self.OnActivity then self.OnActivity() end
    
	local args = { ... }
	local ok, result = pcall(function()
		return self._remote:InvokeServer(command, unpack(args))
	end)
	return ok, result
end

return Network
