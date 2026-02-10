# Bedrock Kernel

A Unix-like kernel for Roblox OS emulation. Bedrock provides core OS functionality including VFS, process scheduling, memory management, and hardware abstraction.

## Features

- **Virtual File System**: Unix-like permissions, path traversal, caching
- **Process Scheduler**: Round-robin with signals and sleep heap
- **Memory Management**: Heap allocator with first-fit strategy
- **Hardware Abstraction**: GPU, HID, RAM, Network drivers
- **System Calls**: 30+ syscalls for file I/O, processes, memory, hardware
- **Custom VM**: Lua bytecode interpreter (FiOne + Yueliang)

## Architecture

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
│   ├── GPU.luau       # Graphics driver
│   ├── HID.luau       # Input driver
│   ├── RAM.luau       # Memory driver
│   └── Network.luau   # Network driver
└── init.luau          # Kernel entry point
```

## Usage

### As Rojo Submodule

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

### Boot Kernel

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kernel = require(ReplicatedStorage.Kernel)

Kernel.Boot()
```

## API

### Kernel.Boot()
Initialize and start the kernel. Sets up VFS, scheduler, hardware, and boots the init process.

### System Calls
See [syscalls documentation](https://github.com/yourusername/PremiumOS/blob/main/docs/syscalls.md) for complete API reference.

## Requirements

- Roblox Studio
- Rojo (for syncing)

## Version Compatibility

| Bedrock Version | Compatible Projects |
|----------------|---------------------|
| 1.0.x          | PremiumOS 1.x       |

## Development

### Running Tests
Tests are maintained in the parent project (e.g., PremiumOS).

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License
