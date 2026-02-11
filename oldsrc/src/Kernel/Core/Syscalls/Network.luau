local Scheduler = require(script.Parent.Parent.Process.Scheduler)
local Heap = require(script.Parent.Parent.Heap)
local RAM = require(script.Parent.Parent.Parent.HAL.RAM)

type System = {
	Scheduler: Scheduler.Scheduler,
	Heap: Heap.Heap,
	RAM: RAM.RAM,
}

local Network = {}

function Network.Init(System)
	return {
		["NET_REQ"] = function(command, ...)
			-- Security: Check if network is available
			if not System.Network then
				return false, "No Network Adapter"
			end

			local pid = System.Scheduler.CurrentPID
			if not pid then
				return false, "No Process Context"
			end

			local proc = System.Scheduler.Processes[pid]
			if not proc then
				return false, "Invalid Process"
			end

			-- If we already have a result, return it (Resumption)
			if proc.SyscallResult then
				local res = proc.SyscallResult
				proc.SyscallResult = nil
				return unpack(res)
			end

			-- ASYNC REQUEST PATTERN
			-- 1. Suspend the process
			proc.State = "WAITING"

			-- 2. Spawn detached thread to handle network
			local args = { ... }
			task.spawn(function()
				-- This runs in Roblox engine context, safely yielding
				local success, result = System.Network:Request(command, unpack(args))

				-- 3. On completion, store result and Wake Process
				proc.SyscallResult = { success, result }
				System.Scheduler:WakeUp(pid)
			end)

			-- 4. Yield the process coroutine to Scheduler
			coroutine.yield()

			-- 5. Fix spurious wakeups or return
			if proc.SyscallResult then
				local res = proc.SyscallResult
				proc.SyscallResult = nil
				return unpack(res)
			end

			return false, "Async Error"
		end,
	}
end

return Network
