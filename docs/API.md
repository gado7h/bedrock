# Bedrock Syscall API Reference

System calls (syscalls) are the interface between userland programs and the Bedrock kernel. All syscalls are invoked via the `libc.Syscall` method.

## File System (FS)

| Syscall | Arguments | Returns | Description |
|---------|-----------|---------|-------------|
| `FS_READ` | `path: string` | `content: string?`, `err: number?` | Reads the content of a file. |
| `FS_WRITE` | `path: string`, `content: string` | `success: boolean`, `err: number?` | Writes content to a file. |
| `FS_LIST` | `path: string` | `names: {string}?` | Lists files in a directory. |
| `FS_MKDIR` | `path: string` | `success: boolean` | Creates a new directory. |
| `FS_REMOVE` | `path: string` | `success: boolean` | Removes a file or directory. |
| `FS_CHMOD` | `path: string`, `mode: number` | `success: boolean` | Changes file permissions (octal). |
| `FS_CHOWN` | `path: string`, `uid: number`, `gid: number` | `success: boolean` | Changes file owner and group. |
| `FS_STAT` | `path: string` | `stat: table?` | Returns file metadata (Type, UID, GID, Mode, Size). |

## Process Management (PROC)

| Syscall | Arguments | Returns | Description |
|---------|-----------|---------|-------------|
| `EXEC` | `path: string`, `env: table?` | `ok: boolean`, `err: any`, `pid: number?` | Executes a program. |
| `EXIT` | `code: number?` | - | Terminates the current process. |
| `SIGNAL` | `pid: number`, `sig: number` | `success: boolean` | Sends a signal to a process. |
| `KILL` | `pid: number` | `success: boolean` | Forcefully kills a process (alias for `SIGNAL(pid, 9)`). |
| `SLEEP` | `ms: number` | - | Yields the process for a specific duration. |
| `WAITPID` | `pid: number` | `success: boolean` | Blocks until the target PID terminates. |
| `PS_LIST` | - | `processes: table` | Returns a list of all active processes. |
| `MALLOC` | `size: number` | `addr: number?` | Allocates memory on the kernel heap. |
| `FREE` | `addr: number` | - | Deallocates heap memory. |
| `GET_ENV` | `key: string` | `val: string?` | Gets an environment variable value. |
| `SET_ENV` | `key: string`, `val: string` | - | Sets an environment variable value. |

## Hardware Abstraction (HW)

| Syscall | Arguments | Returns | Description |
|---------|-----------|---------|-------------|
| `GPU_INFO` | - | `width: number`, `height: number` | Returns display dimensions. |
| `GPU_FLUSH` | `x, y, w, h?` | - | Flushes VRAM dirty region to the screen. |
| `GPU_RECT` | `x, y, w, h, color` | - | Hardware-accelerated rectangle fill. |
| `GPU_BLIT` | `dx, dy, sx, sy, w, h` | - | Hardware-accelerated block transfer (BitBlt). |
| `PRINT` | `msg: string` | - | Prints to standard output. |
| `POLL_EVENTS` | - | `events: {table}` | Returns a list of HID interrupts (keys, mouse). |
| `TTY_READ` | - | `char: string?` | Reads a single character from the process input queue. |
| `DMESG` | - | `logs: {string}` | Returns the kernel log buffer. |

## IPC (Pipes)

| Syscall | Arguments | Returns | Description |
|---------|-----------|---------|-------------|
| `PIPE_OPEN` | - | `handle: number` | Opens a new anonymous pipe. |
| `PIPE_WRITE` | `handle: number`, `data: string` | `success: boolean` | Writes data to a pipe. |
| `PIPE_READ` | `handle: number` | `data: string?` | Reads data from a pipe (blocks if empty). |
| `PIPE_CLOSE` | `handle: number` | - | Closes a pipe handle. |

## Network & Services

| Syscall | Arguments | Returns | Description |
|---------|-----------|---------|-------------|
| `NET_REQ` | `method, url, headers, body` | `table?`, `string?` | Asynchronous HTTP request. |
| `HUB_PULL` | `namespace, repo` | `success: boolean` | Downloads a repository from Bedrock Hub. |
| `HUB_PUSH` | `dirPath, namespace, repo` | `success: boolean` | Uploads a directory to Bedrock Hub. |

## System Control

| Syscall | Arguments | Returns | Description |
|---------|-----------|---------|-------------|
| `SYSTEM_REBOOT` | - | - | Reboots the kernel and restarts BIOS. |
| `SYSTEM_SHUTDOWN` | - | - | Halts the kernel and shuts down all services. |
