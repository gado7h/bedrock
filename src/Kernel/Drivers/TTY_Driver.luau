-- /dev/tty driver
-- Reads from current process stdin
-- Writes to current process stdout (pipes)

local DevTTY = {}
DevTTY.Name = "DevTTY"

-- We need access to Scheduler to find Current Process
local _scheduler: any = nil
local _pipes: any = nil

function DevTTY.Init(scheduler: any, pipes: any)
	_scheduler = scheduler
	_pipes = pipes
end

function DevTTY.Read(path: string, uid: number)
	-- Blocking Read from Stdin
	-- This mimics TTY_READ syscall but via file interface

	local pid = _scheduler.CurrentPID
	if not pid then
		return nil
	end
	local proc = _scheduler.Processes[pid]
	if not proc then
		return nil
	end

	-- Check Pipe
	if proc.StdinPipe then
		local data = _pipes.Read(proc.StdinPipe)
		while data == "" do
			proc.State = "WAITING"
			coroutine.yield()
			data = _pipes.Read(proc.StdinPipe)
		end
		return data
	end

	-- Check Queue (Keyboard)
	if #proc.StdinQueue == 0 then
		proc.State = "WAITING"
		coroutine.yield()
	end
	return table.remove(proc.StdinQueue, 1)
end

function DevTTY.Write(path: string, content: string, uid: number)
	local pid = _scheduler.CurrentPID
	if not pid then
		return false
	end
	local proc = _scheduler.Processes[pid]

	if proc and proc.StdoutPipe then
		_pipes.Write(proc.StdoutPipe, content)
		-- Wake listeners
		for _, p in pairs(_scheduler.Processes) do
			if p.StdinPipe == proc.StdoutPipe and p.State == "WAITING" then
				p.State = "READY"
			end
		end
	else
		-- Standard Console Output
		print("[TTY] " .. content) -- Or use Console API if available?
		-- But Kernel/init doesn't expose Console globally easily without Loop.
		-- For now, print to Roblox Output is Userland "Console" logic.
	end
	return true
end

function DevTTY.List(path: string, uid: number)
	return {}
end

function DevTTY.MkDir(path: string, uid: number)
	return false
end

return DevTTY
