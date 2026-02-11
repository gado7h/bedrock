-- Modular Syscall Handler
-- Orchestrates category-specific syscall modules.

local Syscalls = {}

export type System = {
	Scheduler: any,
	GPU: any,
	HID: any,
	VFS: any,
	Pipes: any,
	RAM: any,
	Heap: any,
	Network: any,
	Hub: any,
}

local _system: System
local _noYield = 0
local HANDLERS: { [string]: any } = {}

-- Forward declaration for internal call
local function Call(name: string, ...: any)
	if name ~= "LIB_LOAD" then
		if _noYield == 0 and _system and _system.Scheduler then
			local pid = _system.Scheduler.CurrentPID
			if pid then
				local proc = _system.Scheduler.Processes[pid]
				if proc and proc.State == "RUNNING" then
					local sliceTime = (os.clock() - proc.StartTime) * 1000
					if sliceTime > 16 then -- 16ms Timeslice
						proc.State = "READY"
						coroutine.yield()
					end
				end
			end
		end
	end

	local handler: (...any) -> ...any = HANDLERS[name]
	if handler then
		return handler(...)
	else
		local Log = require(script.Parent.Parent.Parent.Utils.Log)
		Log.warn("SYSCALL", "Unknown Syscall: %s", name)
		return nil, "Unknown Syscall"
	end
end

Syscalls.Call = Call
Syscalls.BootSequence = nil :: (() -> ())?

function Syscalls.Init(system: System)
	_system = system

	-- Initialize Submodules
	local FileSystem = require(script.FileSystem)
	local Process = require(script.Process)
	local Hardware = require(script.Hardware)
	local Network = require(script.Network)
	local Library = require(script.Library)
	local Hub = require(script.Hub)

	local fsHandlers = FileSystem.Init(system)
	local procHandlers = Process.Init(system, Call)
	local hwHandlers = Hardware.Init(system)
	local netHandlers = Network.Init(system)
	local libHandlers = Library.Init(system, Call)
	local hubHandlers = Hub.Init(system)

	-- Merge Handlers
	for k, v in pairs(fsHandlers) do HANDLERS[k] = v end
	for k, v in pairs(procHandlers) do HANDLERS[k] = v end
	for k, v in pairs(hwHandlers) do HANDLERS[k] = v end
	for k, v in pairs(netHandlers) do HANDLERS[k] = v end
	for k, v in pairs(libHandlers) do HANDLERS[k] = v end
	for k, v in pairs(hubHandlers) do HANDLERS[k] = v end

	-- System Power Management
	HANDLERS["SYSTEM_REBOOT"] = function()
		local Log = require(script.Parent.Parent.Parent.Utils.Log)
		Log.info("KERNEL", "SYSTEM REBOOT initiated...")
		
        -- New Architecture: Defer to Motherboard
        -- We just need to signal the hardware to reset.
        -- But wait, Kernel doesn't have direct access to Motherboard module unless injected?
        -- `_system.RAM` etc are just components.
        -- We CAN access `_G.Hardware` or we can require Motherboard if it's in the hierarchy.
        
        -- Safe bet: Require Motherboard
        local Motherboard = require(script.Parent.Parent.Parent.Parent.Hardware.Motherboard)
        Motherboard.Reset()
	end

	HANDLERS["SYSTEM_SHUTDOWN"] = function()
		local Log = require(script.Parent.Parent.Parent.Utils.Log)
		Log.info("KERNEL", "SYSTEM SHUTDOWN initiated...")
		_system.Scheduler.Halted = true
	end

	-- CPU Introspection
	if _system.Scheduler._cpu then
		_system.Scheduler._cpu:SetSyscallHandler(function(num, cpu)
			if num == 1 then -- PRINT R0
				local val = cpu._state.Registers[1]
				Syscalls.Call("PRINT", "[CPU] R0=" .. tostring(val) .. "\n")
			elseif num == 2 then -- EXIT
				cpu._state.Halted = true
			end
		end)
	end

	_system.Scheduler.OnProcessCrash = function(pid, err)
		Syscalls.Call("PRINT", `\n[KERNEL] Process {pid} crashed:\n{err}\n`)
	end
end

return Syscalls
