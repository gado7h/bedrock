# Bedrock Kernel Guide 🏗️

Bedrock is a professional-grade, Unix-inspired kernel for Roblox. It provides the essential "plumbing" for your OS: a file system (VFS), a process scheduler, memory management, and hardware abstraction.

## 🌟 Why Bedrock?
- **Modular**: Use only the parts you need.
- **Portable**: Run the same "distribution" in multiple Roblox games.
- **Unix-like**: Familiar APIs (`EXEC`, `FS_READ`, `MALLOC`).
- **Data-Driven**: Provision files directly from Roblox `ModuleScripts`.

---

## 🚀 Quick Start: Building a Distribution

A "Distribution" is your OS configuration. Here is how you boot a minimal kernel in Roblox:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bedrock = require(ReplicatedStorage.Packages.Bedrock.Kernel)

-- 1. Configure the system
local config = {
    Name = "MyOS",
    Version = "1.0.0",
    RAMSize = 128 * 1024 * 1024, -- 128 MB
    
    -- Provision initial files
    VFS = {
        ["/etc/motd"] = "Welcome to My Custom OS!",
        ["/bin/init.lua"] = "print('Init system started!')"
    }
}

-- 2. Initialize and Start
Bedrock.Init(config)
Bedrock.Start()
```

---

## 🏗️ Core Concepts

### 1. The Virtual File System (VFS)
The VFS is the heart of Bedrock. It organizes everything into a tree.
- **Mount Points**: You can "mount" drivers (like a GPU or HDD) to specific paths like `/dev/gpu`.
- **Permissions**: Every file has an Owner (UID), Group (GID), and Mode (rwxrwxrwx).

### 2. Process Scheduling
Bedrock uses cooperative multitasking. Use `EXEC` to spawn a new process:
```luau
local ok, err, pid = Syscall("EXEC", "/bin/shell.lua")
```

### 3. Hardware Abstraction (HAL)
Bedrock doesn't talk to Roblox APIs directly. It talks to **Drivers**.
- **GPU**: Handles drawing and text rendering.
- **HID**: Handles keyboard and mouse events.
- **Network**: Bridges to `HttpService` via server-side proxies.

---

## 🔧 Developing for Bedrock

### Adding a New Syscall
1.  Navigate to `src/Kernel/Core/Syscalls/`.
2.  Add a handler to the relevant category (e.g., `FileSystem.luau`).
3.  Register it in the `Init` function.
4.  Documentation! Update the [API Reference](API.md).

### Creating a Driver
Drivers are `ModuleScripts` that implement specific functions (like `Read`, `Write`, or `Flush`). See `src/Kernel/HAL/GPU.luau` for an example.

---

## 📚 Essential Reading
- [**API Reference**](API.md) - List of all 30+ syscalls.
- [**Architecture Deep-Dive**](ARCHITECTURE.md) - How the kernel works internally.
- [**Networking Guide**](NETWORK.md) - How to use the Hub and WAN.
- [**UI & App Development**](UI_AND_APPS.md) - Building graphical interfaces.

---

> [!IMPORTANT]
> Bedrock requires **Server-side Host Services** to be initialized for networking and permanence features to work. See the main README for setup instructions.
