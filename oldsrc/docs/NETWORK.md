# Network Configuration Guide

## Overview

Bedrock provides network capabilities through the HAL (Hardware Abstraction Layer). Network support is **optional** and requires a server-side implementation to function.

## Architecture

```
Userspace Program
    ↓ Syscall("NET_REQ", "GET", "https://api.example.com")
Kernel/Core/Syscalls/Network.luau
    ↓ System.Network:Request()
Kernel/HAL/Network.luau
    ↓ RemoteFunction:InvokeServer()
Server (ServerScriptService)
    ↓ HttpService:RequestAsync()
External API
```

## Server Implementation

### Basic HTTP Proxy

```luau
-- ServerScriptService/NetworkProxy.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local remote = Instance.new("RemoteFunction")
remote.Name = "PremiumOS_Network"
remote.Parent = ReplicatedStorage

remote.OnServerInvoke = function(player, method, url, body)
    -- Validate request
    if not method or not url then
        return nil, "Invalid request"
    end
    
    -- Make HTTP request
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = method,
            Body = body,
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })
    end)
    
    if success then
        return response.Body
    else
        warn("[Network] Request failed:", response)
        return nil, tostring(response)
    end
end

print("[Network] HTTP proxy initialized")
```

### With URL Whitelist (Security)

```luau
-- ServerScriptService/NetworkProxy.server.luau
local ALLOWED_DOMAINS = {
    "api.github.com",
    "httpbin.org",
    "jsonplaceholder.typicode.com"
}

local function isAllowedURL(url)
    for _, domain in ipairs(ALLOWED_DOMAINS) do
        if string.find(url, domain, 1, true) then
            return true
        end
    end
    return false
end

remote.OnServerInvoke = function(player, method, url, body)
    -- Security check
    if not isAllowedURL(url) then
        warn("[Network] Blocked request to:", url)
        return nil, "URL not whitelisted"
    end
    
    -- ... rest of implementation
end
```

### With Rate Limiting

```luau
local playerRequests = {}
local MAX_REQUESTS_PER_MINUTE = 10

remote.OnServerInvoke = function(player, method, url, body)
    local userId = player.UserId
    local now = os.time()
    
    -- Initialize player tracking
    if not playerRequests[userId] then
        playerRequests[userId] = {}
    end
    
    -- Clean old requests (older than 60 seconds)
    local requests = playerRequests[userId]
    for i = #requests, 1, -1 do
        if now - requests[i] > 60 then
            table.remove(requests, i)
        end
    end
    
    -- Check rate limit
    if #requests >= MAX_REQUESTS_PER_MINUTE then
        return nil, "Rate limit exceeded"
    end
    
    -- Record request
    table.insert(requests, now)
    
    -- ... make request
end
```

## Client Usage

### Making HTTP Requests

```luau
-- Userspace program
local libc = require("libc")
local Syscall = libc.Syscalls.Call

-- GET request
local response, err = Syscall("NET_REQ", "GET", "https://api.github.com/users/octocat")

if response then
    print("Response:", response)
else
    print("Error:", err)
end

-- POST request
local data = '{"name":"John","age":30}'
local response, err = Syscall("NET_REQ", "POST", "https://httpbin.org/post", data)
```

### Error Handling

```luau
local response, err = Syscall("NET_REQ", "GET", "https://api.example.com/data")

if not response then
    if err == "Network not available" then
        print("No network server configured")
    elseif err == "Network Offline" then
        print("RemoteFunction not found")
    elseif err == "Rate limit exceeded" then
        print("Too many requests, try again later")
    else
        print("Network error:", err)
    end
    return
end

-- Process response
print("Success:", response)
```

## Standalone Mode (No Server)

If you're using bedrock without a server, network syscalls will gracefully fail:

```luau
-- No server implementation needed
Kernel.Boot()

-- Network calls return error
local response, err = Syscall("NET_REQ", "GET", "https://example.com")
-- response = false
-- err = "Network not available"
```

This allows bedrock to work in:
- Single-player games
- Client-only testing
- Offline development

## Advanced: Custom Network Drivers

You can replace the default HTTP driver with custom implementations:

### WebSocket Driver (Conceptual)

```luau
-- Custom HAL/WebSocket.luau
local WebSocket = {}

function WebSocket.new()
    return setmetatable({
        connections = {}
    }, WebSocket)
end

function WebSocket:Connect(url)
    -- Custom WebSocket implementation
end

-- In Kernel.Boot()
System.Network = WebSocket.new()  -- Replace default
```

### Mock Network (Testing)

```luau
-- tests/MockNetwork.luau
local MockNetwork = {}

function MockNetwork:Request(method, url)
    -- Return fake data for testing
    return true, '{"mock": "data"}'
end

-- In tests
System.Network = MockNetwork.new()
```

## Troubleshooting

### "Network not available"
- No server-side RemoteFunction found
- RemoteFunction not named "PremiumOS_Network"
- RemoteFunction not in ReplicatedStorage

**Solution:** Implement server-side network proxy (see above)

### "Network Offline"
- RemoteFunction exists but isn't responding
- Server script errored during initialization

**Solution:** Check server logs for errors

### Requests timeout
- URL is blocked by Roblox
- Server is slow to respond
- Rate limiting active

**Solution:** Check URL whitelist, increase timeout, reduce request rate

## Security Best Practices

1. **Always whitelist URLs** - Don't allow arbitrary requests
2. **Rate limit requests** - Prevent abuse
3. **Validate input** - Check method, URL, body
4. **Log requests** - Monitor for suspicious activity
5. **Use HTTPS** - Never send sensitive data over HTTP
6. **Sanitize responses** - Don't trust external data

## Future Enhancements

- [ ] TCP/UDP socket support
- [ ] WebSocket connections
- [ ] DNS resolution
- [ ] Network namespaces (per-process isolation)
- [ ] Firewall rules
- [ ] Packet inspection
