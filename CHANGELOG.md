# Changelog

All notable changes to Bedrock will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [Unreleased]

### Planned
- Virtual memory with paging
- Multi-core scheduler support
- Filesystem drivers (ext2-like)
- Network stack (TCP/IP)
- IPC mechanisms (shared memory, message queues)
