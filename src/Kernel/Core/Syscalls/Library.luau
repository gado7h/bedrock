-- Library Syscalls
local Library = {}

function Library.Init(System, Call)
	local HANDLERS = {}
	local _libCache = {}

	HANDLERS["LIB_LOAD"] = function(path: string)
		if _libCache[path] then return _libCache[path] end

		local content, err = Call("FS_READ", path)
		if not content then return nil, err end

		local Loader = require(script.Parent.Parent.Parent.Utils.Loader)
		local scheduler = System.Scheduler
		local currentPid = if scheduler then scheduler.CurrentPID else nil
		local proc = if currentPid then scheduler.Processes[currentPid] else nil
		local env = if proc then proc.Env else getfenv()

		local func, loadErr = Loader.LoadString(System, content, env)
		if func then
			local lib = func()
			_libCache[path] = lib
			return lib
		else
			return nil, loadErr
		end
	end

	HANDLERS["WIPE_LIBS"] = function()
		_libCache = {}
	end

	HANDLERS["PRINT"] = function(msg: string)
		-- Forward to TTY if mounted, or print to debug
		local ok = Call("FS_WRITE", "/dev/tty", msg)
		if not ok then
			print("[SYSCALL PRINT] " .. tostring(msg))
		end
	end

    HANDLERS["CLEAR_STDOUT"] = function()
        -- Implementation specific to display driver if needed
    end

	return HANDLERS
end

return Library
