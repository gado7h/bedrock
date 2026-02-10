local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HDD = {}
HDD.__index = HDD
HDD.Name = "NetworkHDD"
HDD.Async = true

export type HDD = {
	_remote: any,
	Init: (self: HDD) -> (boolean, string?),
	Shutdown: (self: HDD) -> (),
	Read: (self: HDD, path: string, uid: number?) -> (any, string?),
	Write: (self: HDD, path: string, content: any, uid: number?) -> (boolean, string?),
	List: (self: HDD, path: string, uid: number?) -> ({ string }?, string?),
	MkDir: (self: HDD, path: string, uid: number?) -> (boolean, string?),
}

function HDD.new(): HDD
	local self = setmetatable({
		_remote = nil,
	}, HDD)
	return (self :: any) :: HDD
end

function HDD.Init(self: HDD): (boolean, string?)
	local host = ReplicatedStorage:WaitForChild("Bedrock_Host", 10)
	if host then
		self._remote = host:WaitForChild("Bedrock_HDD", 5) :: RemoteFunction?
	end

	if not self._remote then
		return false, "Bedrock_HDD remote not found"
	end

	return true, nil
end

function HDD.Shutdown(self: HDD)
	self._remote = nil
end

function HDD.Read(self: HDD, path: string, uid: number?): (any, string?)
	if not self._remote then
		return nil, "HDD Offline"
	end

	local ok, result = pcall(function()
		return self._remote:InvokeServer("READ", path, uid)
	end)

	if not ok then
		return nil, tostring(result)
	end
	return result
end

function HDD.Write(self: HDD, path: string, content: any, uid: number?): (boolean, string?)
	if not self._remote then
		return false, "HDD Offline"
	end

	local ok, result = pcall(function()
		return self._remote:InvokeServer("WRITE", path, content, uid)
	end)

	if not ok then
		return false, tostring(result)
	end
	return result
end

function HDD.List(self: HDD, path: string, uid: number?): ({ string }?, string?)
	if not self._remote then
		return nil, "HDD Offline"
	end

	local ok, result = pcall(function()
		return self._remote:InvokeServer("LIST", path, uid)
	end)

	if not ok then
		return nil, tostring(result)
	end
	return result
end

function HDD.MkDir(self: HDD, path: string, uid: number?): (boolean, string?)
	if not self._remote then
		return false, "HDD Offline"
	end

	local ok, result = pcall(function()
		return self._remote:InvokeServer("MKDIR", path, uid)
	end)

	if not ok then
		return false, tostring(result)
	end
	return result
end

return HDD
