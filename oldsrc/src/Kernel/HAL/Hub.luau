local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hub = {}
Hub.__index = Hub

export type Hub = {
	_remote: any,
	Push: (self: Hub, namespace: string, repo: string, data: any) -> (boolean, string?),
	Pull: (self: Hub, namespace: string, repo: string) -> (any, string?),
	Init: (self: Hub) -> (boolean, string?),
	Shutdown: (self: Hub) -> (),
}

function Hub.new(): Hub
	local self = setmetatable({
		_remote = nil,
	}, Hub)
	return (self :: any) :: Hub
end

function Hub.Init(self: Hub): (boolean, string?)
	local host = ReplicatedStorage:WaitForChild("Bedrock_Host", 10)
	if host then
		self._remote = host:WaitForChild("Bedrock_Hub", 5) :: RemoteFunction?
	end

	if not self._remote then
		return false, "Bedrock_Hub remote not found"
	end

	return true, nil
end

function Hub.Shutdown(self: Hub)
	self._remote = nil
end

function Hub.Push(self: Hub, namespace: string, repo: string, data: any): (boolean, string?)
	if not self._remote then
		return false, "Hub Offline"
	end

	local ok, success, err = pcall(function()
		return self._remote:InvokeServer("PUSH", namespace, repo, data)
	end)

	if not ok then
		return false, tostring(success)
	end

	return success, err
end

function Hub.Pull(self: Hub, namespace: string, repo: string): (any, string?)
	if not self._remote then
		return nil, "Hub Offline"
	end

	local ok, result, err = pcall(function()
		return self._remote:InvokeServer("PULL", namespace, repo)
	end)

	if not ok then
		return nil, tostring(result)
	end

	return result, err
end

return Hub
