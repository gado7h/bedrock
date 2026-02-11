-- Voyager-1 Bootloader
-- Loads the Kernel image and jumps to it.

local Bootloader = {}

function Bootloader.Load(Hardware, Config)
	print("[BOOTLOADER] Searching for Kernel bundle...")

	-- In our current Roblox implementation, the Kernel is a script we require.
	-- In a real system, we'd read it from HDD/VFS.
	local KernelScript = script.Parent.Parent.Kernel
	local Kernel = require(KernelScript)

	print("[BOOTLOADER] Transferring control to Kernel...")
	Kernel.Init(Hardware, Config)
	Kernel.Start()
end

return Bootloader
