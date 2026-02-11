-- Shared utility for loading and compiling Lua code safely
local LuaVM = require(script.Parent.Parent.Core.LuaVM)

local Loader = {}

-- Cache compiled bytecode to save compilation time
local _bytecodeCache: { [string]: any } = {}

function Loader.LoadString(System: any, content: string, env: any): (any, string?)
	local bc = _bytecodeCache[content]
	local err

	if not bc then
		-- Reset quantum timer for current process to avoid timeout during compilation
		if System and System.Scheduler and (System.Scheduler :: any).CurrentPID then
			local pid = (System.Scheduler :: any).CurrentPID
			local proc = (System.Scheduler :: any).Processes[pid]
			if proc then
				proc.StartTime = os.clock()
			end
		end

		bc, err = LuaVM.Compile(content)
		if bc then
			_bytecodeCache[content] = bc
		end
	end

	if bc then
		return LuaVM.CreateExecutable(bc, env)
	else
		return nil, err
	end
end

return Loader
