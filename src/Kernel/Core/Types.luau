--!strict
export type ProcessState = "READY" | "RUNNING" | "WAITING" | "DEAD" | "SLEEPING" | "SYSCALL"

export type CPUState = {
	Registers: { number },
	PC: number,
	SP: number,
	Flags: { ZF: boolean, CF: boolean },
	Halted: boolean,
}

export type Process = {
	PID: number,
	Name: string,
	Thread: thread?,
	CPU: CPUState?,
	State: ProcessState,
	WakeTime: number?,
	Signals: { number }, -- Pending signals
	SignalHandlers: { [number]: ((...any) -> ())? }?, -- Custom signal handlers
	Stopped: boolean?, -- True if process is stopped (SIGSTOP)
	StartTime: number, -- os.clock() at start of slice
	TotalTime: number, -- Total ms consumed
	StdinQueue: { string },
	StdoutPipe: number?,
	StdinPipe: number?,
	Env: { [string]: string },
	SyscallResult: { any }?,
	UID: number,
	GID: number,
	Waiters: { [number]: boolean }?,
	Next: number?, -- Linked List for Scheduler
	Prev: number?,
}

return {}
