# Bedrock Kernel

A lightweight, Unix-like kernel for Roblox OS emulation. Bedrock provides core OS functionality including virtual file system, process scheduling, memory management, and hardware abstraction.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Features

- **Virtual File System (VFS)**: Unix-like permissions (UID/GID/Mode), path caching, dynamic provisioning
- **Process Scheduler**: Round-robin with signals, sleep heap optimization, memory limits
- **Memory Management**: Heap allocator with first-fit strategy and block coalescing
- **Bedrock Hub**: DataStore-backed repository sharing (PULL/PUSH)
- **Internet Service**: Kernel-level WAN proxy (HTTP)
- **HDD Persistence**: DataStore-backed storage for local files
- **Hardware Abstraction Layer (HAL)**: GPU, HID, RAM drivers
- **System Calls**: 30+ syscalls for file I/O, processes, memory, and networking

## 📦 Installation

### Option A: GitHub Releases (Recommended)
Download the latest `Bedrock.rbxm` from the [Releases](https://github.com/gado7h/bedrock/releases) page and insert it into your Roblox project.

### Option B: Git Submodule
If you are using Rojo, you can add Bedrock as a submodule:

```bash
git submodule add https://github.com/gado7h/bedrock.git packages/bedrock
```

### Rojo Configuration

Bedrock is split into **Kernel** (client-side) and **Server** (host-side) components. Update your `default.project.json`:

```json
{
  "tree": {
    "ReplicatedStorage": {
      "Bedrock": {
        "$path": "packages/bedrock/src/Kernel"
      }
    },
    "ServerScriptService": {
      "BedrockServer": {
        "$path": "packages/bedrock/src/Server"
      }
    }
  }
}
```

## 🎯 Quick Start

Bedrock is a professional-grade kernel that requires a server-side component for networking and persistence.

### 1. Initialize Host Services (Server)
Ensure the `Server` folder is synced to `ReplicatedStorage`. The `init.server.luau` script will automatically handle RemoteFunction initialization.

### 2. Boot the Kernel (Client)

Bedrock is a "Distribution-First" kernel. You initialize it with a configuration and then start the boot process.

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bedrock = require(ReplicatedStorage.Bedrock.Kernel)

-- Configure your Distribution
local config = {
    Name = "MyDistro",
    Version = "1.0.0",
    RAMSize = 512 * 1024 * 1024, -- 512 MB
    
    -- Optional: Provision initial files
    VFS = {
        ["/boot/grub/grub.cfg"] = "linux /boot/vmlinuz.lua",
        ["/boot/vmlinuz.lua"] = "print('Hello from Bedrock!')"
    }
}

-- Initialize & Start
Bedrock.Init(config)
Bedrock.Start()
```

For more details on building your own OS, see the [Distributions Guide](docs/DISTRIBUTIONS.md).

## 🌐 Network & Services

Bedrock provide portable "Host Services" that run on the Roblox server to bridge kernel requests to Roblox APIs.

### Bedrock Hub
A decentralized DataStore-backed registry for sharing code.
- `HUB_PUSH`: Upload current directory to the Hub.
- `HUB_PULL`: Download repository snapshots.

### Internet Service
Wraps `HttpService` for WAN access. Use the `NET_REQ` syscall to make asynchronous web requests.

### HDD Persistence
Automatically maps `/dev/hdd` to a per-player DataStore, ensuring files persist across sessions.

## 📚 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md) - System design and components
- [API Reference](docs/API.md) - Complete documentation for all 30+ syscalls
- [Distributions Guide](docs/DISTRIBUTIONS.md) - Build your own OS on Bedrock
- [UI & App Development](docs/UI_AND_APPS.md) - Create graphical applications
- [Changelog](CHANGELOG.md) - Version history

## 🏗️ Architecture

```
src/
├── Kernel/             # Core Kernel components (Client)
│   ├── Core/           # VFS, Scheduler, Memory, Syscalls
│   ├── HAL/            # Hardware drivers (GPU, HID, RAM, Hub)
│   └── init.luau       # Kernel entry point
└── Server/             # Host Services (Server / RunContext.Server)
    ├── HubService.luau # DataStore Hub backend
    ├── HDDService.luau # DataStore persistence backend
    └── init.server.luau # Host service initializer
```

## 🔧 Requirements

- **Roblox Studio** (latest version)
- **Rojo** 7.x or higher (for syncing)
- **Luau** (strict mode recommended)

## 📖 Usage Examples

### File System Operations

```luau
local Syscall = require(ReplicatedStorage.Kernel.Core.Syscalls).Call

-- Create directory
Syscall("FS_MKDIR", "/tmp/mydir")

-- Write file
Syscall("FS_WRITE", "/tmp/mydir/file.txt", "Hello, World!")

-- Read file
local content = Syscall("FS_READ", "/tmp/mydir/file.txt")
print(content) -- "Hello, World!"
```

### Process Management

```luau
-- Execute program
local ok, err, pid = Syscall("EXEC", "/bin/myprogram.lua")

-- Send signal
Syscall("SIGNAL", pid, 9) -- SIGKILL

-- List processes
local processes = Syscall("PS_LIST")
```

## 📝 Examples

See the [examples/](examples/) directory for complete working examples:

- **[01_basic_usage.lua](examples/01_basic_usage.lua)** - Core kernel features overview
- **[02_filesystem.lua](examples/02_filesystem.lua)** - VFS operations and permissions
- **[03_processes.lua](examples/03_processes.lua)** - Process spawning and signals
- **[04_network.lua](examples/04_network.lua)** - HTTP requests (requires server)

Each example is fully documented and ready to run.

## 🧪 Testing

Bedrock is tested as part of parent projects. See [PremiumOS](https://github.com/gado7h/PremiumOS) for the complete test suite.

## 🤝 Contributing

Contributions are welcome! Please Open a Pull Request on GitHub.

## 📝 Version Compatibility

| Bedrock Version | Compatible Projects | Notes |
|----------------|---------------------|-------|
| 1.1.x          | PremiumOS 1.x       | Added Hub, Internet, HDD |
| 1.0.x          | PremiumOS 1.x       | Initial release |

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by Unix/Linux kernel design
- Built for educational purposes
- Part of the [PremiumOS](https://github.com/gado7h/PremiumOS) project

## 🔗 Links

- [PremiumOS](https://github.com/gado7h/PremiumOS) - Reference implementation
- [Issues](https://github.com/gado7h/bedrock/issues) - Bug reports and feature requests
- [Discussions](https://github.com/gado7h/bedrock/discussions) - Community discussions
