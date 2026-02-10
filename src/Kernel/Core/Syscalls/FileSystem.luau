--!strict

local FileSystem = {}

function FileSystem.Init(System: any)
	local function asyncVFS(proc, func, ...)
		if proc.SyscallResult then
			local res = proc.SyscallResult
			proc.SyscallResult = nil
			return table.unpack(res)
		end

		proc.State = "SYSCALL"
		local args = { ... }
		task.spawn(function()
			local res = { func(table.unpack(args)) }
			proc.SyscallResult = res
			System.Scheduler:WakeUp(proc.PID)
		end)
		coroutine.yield()

		if proc.SyscallResult then
			local res = proc.SyscallResult
			proc.SyscallResult = nil
			return table.unpack(res)
		end
	end

	return {
		["FS_LIST"] = function(path: string)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]
			local uid = (proc and proc.UID) or 0
			local gid = (proc and proc.GID) or 0

			local driver, relPath = System.VFS.GetDriver(path)
			if driver and driver.Async then
				return asyncVFS(proc, driver.List, relPath, uid, gid)
			end

			return System.VFS.List(path, uid, gid)
		end,

		["FS_READ"] = function(path: string)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]
			local uid = (proc and proc.UID) or 0
			local gid = (proc and proc.GID) or 0

			local driver, relPath = System.VFS.GetDriver(path)
			if driver and driver.Async then
				return asyncVFS(proc, driver.Read, relPath, uid, gid)
			end

			return System.VFS.Read(path, uid, gid)
		end,

		["FS_WRITE"] = function(path: string, content: string)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]
			local uid = (proc and proc.UID) or 0
			local gid = (proc and proc.GID) or 0

			path = System.VFS.NormalizePath(path)
			local driver, relPath = System.VFS.GetDriver(path)
			if driver and driver.Async then
				asyncVFS(proc, driver.Write, relPath, content, uid, gid)
				return true
			end

			System.VFS.Write(path, content, uid, gid)
			return true
		end,

		["FS_MKDIR"] = function(path)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]
			local uid = (proc and proc.UID) or 0
			local gid = (proc and proc.GID) or 0

			path = System.VFS.NormalizePath(path)
			local driver, relPath = System.VFS.GetDriver(path)
			if driver and driver.Async then
				return asyncVFS(proc, driver.MkDir, relPath, uid, gid)
			end

			return System.VFS.MkDir(path, uid, gid)
		end,

		["FS_REMOVE"] = function(path)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]
			local uid = (proc and proc.UID) or 0
			local gid = (proc and proc.GID) or 0

			path = System.VFS.NormalizePath(path)
			local driver, relPath = System.VFS.GetDriver(path)
			if driver and driver.Async and driver.Remove then
				-- Support async Remove if driver has it
				return asyncVFS(proc, driver.Remove, relPath, uid, gid)
			end

			return System.VFS.Remove(path, uid, gid)
		end,

		["FS_CHMOD"] = function(path, mode)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]
			local uid = (proc and proc.UID) or 0
			local gid = (proc and proc.GID) or 0

			return System.VFS.Chmod(path, mode, uid, gid)
		end,

		["FS_CHOWN"] = function(path, newUid, newGid)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]
			local uid = (proc and proc.UID) or 0
			local gid = (proc and proc.GID) or 0

			return System.VFS.Chown(path, newUid, newGid, uid, gid)
		end,

		["FS_STAT"] = function(path)
			local pid = System.Scheduler.CurrentPID
			local proc = System.Scheduler.Processes[pid]
			local uid = (proc and proc.UID) or 0
			local gid = (proc and proc.GID) or 0

			return System.VFS.Stat(path, uid, gid)
		end,
	}
end

return FileSystem
