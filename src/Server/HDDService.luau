--!strict
local DataStoreService = game:GetService("DataStoreService")

local HDDService = {}
local HDD_DATASTORE_NAME = "Bedrock_UserStorage_v1"

-- User-specific storage handle
local function getStoreForPlayer(player: Player)
	return DataStoreService:GetDataStore(HDD_DATASTORE_NAME, "User_" .. player.UserId)
end

function HDDService.HandleRequest(player: Player, op: string, path: string, arg1: any)
	local store = getStoreForPlayer(player)

	if op == "READ" then
		local success, data = pcall(function()
			return store:GetAsync("FILE_" .. path)
		end)
		return success and data or nil
	elseif op == "WRITE" then
		local success, err = pcall(function()
			store:SetAsync("FILE_" .. path, arg1)
		end)
		
		-- Update manifest per-user for folder listing
		local manifestSuccess, manifest = pcall(function()
			return store:GetAsync("MANIFEST") or {}
		end)
		if manifestSuccess then
			manifest[path] = "FILE"
			pcall(function()
				store:SetAsync("MANIFEST", manifest)
			end)
		end

		return success
	elseif op == "LIST" then
		local success, manifest = pcall(function()
			return store:GetAsync("MANIFEST") or {}
		end)
		if not success then
			return {}
		end

		-- Simple direct child filter logic
		local children = {}
		if path:sub(-1) ~= "/" then
			path = path .. "/"
		end
		if path == "//" then
			path = "/"
		end

		for p, _ in pairs(manifest) do
			if p:sub(1, #path) == path then
				local sub = p:sub(#path + 1)
				if not sub:find("/") then
					table.insert(children, sub)
				end
			end
		end
		return children
	elseif op == "MKDIR" then
		local success, manifest = pcall(function()
			local m = store:GetAsync("MANIFEST") or {}
			m[path] = "DIR"
			store:SetAsync("MANIFEST", m)
			return true
		end)
		return success
	end

	return nil
end

return HDDService
