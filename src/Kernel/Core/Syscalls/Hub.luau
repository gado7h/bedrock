--!strict
local Syscalls = {}

function Syscalls.Init(system: any)
	local Hub = system.Hub

	return {
		["HUB_PUSH"] = function(namespace: string, repo: string, data: any)
			return Hub:Push(namespace, repo, data)
		end,

		["HUB_PULL"] = function(namespace: string, repo: string)
			return Hub:Pull(namespace, repo)
		end,
	}
end

return Syscalls
