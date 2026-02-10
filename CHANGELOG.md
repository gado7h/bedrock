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
