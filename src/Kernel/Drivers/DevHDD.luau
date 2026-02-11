-- /dev/hdd driver
-- Maps kernel VFS calls to Physical HDD component.

local DevHDD = {}
DevHDD.Name = "DevHDD"
DevHDD.Async = true

local _hdd = nil -- Physical HDD instance

function DevHDD.Init(hdd: any)
	_hdd = hdd
end

function DevHDD.Read(path: string, uid: number?): (any, string?)
	if not _hdd then return nil, "HDD Offline" end
	return _hdd:Invoke("READ", path, uid)
end

function DevHDD.Write(path: string, content: any, uid: number?): (boolean, string?)
	if not _hdd then return false, "HDD Offline" end
	return _hdd:Invoke("WRITE", path, content, uid)
end

function DevHDD.List(path: string, uid: number?): ({ string }?, string?)
	if not _hdd then return nil, "HDD Offline" end
	return _hdd:Invoke("LIST", path, uid)
end

function DevHDD.MkDir(path: string, uid: number?): (boolean, string?)
	if not _hdd then return false, "HDD Offline" end
	return _hdd:Invoke("MKDIR", path, uid)
end

return DevHDD
