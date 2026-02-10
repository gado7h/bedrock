# Bedrock Architecture

## Overview

Bedrock is a microkernel-inspired OS kernel for Roblox, implementing Unix-like abstractions while optimized for the Roblox runtime environment.

## Design Principles

1. **Separation of Concerns**: Clear boundaries between kernel, HAL, and userspace
2. **Minimal Kernel**: Core functionality only; complex features in userspace
3. **Performance**: Caching, lazy evaluation, and efficient data structures
4. **Compatibility**: Unix-like API for familiar development experience

## System Layers

```
┌─────────────────────────────────────────┐
│           Userspace Programs            │
│    (Applications, Libraries, Shell)     │
└─────────────────┬───────────────────────┘
                  │ System Calls
┌─────────────────▼───────────────────────┐
│              Kernel Core                │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
│  │   VFS    │ │Scheduler │ │  Heap   │ │
│  │  Cache   │ │ Signals  │ │ Alloc   │ │
│  └──────────┘ └──────────┘ └─────────┘ │
└─────────────────┬───────────────────────┘
                  │ HAL Interface
┌─────────────────▼───────────────────────┐
│         Hardware Abstraction            │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌────────┐ │
│  │ GPU  │ │ HID  │ │ RAM  │ │Network │ │
│  └──────┘ └──────┘ └──────┘ └────────┘ │
└─────────────────┬───────────────────────┘
                  │ Roblox APIs
┌─────────────────▼───────────────────────┐
│            Roblox Runtime               │
│  (RunService, UserInputService, etc.)   │
└─────────────────────────────────────────┘
```

## Core Components

### Virtual File System (VFS)

**Purpose**: Unified interface for file operations with Unix permissions.

**Key Features**:
- Tree-based in-memory file system
- Unix permissions (UID/GID/Mode)
- Path normalization and caching
- Mount point support for drivers

**Performance**:
- O(1) cached path lookups
- Selective cache invalidation
- Lazy directory traversal

**Files**: `Core/VFS.luau`

---

### Process Scheduler

**Purpose**: Cooperative multitasking with round-robin scheduling.

**Key Features**:
- Round-robin process scheduling
- Signal handling (SIGINT, SIGKILL, SIGTERM, custom)
- Sleep heap for timer-based wakeups
- Process environment variables

**Performance**:
- O(log n) sleep heap operations
- O(1) process switching
- Linked list for ready queue

**Files**: `Core/Scheduler.luau`, `Core/Signals.luau`

---

### Memory Management

**Purpose**: Dynamic memory allocation with heap management.

**Key Features**:
- First-fit allocation strategy
- Block coalescing on free
- Alignment support
- Out-of-memory handling

**Performance**:
- O(n) allocation (n = number of free blocks)
- O(1) deallocation
- Automatic block merging

**Files**: `Core/Heap.luau`

---

### System Calls

**Purpose**: Kernel-userspace interface.

**Categories**:
- **File System**: Read, Write, List, MkDir, Remove, Chmod, Chown, Stat
- **Process**: Exec, Signal, Kill, Sleep, WaitPid, PsList
- **Memory**: Malloc, Free
- **Hardware**: GPU operations, Event polling, TTY I/O
- **I/O**: Pipe operations
- **System**: Reboot, Shutdown
- **Environment**: Get/Set environment variables
- **Library**: Dynamic library loading
- **Network**: HTTP requests

**Files**: `Core/Syscalls/*.luau`

---

### Hardware Abstraction Layer (HAL)

**Purpose**: Abstract Roblox-specific APIs into generic drivers.

#### GPU Driver
- 16-color indexed palette
- Software rendering to buffer
- Dirty rectangle optimization
- Screen scrolling

#### HID Driver
- Keyboard input (with modifiers)
- Mouse input (position + buttons)
- Interrupt queue for events

#### RAM Driver
- Unified memory buffer
- 8-bit and 32-bit operations
- Memory fill and copy

#### Network Driver
- HTTP request abstraction
- Async request handling

**Files**: `HAL/*.luau`

---

### Lua VM

**Purpose**: Execute untrusted userspace code in sandboxed environment.

**Components**:
- **Yueliang**: Lua 5.1 compiler (source → bytecode)
- **FiOne**: Bytecode interpreter

**Features**:
- Custom environment per process
- Syscall integration
- Error handling and recovery

**Files**: `Core/LuaVM/*.luau`

---

## Data Flow Examples

### File Read Operation

```
User Program
    ↓ Syscall("FS_READ", "/etc/config")
Syscalls/FileSystem.luau
    ↓ VFS.Read(path, uid, gid)
Core/VFS.luau
    ↓ CheckAccess() → Traverse() → node.Content
    ↑ Return file content
Syscalls/FileSystem.luau
    ↑ Return to user
User Program
```

### Process Execution

```
User Program
    ↓ Syscall("EXEC", "/bin/ls.lua")
Syscalls/Process.luau
    ↓ VFS.Read() → Loader.Compile() → Scheduler.Spawn()
Core/Scheduler.luau
    ↓ Create process, add to queue
    ↓ Schedule() picks process
    ↓ Execute in LuaVM
Core/LuaVM/FiOne.luau
    ↓ Run bytecode
    ↑ Yield on syscall or completion
Core/Scheduler.luau
    ↑ Return PID
User Program
```

## Performance Characteristics

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| VFS Traverse (cached) | O(1) | Path cache hit |
| VFS Traverse (uncached) | O(d) | d = path depth |
| VFS Write | O(d + k) | k = invalidated paths |
| Process Spawn | O(1) | Linked list append |
| Process Schedule | O(1) | Round-robin |
| Sleep/Wake | O(log n) | Binary heap |
| Malloc | O(f) | f = free blocks |
| Free | O(1) | With coalescing |

## Memory Layout

```
RAM Buffer (500MB default)
┌─────────────────────────────────────┐
│  0x00000000 - 0x000FFFFF  │  1MB   │ Kernel Reserved
├─────────────────────────────────────┤
│  0x00100000 - 0x1DFFFFFF  │ 479MB  │ Heap (User Allocations)
├─────────────────────────────────────┤
│  0x1E000000 - 0x1E8FFFFF  │  9MB   │ VRAM (320x180 screen)
├─────────────────────────────────────┤
│  0x1E900000 - 0x1FFFFFFF  │ 11MB   │ Reserved
└─────────────────────────────────────┘
```

## Security Model

- **UID 0 (root)**: Full system access
- **UID > 0**: Restricted by file permissions
- **Permissions**: Unix-style rwxrwxrwx (owner/group/other)
- **Sandboxing**: LuaVM isolates userspace from kernel

## Future Enhancements

- [ ] Virtual memory with paging
- [ ] Multi-core scheduler support
- [ ] Filesystem drivers (ext2-like)
- [ ] Network stack (TCP/IP)
- [ ] IPC mechanisms (shared memory, message queues)
