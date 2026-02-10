-- Pipes Service: Handles FIFO communication between processes

local Pipes = {
	_pipes = {} :: { [number]: { Buffer: { string }, Open: boolean } },
	_nextHandle = 1,
}

function Pipes.Open()
	local handle = Pipes._nextHandle
	Pipes._nextHandle += 1

	Pipes._pipes[handle] = {
		Buffer = {},
		Open = true,
	}

	return handle
end

function Pipes.Write(handle: number, data: string)
	local pipe = Pipes._pipes[handle]
	if pipe and pipe.Open then
		table.insert(pipe.Buffer, data)
		return true
	end
	return false
end

function Pipes.Read(handle: number): string?
	local pipe = Pipes._pipes[handle]
	if not pipe then
		return nil
	end

	if #pipe.Buffer == 0 then
		if not pipe.Open then
			return nil
		end -- EOF
		return "" -- Nothing to read yet
	end

	return table.remove(pipe.Buffer, 1)
end

function Pipes.Close(handle: number)
	local pipe = Pipes._pipes[handle]
	if pipe then
		pipe.Open = false
		-- We don't delete yet because there might be data to read (EOF)
	end
end

function Pipes.Cleanup(handle: number)
	Pipes._pipes[handle] = nil
end

return Pipes
