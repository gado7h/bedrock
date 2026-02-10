--!strict
-- Voyager-1 Hardware RAM (1MB)
-- Unified memory for kernel, user, vram, and mmio.

local RAM = {}
RAM.__index = RAM

export type RAM = typeof(setmetatable(
	{} :: {
		_buffer: buffer,
		Size: number,
	},
	RAM
))

function RAM.new(size: number): RAM
	local self = setmetatable({
		_buffer = buffer.create(size),
		Size = size,
	}, RAM)
	return self
end

-- Memory Range Helpers
function RAM:Read8(addr: number): number
	if addr < 0 or addr >= self.Size then
		return 0
	end
	return buffer.readu8(self._buffer, addr)
end

function RAM:Write8(addr: number, val: number)
	if addr < 0 or addr >= self.Size then
		return
	end
	buffer.writeu8(self._buffer, addr, val)
end

function RAM:Read32(addr: number): number
	if addr < 0 or addr > self.Size - 4 then
		return 0
	end
	return buffer.readu32(self._buffer, addr)
end

function RAM:Write32(addr: number, val: number)
	if addr < 0 or addr > self.Size - 4 then
		return
	end
	buffer.writeu32(self._buffer, addr, val)
end

function RAM:Copy(dest: number, src: number, size: number)
	if dest < 0 or src < 0 or (dest + size) > self.Size or (src + size) > self.Size then
		return
	end
	buffer.copy(self._buffer, dest, self._buffer, src, size)
end

function RAM:Fill(addr: number, val: number, size: number)
	if addr < 0 or (addr + size) > self.Size then
		return
	end
	buffer.fill(self._buffer, addr, val, size)
end

function RAM:GetBuffer(): buffer
	return self._buffer
end

return RAM
