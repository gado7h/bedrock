# Bedrock Kernel

A lightweight, Unix-like kernel for Roblox OS emulation. Bedrock provides core OS functionality including virtual file system, process scheduling, memory management, and hardware abstraction.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Features

- **Virtual File System (VFS)**: Unix-like permissions (UID/GID/Mode), path caching, dynamic provisioning
- **Process Scheduler**: Round-robin with signals, sleep heap optimization, memory limits
- **Memory Management**: Heap allocator with first-fit strategy and block coalescing
- **Hardware Abstraction Layer (HAL)**: GPU, HID, RAM, Network drivers
- **System Calls**: 30+ syscalls for file I/O, processes, memory, and hardware
- **Custom Lua VM**: Bytecode interpreter (FiOne + Yueliang) for sandboxed execution

## 📦 Installation

### As Git Submodule (Recommended)

```bash
cd your-roblox-project
git submodule add https://github.com/gado7h/bedrock.git bedrock
git submodule update --init --recursive
```

### Rojo Configuration

```json
{
  "tree": {
    "ReplicatedStorage": {
      "Kernel": {
        "$path": "bedrock/Kernel"
      }
    }
  }
}
```

## 🎯 Quick Start

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kernel = require(ReplicatedStorage.Kernel)

-- Boot the kernel
Kernel.Boot()
```

### Network Configuration

Bedrock's network support is **optional** and requires a server-side implementation.

#### Without Server (Standalone)
```luau
Kernel.Boot()  -- Network auto-disabled if no server found
```

Network syscalls will return `false, "Network not available"`.

#### With Server (HTTP Proxy)
Create a server-side RemoteFunction to enable network:

```luau
-- ServerScriptService/NetworkProxy.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local remote = Instance.new("RemoteFunction")
remote.Name = "PremiumOS_Network"
remote.Parent = ReplicatedStorage

remote.OnServerInvoke = function(player, method, url, body)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = method,
            Body = body,
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })
    end)
    
    if success then
        return response.Body
    else
        return nil, response  -- Error message
    end
end
```

Then boot normally:
```luau
Kernel.Boot()  -- Network auto-enabled when server is present
```

## 📚 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md) - System design and components
- [API Reference](docs/API.md) - Complete syscall documentation
- [Network Configuration](docs/NETWORK.md) - Server setup and usage
- [Changelog](CHANGELOG.md) - Version history

## 🏗️ Architecture

```
Kernel/
├── Core/              # Kernel core components
│   ├── VFS.luau       # Virtual file system
│   ├── Scheduler.luau # Process scheduler  
│   ├── Heap.luau      # Memory allocator
│   ├── Bootstrap.luau # File provisioning
│   ├── LuaVM/         # Lua VM (FiOne + Yueliang)
│   └── Syscalls/      # System call handlers
├── HAL/               # Hardware abstraction layer
│   ├── GPU.luau       # Graphics driver (16-color palette)
│   ├── HID.luau       # Input driver (keyboard/mouse)
│   ├── RAM.luau       # Memory driver (unified buffer)
│   └── Network.luau   # Network driver (HTTP)
└── init.luau          # Kernel entry point
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

Each example is fully documented and ready to run. See [examples/README.md](examples/README.md) for details.

## 🧪 Testing

Bedrock is tested as part of parent projects. See [PremiumOS](https://github.com/gado7h/PremiumOS) for the complete test suite.

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 Version Compatibility

| Bedrock Version | Compatible Projects | Notes |
|----------------|---------------------|-------|
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
