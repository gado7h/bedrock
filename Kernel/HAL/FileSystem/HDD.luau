local HDD = {}
HDD.Name = "NetworkHDD"
HDD.Async = true

-- Wait for Remotes (Blocking? No, this runs in Kernel Init, likely fine if Remotes exist)
-- But Kernel Init is a require.
-- Using WaitForChild might yield the require?
-- Kernel Init runs in a script. Script runs in Roblox Task Scheduler. Yielding is fine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("PremiumOS_Remotes", 5)
if not Remotes then
	warn("[HDD] Remotes not found!")
end

local IO = Remotes and Remotes:WaitForChild("HDD_IO", 5)

function HDD.Read(path, uid)
	if not IO then
		return nil
	end
	return IO:InvokeServer("READ", path, uid)
end

function HDD.Write(path, content, uid)
	if not IO then
		return false
	end
	return IO:InvokeServer("WRITE", path, content, uid)
end

function HDD.List(path, uid)
	if not IO then
		return nil
	end
	return IO:InvokeServer("LIST", path, uid)
end

function HDD.MkDir(path, uid)
	if not IO then
		return false
	end
	return IO:InvokeServer("MKDIR", path, uid)
end

return HDD
