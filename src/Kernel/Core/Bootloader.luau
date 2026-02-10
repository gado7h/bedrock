local Bootloader = {}

function Bootloader.Run(VFS: any, Syscalls: any)
	local Log = require(script.Parent.Parent.Core.Log)
	Log.info("BOOT", "Bedrock Bootloader v1.0")

	-- 1. Look for GRUB Configuration
	local grubContent = VFS.Read("/boot/grub/grub.cfg")
	if grubContent then
		Log.info("BOOT", "Found valid configuration at /boot/grub/grub.cfg")
		
		-- Simple parser for "linux /path/to/script"
		-- In a real implementation, this would parse menu entries
		for line in string.gmatch(grubContent, "[^\r\n]+") do
			local cmd, arg = string.match(line, "^%s*(%S+)%s+(%S+)")
			if cmd == "entry" or cmd == "linux" or cmd == "boot" then
				if VFS.Stat(arg) then
					Log.info("BOOT", "Booting entry: %s", arg)
					return Syscalls.Call("EXEC", arg)
				else
					Log.warn("BOOT", "Configured entry not found: %s", arg)
				end
			end
		end
	end

	-- 2. Fallback: HDD Boot (MBR style)
	if VFS.Stat("/dev/hdd/boot.lua") then
		Log.info("BOOT", "Booting from HDD (/dev/hdd/boot.lua)")
		return Syscalls.Call("EXEC", "/dev/hdd/boot.lua")
	end

	-- 3. Fallback: System/Initramfs
	if VFS.Stat("/sbin/main.lua") then
		Log.info("BOOT", "Booting from internal storage (/sbin/main.lua)")
		return Syscalls.Call("EXEC", "/sbin/main.lua")
	end

	Log.fatal("BOOT", "KERNEL PANIC: No bootable medium found!")
	Log.fatal("BOOT", "Please verify /boot/grub/grub.cfg or install a valid system.")
end

return Bootloader
