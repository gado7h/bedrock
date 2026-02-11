-- Kernel Heap Allocator (First-Fit)
-- Manages RAM from 0x080000 to 0x0FFFFF

local RAM = require(script.Parent.Parent.HAL.RAM)

local Heap = {}
Heap.__index = Heap

type BlockHeader = {
	addr: number,
	size: number,
	used: boolean,
}

export type Heap = typeof(setmetatable(
	{} :: {
		_ram: any,
		_start: number,
		_end: number,
		_blocks: { BlockHeader },
	},
	Heap
))

function Heap.new(ram, startAddr, endAddr)
	local self = setmetatable({
		_ram = ram,
		_start = startAddr,
		_end = endAddr,
		_blocks = {
			{ addr = startAddr, size = endAddr - startAddr, used = false },
		},
	}, Heap)
	return self
end

function Heap:Malloc(size: number): number?
	local self = self :: Heap
	-- Align to 4 bytes
	size = math.ceil(size / 4) * 4

	for i, block in ipairs(self._blocks) do
		if not block.used and block.size >= size then
			-- Found a fit!
			block.used = true

			-- Split block if there's significant remainder
			if block.size > size + 8 then
				local remainder = block.size - size
				block.size = size

				local newBlock = {
					addr = block.addr + size,
					size = remainder,
					used = false,
				}
				table.insert(self._blocks, i + 1, newBlock)
			end

			return block.addr
		end
	end

	return nil -- OOM
end

function Heap:Free(addr: number)
	local self = self :: Heap
	for i, block in ipairs(self._blocks) do
		if block.addr == addr then
			block.used = false

			-- Merge with neighbors
			local nextBlock = self._blocks[i + 1]
			if nextBlock and not nextBlock.used then
				block.size += nextBlock.size
				table.remove(self._blocks, i + 1)
			end

			local prevBlock = self._blocks[i - 1]
			if prevBlock and not prevBlock.used then
				prevBlock.size += block.size
				table.remove(self._blocks, i)
			end

			return
		end
	end
end

function Heap:Reset()
	local self = self :: Heap
	self._blocks = {
		{ addr = self._start, size = self._end - self._start, used = false },
	}
end

return Heap
