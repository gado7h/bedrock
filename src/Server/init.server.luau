-- This script runs on the Server due to RunContext.Server configuration in Rojo
local HubService = require(script.Parent:WaitForChild("HubService"))
local InternetService = require(script.Parent:WaitForChild("InternetService"))
local HDDService = require(script.Parent:WaitForChild("HDDService"))

local function setup()
	print("[Bedrock] Initializing Kernel Host Services...")

	-- 1. Hub Service
	local hubRemote = Instance.new("RemoteFunction")
	hubRemote.Name = "Bedrock_Hub"
	hubRemote.Parent = script.Parent

	hubRemote.OnServerInvoke = function(player, op, namespace, repo, data)
		return HubService.HandleRequest(player, op, namespace, repo, data)
	end

	-- 2. Internet Service
	local internetRemote = Instance.new("RemoteFunction")
	internetRemote.Name = "Bedrock_Internet"
	internetRemote.Parent = script.Parent

	internetRemote.OnServerInvoke = function(player, method, url, headers, body)
		return InternetService.HandleRequest(player, method, url, headers, body)
	end

	-- 3. HDD Service
	local hddRemote = Instance.new("RemoteFunction")
	hddRemote.Name = "Bedrock_HDD"
	hddRemote.Parent = script.Parent

	hddRemote.OnServerInvoke = function(player, op, path, arg1)
		return HDDService.HandleRequest(player, op, path, arg1)
	end

	print("[Bedrock] Host Services Ready.")
end

setup()
