local RAM = require(script.Parent.Components.RAM)
local GPU = require(script.Parent.Components.GPU)
local CPU = require(script.Parent.Components.CPU)
local HID = require(script.Parent.Components.HID)
local Network = require(script.Parent.Components.Network)
local Hub = require(script.Parent.Components.Hub)
local HDD = require(script.Parent.Components.HDD_Physical)

-- The Voyager-1 Motherboard
-- Physical entry point of the machine.

local Motherboard = {}

-- Hardware State
Motherboard.State = {
    Powered = false,
    LEDs = {
        PWR = false,
        HDD = false,
        NET = false
    }
}

-- Components
Motherboard.Hardware = {}

function Motherboard.PowerOn(Config)
    if Motherboard.State.Powered then return end
    
	Config = Config or {}
	local RAM_SIZE = Config.RAMSize or 16 * 1024 * 1024 -- 16 MB default
	local SCREEN_W = Config.Width or 320
	local SCREEN_H = Config.Height or 180
    local VRAM_OFFSET = 0x040000 -- Standard Voyager-1 VRAM Base

	-- 1. Power Up Components
	local physicalRAM = RAM.new(RAM_SIZE)
	local physicalGPU = GPU.new(physicalRAM, SCREEN_W, SCREEN_H, VRAM_OFFSET)
    local physicalCPU = CPU.new(physicalRAM)
	local physicalHID = HID.new()
	local physicalNetwork = Network.new()
	local physicalHub = Hub.new()
	local physicalHDD = HDD.new()
    
    -- Wiring LEDs
    physicalHDD.OnActivity = function()
        Motherboard.State.LEDs.HDD = true
    end
    physicalNetwork.OnActivity = function()
        Motherboard.State.LEDs.NET = true
    end

	Motherboard.Hardware = {
		RAM = physicalRAM,
		GPU = physicalGPU,
		CPU = physicalCPU,
		HID = physicalHID,
		Network = physicalNetwork,
		Hub = physicalHub,
		HDD = physicalHDD,
	}

    _G.Hardware = Motherboard.Hardware

    Motherboard.State.Powered = true
    Motherboard.State.LEDs.PWR = true
    
    local HardwareCP = require(script.Parent.ControlPanel.HardwareCP)
    HardwareCP.Mount(Motherboard)

    print("[MOTHERBOARD] Power On sequence initiated.")

	-- 2. Hand control to BIOS
	local BIOS = require(script.Parent.Parent.Firmware.BIOS)
	BIOS.Boot(Motherboard.Hardware, Config)
    
    -- 3. Start CPU Clock
    -- The CPU needs to run. In a real machine it runs immediately.
    -- Here we need to expose the CPU loop to the Kernel's Scheduler OR run it here.
    -- The Kernel Scheduler usually manages the "Thread" that steps the CPU.
    -- But if we want "Motherboard-First", maybe the Motherboard starts a Heartbeat?
    -- However, the Kernel needs to manage processes. The "CPU" is a resource used by the Scheduler.
    -- So for now, we just leave it instantiated and let the Kernel pick it up.
end

function Motherboard.PowerOff()
    if not Motherboard.State.Powered then return end
    
    print("[MOTHERBOARD] Power Down.")
    Motherboard.State.Powered = false
    Motherboard.State.LEDs.PWR = false
    
    -- Reset Components
    if Motherboard.Hardware.HID then Motherboard.Hardware.HID:Shutdown() end
    -- Clearing references to help GC
    Motherboard.Hardware = {}
end

function Motherboard.Reset()
    Motherboard.PowerOff()
    task.wait(0.5)
    Motherboard.PowerOn()
end

return Motherboard
