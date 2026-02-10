local Bootstrap = {}

function Bootstrap.Init(System)
    local VFS = System.VFS
    local _system = System
	local Log = require(script.Parent.Log)
	local Log = require(script.Parent.Log)
	Log.info("BOOTSTRAP", "Dynamic provisioning starting...")

    -- Clear screen to remove "Rebooting..." text from previous session
    if System.GPU then
        System.GPU:Clear(0) -- Clear to black
    end

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Userspace = ReplicatedStorage:WaitForChild("Userspace")

	local function provisionFolder(folderName: string, vfsPath: string)
		local folder = Userspace:FindFirstChild(folderName)
		if not folder then
			return
		end

		VFS.MkDir(vfsPath, 0, 0)
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("ModuleScript") then
				local name = child.Name
				-- Convert .luau name to .lua for VFS (tradition)
				local vfsFileName = vfsPath .. "/" .. name .. ".lua"

				local success, result = pcall(require, child)
				if success then
					VFS.Write(vfsFileName, result, 0, 0)
					Log.info("BOOTSTRAP", "Provisioned %s", vfsFileName)
				else
					Log.warn("BOOTSTRAP", "Failed to load %s: %s", name, tostring(result))
				end
			elseif child:IsA("Folder") then
				provisionFolder(folderName .. "/" .. child.Name, vfsPath .. "/" .. child.Name)
			end
		end
	end

	-- Minimal "initramfs" provisioning
	provisionFolder("bin", "/bin")
	provisionFolder("lib", "/lib")
	provisionFolder("sbin", "/sbin")
	provisionFolder("etc", "/etc")

    -- Ensure system directories exist
    VFS.MkDir("/dev", 0, 0)
    VFS.MkDir("/home", 0, 0)
    VFS.MkDir("/home/root", 0, 0)

    -- Configure Drivers
    local GPU_Driver = require(script.Parent.Parent.Drivers.GPU_Driver)
    GPU_Driver.Init(_system.GPU)
    VFS.Mount("/dev/gpu", GPU_Driver)

    local TTY_Driver = require(script.Parent.Parent.Drivers.TTY_Driver)
    TTY_Driver.Init(_system.Scheduler, _system.Pipes)
    VFS.Mount("/dev/tty", TTY_Driver)
    
    -- NOTE: HDD driver is usually handled by the HDD Service or Hub, 
    -- but if we had a dedicated driver file we would mount it here too.
    -- For now, /dev/hdd remains a placeholder or we can implement a stub driver later.

	Log.info("BOOTSTRAP", "VFS Provisioning Complete (Dynamic).")
end

return Bootstrap
