return [==[
-- File System Example
-- Demonstrates VFS operations and permissions

local libc = require("libc")
local Syscall = libc.Syscalls.Call

libc.Print("=== File System Demo ===\n\n")

-- Create directory structure
libc.Print("Creating directory structure...\n")
Syscall("FS_MKDIR", "/tmp/myapp")
Syscall("FS_MKDIR", "/tmp/myapp/data")
Syscall("FS_MKDIR", "/tmp/myapp/logs")

-- Write files
libc.Print("Writing files...\n")
Syscall("FS_WRITE", "/tmp/myapp/config.txt", "debug=true\nport=8080")
Syscall("FS_WRITE", "/tmp/myapp/data/users.json", '{"users":[]}')
Syscall("FS_WRITE", "/tmp/myapp/logs/app.log", "Application started\n")

-- Read and display
libc.Print("\nReading config:\n")
local config = Syscall("FS_READ", "/tmp/myapp/config.txt")
libc.Print(config .. "\n")

-- List directory contents
libc.Print("\nDirectory contents:\n")
local function listDir(path, indent)
    indent = indent or ""
    local files = Syscall("FS_LIST", path)
    
    if files then
        for _, file in ipairs(files) do
            local fullPath = path .. "/" .. file
            local stat = Syscall("FS_STAT", fullPath)
            
            if stat then
                if stat.Type == "DIR" then
                    libc.Print(indent .. "📁 " .. file .. "/\n")
                    listDir(fullPath, indent .. "  ")
                else
                    libc.Print(indent .. "📄 " .. file .. " (" .. stat.Size .. " bytes)\n")
                end
            end
        end
    end
end

listDir("/tmp/myapp")

-- File permissions
libc.Print("\nFile permissions:\n")
local stat = Syscall("FS_STAT", "/tmp/myapp/config.txt")
libc.Print("  Mode: " .. stat.Mode .. "\n")
libc.Print("  UID: " .. stat.UID .. "\n")
libc.Print("  GID: " .. stat.GID .. "\n")

-- Change permissions
Syscall("FS_CHMOD", "/tmp/myapp/config.txt", 420)  -- 0644
libc.Print("  Changed to 0644 (420)\n")

-- Cleanup
libc.Print("\nCleaning up...\n")
Syscall("FS_REMOVE", "/tmp/myapp/config.txt")
Syscall("FS_REMOVE", "/tmp/myapp/data/users.json")
Syscall("FS_REMOVE", "/tmp/myapp/logs/app.log")
Syscall("FS_REMOVE", "/tmp/myapp/data")
Syscall("FS_REMOVE", "/tmp/myapp/logs")
Syscall("FS_REMOVE", "/tmp/myapp")

libc.Print("Done!\n")
]==]
