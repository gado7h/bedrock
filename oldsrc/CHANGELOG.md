# Changelog

All notable changes to Bedrock will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-02-10

### Added
- **Restructured Core**: Moved source code to `src/Kernel` and `src/Server`.
- **Bedrock Hub**: DataStore-backed repository sharing system.
- **Internet Service**: Built-in HttpService proxy for WAN connectivity.
- **HDD Persistence**: Migrated local DataStore storage into the kernel.
- **Hub System Calls**: `HUB_PUSH` and `HUB_PULL` for sharing snapshots.
- **Portable Host**: All server-side logic now uses `RunContext.Server` for easy integration.

### Changed
- Refactored `Network` HAL to standardized naming.
- Refactored `HDD` HAL to use kernel host services.

### Performance
- Optimized VFS stubs for cloud-backed drivers.

## [1.0.0] - 2026-02-10

### Added
- Initial release of Bedrock kernel
- Virtual File System (VFS) with Unix permissions
- Process Scheduler with round-robin and signals
- Memory Management (Heap allocator)
- Hardware Abstraction Layer (GPU, HID, RAM, Network)
- 30+ System Calls
- Custom Lua VM (FiOne + Yueliang)
- Bootstrap file provisioning system
- Path caching for VFS performance
- Selective cache invalidation

### Performance
- O(1) cached VFS path lookups
- O(log n) sleep heap for process timers
- Optimized memory allocation with block coalescing

### Documentation
- Comprehensive README
- Architecture guide
- Complete API reference

## [1.3.0] - 2026-02-10

### Added
- **32-Bit True Color (RGBA)**: Kernel now supports 16.7 million colors. VRAM is now a direct 4-byte-per-pixel buffer.
- **Aspect Ratio Constraint**: GPU HAL now includes `UIAspectRatioConstraint` to ensure display proportions are maintained regardless of ScreenGui size.
- **Memory Map Expansion**: Increased VRAM allocation to support up to 800x600 in True Color (1.92 MB).

### Changed
- Refactored `GPU.Flush` and primitive functions (`FillRect`, `Scroll`, `BitBlt`) for 32-bit pixel stride.
- Relocated `PALETTE_BASE` and `HEAP_START` to accommodate larger VRAM.

## [1.2.3] - 2026-02-10

### Fixed
- **Memory Map Overlap**: Expanded internal memory map to prevent VRAM from overflowing into the palette region at higher resolutions (640x360+).
- **Infinite Service Init Hang**: Added timeouts to server-side service loading to prevent the kernel from hanging indefinitely if a file is missing or correctly mapped.
- **Kernel Debug Visibility**: Enabled kernel-to-Studio log redirection by default to aid in troubleshooting boot failures.

## [1.2.2] - 2026-02-10

### Fixed
- **BIOS POST HDD Failure**: Resolved a hardware initialization error where HALs failed to locate server-side remotes.
- **Service Discovery Yield**: Fixed an infinite yield issue in `ServerScriptService` by correcting module require paths in `init.server.luau`.
- **Host Service Bridge**: Established a unified `Bedrock_Host` folder in `ReplicatedStorage` for reliable client-server communication.

### Changed
- Standardized remote discovery across all hardware abstractions (HDD, Hub, Network).

## [Unreleased]

### Planned
- Virtual memory with paging
- Multi-core scheduler support
- Filesystem drivers (ext2-like)
- Network stack (TCP/IP)
- IPC mechanisms (shared memory, message queues)
