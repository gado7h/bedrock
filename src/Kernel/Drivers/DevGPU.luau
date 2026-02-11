-- /dev/gpu driver
-- Allows writing to VRAM via internal hardware access
-- Maps kernel-level calls to Physical GPU component.

local DevGPU = {}
DevGPU.Name = "DevGPU"

local _gpu = nil -- Injected in Init

function DevGPU.Init(gpu: any)
	_gpu = gpu
end

function DevGPU.Read(path: string, uid: number): string?
	if not _gpu then return nil end
	return _gpu.Width .. "," .. _gpu.Height
end

function DevGPU.Write(path: string, content: string, uid: number)
	if not _gpu then return false end

	local parts = string.split(content, ":")
	local cmd = parts[1]

	if cmd == "CLEAR" then
		local col = tonumber(parts[2]) or 0
		_gpu:Clear(col)
	elseif cmd == "PIXEL" then
		if parts[2] then
			local args = string.split(parts[2], ",")
			local x = tonumber(args[1])
			local y = tonumber(args[2])
			local c = tonumber(args[3])
			if x and y and c then
                -- Direct VRAM write via physical RAM component
				local vramStart = 0x040000
				local addr = vramStart + ((y * _gpu.Width + x) * 4) 
				_gpu._ram:Write32(addr, c)
			end
		end
	end

	return true
end

function DevGPU.List(path: string, uid: number) return {} end
function DevGPU.MkDir(path: string, uid: number) return false end

return DevGPU
