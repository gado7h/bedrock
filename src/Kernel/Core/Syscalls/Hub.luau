-- Hub Syscalls
local Hub = {}

function Hub.Init(System)
	local HANDLERS = {}

	HANDLERS["HUB_INVOKE"] = function(cmd: string, ...: any)
		if System.Hub then
			return System.Hub:Invoke(cmd, ...)
		end
		return nil, "Hub Offline"
	end

	return HANDLERS
end

return Hub
