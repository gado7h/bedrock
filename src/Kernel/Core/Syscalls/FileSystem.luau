-- FileSystem Syscalls
local Errno = require(script.Parent.Parent.Parent.Utils.Errno)

local FileSystem = {}

function FileSystem.Init(System)
	local VFS = System.VFS
	local HANDLERS = {}

	HANDLERS["FS_READ"] = function(path: string)
		local content, err = VFS.Read(path, 0, 0)
		if not content then return nil, err or Errno.ENOENT end
		return content
	end

	HANDLERS["FS_WRITE"] = function(path: string, content: any)
		local ok, err = VFS.Write(path, content, 0, 0)
		if not ok then return false, err or Errno.EIO end
		return true
	end

	HANDLERS["FS_LIST"] = function(path: string)
		local list, err = VFS.List(path, 0, 0)
		if not list then return nil, err or Errno.ENOENT end
		return list
	end

	HANDLERS["FS_STAT"] = function(path: string)
		local stat, err = VFS.Stat(path)
		if not stat then return nil, err or Errno.ENOENT end
		return stat
	end

	HANDLERS["FS_MKDIR"] = function(path: string)
		local ok, err = VFS.MkDir(path, 0, 0)
		if not ok then return false, err or Errno.EACCES end
		return true
	end

    HANDLERS["FS_EXISTS"] = function(path: string)
        return VFS.Stat(path) ~= nil
    end

	return HANDLERS
end

return FileSystem
