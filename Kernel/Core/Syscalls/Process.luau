--!strict
local MemoryMap = require(script.Parent.Parent.Memory.MemoryMap)

local Process = {}

function Process.Init(System: any, CallSyscall: (string, ...any) -> ...any)
	local LuaVM = require(script.Parent.Parent.LuaVM)

	-- We need CachedLoadstring here or in Library.luau?
	-- EXEC uses CachedLoadstring. Library loads use it.
	-- Let's put CachedLoadstring logic here or in Library.
	-- EXEC loads the main script.
	-- Ideally we use a shared util or Library module.
	-- For now, I'll duplicate CachedLoadstring slightly or move it to a Util if needed.
	-- Better: Library.luau exports Compile/Load helpers? No, Library handles LIB_LOAD.
	local Loader = require(script.Parent.Parent.Loader)

	return {
		["SIGNAL"] = function(pid: number, sig: number)
			local proc = System.Scheduler.Processes[pid]
			if proc then
				proc.Signals = proc.Signals or {}
				table.insert(proc.Signals, sig)
				if proc.State == "WAITING" then
					proc.State = "READY"
					System.Scheduler:_addToTail(pid)
				end
				return true
			end
			return false
		end,

		-- Register a signal handler for the current process
		["SIGNAL_HANDLER"] = function(sig: number, handler: ((...any) -> ())?)
			local pid = System.Scheduler.CurrentPID
			if not pid then
				return false
			end
			local proc = System.Scheduler.Processes[pid]
			if not proc then
				return false
			end

			proc.SignalHandlers = proc.SignalHandlers or {}
			proc.SignalHandlers[sig] = handler -- nil to clear handler
			return true
		end,

		["KILL"] = function(pid: number)
			local proc = System.Scheduler.Processes[pid]
			if proc then
				proc.Signals = proc.Signals or {}
				table.insert(proc.Signals, 9) -- SIGKILL
				if proc.State == "WAITING" then
					proc.State = "READY"
					System.Scheduler:_addToTail(pid)
				end
				return true
			end
			return false
		end,

		["SLEEP"] = function(seconds)
			local pid = System.Scheduler.CurrentPID
			if pid then
				local proc = System.Scheduler.Processes[pid]
				proc.State = "SLEEPING"
				proc.WakeTime = os.clock() + (seconds or 0)
				System.Scheduler:_heapPush(pid) -- Add to sleep heap for O(log n) wake
				coroutine.yield()
			end
		end,

		["WAIT_PID"] = function(targetPid: number)
			local myPid = System.Scheduler.CurrentPID
			if not myPid then
				return false
			end

			local target = System.Scheduler.Processes[targetPid]
			if target and target.State ~= "DEAD" then
				target.Waiters = target.Waiters or {}
				target.Waiters[myPid] = true

				local me = System.Scheduler.Processes[myPid]
				me.State = "WAITING"
				coroutine.yield()
				return true
			end
			return false
		end,

		["MALLOC"] = function(size: number)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]

			if proc and proc.MemoryLimit and (proc.MemoryUsed or 0) + size > proc.MemoryLimit then
				return 0 -- Out of memory
			end

			local addr = System.Heap:Malloc(size)
			if addr ~= 0 and proc then
				proc.MemoryUsed = (proc.MemoryUsed or 0) + size
				proc.Allocations = proc.Allocations or {}
				proc.Allocations[addr] = size
			end
			return addr
		end,

		["FREE"] = function(addr: number)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]

			if proc and proc.Allocations and proc.Allocations[addr] then
				local size = proc.Allocations[addr]
				proc.MemoryUsed = proc.MemoryUsed - size
				proc.Allocations[addr] = nil
			end

			System.Heap:Free(addr)
		end,

		["PS_LIST"] = function()
			local list = {}
			for pid, proc in pairs(System.Scheduler.Processes) do
				table.insert(list, { PID = pid, Name = proc.Name, State = proc.State })
			end
			return list
		end,

		["PS_KILL"] = function(pid: number)
			return System.Scheduler:Kill(pid)
		end,

		["ENV_GET"] = function(key: string)
			local pid = System.Scheduler.CurrentPID
			local proc = pid and System.Scheduler.Processes[pid]
			return proc and proc.Env[key]
		end,

		["ENV_SET"] = function(key: string, val: string)
			local pid = System.Scheduler.CurrentPID
			local proc = pid and System.Scheduler.Processes[pid]
			if proc then
				proc.Env[key] = val
				return true
			end
			return false
		end,

		["REBOOT"] = function()
			-- Note: Needs access to BootSequence in Syscalls main
			-- We can trigger an event or handle it here if passed
			return CallSyscall("REBOOT_INTERNAL")
		end,

		["EXEC"] = function(path: string, config: { stdin: number?, stdout: number?, args: { string }? }?)
			local content = CallSyscall("FS_READ", path)
			if not content then
				return false, "File not found"
			end

			-- Environment inheritance
			local parentPID = System.Scheduler.CurrentPID
			local parentProc = parentPID and System.Scheduler.Processes[parentPID]
			local procEnv = {}
			if parentProc and parentProc.Env then
				for k, v in pairs(parentProc.Env) do
					procEnv[k] = v
				end
			end

			-- Default Environment
			local env = {
				print = function(...)
					local args = { ... }
					for i = 1, #args do
						args[i] = tostring(args[i])
					end
					CallSyscall("PRINT", table.concat(args, " ") .. "\n")
				end,
				table = table,
				string = string,
				math = math,
				bit32 = bit32,
				buffer = buffer,
				pairs = pairs,
				ipairs = ipairs,
				next = next,
				tostring = tostring,
				tonumber = tonumber,
				type = type,
				assert = assert,
				error = error,
				pcall = pcall,
				xpcall = xpcall,
				select = select,
				unpack = unpack,
				os = {
					clock = os.clock,
					date = os.clock,
					time = os.time,
					difftime = os.difftime,
					getenv = function(key)
						return CallSyscall("ENV_GET", key)
					end,
				},
				Enum = Enum,
				Color3 = Color3,
				CFrame = CFrame,
				Vector3 = Vector3,
				Vector2 = Vector2,
				UDim2 = UDim2,
				UDim = UDim,
				Syscall = function(...)
					return CallSyscall(...)
				end,
				require = function(n)
					return CallSyscall("LIB_LOAD", n)
				end,
				io = {
					write = function(...)
						local args = { ... }
						CallSyscall("PRINT", table.concat(args, ""))
					end,
					read = function()
						local str = ""
						while true do
							local char = CallSyscall("TTY_READ")
							if not char then
								CallSyscall("SLEEP", 0.02)
							else
								if char == "\n" or char == "\r" then
									CallSyscall("PRINT", "\n")
									break
								end

								if char == "\b" then
									if #str > 0 then
										str = string.sub(str, 1, #str - 1)
										CallSyscall("PRINT", "\b")
									end
								else
									CallSyscall("PRINT", char)
									str = str .. char
								end
							end
						end
						return str
					end,
					flush = function() end,
				},
				libc = {
					ReadLine = function()
						return env.io.read()
					end,
					Sleep = function(s)
						return CallSyscall("SLEEP", s)
					end,
					LoadLibrary = function(name)
						return CallSyscall("LIB_LOAD", name)
					end,
					Kill = function(pid)
						return CallSyscall("KILL", pid)
					end,
					Signal = function(pid, sig)
						return CallSyscall("SIGNAL", pid, sig)
					end,
					Network = {
						Request = function(cmd, ...)
							return CallSyscall("NET_REQ", cmd, ...)
						end,
					},
					Yield = coroutine.yield,
					Syscalls = { Call = CallSyscall },
				},
				arg = config and config.args or {},
			}
			env._G = env

			if string.sub(path, -4) == ".bin" then
				-- BINARY LOADER
				local addr = MemoryMap.PROGRAM_BASE
				for i = 1, #content do
					System.RAM:Write8(addr + i - 1, string.byte(content, i))
				end
				local pid = System.Scheduler:SpawnBinary(path, addr)
				return true, nil, pid
			end

			local func, err = Loader.LoadString(System, content, env)
			if not func then
				return false, err or "Compilation failed"
			end

			local pid = System.Scheduler:Spawn(path, func)
			local proc = System.Scheduler.Processes[pid]
			proc.Env = procEnv
			proc.MemoryLimit = 10 * 1024 * 1024

			if config then
				proc.StdinPipe = config.stdin
				proc.StdoutPipe = config.stdout
			end
			return true, nil, pid
		end,

		["PROCESS_SPAWN"] = function(path: string, name: string)
			-- Wrapper for EXEC to match common userland expectations
			local ok, err, pid = CallSyscall("EXEC", path, { args = { name } })
			return ok, pid or err
		end,
	}
end

return Process
