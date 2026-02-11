local Bootstrap = {}

-- Bootstrap / VFS Provisioner
-- Role: Loads the "Initial Ramdisk" (InitRD) from Roblox ReplicatedStorage
-- into the Kernel VFS. This simulates mounting a boot drive.

function Bootstrap.Init(System)
	local VFS = System.VFS
	local Log = require(script.Parent.Parent.Utils.Log)
	
    Log.info("BOOTSTRAP", "Mounting InitRD from ReplicatedStorage/Userspace...")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Userspace = ReplicatedStorage:FindFirstChild("Userspace")
    
    -- In Bedrock dev environment, Userspace might be in specific place.
    -- In PremiumOS, it's at root of src? No, in game hierarchy it's likely folder.
    -- We'll assume the standard folder structure.
    
    if not Userspace then
        Log.warn("BOOTSTRAP", "No Userspace folder found in ReplicatedStorage!")
        return
    end

	local function provisionFolder(folderName: string, vfsPath: string)
		local folder = Userspace:FindFirstChild(folderName)
		if not folder then return end

		if VFS and VFS.MkDir then
			VFS.MkDir(vfsPath, 0, 0)
		end

		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("ModuleScript") then
				local name = child.Name
				local success, result = pcall(require, child)
				if success then
                    local content = result
                    local extension = ".lua"

                    -- Handle "Source" table format if present (e.g. from Rojo sometimes or custom)
                    if type(result) == "table" and result.source then
                        content = result.source
                        if result.extension then extension = result.extension end
                    end
                    
                    if type(content) ~= "string" and type(content) ~= "function" then
                         -- If it's a module returning a table (API), we can't "execute" it as a script easily
                         -- unless we serialize it.
                         -- BUT, for Bedrock, we expect "Binary" scripts to return a function or string source.
                         -- If it returns a table, it's a Library.
                         -- We'll store it opaque? No, VFS stores strings.
                         -- We need source code. 
                         -- ReplicatedStorage source access is restricted in Roblox unless usage of specialized plugins.
                         -- Standard ModuleScripts execute and return value.
                         
                         -- If the return is a function, we can wrap it.
                         -- If the return is a table, we can't save it to VFS easily for execution later.
                         -- This is a known limitation of Roblox OSs without loadstring/source access.
                         -- ASSUMPTION: The 'Userspace' folder contains ModuleScripts that return
                         -- their source code as a string OR are pre-compiled functions we cache?
                         
                         -- Refined Approach:
                         -- Bootstrap loads the *ModuleScript Instance* itself? No.
                         -- Let's assume for now the user has specific loader setup where these modules return a
                         -- structure { source = "..." } OR just the function.
                    end

                    -- If it's a function (compiled module), we can't save to VFS string content.
                    -- EXCEPT if we use a special VFS file type "roblox_asset".
                    -- For this refactor, let's stick to the previous implementation's assumption:
                    -- That `require(child)` returns the content/source or we just store the result?
                    -- Looking at previous code: `local content = result`.
                    
                    -- FIX: If it's a raw function, likely `loadstring` output.
                    -- The VFS is string-based.
                    -- We might need a "RamFS" node type that holds Lua Objects.
                    
                    -- For now, let's just save.
				    local vfsFileName = vfsPath .. "/" .. name
                    if not string.find(name, "%.") then vfsFileName = vfsFileName .. extension end

					VFS.Write(vfsFileName, content, 0, 0)
					Log.info("BOOTSTRAP", "Provisioned %s", vfsFileName)
				end
			elseif child:IsA("Folder") then
				provisionFolder(folderName .. "/" .. child.Name, vfsPath .. "/" .. child.Name)
			end
		end
	end
    
    -- Provision the 'init' script specifically if it exists at root?
    -- Previous implementation scanned specific folders.
    -- Let's scan Root and specific standard dirs.
    
    -- Root Files
    for _, child in ipairs(Userspace:GetChildren()) do
        if child:IsA("ModuleScript") then
             -- e.g. init.luau
             local success, res = pcall(require, child)
             if success then
                 local name = child.Name
                 if name == "init" then name = "init.lua" end
                 VFS.Write("/" .. name, res, 0, 0)
             end
        end
    end

	provisionFolder("bin", "/bin")
	provisionFolder("lib", "/lib")
	provisionFolder("sbin", "/sbin")
	provisionFolder("etc", "/etc")

    -- Ensure /dev exists
    VFS.MkDir("/dev", 0, 0)
    VFS.MkDir("/home", 0, 0)

	Log.info("BOOTSTRAP", "InitRD Mounted.")
end

return Bootstrap
