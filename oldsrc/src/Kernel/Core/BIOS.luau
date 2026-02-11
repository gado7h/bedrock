local Log = require(script.Parent.Log)

local BIOS = {}
BIOS.__index = BIOS

type Device = {
	Init: (self: Device) -> (boolean, string?),
	Name: string?,
}

function BIOS.InitHardware(devices: { [string]: any })
	Log.info("BIOS", "Performing POST (Power-On Self Test)...")

	for name, device in pairs(devices) do
		if type(device) == "table" and device.Init then
			local ok, err = (device :: any):Init()
			if not ok then
				Log.error("BIOS", "POST Failure: " .. name .. " - " .. tostring(err))
				return false, "Hardware Failure: " .. name
			end
			Log.info("BIOS", "Device OK: " .. name)
		end
	end

	return true, ""
end

function BIOS.Boot(VFS: any, Syscalls: any)
	Log.info("BIOS", "Handing over control to Bootloader...")
	local Bootloader = require(script.Parent.Bootloader)
	Bootloader.Run(VFS, Syscalls)
end

return BIOS
