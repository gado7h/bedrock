--!strict
local Library = {}

function Library.Init(System: any, CallSyscall: (string, ...any) -> ...any)
	local LuaVM = require(script.Parent.Parent.LuaVM)
	local Loader = require(script.Parent.Parent.Loader)
	local _libCache = {}

	return {
		["LIB_LOAD"] = function(name: string)
			-- We assume Caller handles noYield increment if vital, or we do it here?
			-- Syscalls.luau incremented _noYield.
			-- We can't easily access local _noYield of main module.
			-- Use a System state or argument?
			-- For now, we trust the caller (Userspace) won't explode if we yield
			-- UNLESS we are in an IRQ or similar.
			-- But LIB_LOAD is usually called from user code.

			local ok, result = pcall(function()
				if _libCache[name] then
					return _libCache[name]
				end

				local path = "/lib/" .. name .. ".lua"
				-- print(`[LIBRARY] Loading {name} from {path}...`)

				local content = CallSyscall("FS_READ", path)
				if not content then
					warn(`[KERNEL] LIB_LOAD: '{path}' not found in VFS!`)
					return nil
				end
				-- print(`[KERNEL] LIB_LOAD: Loaded '{path}' ({#content} bytes)`)

				-- Setup library environment (isolated)
				local env = {
					print = function(...)
						local args = { ... }
						local str = ""
						for i, v in ipairs(args) do
							str = str .. tostring(v) .. "\t"
						end
						CallSyscall("PRINT", str)
					end,
					math = math,
					table = table,
					string = string,
					Color3 = Color3,
					bit32 = bit32,
					buffer = buffer,
					pairs = pairs,
					ipairs = ipairs,
					next = next,
					tostring = tostring,
					tonumber = tonumber,
					type = type,
					os = { clock = os.clock, date = os.date },
					Enum = Enum,
					Syscall = function(...)
						return CallSyscall(...)
					end,
					require = function(n)
						return CallSyscall("LIB_LOAD", n)
					end,
					getfenv = getfenv,
					libc = {
						LoadLibrary = function(n)
							return CallSyscall("LIB_LOAD", n)
						end,
					},
				}
				env._G = env

				-- print(`[LIBRARY] Compiling {name}...`)
				local fn, err = Loader.LoadString(System, content, env)
				if not fn then
					warn(`[KERNEL] LIB_LOAD: Compilation error for '{name}': {err}`)
					return nil
				end

				-- print(`[LIBRARY] Executing {name}...`)
				local executionOk, executionResult = pcall(fn)
				if not executionOk then
					warn(`[KERNEL] LIB_LOAD: Execution error for '{name}': {executionResult}`)
					return nil
				end

				-- print(`[LIBRARY] Success {name}`)
				_libCache[name] = executionResult
				return executionResult
			end)

			if not ok then
				warn(`[KERNEL] LIB_LOAD Critical Error: {result}`)
				return nil
			end
			return result
		end,
	}
end

return Library
