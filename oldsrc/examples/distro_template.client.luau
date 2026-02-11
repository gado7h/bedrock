-- Bedrock Distribution Template
-- This is a client-side script (LocalScript) that initializes the Bedrock Kernel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bedrock = require(ReplicatedStorage:WaitForChild("Kernel"))

-- 1. Configure the Kernel
-- You can customize RAM, Resolution, and inject custom files here.
local config = {
	Name = "MyCustomDistro",
	Version = "0.1.0-alpha",
	RAMSize = 256 * 1024 * 1024, -- 256 MB
	VideoWidth = 480,
	VideoHeight = 270,
	BootScript = "/boot.lua",
	
	-- Custom Virtual File System Provisioning
	VFS = {
		["/boot/grub/grub.cfg"] = [[
			# Bedrock Boot Configuration
			linux /boot/vmlinuz.lua
		]],
		["/boot/vmlinuz.lua"] = [[
			local sys = require(libc.Syscalls)
			print("Welcome to MyCustomDistro (via Bootloader)!")
			sys.Call("EXEC", "/bin/sh.lua") 
		]],
		["/etc/motd"] = "Hello from Custom VFS!\n",
	}
}

-- 2. Initialize the System
print("Booting Bedrock...")
Bedrock.Init(config)

-- 3. Start the Kernel
Bedrock.Start()
