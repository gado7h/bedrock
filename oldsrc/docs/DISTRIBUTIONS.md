# Building Bedrock Distributions

Bedrock is designed as a modular **Kernel Library**, not just a monolithic OS. This means you can build your own custom Operating System ("Distribution") on top of Bedrock without modifying the core kernel code.

## The Philosophy

Just like Linux has Ubuntu, Arch, and Fedora, Bedrock allows you to create:
-   **Desktop OS**: With a full GUI and window manager.
-   **Server OS**: Headless, optimized for backend tasks.
-   **Embedded OS**: Minimal footprint for specific devices (e.g., in-game computers).

## How it Works

The Bedrock Kernel is a `ModuleScript` that you `require()` in your own client-side LocalScript.

1.  **Configure**: You pass a configuration table to `Kernel.Init()`.
2.  **Initialize**: The kernel sets up the hardware (Virtual RAM, GPU, Network).
3.  **Boot**: You call `Kernel.Start()`, which hands control to the Scheduler.

## Creating a Distribution

### 1. Structure
Create a new Folder or Project in your Rojo tree for your distro.
```
MyDistro/
├── src/
│   ├── Client/
│   │   └── Init.client.luau  <-- Your Boot Script
│   └── Shared/
│       └── ...
```

### 2. Bootloader Configuration (The GRUB way)

Bedrock now includes an explicit `Bootloader` module that looks for a configuration at `/boot/grub/grub.cfg`. This allows you to decouple your distribution initialization from the kernel.

Example `grub.cfg`:
```cfg
# MyDistro Boot Config
linux /boot/vmlinuz.lua
```

Your `vmlinuz.lua` (the virtual kernel/init script) would then handle the rest of the OS startup.

### 3. Boot Script (Init.client.luau)

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bedrock = require(ReplicatedStorage.Bedrock.Kernel)

local config = {
    Name = "MyDistro",
    Version = "1.0.0",
    RAMSize = 128 * 1024 * 1024, -- 128 MB
    
    -- Custom VFS (Inject your own files!)
    VFS = {
        ["/boot/grub/grub.cfg"] = "linux /boot/vmlinuz.lua",
        ["/boot/vmlinuz.lua"] = [[
            local sys = require(libc.Syscalls)
            sys.Call("PRINT", "Booting MyDistro...\n")
            sys.Call("EXEC", "/bin/hello.lua")
        ]],
        ["/bin/hello.lua"] = "print('Hello from MyDistro!')"
    }
}

Bedrock.Init(config)
Bedrock.Start()
```

## Customizing the Environment

You can customize almost anything via the `VFS` configuration:
-   **Network Config**: Inject `/etc/hosts` or `/etc/resolv.conf` (if supported by your network stack).
-   **Startup Scripts**: Create a custom `/etc/init.d/rcS` style startup.
-   **UI**: Replace `/bin/shell.lua` or `/bin/desktop.lua` with your own UI code.

## Best Practices

-   **Do not modify Bedrock Source**: Treat the `Kernel` folder as a read-only dependency (like a package).
-   **Use Userland APIs**: Your custom scripts should use `syscalls` (via `libc`), NOT internal kernel functions.
-   **Keep it Lightweight**: Only inject what you need in the VFS config. Large assets should be loaded dynamically via `Network` or `HDD`.
