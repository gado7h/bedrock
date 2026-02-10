-- Centralized memory address constants for the Voyager-1 architecture
-- All kernel/HAL modules reference this instead of hardcoded addresses

local MemoryMap = {}

-- Binary program load address
MemoryMap.PROGRAM_BASE = 0x020000

-- Initial stack pointer for binary processes
MemoryMap.STACK_INIT = 0x01FFFF

-- Video RAM (indexed color buffer)
MemoryMap.VRAM_BASE = 0x040000

-- Color palette (16 entries × 4 bytes RGBA)
MemoryMap.PALETTE_BASE = 0x078000

-- Kernel heap region
MemoryMap.HEAP_START = 0x080000
MemoryMap.HEAP_END = 0x100000

return MemoryMap
