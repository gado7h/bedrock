return [==[
-- Network Example
-- Demonstrates HTTP requests (requires server implementation)

local libc = require("libc")
local Syscall = libc.Syscalls.Call

libc.Print("=== Network Demo ===\n\n")

-- Check if network is available
libc.Print("Testing network availability...\n")
local response, err = Syscall("NET_REQ", "GET", "https://httpbin.org/get")

if not response then
    libc.Print("Network not available: " .. (err or "unknown error") .. "\n")
    libc.Print("\nTo enable network, implement a server-side RemoteFunction.\n")
    libc.Print("See docs/NETWORK.md for details.\n")
    return
end

libc.Print("Network is available!\n\n")

-- GET request
libc.Print("1. GET Request\n")
local response, err = Syscall("NET_REQ", "GET", "https://httpbin.org/get")

if response then
    libc.Print("Response received (" .. #response .. " bytes)\n")
else
    libc.Print("Error: " .. err .. "\n")
end

-- POST request
libc.Print("\n2. POST Request\n")
local data = '{"name":"Bedrock","version":"1.0"}'
local response, err = Syscall("NET_REQ", "POST", "https://httpbin.org/post", data)

if response then
    libc.Print("POST successful (" .. #response .. " bytes)\n")
else
    libc.Print("Error: " .. err .. "\n")
end

-- Error handling
libc.Print("\n3. Error Handling\n")
local response, err = Syscall("NET_REQ", "GET", "https://invalid-url-that-does-not-exist.com")

if not response then
    libc.Print("Expected error: " .. err .. "\n")
end

libc.Print("\nNetwork demo complete!\n")
]==]
