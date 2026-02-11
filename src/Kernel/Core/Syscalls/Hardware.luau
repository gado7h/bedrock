-- Hardware Syscalls
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
			return { Width = System.GPU.Width, Height = System.GPU.Height }
		end
		return nil
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
