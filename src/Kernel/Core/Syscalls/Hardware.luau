local MemoryMap = require(script.Parent.Parent.Memory.MemoryMap)

local Hardware = {}

function Hardware.Init(System)
	local HANDLERS = {}

	HANDLERS["GPU_FLUSH"] = function()
		if System.GPU then System.GPU:Flush() end
	end

	HANDLERS["GPU_CLEAR"] = function(color: number)
		if System.GPU then System.GPU:Clear(color) end
	end

	HANDLERS["GPU_INFO"] = function()
		if System.GPU then
			return System.GPU.Width, System.GPU.Height
		end
		return 0, 0
	end

    HANDLERS["GET_VRAM_PTR"] = function()
        if System.RAM then return System.RAM:GetBuffer() end
        return nil
    end

    HANDLERS["GPU_RECT"] = function(x, y, w, h, rgba)
        local gpu = System.GPU
        local ram = System.RAM
        if not gpu or not ram then return end
        
        local vram = MemoryMap.VRAM_BASE
        local sw = gpu.Width
        
        for i = 0, h - 1 do
            local rowAddr = vram + ((y + i) * sw + x) * 4
            ram:Fill32(rowAddr, rgba, w * 4)
        end
        gpu:Flush()
    end

    HANDLERS["GPU_SCROLL"] = function(dy, rgba)
        local gpu = System.GPU
        local ram = System.RAM
        if not gpu or not ram then return end
        
        local vram = MemoryMap.VRAM_BASE
        local sw = gpu.Width
        local sh = gpu.Height
        local rowSize = sw * 4
        
        if dy > 0 then
            -- Scroll up
            ram:Copy(vram, vram + dy * rowSize, (sh - dy) * rowSize)
            -- Clear bottom
            ram:Fill32(vram + (sh - dy) * rowSize, rgba, dy * rowSize)
        elseif dy < 0 then
            -- Scroll down
            local ady = math.abs(dy)
            ram:Copy(vram + ady * rowSize, vram, (sh - ady) * rowSize)
            -- Clear top
            ram:Fill32(vram, rgba, ady * rowSize)
        end
        gpu:Flush()
    end

	HANDLERS["HID_POLL"] = function()
		if System.HID then
			return System.HID:Poll()
		end
		return {}
	end

	HANDLERS["MALLOC"] = function(size: number)
		if System.Heap then
			return System.Heap:Malloc(size)
		end
		return nil
	end

	HANDLERS["FREE"] = function(addr: number)
		if System.Heap then
			System.Heap:Free(addr)
		end
	end

	return HANDLERS
end

return Hardware
