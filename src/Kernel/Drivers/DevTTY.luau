-- /dev/tty driver
-- Interacts with current process stdin/stdout.

local DevTTY = {}
DevTTY.Name = "DevTTY"

local _scheduler = nil
local _pipes = nil

function DevTTY.Init(scheduler: any, pipes: any)
	_scheduler = scheduler
	_pipes = pipes
end

function DevTTY.Read(path: string, uid: number)
	local pid = _scheduler.CurrentPID
	if not pid then return nil end
	local proc = _scheduler.Processes[pid]
	if not proc then return nil end

	if proc.StdinPipe then
		local data = _pipes.Read(proc.StdinPipe)
		while data == "" do
			proc.State = "WAITING"
			coroutine.yield()
			data = _pipes.Read(proc.StdinPipe)
		end
		return data
	end

	if #proc.StdinQueue == 0 then
		proc.State = "WAITING"
		coroutine.yield()
	end
	return table.remove(proc.StdinQueue, 1)
end

function DevTTY.Write(path: string, content: string, uid: number)
	local pid = _scheduler.CurrentPID
	if not pid then return false end
	local proc = _scheduler.Processes[pid]

	if proc and proc.StdoutPipe then
		_pipes.Write(proc.StdoutPipe, content)
		for _, p in pairs(_scheduler.Processes) do
			if p.StdinPipe == proc.StdoutPipe and p.State == "WAITING" then
				p.State = "READY"
			end
		end
	else
		print("[TTY] " .. content)
	end
	return true
end

function DevTTY.List(path: string, uid: number) return {} end
function DevTTY.MkDir(path: string, uid: number) return false end

return DevTTY
