local Hardware = {}

function Hardware.Init(System: any)
	-- Internal buffers/queues could go here if needed,
	-- but Syscalls.luau used file-locals. We can use closure upvalues from Init.

	local _stdoutQueue: { string } = {}

	return {
		-- Raw Video Memory Access
		["MEM_WRITE"] = function(addr: number, val: number)
			System.RAM:Write8(addr, val)
		end,

		["MEM_READ"] = function(addr: number)
			return System.RAM:Read8(addr)
		end,

		["MEM_FILL"] = function(addr: number, val: number, len: number)
			System.RAM:Fill(addr, val, len)
		end,

		["GET_VRAM_PTR"] = function()
			return System.RAM:GetBuffer()
		end,

		["GPU_FLUSH"] = function(x: number?, y: number?, w: number?, h: number?)
			System.GPU:Flush(x, y, w, h)
		end,

		["GPU_INFO"] = function()
			return System.GPU.Width, System.GPU.Height
		end,

		["GPU_SCROLL"] = function(dy: number, colorRGBA: number)
			System.GPU:Scroll(dy, colorRGBA)
		end,
		
		["GPU_RECT"] = function(x: number, y: number, w: number, h: number, colorRGBA: number)
			System.GPU:FillRect(x, y, w, h, colorRGBA)
		end,
		
		["GPU_BLIT"] = function(dx: number, dy: number, sx: number, sy: number, w: number, h: number)
			System.GPU:BitBlt(dx, dy, sx, sy, w, h)
		end,

		["PRINT"] = function(msg: string)
			local pid = System.Scheduler.CurrentPID
			local proc = pid and System.Scheduler.Processes[pid]
			if proc and proc.StdoutPipe then
				local handle = proc.StdoutPipe
				System.Pipes.Write(handle, msg .. "\n")
				-- Wake up listeners
				for _, p in pairs(System.Scheduler.Processes) do
					if p.StdinPipe == handle then
						System.Scheduler:WakeUp(p.PID)
					end
				end
			else
				table.insert(_stdoutQueue, msg)
				local Log = require(script.Parent.Parent.Log)
				Log.info("USERLAND", msg)
			end
		end,

		["POLL_STDOUT"] = function()
			local batch = _stdoutQueue
			_stdoutQueue = {}
			return batch
		end,

		["PIPE_OPEN"] = function()
			local handle = System.Pipes.Open()
			local pid = System.Scheduler.CurrentPID
			if pid then
				local proc = System.Scheduler.Processes[pid]
				if proc then
					if not proc.OpenHandles then
						proc.OpenHandles = {}
					end
					proc.OpenHandles[handle] = true
				end
			end
			return handle
		end,

		["PIPE_WRITE"] = function(handle: number, data: string)
			local success = System.Pipes.Write(handle, data)
			if success then
				for _, p in pairs(System.Scheduler.Processes) do
					if p.StdinPipe == handle then
						System.Scheduler:WakeUp(p.PID)
					end
				end
			end
			return success
		end,

		["PIPE_CLOSE"] = function(handle: number)
			System.Pipes.Close(handle)
			local pid = System.Scheduler.CurrentPID
			if pid then
				local proc = System.Scheduler.Processes[pid]
				if proc and proc.OpenHandles then
					proc.OpenHandles[handle] = nil
				end
			end
		end,

		["POLL_EVENTS"] = function()
			return System.HID:PollInterrupts()
		end,

		["DMESG"] = function()
			local Log = require(script.Parent.Parent.Log)
			return Log.dmesg()
		end,

		["TTY_READ"] = function()
			-- Reads from current process's StdinQueue OR StdinPipe
			local pid = System.Scheduler.CurrentPID
			if not pid then
				return nil
			end

			local proc = System.Scheduler.Processes[pid]
			if not proc then
				return nil
			end

			if proc.StdinPipe then
				local data = System.Pipes.Read(proc.StdinPipe)
				while data == "" do
					proc.State = "WAITING"
					coroutine.yield()
					data = System.Pipes.Read(proc.StdinPipe)
				end
				return data
			end

			if #proc.StdinQueue == 0 then
				-- Block process until input arrives
				-- Log.debug("TTY", "PID %d blocked on TTY_READ", pid)
				proc.State = "WAITING"
				coroutine.yield()
				-- Re-entrant: once woken, stdin should have content
				-- Log.debug("TTY", "PID %d resumed. Queue: %d", pid, #proc.StdinQueue)
			end

			local val = table.remove(proc.StdinQueue, 1)
			return val
		end,

		["TTY_WRITE"] = function(pid: number, char: string)
			-- Shell calls this to send input to a process
			local proc = System.Scheduler.Processes[pid]
			if proc then
				table.insert(proc.StdinQueue, char)
				-- Log.debug("TTY", "TTY_WRITE to %d: %s", pid, char)
				System.Scheduler:WakeUp(pid)
				return true
			end
			return false
		end,
	}
end

return Hardware
