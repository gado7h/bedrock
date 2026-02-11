-- Network Syscalls
local Network = {}

function Network.Init(System)
	local HANDLERS = {}

	HANDLERS["NET_REQUEST"] = function(cmd: string, ...: any)
		if System.Network then
			return System.Network:Invoke(cmd, ...)
		end
		return false, "Network Offline"
	end

	return HANDLERS
end

return Network
