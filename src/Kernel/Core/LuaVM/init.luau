local compile = require(script:WaitForChild("Yueliang"))
local createExecutable = require(script:WaitForChild("FiOne"))

local LuaVM = {}

function LuaVM.Compile(source: string)
	local ok, result = pcall(function()
		return compile(source, "UserChunk")
	end)
	if ok then
		return result, nil
	else
		return nil, result
	end
end

function LuaVM.CreateExecutable(bytecode: string, env: { [any]: any }?)
	local ok, result = pcall(function()
		return createExecutable(bytecode, env or {})
	end)
	if ok then
		return result, nil
	else
		return nil, result
	end
end

function LuaVM.Load(source: string, env: { [any]: any }?)
	local bc, err = LuaVM.Compile(source)
	if not bc then
		return nil, err
	end
	return LuaVM.CreateExecutable(bc, env)
end

setmetatable(LuaVM, {
	__call = function(_, ...)
		return LuaVM.Load(...)
	end,
})

return LuaVM
