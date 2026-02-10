--!strict
local Types = require(script.Parent.Parent.Types)
local Signals = require(script.Parent.Parent.Signals)
local MemoryMap = require(script.Parent.Parent.Memory.MemoryMap)
local Log = require(script.Parent.Parent.Log)

local Scheduler = {}
Scheduler.__index = Scheduler

export type Scheduler = typeof(setmetatable(
	{} :: {
		Processes: { [number]: Types.Process },
		Head: number?, -- Start of Run Queue
		Tail: number?, -- End of Run Queue
		CurrentPID: number?,
		_nextPid: number,
		_cpu: any,
		_sleepHeap: { number }, -- Min-heap of PIDs ordered by WakeTime
		OnProcessCrash: ((number, string) -> ())?,
	},
	Scheduler
))

function Scheduler.new(ram: any): Scheduler
	local CPU = require(script.Parent.Parent.CPU)
	return setmetatable({
		Processes = {},
		Head = nil,
		Tail = nil,
		CurrentPID = nil,
		_nextPid = 1,
		_cpu = CPU.new(ram),
		_sleepHeap = {}, -- Min-heap for sleeping processes
		Halted = false,
	}, Scheduler)
end

-- Min-Heap helpers for sleep queue (ordered by WakeTime)
function Scheduler:_heapPush(pid: number)
	local heap = self._sleepHeap
	table.insert(heap, pid)
	-- Bubble up
	local idx = #heap
	while idx > 1 do
		local parent = math.floor(idx / 2)
		local pProc = self.Processes[heap[parent]]
		local cProc = self.Processes[heap[idx]]
		if pProc and cProc and (cProc.WakeTime or 0) < (pProc.WakeTime or 0) then
			heap[parent], heap[idx] = heap[idx], heap[parent]
			idx = parent
		else
			break
		end
	end
end

