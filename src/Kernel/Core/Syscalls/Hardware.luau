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
        if System.GPU then
            System.GPU:Rect(x, y, w, h, rgba)
        end
    end

    HANDLERS["GPU_SCROLL"] = function(dy, rgba)
        if System.GPU then
            System.GPU:Scroll(dy, rgba)
        end
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
