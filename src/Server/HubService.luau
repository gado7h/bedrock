--!strict
local DataStoreService = game:GetService("DataStoreService")

local HubService = {}
local HUB_DATASTORE_NAME = "Bedrock_Hub_v1"

-- Repositories are stored as: User_[UserId]/[RepoName]
-- We use a global DataStore but scope it by UserId in the key to simplify permissions (simple "own vs others")

local function getStore()
	return DataStoreService:GetDataStore(HUB_DATASTORE_NAME)
end

function HubService.HandleRequest(player: Player, op: string, namespace: string, repo: string, data: any)
	local store = getStore()
	local key = string.format("%s/%s", namespace, repo)

	-- Authorization Check: Only allow pushing to your own namespace
	-- Namespace format: "User_[UserId]"
	if op == "PUSH" then
		local requiredNamespace = "User_" .. player.UserId
		if namespace ~= requiredNamespace then
			return false, "Permission Denied: Cannot push to another user's namespace"
		end

		local success, err = pcall(function()
			store:SetAsync(key, {
				snapshot = data, -- Serialized VFS tree
				author = player.Name,
				updated = os.time()
			})
		end)

		if not success then
			warn("[HubService] Push failed:", err)
		end
		return success, err
	elseif op == "PULL" then
		local success, result = pcall(function()
			return store:GetAsync(key)
		end)

		if not success then
			warn("[HubService] Pull failed:", result)
			return nil, result
		end

		return result -- This includes the snapshot
	elseif op == "LIST" then
		-- Listing is harder with simple DataStores without a secondary index or ListKeysAsync (which needs Scopes)
		-- For now, we return empty or a "not implemented" if we don't have a manifest.
		-- A proper registry would maintain a manifest per user.
		return nil, "Listing not yet implemented"
	end

	return nil, "Invalid Operation"
end

return HubService
