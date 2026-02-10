local Bootstrap = {}

function Bootstrap.Init(System)
    local VFS = System.VFS
    local _system = System
	local Log = require(script.Parent.Log)
	Log.info("BOOTSTRAP", "Dynamic provisioning starting...")

    -- Clear screen to remove "Rebooting..." text from previous session
    if System.GPU then
        System.GPU:Clear(0) -- Clear to black
        System.GPU:Flush() -- REQUIRED to actually blank the screen
    end

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Userspace = ReplicatedStorage:WaitForChild("Userspace")

	local function provisionFolder(folderName: string, vfsPath: string)
		local folder = Userspace:FindFirstChild(folderName)
		if not folder then
			return
		end


		if VFS and VFS.MkDir then
			VFS.MkDir(vfsPath, 0, 0)
		else
			Log.error("BOOTSTRAP", "VFS.MkDir missing! VFS: %s", tostring(VFS))
			return
		end

		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("ModuleScript") then
				local name = child.Name
				-- Only append .lua if no extension exists
                local vfsFileName = vfsPath .. "/" .. name
                if not string.find(name, "%.") then
                    vfsFileName = vfsFileName .. ".lua"
                end

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

    -- Create Device Nodes (Placeholders so they appear in 'ls')
    VFS.Write("/dev/gpu", "GPU DRIVER", 0, 0)
    VFS.Write("/dev/tty", "TTY DRIVER", 0, 0)
    VFS.Write("/dev/hdd", "HDD DRIVER", 0, 0)

    -- Configure Drivers
    local GPU_Driver = require(script.Parent.Parent.Drivers.GPU_Driver)
    GPU_Driver.Init(_system.GPU)
    VFS.Mount("/dev/gpu", GPU_Driver)

    local TTY_Driver = require(script.Parent.Parent.Drivers.TTY_Driver)
    TTY_Driver.Init(_system.Scheduler, _system.Pipes)
    VFS.Mount("/dev/tty", TTY_Driver)
    
    local HDD_Driver = require(script.Parent.Parent.Drivers.HDD_Driver)
    -- HDD instance is already initialized and passed in _system.HDD if we wanted, 
    -- but usually it's just mounted. 
    -- If _system has the hdd instance (from init.luau), we can mount its FS part.
    if _system.HDD then
        VFS.Mount("/dev/hdd", _system.HDD)
    end

	Log.info("BOOTSTRAP", "VFS Provisioning Complete (Dynamic).")
end

return Bootstrap
