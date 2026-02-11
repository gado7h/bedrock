local Types = require(script.Parent.Parent.Types)
local Signals = require(script.Parent.Parent.Signals)
local MemoryMap = require(script.Parent.Parent.Memory.MemoryMap)
local Log = require(script.Parent.Parent.Log)

local Scheduler = {}
Scheduler.__index = Scheduler

export type Queue = {
	Head: number?,
	Tail: number?,
}

export type Scheduler = {
	Processes: { [number]: any }, -- Types.Process circular dep, using any for now or need to require Types
	Queues: { [number]: Queue },
	CurrentPID: number?,
	_nextPid: number,
	_cpu: any,
	_sleepHeap: { number },
	_tickets: number,
	OnProcessCrash: ((number, string) -> ())?,
	Halted: boolean,
	Kill: (self: Scheduler, pid: number) -> boolean,
	Spawn: (self: Scheduler, name: string, entry: () -> (), initialEnv: { [string]: string }?) -> number,
	SpawnBinary: (self: Scheduler, name: string, pc: number) -> number,
	WakeUp: (self: Scheduler, pid: number) -> boolean,
	Schedule: (self: Scheduler, dt: number) -> (),
	_addToTail: (self: Scheduler, pid: number) -> (),
	_remove: (self: Scheduler, pid: number) -> (),
	_heapPush: (self: Scheduler, pid: number) -> (),
	_heapPop: (self: Scheduler) -> number?,
}

function Scheduler.new(ram)
	local CPU = require(script.Parent.Parent.CPU)
	local self = setmetatable({
		Processes = {},
		Queues = {
			[0] = { Head = nil, Tail = nil },
			[1] = { Head = nil, Tail = nil },
			[2] = { Head = nil, Tail = nil },
		},
		CurrentPID = nil,
		_nextPid = 1,
		_cpu = CPU.new(ram),
		_sleepHeap = {},
		_tickets = 0,
		Halted = false,
	}, Scheduler)

	return self
end

function Scheduler:_heapPush(pid: number)
	local heap = self._sleepHeap
	table.insert(heap, pid)
	local idx = #heap
	while idx > 1 do
		local parent = math.floor(idx / 2)
		local pProc = self.Processes[heap[parent]]
		local cProc = self.Processes[heap[idx]]
		-- Narrowing check
		if pProc and cProc then
			local pWake = (pProc :: Types.Process).WakeTime or 0
			local cWake = (cProc :: Types.Process).WakeTime or 0
			if cWake < pWake then
				heap[parent] = heap[idx]
				heap[idx] = heap[parent]
				idx = parent
			else
				break
			end
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
	local processes: { [number]: any } = self.Processes :: any
	local top = heap[1]
	heap[1] = heap[#heap]
	table.remove(heap)
	local idx = 1
	local size = #heap
	while true do
		local smallest = idx
		local left = idx * 2
		local right = idx * 2 + 1
		local sProc = processes[heap[smallest]]
		if not sProc then
			break
		end

		if left <= size then
			local lProc = processes[heap[left]]
			if lProc then
				local lWake = (lProc :: any).WakeTime or 0
				local sWake = (sProc :: any).WakeTime or 0
				if lWake < sWake then
					smallest = left
					sProc = lProc
				end
			end
		end
		if right <= size then
			local rProc = processes[heap[right]]
			if rProc then
				local rWake = (rProc :: any).WakeTime or 0
				local sWake = (sProc :: any).WakeTime or 0
				if rWake < sWake then
					smallest = right
				end
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

function Scheduler:_cleanupResources(pid: number)
	local processes: { [number]: any } = self.Processes :: any
	local proc = processes[pid]
	if not proc then return end

	-- Close open pipes
	if proc.OpenHandles then
		local Pipes = require(script.Parent.Parent.Pipes)
		for handle, _ in pairs(proc.OpenHandles) do
			Pipes.Close(handle)
			Pipes.Cleanup(handle)
		end
	end

	-- Wake up waiters
	if proc.Waiters then
		for waiterPid, _ in pairs(proc.Waiters) do
			self:WakeUp(waiterPid)
		end
	end
end

function Scheduler:_addToTail(pid: number)
	local processes: { [number]: any } = self.Processes :: any
	local proc = processes[pid]
	if not proc then
		return
	end

	self:_remove(pid)

	local q = (self.Queues :: any)[proc.Priority]
	if not q then
		return
	end

	if not q.Head then
		q.Head = pid
		q.Tail = pid
		proc.Next = nil
		proc.Prev = nil
	else
		local tailPid = q.Tail :: number
		local tailProc = processes[tailPid]
		if tailProc then
			tailProc.Next = pid
			proc.Prev = tailPid
			proc.Next = nil
			q.Tail = pid
		end
	end
end

function Scheduler:_remove(pid: number)
	local processes: { [number]: any } = self.Processes :: any
	local proc = processes[pid]
	if not proc then
		return
	end

	local q = (self.Queues :: any)[proc.Priority]
	if not q then
		return
	end

	local nextPid = proc.Next
	local prevPid = proc.Prev

	if prevPid then
		local prevProc = processes[prevPid]
		if prevProc then
			prevProc.Next = nextPid
		end
	elseif q.Head == pid then
		q.Head = nextPid
	end

	if nextPid then
		local nextProc = processes[nextPid]
		if nextProc then
			nextProc.Prev = prevPid
		end
	elseif q.Tail == pid then
		q.Tail = prevPid
	end

	proc.Next = nil
	proc.Prev = nil
end

function Scheduler:Spawn(name: string, entry: () -> (), initialEnv: { [string]: string }?)
	local processes: { [number]: any } = self.Processes :: any
	local pid = self._nextPid;
	(self :: Scheduler)._nextPid += 1

	local thread = coroutine.create(entry)
	local env = {}
	local uid, gid, priority = 0, 0, 1

	if self.CurrentPID then
		local parent = processes[self.CurrentPID]
		if parent then
			uid = parent.UID
			gid = parent.GID
			priority = parent.Priority
			for k, v in pairs(parent.Env) do
				env[k] = v
			end
		end
	end

	if initialEnv then
		for k, v in pairs(initialEnv) do
			env[k] = v
		end
		if initialEnv["_PRIORITY"] then
			priority = math.clamp(tonumber(initialEnv["_PRIORITY"]) or 1, 0, 2)
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
		Priority = priority,
	}

	processes[pid] = process
	self:_addToTail(pid)
	Log.info("SCHEDULER", "Spawned Process %d: %s (Priority: %d)", pid, name, priority)
	return pid
