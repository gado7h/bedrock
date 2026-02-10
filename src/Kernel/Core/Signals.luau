--!strict
-- Signal Constants (Unix-compatible numbers)

local Signals = {}

-- Termination signals
Signals.SIGHUP = 1 -- Hangup
Signals.SIGINT = 2 -- Interrupt (Ctrl+C)
Signals.SIGQUIT = 3 -- Quit
Signals.SIGKILL = 9 -- Force kill (cannot be caught)
Signals.SIGTERM = 15 -- Termination request

-- User-defined signals
Signals.SIGUSR1 = 10
Signals.SIGUSR2 = 12

-- Job control signals
Signals.SIGCONT = 18 -- Continue (resume stopped process)
Signals.SIGSTOP = 19 -- Stop (cannot be caught)

-- Default actions for each signal
Signals.DefaultAction = {
	[Signals.SIGHUP] = "terminate",
	[Signals.SIGINT] = "terminate",
	[Signals.SIGQUIT] = "terminate",
	[Signals.SIGKILL] = "terminate", -- Always terminates, uncatchable
	[Signals.SIGTERM] = "terminate",
	[Signals.SIGUSR1] = "terminate",
	[Signals.SIGUSR2] = "terminate",
	[Signals.SIGCONT] = "continue",
	[Signals.SIGSTOP] = "stop", -- Always stops, uncatchable
}

-- Signals that cannot be caught or ignored
Signals.Uncatchable = {
	[Signals.SIGKILL] = true,
	[Signals.SIGSTOP] = true,
}

return Signals
