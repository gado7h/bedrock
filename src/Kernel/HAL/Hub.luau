--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hub = {}
Hub.__index = Hub

export type Hub = typeof(setmetatable(
	{} :: {
		_remote: RemoteFunction?,
	},
	Hub
))

function Hub.new(): Hub
	local self = setmetatable({
		_remote = nil,
	}, Hub)

	-- Locate the RemoteFunction (Server sets it up in src/Server)
	-- It will be located in the Server folder in ReplicatedStorage
	local ServerFolder = ReplicatedStorage:WaitForChild("Server", 10)
	if ServerFolder then
		self._remote = ServerFolder:WaitForChild("Bedrock_Hub", 5) :: RemoteFunction?
	end

	if not self._remote then
		warn("[KERNEL] Hub HAL: Could not find 'Bedrock_Hub' RemoteFunction!")
	end

	return self
end

function Hub:Push(namespace: string, repo: string, data: any): (boolean, string?)
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

function Hub:Pull(namespace: string, repo: string): (any, string?)
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
