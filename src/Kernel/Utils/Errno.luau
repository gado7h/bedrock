-- POSIX-compatible error codes for kernel operations
-- Extended for Bedrock VFS support

local Errno = {}

Errno.SUCCESS = 0
Errno.EPERM = 1 -- Operation not permitted
Errno.ENOENT = 2 -- No such file or directory
Errno.ESRCH = 3 -- No such process
Errno.EIO = 5 -- I/O error
Errno.E2BIG = 7 -- Argument list too long
Errno.ENOEXEC = 8 -- Exec format error
Errno.EBADF = 9 -- Bad file number
Errno.ECHILD = 10 -- No child processes
Errno.EAGAIN = 11 -- Try again
Errno.ENOMEM = 12 -- Out of memory
Errno.EACCES = 13 -- Permission denied
Errno.EFAULT = 14 -- Bad address
Errno.EBUSY = 16 -- Device or resource busy
Errno.EEXIST = 17 -- File exists
Errno.EXDEV = 18 -- Cross-device link
Errno.ENODEV = 19 -- No such device
Errno.ENOTDIR = 20 -- Not a directory
Errno.EISDIR = 21 -- Is a directory
Errno.EINVAL = 22 -- Invalid argument
Errno.ENFILE = 23 -- File table overflow
Errno.EMFILE = 24 -- Too many open files
Errno.ENOTTY = 25 -- Not a typewriter
Errno.EFBIG = 27 -- File too large
Errno.ENOSPC = 28 -- No space left on device
Errno.ESPIPE = 29 -- Illegal seek
Errno.EROFS = 30 -- Read-only file system
Errno.EMLINK = 31 -- Too many links
Errno.EPIPE = 32 -- Broken pipe
Errno.EDOM = 33 -- Math argument out of domain of func
Errno.ERANGE = 34 -- Math result not representable
Errno.ENOSYS = 38 -- Function not implemented

-- Bedrock Specific
Errno.ETIMEOUT = 100
Errno.EUNKNOWN = 999

Errno.Messages = {
	[Errno.SUCCESS] = "Success",
	[Errno.EPERM] = "Operation not permitted",
	[Errno.ENOENT] = "No such file or directory",
	[Errno.ESRCH] = "No such process",
	[Errno.EIO] = "I/O error",
    [Errno.E2BIG] = "Argument list too long",
	[Errno.ENOEXEC] = "Exec format error",
    [Errno.EBADF] = "Bad file number",
    [Errno.ECHILD] = "No child processes",
    [Errno.EAGAIN] = "Try again",
	[Errno.ENOMEM] = "Out of memory",
	[Errno.EACCES] = "Permission denied",
    [Errno.EFAULT] = "Bad address",
    [Errno.EBUSY] = "Device or resource busy",
	[Errno.EEXIST] = "File already exists",
    [Errno.EXDEV] = "Cross-device link",
    [Errno.ENODEV] = "No such device",
	[Errno.ENOTDIR] = "Not a directory",
	[Errno.EISDIR] = "Is a directory",
    [Errno.EINVAL] = "Invalid argument",
    [Errno.ENFILE] = "File table overflow",
    [Errno.EMFILE] = "Too many open files",
    [Errno.ENOTTY] = "Not a typewriter",
    [Errno.EFBIG] = "File too large",
    [Errno.ENOSPC] = "No space left on device",
    [Errno.ESPIPE] = "Illegal seek",
    [Errno.EROFS] = "Read-only file system",
    [Errno.EMLINK] = "Too many links",
    [Errno.EPIPE] = "Broken pipe",
    [Errno.EDOM] = "Math argument out of domain of func",
    [Errno.ERANGE] = "Math result not representable",
	[Errno.ENOSYS] = "Function not implemented",
    [Errno.ETIMEOUT] = "Operation timed out",
    [Errno.EUNKNOWN] = "Unknown error",
}

function Errno.Strerror(code: number): string
	return Errno.Messages[code] or `Unknown error ({code})`
end

return Errno
