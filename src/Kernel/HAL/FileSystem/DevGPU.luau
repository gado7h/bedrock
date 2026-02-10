-- /dev/gpu driver
-- Allows writing to VRAM via FS_WRITE
-- Allows reading screen info via FS_READ

local DevGPU = {}
DevGPU.Name = "DevGPU"

local GPU = require(script.Parent.Parent.GPU)
local _gpu: GPU.GPU? = nil -- Injected in Init

function DevGPU.Init(gpu: GPU.GPU)
	_gpu = gpu
end

function DevGPU.Read(path: string, uid: number): string?
	if not _gpu then
		return nil
	end

	-- /dev/gpu just returns W,H for now if read directly
	-- Or maybe dump VRAM?
	-- Let's return W,H as a string "320,180"
	return _gpu.Width .. "," .. _gpu.Height
end

function DevGPU.Write(path: string, content: string, uid: number)
	if not _gpu then
		return false
	end

	-- Protocol:
	-- "CLEAR:color"
	-- "PIXEL:x,y,color"
	-- "FILL:x,y,w,h,color"

	-- This assumes content is a command string
	-- For binary VRAM access, we'd need a different approach or buffer

	local parts = string.split(content, ":")
	local cmd = parts[1]

	print("[DevGPU] Write: " .. content)

	if cmd == "CLEAR" then
		local col = tonumber(parts[2]) or 0
		print("[DevGPU] Clearing to " .. col)
		_gpu:Clear(col)
		print("[DevGPU] Cleared.")
	elseif cmd == "PIXEL" then
		-- PIXEL:x,y,col
		if parts[2] then
			local args = string.split(parts[2], ",")
			local x = tonumber(args[1])
			local y = tonumber(args[2])
			local c = tonumber(args[3])
			if x and y and c then
				local _ = (y * _gpu.Width + x) * 4 -- Simple approx for VRAM addr?
				-- Wait, GPU.luau doesn't expose SetPixel directly, it uses VRAM
				-- But we have _gpu instance.
				-- Let's use direct VRAM access if we can, or add SetPixel to GPU
				-- GPU.luau uses RAM.

				-- Recalculate address based on GPU logic
				-- (y * width + x) + VRAM_START
				local vramStart = 0x040000
				local addr = vramStart + (y * _gpu.Width + x)
				_gpu._ram:Write8(addr, c)
			end
		end
	end

	return true
end

function DevGPU.List(path: string, uid: number)
	return {}
end

function DevGPU.MkDir(path: string, uid: number)
	return false -- Cannot create dirs in a device
end

return DevGPU