function Scheduler:_heapPop(): number?
	local heap = self._sleepHeap
	if #heap == 0 then
		return nil
	end
	local top = heap[1]
	heap[1] = heap[#heap]
	table.remove(heap)
	-- Bubble down
	local idx = 1
	local size = #heap
	while true do
		local smallest = idx
		local left = idx * 2
		local right = idx * 2 + 1

		local sProc = self.Processes[heap[smallest]]
		if left <= size then
			local lProc = self.Processes[heap[left]]
			if lProc and sProc and (lProc.WakeTime or 0) < (sProc.WakeTime or 0) then
				smallest = left
				sProc = lProc
			end
		end
		if right <= size then
			local rProc = self.Processes[heap[right]]
			if rProc and sProc and (rProc.WakeTime or 0) < (sProc.WakeTime or 0) then
				smallest = right
			end
		end

		if smallest ~= idx then
			heap[idx], heap[smallest] = heap[smallest], heap[idx]
			idx = smallest
		else
			break
		end
	end
	return top
end

function Scheduler:_heapPeek(): number?
	return self._sleepHeap[1]
end

-- Linked List Helpers
function Scheduler:_addToTail(pid: number)
	local proc = self.Processes[pid]
	if not proc then
		return
	end

	-- If already in list, remove first to avoid cycles/dupes
	if proc.Next or proc.Prev or self.Head == pid then
		self:_remove(pid)
	end

	if not self.Head then
		self.Head = pid
		self.Tail = pid
		proc.Next = nil
		proc.Prev = nil
	else
		local tailProc = self.Processes[self.Tail :: number]
		tailProc.Next = pid
		proc.Prev = self.Tail
		proc.Next = nil
		self.Tail = pid
	end
end

function Scheduler:_remove(pid: number)
	local proc = self.Processes[pid]
	if not proc then
		return
	end

	local nextPid = proc.Next
	local prevPid = proc.Prev

	if prevPid then
		local prevProc = self.Processes[prevPid]
		prevProc.Next = nextPid
	else
		self.Head = nextPid
	end

	if nextPid then
		local nextProc = self.Processes[nextPid]
		nextProc.Prev = prevPid
	else
		self.Tail = prevPid
	end

	proc.Next = nil
	proc.Prev = nil
end

function Scheduler:Spawn(name: string, entry: () -> (), initialEnv: { [string]: string }?)
	local pid = self._nextPid
	self._nextPid += 1

	local thread = coroutine.create(entry)

	local env = {}
	local uid, gid = 0, 0

	if self.CurrentPID and self.Processes[self.CurrentPID] then
		local parent = self.Processes[self.CurrentPID]
		uid = parent.UID
		gid = parent.GID
		for k, v in pairs(parent.Env) do
			env[k] = v
		end
	end

	if initialEnv then
		for k, v in pairs(initialEnv) do
			env[k] = v
		end
	end

	local process: Types.Process = {
		PID = pid,
		Name = name,
		Thread = thread,
		State = "READY",
		StdinQueue = {},
		Env = env,
		Signals = {},
		StartTime = 0,
		TotalTime = 0,
		UID = uid,
		GID = gid,
	}

	self.Processes[pid] = process
	self:_addToTail(pid)

	Log.info("SCHEDULER", "Spawned Process %d: %s", pid, name)
	return pid
end

function Scheduler:SpawnBinary(name: string, pc: number)
	local pid = self._nextPid
	self._nextPid += 1

	local uid, gid = 0, 0
	if self.CurrentPID and self.Processes[self.CurrentPID] then
		local parent = self.Processes[self.CurrentPID]
		uid = parent.UID
		gid = parent.GID
	end

	local process: Types.Process = {
		PID = pid,
		Name = name,
		Thread = nil,
		CPU = {
			Registers = { 0, 0, 0, 0, 0, 0, 0, 0 },
			PC = pc,
			SP = MemoryMap.STACK_INIT,
			Flags = { ZF = false, CF = false },
			Halted = false,
		},
		State = "READY",
		StdinQueue = {},
		Signals = {},
		StartTime = 0,
		TotalTime = 0,
		Env = {},
		UID = uid,
		GID = gid,
	}

	self.Processes[pid] = process
	self:_addToTail(pid)
	return pid
end

function Scheduler:WakeUp(pid: number)
	local proc = self.Processes[pid]
	if proc and (proc.State == "WAITING" or proc.State == "SYSCALL" or proc.State == "SLEEPING") then
		proc.State = "READY"
		self:_addToTail(pid)
		return true
	end
	return false
end

function Scheduler:Schedule(dt: number)
	if self.Halted then
		return
	end
	-- Wake up sleeping processes using min-heap (O(log n) per wake instead of O(n))
	local now = os.clock()
	while #self._sleepHeap > 0 do
		local topPid = self._sleepHeap[1]
		local proc = self.Processes[topPid]

		-- Remove stale entries (dead or no longer waiting with WakeTime)
		if not proc or (proc.State ~= "WAITING" and proc.State ~= "SLEEPING") or not proc.WakeTime then
			self:_heapPop()
		elseif proc.WakeTime <= now then
			-- Time to wake up
			self:_heapPop()
			proc.State = "READY"
			proc.WakeTime = nil
			self:_addToTail(proc.PID)
		else
			-- Top of heap not ready yet, stop checking
			break
		end
	end

	-- Round Robin (O(1))
	if not self.Head then
		return
	end

	local pid = self.Head
	-- Rotate: Remove head, later add to tail if still runnable
	self:_remove(pid)

	local proc = self.Processes[pid]
	if not proc then
		return
	end -- Should not happen

	if proc.State == "READY" then
		-- Check if process is stopped (SIGSTOP)
		if proc.Stopped then
			self:_addToTail(pid)
			return -- Skip this process, it's suspended
		end

		-- Signal Handling
		proc.Signals = proc.Signals or {}
		while #proc.Signals > 0 do
			local sig = table.remove(proc.Signals, 1)
			local handled = false
			local dead = false

			-- SIGSTOP: Always stops, uncatchable
			if sig == Signals.SIGSTOP then
				Log.info("KERNEL", "Process %d stopped (SIGSTOP)", pid)
				proc.Stopped = true
				self:_addToTail(pid)
				return
			end

			-- SIGCONT: Resume stopped process
			if sig == Signals.SIGCONT then
				if proc.Stopped then
					Log.info("KERNEL", "Process %d continued (SIGCONT)", pid)
					proc.Stopped = false
				end
				handled = true
			end

			-- SIGKILL: Always terminates, uncatchable
			if sig == Signals.SIGKILL then
				Log.info("KERNEL", "Process %d force-terminated (SIGKILL)", pid)
				proc.State = "DEAD"
				dead = true
			end

			-- Check for custom handler (unless uncatchable)
			if not handled and not dead and not Signals.Uncatchable[sig] then
				local handlers = proc.SignalHandlers
				if handlers and handlers[sig] then
					-- Custom handler registered - call it
					local ok, err = pcall(handlers[sig], sig)
					if not ok then
						Log.warn("KERNEL", "Signal handler error in PID %d: %s", pid, tostring(err))
					end
					handled = true
				end
			end

			-- Default action if not handled
			if not handled and not dead then
				local action = Signals.DefaultAction[sig]
				if action == "terminate" then
					Log.info("KERNEL", "Process %d terminated by signal %d", pid, sig)
					proc.State = "DEAD"
					dead = true
				end
			end

			if dead then
				self.Processes[pid] = nil
				if proc.Waiters then
					for waiterPid, _ in pairs(proc.Waiters) do
						local waiter = self.Processes[waiterPid]
						if waiter and waiter.State == "WAITING" then
							waiter.State = "READY"
							self:_addToTail(waiterPid)
						end
					end
				end
				return
			end
		end

		self.CurrentPID = pid
		proc.State = "RUNNING"
		proc.StartTime = os.clock()

		if proc.Thread then
			-- Lua Process
			local success, result = coroutine.resume(proc.Thread, dt)
			local elapsed = (os.clock() - proc.StartTime) * 1000
			proc.TotalTime += elapsed

			if not success then
				Log.warn("KERNEL", "Process %d crashed: %s", pid, tostring(result))
				if self.OnProcessCrash then
					self.OnProcessCrash(pid, tostring(result))
				end
				proc.State = "DEAD"
			elseif coroutine.status(proc.Thread) == "dead" then
				Log.info("SCHEDULER", "Process %d (%s) exited.", pid, proc.Name)
				proc.State = "DEAD"
			end

			-- Wake up Listeners/Waiters if Dead
			if proc.State == "DEAD" and proc.Waiters then
				for waiterPid, _ in pairs(proc.Waiters) do
					local waiter = self.Processes[waiterPid]
					if waiter and waiter.State == "WAITING" then
						waiter.State = "READY"
						self:_addToTail(waiterPid)
					end
				end
			end
		elseif proc.CPU then
			-- Binary Process
			self._cpu._state = proc.CPU
			for i = 1, 1000 do
				self._cpu:Step()
				if proc.CPU.Halted then
					break
				end
			end
			local elapsed = (os.clock() - proc.StartTime) * 1000
			proc.TotalTime += elapsed
			if proc.CPU.Halted then
				Log.info("KERNEL", "Binary process %d (%s) halted.", pid, proc.Name)
				proc.State = "DEAD"
			end
		end

		self.CurrentPID = nil

		if proc.State == "RUNNING" then
			proc.State = "READY"
			self:_addToTail(pid)
		elseif proc.State == "READY" then
			-- Preempted or yielded with READY state
			self:_addToTail(pid)
		elseif proc.State == "DEAD" then
			self.Processes[pid] = nil
		else
			-- WAITING, SLEEPING, SYSCALL etc. Don't add to queue.
		end
	else
		-- If not READY (e.g. WAITING but in queue? Should not happen if logic is correct),
		-- skip or requeue if it just became ready?
		-- If State is DEAD, cleanup.
		if proc.State == "DEAD" then
			self.Processes[pid] = nil
		elseif proc.State == "READY" then
			self:_addToTail(pid)
		end
	end
end

function Scheduler:Kill(pid: number)
	local proc = self.Processes[pid]
	if proc then
		proc.State = "DEAD"
		Log.info("KERNEL", "Killed Process %d: %s", pid, proc.Name)
		return true
	end
	return false
end

return Scheduler
