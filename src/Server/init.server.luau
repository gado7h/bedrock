-- This script runs on the Server due to RunContext.Server configuration in Rojo
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HubServiceModule = script:WaitForChild("HubService", 5)
local InternetServiceModule = script:WaitForChild("InternetService", 5)
local HDDServiceModule = script:WaitForChild("HDDService", 5)

if not HubServiceModule or not InternetServiceModule or not HDDServiceModule then
	warn("[Bedrock] CRITICAL: Host services (Hub/Internet/HDD) failed to load within 5s!")
	return
end

local HubService = require(HubServiceModule)
local InternetService = require(InternetServiceModule)
local HDDService = require(HDDServiceModule)

local function setup()
	print("[Bedrock] Initializing Kernel Host Services...")

	-- Create a unified bridge for the client HALs to find remotes
	local hostFolder = ReplicatedStorage:FindFirstChild("Bedrock_Host")
	if not hostFolder then
		hostFolder = Instance.new("Folder")
		hostFolder.Name = "Bedrock_Host"
		hostFolder.Parent = ReplicatedStorage
	end

	-- 1. Hub Service
	local hubRemote = hostFolder:FindFirstChild("Bedrock_Hub") or Instance.new("RemoteFunction")
	hubRemote.Name = "Bedrock_Hub"
	hubRemote.Parent = hostFolder

	hubRemote.OnServerInvoke = function(player, op, namespace, repo, data)
		return HubService.HandleRequest(player, op, namespace, repo, data)
	end

	-- 2. Internet Service
	local internetRemote = hostFolder:FindFirstChild("Bedrock_Internet") or Instance.new("RemoteFunction")
	internetRemote.Name = "Bedrock_Internet"
	internetRemote.Parent = hostFolder

	internetRemote.OnServerInvoke = function(player, method, url, headers, body)
		return InternetService.HandleRequest(player, method, url, headers, body)
	end

	-- 3. HDD Service
	local hddRemote = hostFolder:FindFirstChild("Bedrock_HDD") or Instance.new("RemoteFunction")
	hddRemote.Name = "Bedrock_HDD"
	hddRemote.Parent = hostFolder

	hddRemote.OnServerInvoke = function(player, op, path, arg1)
		return HDDService.HandleRequest(player, op, path, arg1)
	end

	print("[Bedrock] Host Services Ready in ReplicatedStorage.Bedrock_Host")
end

setup()