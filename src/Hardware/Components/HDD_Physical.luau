local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- HDD Physical Component
-- Bridges to Bedrock_HDD RemoteFunction (DataStore access).

local HDD = {}
HDD.__index = HDD

function HDD.new()
	local self = setmetatable({
		_remote = nil,
        OnActivity = nil :: (() -> ())?,
	}, HDD)
	return self
end

function HDD:Connect()
	local host = ReplicatedStorage:WaitForChild("Bedrock_Host", 10)
	if host then
		self._remote = host:WaitForChild("Bedrock_HDD", 5) :: RemoteFunction?
	end
	return self._remote ~= nil
end

function HDD:Invoke(command: string, ...: any)
	if not self._remote then return nil, "HDD Offline" end
    
    if self.OnActivity then self.OnActivity() end
    
	local args = { ... }
	local ok, result = pcall(function()
		return self._remote:InvokeServer(command, unpack(args))
	end)
	if not ok then return nil, tostring(result) end
	return result
end

return HDD
