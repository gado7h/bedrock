return [==[
-- Basic Kernel Usage Example
-- Demonstrates core syscalls and kernel features

local libc = require("libc")
local Syscall = libc.Syscalls.Call

libc.Print("=== Bedrock Kernel Demo ===\n\n")

-- 1. File System Operations
libc.Print("1. File System\n")
Syscall("FS_MKDIR", "/tmp/demo")
Syscall("FS_WRITE", "/tmp/demo/hello.txt", "Hello from Bedrock!")

local content = Syscall("FS_READ", "/tmp/demo/hello.txt")
libc.Print("  Read file: " .. content .. "\n")

local files = Syscall("FS_LIST", "/tmp/demo")
libc.Print("  Files in /tmp/demo: " .. #files .. "\n")

-- 2. Process Information
libc.Print("\n2. Process Management\n")
local processes = Syscall("PS_LIST")
libc.Print("  Running processes: " .. #processes .. "\n")

for _, proc in ipairs(processes) do
    libc.Print("    PID " .. proc.PID .. ": " .. proc.Name .. "\n")
end

-- 3. Memory Allocation
libc.Print("\n3. Memory Management\n")
local addr = Syscall("MALLOC", 1024)
if addr ~= 0 then
    libc.Print("  Allocated 1KB at address: " .. addr .. "\n")
    Syscall("FREE", addr)
    libc.Print("  Memory freed\n")
end

-- 4. Environment Variables
libc.Print("\n4. Environment\n")
Syscall("ENV_SET", "DEMO_VAR", "Hello World")
local value = Syscall("ENV_GET", "DEMO_VAR")
libc.Print("  DEMO_VAR = " .. value .. "\n")

-- 5. Cleanup
Syscall("FS_REMOVE", "/tmp/demo/hello.txt")
Syscall("FS_REMOVE", "/tmp/demo")

libc.Print("\nDemo complete!\n")
]==]
