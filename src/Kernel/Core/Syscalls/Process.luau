local Signals = require(script.Parent.Parent.IPC.Signals)

local Process = {}

function Process.Init(System, Call)
	local scheduler = System.Scheduler
	local HANDLERS = {}

	HANDLERS["EXEC"] = function(path: string, args: { string }?, env: { [string]: string }?)
		local vfs = System.VFS
		local content, err = vfs.Read(path, 0, 0)
		if not content then return nil, "File not found" end

		local Loader = require(script.Parent.Parent.Parent.Utils.Loader)
		local procEnv = env or {}
        
        -- Binary Detection: Check for null byte header or .bin extension
        local isBinary = string.sub(content, 1, 1) == "\0" or string.sub(path, -4) == ".bin"
        
        if isBinary then
             -- Load Binary into RAM
             local RAM = System.RAM
             local MemoryMap = require(script.Parent.Parent.Memory.MemoryMap)
             local baseAddr = MemoryMap.PROGRAM_BASE
             
             -- Write content to RAM
             for i = 1, #content do
                 local byte = string.byte(content, i, i)
                 RAM:Write8(baseAddr + i - 1, byte)
             end
             
             local pid = scheduler:SpawnBinary(path, baseAddr)
             return true, nil, pid
        else
            -- Lua Script Execution
    		local pid = scheduler:Spawn(path, function()
    			local proc = scheduler.Processes[(scheduler :: any).CurrentPID]
    			local env = if proc then proc.Env else procEnv
    			local executable, _loadErr = Loader.LoadString(System, content, env)
    			if executable then
                    print("DEBUG: Executing process with args: " .. tostring(#(args or {})))
    				executable(table.unpack(args or {}))
    			else
    				warn("Failed to load binary: " .. tostring(_loadErr))
    			end
    		end, procEnv)
            return true, nil, pid
        end
	end

	HANDLERS["KILL"] = function(pid: number, sig: number?)
		local proc = scheduler.Processes[pid]
		if not proc then return false, "No such process" end
		
		local signal = sig or Signals.SIGTERM
		table.insert(proc.Signals, signal)
		return true
	end

	HANDLERS["GETPID"] = function()
		return scheduler.CurrentPID
	end

	HANDLERS["PS"] = function()
		local list = {}
		for pid, proc in pairs(scheduler.Processes) do
			table.insert(list, {
				PID = pid,
				Name = proc.Name,
				State = proc.State,
				Time = proc.TotalTime,
                UID = proc.UID,
                CPU = proc.CPU ~= nil,
			})
		end
		return list
	end

	HANDLERS["SLEEP"] = function(seconds: number)
		local pid = scheduler.CurrentPID
		if not pid then return end
		local proc = scheduler.Processes[pid]
		if not proc then return end

		proc.State = "SLEEPING"
		proc.WakeTime = os.clock() + seconds
		scheduler:_heapPush(pid)
		coroutine.yield()
	end

	HANDLERS["WAITPID"] = function(targetPid: number)
		local pid = scheduler.CurrentPID
		if not pid then return end
		local proc = scheduler.Processes[pid]
		local target = scheduler.Processes[targetPid]
		if not target then return end

		target.Waiters = target.Waiters or {}
		target.Waiters[pid] = true
		proc.State = "WAITING"
		coroutine.yield()
	end

	return HANDLERS
end

return Process
