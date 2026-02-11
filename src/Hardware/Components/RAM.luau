-- Voyager-1 Hardware RAM
-- Raw buffer manipulation.

local RAM = {}
RAM.__index = RAM

export type RAM = typeof(setmetatable(
	{} :: {
		_buffer: buffer,
		Size: number,
	},
	RAM
))

function RAM.new(size)
	local self = setmetatable({
		_buffer = buffer.create(size),
		Size = size,
	}, RAM)
	return self
end

function RAM:Read8(addr)
	if addr < 0 or addr >= self.Size then return 0 end
	return buffer.readu8(self._buffer, addr)
end

function RAM:Write8(addr, val)
	if addr < 0 or addr >= self.Size then return end
	buffer.writeu8(self._buffer, addr, val)
end

function RAM:Read32(addr)
	if addr < 0 or addr > self.Size - 4 then return 0 end
	return buffer.readu32(self._buffer, addr)
end

function RAM:Write32(addr, val)
	if addr < 0 or addr > self.Size - 4 then return end
	buffer.writeu32(self._buffer, addr, val)
end

function RAM:Copy(dest, src, size)
	if dest < 0 or src < 0 or (dest + size) > self.Size or (src + size) > self.Size then return end
	buffer.copy(self._buffer, dest, self._buffer, src, size)
end

function RAM:Fill(addr, val, size)
	if addr < 0 or (addr + size) > self.Size then return end
	buffer.fill(self._buffer, addr, val, size)
end

function RAM:Fill32(addr, val, size)
	if addr < 0 or (addr + size) > self.Size then return end
	for i = 0, size - 4, 4 do
		buffer.writeu32(self._buffer, addr + i, val)
	end
end

function RAM:GetBuffer()
	return self._buffer
end

return RAM
