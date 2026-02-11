# Bedrock Examples

Practical examples demonstrating how to use the Bedrock kernel.

## Running Examples

These examples are designed to be executed from a userspace environment with `libc` available.

### In PremiumOS

```luau
-- From shell
> exec /path/to/example.lua

-- From code
Syscall("EXEC", "/path/to/example.lua")
```

### Standalone Integration

```luau
-- Copy example to your VFS
local exampleCode = require(script.Parent.examples["01_basic_usage"])
VFS.Write("/tmp/demo.lua", exampleCode)

-- Execute
Syscall("EXEC", "/tmp/demo.lua")
```

## Examples

### 01_basic_usage.lua
**Overview of core kernel features**

Demonstrates:
- File system operations (read, write, list)
- Process management (list processes)
- Memory allocation (malloc, free)
- Environment variables (get, set)

**Run:** `exec /examples/01_basic_usage.lua`

---

### 02_filesystem.lua
**Complete VFS demonstration**

Demonstrates:
- Directory creation and traversal
- File operations (write, read, stat)
- Permissions (chmod, mode checking)
- Recursive directory listing
- Cleanup operations

**Run:** `exec /examples/02_filesystem.lua`

---

### 03_processes.lua
**Process spawning and management**

Demonstrates:
- Process listing
- Spawning child processes
- Waiting for process completion
- Signal handlers (SIGINT)
- Sleep/scheduling

**Run:** `exec /examples/03_processes.lua`

---

### 04_network.lua
**Network requests (requires server)**

Demonstrates:
- Network availability checking
- GET requests
- POST requests with body
- Error handling

**Requirements:** Server-side network implementation (see [docs/NETWORK.md](../docs/NETWORK.md))

**Run:** `exec /examples/04_network.lua`

---

## Creating Your Own Programs

All userspace programs follow this pattern:

```luau
return [==[
-- Your program code
local libc = require("libc")
local Syscall = libc.Syscalls.Call

-- Use syscalls
Syscall("FS_WRITE", "/tmp/file.txt", "data")

-- Use libc helpers
libc.Print("Hello!\n")
]==]
```

### Available Syscalls

See [docs/API.md](../docs/API.md) for complete syscall reference.

**File System:**
- `FS_READ`, `FS_WRITE`, `FS_LIST`, `FS_MKDIR`, `FS_REMOVE`
- `FS_CHMOD`, `FS_CHOWN`, `FS_STAT`

**Process:**
- `EXEC`, `SIGNAL`, `KILL`, `SLEEP`, `WAIT_PID`, `PS_LIST`
- `SIGNAL_HANDLER`

**Memory:**
- `MALLOC`, `FREE`

**Hardware:**
- `GPU_INFO`, `GPU_FLUSH`, `GET_VRAM_PTR`, `POLL_EVENTS`, `TTY_READ`

**I/O:**
- `PIPE_OPEN`, `PIPE_WRITE`, `PIPE_READ`, `PIPE_CLOSE`

**System:**
- `PRINT`, `SYSTEM_REBOOT`, `SYSTEM_SHUTDOWN`

**Environment:**
- `ENV_GET`, `ENV_SET`

**Library:**
- `LIB_LOAD`

**Network:**
- `NET_REQ`

## Tips

1. **Always check return values** - Syscalls return `success, error`
2. **Clean up resources** - Remove temp files, free memory
3. **Handle errors gracefully** - Network may not be available
4. **Use libc helpers** - `libc.Print()` is easier than raw syscalls
5. **Test incrementally** - Start simple, add complexity

## Next Steps

- Read [Architecture Guide](../docs/ARCHITECTURE.md) to understand kernel internals
- Check [API Reference](../docs/API.md) for complete syscall documentation
- See [Network Configuration](../docs/NETWORK.md) for server setup
