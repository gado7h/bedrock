local RunService = game:GetService("RunService")

local MemoryMap = require(script.Core.Memory.MemoryMap)

local GPU = require(script.HAL.GPU)
local HID = require(script.HAL.HID)
local Network = require(script.HAL.Network)
local Scheduler = require(script.Core.Process.Scheduler)
local Syscalls = require(script.Core.Syscalls)
local Pipes = require(script.Core.Pipes)
-- local libc = require(script.Parent.Userland.libc) -- DECOUPLED!

local Log = require(script.Core.Log)

local RAM = require(script.HAL.RAM)
local Hub = require(script.HAL.Hub)

local Kernel = {}

-- Kernel Configuration Type
export type KernelConfig = {
	Name: string?,
	Version: string?,
	BootScript: string?,
	RAMSize: number?,
	VideoWidth: number?,
	VideoHeight: number?,
	VFS: any?, -- Application specific VFS provisioning
}

local _config: KernelConfig = {
	Name = "Bedrock",
	Version = "1.0.0",
	BootScript = "/boot.lua",
	RAMSize = 512 * 1024 * 1024,
	VideoWidth = 640,
	VideoHeight = 360,
}

local _system = {}

function Kernel.Init(config: KernelConfig?)
	if config then
		for k, v in pairs(config) do
			_config[k] = v
		end
	end

	Log.info("KERNEL", "Initializing %s v%s...", _config.Name, _config.Version)

	-- 1. Hardware Initialization
	local ram = RAM.new(_config.RAMSize)
	local gpu = GPU.new(ram, _config.VideoWidth, _config.VideoHeight)
	local hid = HID.new()
	local network = Network.new()
	local hub = Hub.new()
	local hdd = require(script.HAL.FileSystem.HDD).new()

	local VFS = require(script.Core.VFS)
	local BIOS = require(script.Core.BIOS)

	-- 2. BIOS POST
	local ok, _err = BIOS.InitHardware({
		RAM = ram,
		GPU = gpu,
		HID = hid,
		Network = network,
		Hub = hub,
		HDD = hdd,
	})

	if not ok then
		-- BIOS Panic
		gpu:Clear(4) -- Red
		gpu:Flush()
		error("BIOS POST Failed: " .. tostring(_err))
	end

	-- 3. Core Initialization
	VFS.Init()
	VFS.Mount("/dev/hdd", hdd)

	-- 3b. Bootstrap / Provisioning (Flash "Disk")
	local Bootstrap = require(script.Core.Bootstrap)
	Bootstrap.Init(VFS)

	-- Custom VFS Provisioning (if provided by Distro)
	if _config.VFS then
		Log.info("KERNEL", "Applying custom VFS provisioning...")
		for path, content in pairs(_config.VFS) do
			VFS.Write(path, content, 0, 0)
		end
	end

	local scheduler = Scheduler.new(ram)
	local Heap = require(script.Core.Memory.Heap)
	local heap = Heap.new(ram, MemoryMap.HEAP_START, MemoryMap.HEAP_END)

	Syscalls.Init({
		Scheduler = scheduler,
		GPU = gpu,
		HID = hid,
		VFS = VFS,
		Pipes = Pipes,
		RAM = ram,
		Heap = heap,
		Network = network,
		Hub = hub,
	})

	_system = {
		Scheduler = scheduler,
		VFS = VFS,
		BIOS = BIOS,
		GPU = gpu,
	}
	
	Log.info("KERNEL", "Initialization Complete. Ready to Start.")
	return Kernel
end

function Kernel.Start()
	if not _system.Scheduler then
		error("Kernel not initialized! Call Kernel.Init() first.")
	end

	local VFS = _system.VFS
	local BIOS = _system.BIOS
	local scheduler = _system.Scheduler

	-- 4. Hand over to BIOS for Booting
	local function BootSequence()
		-- Try Distro BootScript first
		if _config.BootScript and VFS.Stat(_config.BootScript) then
			Log.info("KERNEL", "Booting custom script: %s", _config.BootScript)
			Syscalls.Call("EXEC", _config.BootScript)
		else
			-- Fallback to standard BIOS boot
			BIOS.Boot(VFS, Syscalls)
		end
	end

	-- Save for reboot
	Syscalls.BootSequence = BootSequence

	scheduler:Spawn("BIOS", BootSequence)

	-- 5. Main Loop (The "idle" loop handling hardware and scheduling)
	RunService.Heartbeat:Connect(function(dt)
		-- Schedule
		scheduler:Schedule(dt)
		-- Note: GPU flush is handled by userspace apps (libc.Graphics.Flush)
	end)

	Log.info("KERNEL", "Kernel Started.")
end

return Kernel
