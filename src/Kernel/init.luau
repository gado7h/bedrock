local RunService = game:GetService("RunService")

local MemoryMap = require(script.Core.Memory.MemoryMap)
local Scheduler = require(script.Core.Scheduler)
local Syscalls = require(script.Core.Syscalls)
local Pipes = require(script.Core.IPC.Pipes)
local Log = require(script.Utils.Log)
local Bootstrap = require(script.Core.Bootstrap)
local VFS = require(script.Core.VFS)
local Heap = require(script.Core.Memory.Heap)

local Kernel = {}

-- Kernel configuration state
local _config = {
	Name = "Bedrock",
	Version = "1.0.0",
	BootScript = "/boot.lua",
}

local _system = {}

-- Real Kernel Init: Probes existing hardware
function Kernel.Init(Hardware, Config)
	if Config then
		for k, v in pairs(Config) do _config[k] = v end
	end

	Log.info("KERNEL", "Bedrock Kernel v%s starting...", _config.Version)
	Log.info("KERNEL", "Probing hardware...")

	-- 1. Component Verification
	local ram = Hardware.RAM
	local gpu = Hardware.GPU
	local hid = Hardware.HID
	
	if not ram or not gpu then
		error("KERNEL PANIC: Critical hardware missing during boot!")
	end

	-- 2. Core Subsystem Initialization
	VFS.Init()
	
	local scheduler = Scheduler.new(Hardware.CPU, ram)
	local heap = Heap.new(ram, MemoryMap.HEAP_START, MemoryMap.HEAP_END)

	-- 3. Device Initialization (Mounting drivers to hardware)
	local DevGPU = require(script.Drivers.DevGPU)
	DevGPU.Init(gpu)
	VFS.Mount("/dev/gpu", DevGPU)

	local DevTTY = require(script.Drivers.DevTTY)
	DevTTY.Init(scheduler, Pipes)
	VFS.Mount("/dev/tty", DevTTY)

    local DevHDD = require(script.Drivers.DevHDD)
    DevHDD.Init(Hardware.HDD)
    VFS.Mount("/dev/hdd", DevHDD)

	-- 4. Kernel Provisioning
	Bootstrap.Init({
		VFS = VFS,
		GPU = gpu,
		Scheduler = scheduler,
		Pipes = Pipes,
        HDD = Hardware.HDD, -- For legacy support in bootstrap if needed
	})

	-- Apply custom VFS provisioning
	if _config.VFS then
		for path, content in pairs(_config.VFS) do
            -- Ensure parent directories exist
            local parts = string.split(path, "/")
            if #parts > 1 then
                local current = ""
                for i = 1, #parts - 1 do
                    current = current .. "/" .. parts[i]
                    if not VFS.Stat(current) then
                        VFS.MkDir(current, 0, 0)
                    end
                end
            end
			VFS.Write(path, content, 0, 0)
		end
	end

	-- 5. Syscall Registration
	Syscalls.Init({
		Scheduler = scheduler,
		GPU = gpu,
		HID = hid,
		VFS = VFS,
		Pipes = Pipes,
		RAM = ram,
		Heap = heap,
		Network = Hardware.Network,
		Hub = Hardware.Hub,
	})

	scheduler.SyscallHandler = Syscalls.Call

	_system = {
		Scheduler = scheduler,
		VFS = VFS,
		Syscalls = Syscalls,
	}

	Log.info("KERNEL", "Kernel initialized successfully.")
end

function Kernel.Start()
	if not _system.Scheduler then
		error("Kernel not initialized!")
	end

	local scheduler = _system.Scheduler

	local function BootSequence()
		if _config.BootScript and _system.VFS.Stat(_config.BootScript) then
			Log.info("KERNEL", "Executing boot script: %s", _config.BootScript)
			_system.Syscalls.Call("EXEC", _config.BootScript)
		elseif _system.VFS.Stat("/etc/.init") then
             Log.info("KERNEL", "Spawning init process (PID 1) via ASM...")
             -- Execute asm.lua with the init file as an argument
             _system.Syscalls.Call("EXEC", "/bin/asm.lua", {"/etc/.init"})
        elseif _system.VFS.Stat("/init.lua") then
            Log.info("KERNEL", "Spawning legacy init (PID 1)...")
            _system.Syscalls.Call("EXEC", "/init.lua")
        else
            -- Fallback
            Log.info("KERNEL", "No init found. Starting emergency shell...")
            _system.Syscalls.Call("EXEC", "/bin/sh.lua")
		end
	end

	_system.Syscalls.BootSequence = BootSequence
	scheduler:Spawn("Init", BootSequence)

	RunService.Heartbeat:Connect(function(dt)
		scheduler:Schedule(dt)
	end)

	Log.info("KERNEL", "Kernel main loop started.")
end

return Kernel