end

function Scheduler:SpawnBinary(name: string, pc: number)
	local processes: { [number]: any } = self.Processes :: any
	local pid = self._nextPid;
	(self :: Scheduler)._nextPid += 1

	local uid, gid, priority = 0, 0, 1
	if self.CurrentPID then
		local parent = processes[self.CurrentPID]
		if parent then
			uid = parent.UID
			gid = parent.GID
			priority = parent.Priority
		end
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
		Priority = priority,
	}

	processes[pid] = process
	self:_addToTail(pid)
	return pid
end

function Scheduler:Kill(pid: number)
	local processes: { [number]: any } = self.Processes :: any
	local proc = processes[pid]
	if proc then
		proc.State = "DEAD"
		Log.info("KERNEL", "Killed Process %d: %s", pid, (proc :: any).Name)
		return true
	end
	return false
end

function Scheduler:WakeUp(pid: number)
	local processes: { [number]: any } = self.Processes :: any
	local proc = processes[pid]
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
	local processes: { [number]: any } = self.Processes :: any

	local now = os.clock()
	while #self._sleepHeap > 0 do
		local topPid = self._sleepHeap[1]
		local proc = processes[topPid]
		if not proc or (proc.State ~= "WAITING" and proc.State ~= "SLEEPING") or not proc.WakeTime then
			self:_heapPop()
		elseif (proc.WakeTime :: any) <= now then
			self:_heapPop()
			proc.State = "READY"
			proc.WakeTime = nil
			self:_addToTail(proc.PID)
		else
			break
		end
	end

	(self :: Scheduler)._tickets = ((self :: Scheduler)._tickets + 1) % 7
	local priorityOrder = { 2, 1, 0 }
	if self._tickets >= 4 and self._tickets < 6 then
		priorityOrder = { 1, 2, 0 }
	elseif self._tickets == 6 then
		priorityOrder = { 0, 2, 1 }
	end

	local targetPid = nil
	for _, p in ipairs(priorityOrder) do
		local q = (self.Queues :: any)[p]
		if q and q.Head then
			targetPid = q.Head
			break
		end
	end

	if not targetPid then
		return
	end

	local pid = targetPid :: number
	self:_remove(pid)

	local proc = processes[pid]
	if not proc then
		return
	end

	if proc.State == "READY" then
		if proc.Stopped then
			self:_addToTail(pid)
			return
		end

		-- Signal Handling
		local sigs = proc.Signals
		if sigs then
			while #sigs > 0 do
				local sig = table.remove(sigs, 1) :: number
				local handled = false
				local dead = false

				if sig == Signals.SIGSTOP then
					proc.Stopped = true
					self:_addToTail(pid)
					return
				end
				if sig == Signals.SIGCONT then
					proc.Stopped = false
					handled = true
				end
				if sig == Signals.SIGKILL then
					proc.State = "DEAD"
					dead = true
				end
				if not handled and not dead and not Signals.Uncatchable[sig] then
					local handlers = proc.SignalHandlers
					if handlers and handlers[sig] then
						pcall(handlers[sig], sig)
						handled = true
					end
				end
				if not handled and not dead then
					if Signals.DefaultAction[sig] == "terminate" then
						proc.State = "DEAD"
						dead = true
					end
				end
				if dead then
					self:_cleanupResources(pid)
					processes[pid] = nil
					return
				end
			end
		end

		self.CurrentPID = pid
		proc.State = "RUNNING"
		proc.StartTime = os.clock()

		if proc.Thread then
			local success, result = coroutine.resume(proc.Thread, dt)
			local elapsed = (os.clock() - proc.StartTime) * 1000
			(proc :: any).TotalTime += elapsed

			if not success then
				Log.warn("KERNEL", "Process %d crashed: %s", pid, tostring(result))
				if self.OnProcessCrash then
					self.OnProcessCrash(pid, tostring(result))
				end
				(proc :: any).State = "DEAD"
			elseif coroutine.status(proc.Thread) == "dead" then
				(proc :: any).State = "DEAD"
			end
		elseif proc.CPU then
			local cpu = proc.CPU
			self._cpu._state = cpu
			for _ = 1, 1000 do
				self._cpu:Step()
				if cpu.Halted then
					break
				end
			end
			local elapsed = (os.clock() - proc.StartTime) * 1000
			(proc :: any).TotalTime += elapsed
			if cpu.Halted then
				(proc :: any).State = "DEAD"
			end
		end

		(self :: any).CurrentPID = nil
		-- CAST proc.State to any to avoid comparison errors with union types
		if (proc.State :: any) == "RUNNING" or (proc.State :: any) == "READY" then
			(proc :: any).State = "READY"
			self:_addToTail(pid)
		elseif (proc.State :: any) == "DEAD" then
			self:_cleanupResources(pid)
			processes[pid] = nil
		end
	end
end

return Scheduler
