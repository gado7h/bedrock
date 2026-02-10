local Bootstrap = {}

function Bootstrap.Init(VFS)
	local Log = require(script.Parent.Log)
	Log.info("BOOTSTRAP", "Dynamic provisioning starting...")

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

	Log.info("BOOTSTRAP", "VFS Provisioning Complete (Dynamic).")
end

return Bootstrap
