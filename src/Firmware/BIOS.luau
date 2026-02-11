-- Voyager-1 BIOS (Basic Input/Output System)
-- Handles POST and initializes physical hardware.

local BIOS = {}

function BIOS.Boot(Hardware, Config)
	print("[BIOS] Voyager-1 BIOS v1.0.0 initializing...")

	-- 1. POST (Power-On Self Test)
	if not Hardware.RAM then
		error("[BIOS] FATAL: RAM not detected!")
	end
    if not Hardware.CPU then
        error("[BIOS] FATAL: CPU not detected!")
    end

	print(`[BIOS] RAM Test: {Hardware.RAM.Size / 1024 / 1024}MB OK`)

	-- 2. Initialize Hardware
	Hardware.GPU:Init()
    Hardware.GPU:Clear(0x000000FF) -- Black
	print("[BIOS] GPU initialized.")

	Hardware.HID:Init()
	print("[BIOS] HID initialized.")
    
    Hardware.Network:Connect()
    Hardware.Hub:Connect()
    Hardware.HDD:Connect()
    print("[BIOS] Service bridges connected.")

	-- 3. Load Bootloader
	local Bootloader = require(script.Parent.Bootloader)
	Bootloader.Load(Hardware, Config)
end

return BIOS
