--!strict
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

function Kernel.Boot()
	Log.info("KERNEL", "Initializing...")

	-- 1. Hardware Initialization
	local ram = RAM.new(500 * 1024 * 1024) -- 500MB Unified RAM
	local gpu = GPU.new(ram, 320, 180)
	local hid = HID.new()
	local network = Network.new()
	local hub = Hub.new()

	local VFS = require(script.Core.VFS) -- NEW

	-- 2. Core Initialization
	VFS.Init() -- Create default tree

	-- 2b. Bootstrap / Provisioning (Flash "Disk")
	local Bootstrap = require(script.Core.Bootstrap)
	Bootstrap.Init(VFS)

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

	Log.info("KERNEL", "Hardware Initialized.")

	-- 3. Kernel Services (e.g. WindowManager would go here)

	-- 4. BIOS / Bootloader Sequence
	local function BootSequence()
		Log.info("BIOS", "Searching for bootloader...")
		local bootScript = VFS.Read("/sbin/main.lua", 0, 0)
		if bootScript then
			Log.info("BIOS", "Booting /sbin/main.lua ...")
		end
		local ok, pidOrErr = Syscalls.Call("EXEC", "/sbin/main.lua")

		if not ok then
			Log.fatal("BIOS", "Init failed: %s", tostring(pidOrErr))
			-- Kernel Panic?
			gpu:Clear(4) -- Red
			gpu:Flush()
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

	Log.info("KERNEL", "Booted. Handing over to Scheduler.")
end

return Kernel
