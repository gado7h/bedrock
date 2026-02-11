return [==[
-- Process Management Example
-- Demonstrates process spawning, signals, and IPC

local libc = require("libc")
local Syscall = libc.Syscalls.Call

libc.Print("=== Process Management Demo ===\n\n")

-- 1. List current processes
libc.Print("Current processes:\n")
local processes = Syscall("PS_LIST")
for _, proc in ipairs(processes) do
    libc.Print(string.format("  [%d] %s (%s)\n", proc.PID, proc.Name, proc.State))
end

-- 2. Create a simple worker program
libc.Print("\nCreating worker program...\n")
local workerCode = [[
local libc = require("libc")
local Syscall = libc.Syscalls.Call

-- Worker does some work
for i = 1, 3 do
    libc.Print("Worker: Task " .. i .. "/3\n")
    Syscall("SLEEP", 0.5)
end

libc.Print("Worker: Complete!\n")
]]

Syscall("FS_WRITE", "/tmp/worker.lua", workerCode)

-- 3. Spawn worker process
libc.Print("Spawning worker...\n")
local ok, err, workerPid = Syscall("EXEC", "/tmp/worker.lua")

if ok and workerPid then
    libc.Print("Worker spawned with PID: " .. workerPid .. "\n")
    
    -- Wait for worker to complete
    libc.Print("Waiting for worker...\n")
    Syscall("WAIT_PID", workerPid)
    libc.Print("Worker finished!\n")
end

-- 4. Signal handling
libc.Print("\nSetting up signal handler...\n")
local signalReceived = false

Syscall("SIGNAL_HANDLER", 2, function()  -- SIGINT
    libc.Print("Caught SIGINT!\n")
    signalReceived = true
end)

-- 5. Sleep demonstration
libc.Print("Sleeping for 1 second...\n")
Syscall("SLEEP", 1)
libc.Print("Awake!\n")

-- Cleanup
Syscall("FS_REMOVE", "/tmp/worker.lua")

libc.Print("\nDemo complete!\n")
]==]
