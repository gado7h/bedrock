-- Centralized memory address constants for the Voyager-1 architecture
-- All kernel/HAL modules reference this instead of hardcoded addresses

local MemoryMap = {}

-- Binary program load address
MemoryMap.PROGRAM_BASE = 0x020000

-- Initial stack pointer for binary processes
MemoryMap.STACK_INIT = 0x01FFFF

-- Video RAM (32-bit RGBA buffer)
-- Supports up to 800x600 (1,920,000 bytes)
MemoryMap.VRAM_BASE = 0x040000

-- Palette is no longer needed for True Color, but we keep the address for backward compatibility
-- or for system-wide UI theme storage.
MemoryMap.PALETTE_BASE = 0x300000

-- Kernel heap region
MemoryMap.HEAP_START = 0x400000
MemoryMap.HEAP_END = 0x800000

return MemoryMap
