-- POSIX-compatible error codes for kernel operations

local Errno = {}

Errno.SUCCESS = 0
Errno.EPERM = 1 -- Operation not permitted
Errno.ENOENT = 2 -- No such file or directory
Errno.ESRCH = 3 -- No such process
Errno.EIO = 5 -- I/O error
Errno.ENOEXEC = 8 -- Exec format error
Errno.EACCES = 13 -- Permission denied
Errno.EEXIST = 17 -- File exists
Errno.ENOTDIR = 20 -- Not a directory
Errno.EISDIR = 21 -- Is a directory
Errno.ENOMEM = 12 -- Out of memory
Errno.ENOSYS = 38 -- Function not implemented

-- Human-readable descriptions
Errno.Messages = {
	[Errno.SUCCESS] = "Success",
	[Errno.EPERM] = "Operation not permitted",
	[Errno.ENOENT] = "No such file or directory",
	[Errno.ESRCH] = "No such process",
	[Errno.EIO] = "I/O error",
	[Errno.ENOEXEC] = "Exec format error",
	[Errno.EACCES] = "Permission denied",
	[Errno.EEXIST] = "File already exists",
	[Errno.ENOTDIR] = "Not a directory",
	[Errno.EISDIR] = "Is a directory",
	[Errno.ENOMEM] = "Out of memory",
	[Errno.ENOSYS] = "Function not implemented",
}

-- Get a human-readable error string
function Errno.Strerror(code: number): string
	return Errno.Messages[code] or `Unknown error ({code})`
end

return Errno
