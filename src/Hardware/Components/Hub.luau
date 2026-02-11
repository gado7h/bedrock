local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Hub Physical Component
-- Bridges to Bedrock_Hub RemoteFunction.

local Hub = {}
Hub.__index = Hub

function Hub.new()
	local self = setmetatable({
		_remote = nil,
	}, Hub)
	return self
end

function Hub:Connect()
	local host = ReplicatedStorage:WaitForChild("Bedrock_Host", 10)
	if host then
		self._remote = host:WaitForChild("Bedrock_Hub", 5) :: RemoteFunction?
	end
	return self._remote ~= nil
end

function Hub:Invoke(command: string, ...: any)
	if not self._remote then return nil, "Hub Offline" end
	local args = { ... }
	local ok, result, err = pcall(function()
		return self._remote:InvokeServer(command, unpack(args))
	end)
    if not ok then return nil, tostring(result) end
	return result, err
end

return Hub
