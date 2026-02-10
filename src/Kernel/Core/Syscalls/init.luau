local Scheduler = require(script.Parent.Process.Scheduler)
local GPU = require(script.Parent.Parent.HAL.GPU)
local RAM = require(script.Parent.Parent.HAL.RAM)

-- Load Submodules
local FileSystem = require(script.FileSystem)
local Process = require(script.Process)
local Hardware = require(script.Hardware)
local Network = require(script.Network)
local Library = require(script.Library)
local Hub = require(script.Hub)

local Syscalls = {}

export type System = {
	Scheduler: Scheduler.Scheduler,
	GPU: GPU.GPU,
	HID: any,
	VFS: any,
	Pipes: any,
	RAM: RAM.RAM,
	Heap: any,
	Network: any,
	Hub: any,
}

local _system: System
local _noYield = 0
local HANDLERS: { [string]: any } = {}

-- Forward declaration for internal call
local function Call(name: string, ...: any)
	-- Tracing
	local args = { ... }
	local argStr = ""
	for i, v in ipairs(args) do
		argStr = argStr .. tostring(v) .. ", "
	end
	-- print(`[SYSCALL] {name} ({argStr})`)

	if name ~= "LIB_LOAD" then
		-- In Syscalls.luau original: checkPreemption logic
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
		local Log = require(script.Parent.Log)
		Log.warn("KERNEL", "Unknown Syscall: %s", name)
		return nil, "Unknown Syscall"
	end
end

Syscalls.Call = Call
Syscalls.BootSequence = nil :: (() -> ())?

function Syscalls.Init(system: System)
	_system = system

	-- Initialize Submodules
	local fsHandlers = FileSystem.Init(system) :: { [string]: any }
	local procHandlers = Process.Init(system, Call) :: { [string]: any }
	local hwHandlers = Hardware.Init(system) :: { [string]: any }
	local netHandlers = Network.Init(system) :: { [string]: any }
	local libHandlers = Library.Init(system, Call) :: { [string]: any }
	local hubHandlers = Hub.Init(system) :: { [string]: any }

	-- Merge Handlers
	for k, v in pairs(fsHandlers) do
		HANDLERS[k] = v
	end
	for k, v in pairs(procHandlers) do
		HANDLERS[k] = v
	end
	for k, v in pairs(hwHandlers) do
		HANDLERS[k] = v
	end
	for k, v in pairs(netHandlers) do
		HANDLERS[k] = v
	end
	for k, v in pairs(libHandlers) do
		HANDLERS[k] = v
	end
	for k, v in pairs(hubHandlers) do
		HANDLERS[k] = v
	end

	-- Add REBOOT_INTERNAL
	-- Power Management Syscalls
	HANDLERS["SYSTEM_REBOOT"] = function()
		local Log = require(script.Parent.Log)
		local pid = _system.Scheduler.CurrentPID
		Log.info("KERNEL", "SYSTEM REBOOT initiated by PID %s...", tostring(pid or "SYSTEM"))

		-- Power Down Hardware
		if _system.HID.Reset then
			_system.HID.Enabled = false
			(_system.HID :: any):Reset()
		end

		-- Wipe Memory & State
		_system.Heap:Reset()
		if _system.RAM.Fill and _system.RAM.Size then
			_system.RAM:Fill(0, 0, _system.RAM.Size)
		end

		-- Restore Palette and Clear Screen
		if _system.GPU.Reset then
			(_system.GPU :: any):Reset()
		else
			_system.GPU:Clear(0)
		end

		-- Mark caller as DEAD
		if pid then
			local proc = _system.Scheduler.Processes[pid]
			if proc then
				proc.State = "DEAD"
			end
		end

		-- Wipe Scheduler Tables
		_system.Scheduler.Processes = {}
		_system.Scheduler._nextPid = 1
		_system.Scheduler.CurrentPID = nil
		(_system.Scheduler :: any).SearchQueue = {}
		_system.Scheduler.Halted = false

		-- Re-Provision Filesystem
		local Bootstrap = require(script.Parent.Bootstrap)
		Bootstrap.Init(_system.VFS)

		Log.info("KERNEL", "System state cleared. Restarting BIOS in 500ms...")

		if Syscalls.BootSequence then
			task.delay(0.5, function()
				_system.HID.Enabled = true
                if _system.GPU.Init then (_system.GPU :: any):Init() end
				_system.Scheduler:Spawn("BIOS", Syscalls.BootSequence :: any)
			end)
		else
			Log.warn("KERNEL", "CRITICAL ERROR: BootSequence missing")
		end
	end

	HANDLERS["SYSTEM_SHUTDOWN"] = function()
		local Log = require(script.Parent.Log)
		local pid = _system.Scheduler.CurrentPID
		Log.info("KERNEL", "SYSTEM SHUTDOWN initiated by PID %s...", tostring(pid or "SYSTEM"))

		-- Halt Scheduler
		_system.Scheduler.Halted = true

		-- Power Down Input
		if _system.HID.Reset then
			_system.HID.Enabled = false
			(_system.HID :: any):Reset()
		end

		-- Wipe Memory
		if _system.RAM.Fill and _system.RAM.Size then
			_system.RAM:Fill(0, 0, _system.RAM.Size)
		end

		-- Clear Screen
		_system.GPU:Clear(0)

		Log.info("KERNEL", "System Halted. It is now safe to close the window.")
	end

	-- Setup CPU Interrupt Handlers
	if _system.Scheduler._cpu then
		_system.Scheduler._cpu:SetSyscallHandler(function(num, cpu)
			if num == 1 then -- PRINT R0
				local val = cpu._state.Registers[1]
				Syscalls.Call("PRINT", "[CPU] R0=" .. tostring(val) .. "\n")
			elseif num == 2 then -- EXIT
				cpu._state.Halted = true
			elseif num == 3 then -- PRINT STRING R0
				local addr = cpu._state.Registers[1]
				local str = ""
				while true do
					local char = _system.RAM:Read8(addr)
					if char == 0 then
						break
					end
					str = str .. string.char(char)
					addr = addr + 1
				end
				Syscalls.Call("PRINT", str)
			elseif num == 4 then -- CLEAR SCREEN R0
				local color = cpu._state.Registers[1]
				_system.GPU:Clear(color)
			elseif num == 5 then -- EXEC PATH R0
				local addr = cpu._state.Registers[1]
				local path = ""
				while true do
					local char = _system.RAM:Read8(addr)
					if char == 0 then
						break
					end
					path = path .. string.char(char)
					addr = addr + 1
				end
				local _ok, _err, pid = Syscalls.Call("EXEC", path)
				cpu._state.Registers[1] = pid or 0
			elseif num == 6 then -- START_SHELL
				task.spawn(function()
					Syscalls.Call("EXEC", "/bin/sh.lua")
				end)
			elseif num == 10 then -- MALLOC
				local size = cpu._state.Registers[1]
				cpu._state.Registers[1] = Syscalls.Call("MALLOC", size) or 0
			elseif num == 11 then -- FREE
				local addr = cpu._state.Registers[1]
				Syscalls.Call("FREE", addr)
			end
		end)
	end

	-- Crash Reporting
	_system.Scheduler.OnProcessCrash = function(pid, err)
		Syscalls.Call("PRINT", `\n[KERNEL] Process {pid} crashed:\n{err}\n`)
	end
end

return Syscalls
