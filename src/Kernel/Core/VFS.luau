--!strict
-- Virtual File System (RAM based)
local VFS = {}

type Node = {
	Type: "DIR" | "FILE",
	Name: string,
	Parent: Node?,
	Children: { [string]: Node }, -- For DIR
	Content: string?, -- For FILE
	UID: number, -- Owner ID
	GID: number, -- Group ID
	Mode: number, -- Permissions (octal representation, e.g., 0755)
}

local _root: Node = {
	Type = "DIR",
	Name = "",
	Children = {},
	UID = 0,
	GID = 0,
	Mode = 493, -- 0755 in decimal
}

local _pathCache: { [string]: Node } = {}

-- Selective cache invalidation (invalidates path and all children)
local function invalidatePath(path: string)
	local normalized = VFS.NormalizePath(path)
	
	-- Invalidate this exact path
	_pathCache[normalized] = nil
	
	-- Invalidate all parent paths up to root
	local parts = string.split(normalized, "/")
	local accumulated = ""
	for _, part in ipairs(parts) do
		if part ~= "" then
			accumulated = accumulated .. "/" .. part
			_pathCache[accumulated] = nil
		end
	end
	
	-- Invalidate all children (prefix match)
	local prefix = normalized .. "/"
	for cachedPath in pairs(_pathCache) do
		if string.sub(cachedPath, 1, #prefix) == prefix then
			_pathCache[cachedPath] = nil
		end
	end
end

-- Permission masks
local S_IXOTH = 1
local S_IWOTH = 2
local S_IROTH = 4
local S_IXGRP = 8
local S_IWGRP = 16
local S_IRGRP = 32
local S_IXUSR = 64
local S_IWUSR = 128
local S_IRUSR = 256

-- Current Working Directory helper (not used by kernel, passed by user)
-- Kernel just handles absolute paths or resolves them.
-- For simplicity, we'll assume Userland resolves PWD or passes full paths.
-- Or simpler: Kernel handles Paths.

local Errno = require(script.Parent.Errno)

-- Permission Check Logic
-- mask: 4 (Read), 2 (Write), 1 (Execute)
function VFS.CheckAccess(path: string, mask: number, uid: number?, gid: number?): boolean
	if not uid or uid == 0 then
		return true
	end -- Root/System always has access

	local node = VFS.Traverse(path)
	if not node then
		return false
	end

	local mode = node.Mode

	-- Owner check
	if node.UID == uid then
		local ownerMask = 0
		if bit32.band(mask, 4) ~= 0 and bit32.band(mode, S_IRUSR) ~= 0 then
			ownerMask = bit32.bor(ownerMask, 4)
		end
		if bit32.band(mask, 2) ~= 0 and bit32.band(mode, S_IWUSR) ~= 0 then
			ownerMask = bit32.bor(ownerMask, 2)
		end
		if bit32.band(mask, 1) ~= 0 and bit32.band(mode, S_IXUSR) ~= 0 then
			ownerMask = bit32.bor(ownerMask, 1)
		end
		if bit32.band(ownerMask, mask) == mask then
			return true
		end
	end

	-- Group check
	if node.GID == gid then
		local groupMask = 0
		if bit32.band(mask, 4) ~= 0 and bit32.band(mode, S_IRGRP) ~= 0 then
			groupMask = bit32.bor(groupMask, 4)
		end
		if bit32.band(mask, 2) ~= 0 and bit32.band(mode, S_IWGRP) ~= 0 then
			groupMask = bit32.bor(groupMask, 2)
		end
		if bit32.band(mask, 1) ~= 0 and bit32.band(mode, S_IXGRP) ~= 0 then
			groupMask = bit32.bor(groupMask, 1)
		end
		if bit32.band(groupMask, mask) == mask then
			return true
		end
	end

	-- Others check
	local otherMask = 0
	if bit32.band(mask, 4) ~= 0 and bit32.band(mode, S_IROTH) ~= 0 then
		otherMask = bit32.bor(otherMask, 4)
	end
	if bit32.band(mask, 2) ~= 0 and bit32.band(mode, S_IWOTH) ~= 0 then
		otherMask = bit32.bor(otherMask, 2)
	end
	if bit32.band(mask, 1) ~= 0 and bit32.band(mode, S_IXOTH) ~= 0 then
		otherMask = bit32.bor(otherMask, 1)
	end
	if bit32.band(otherMask, mask) == mask then
		return true
	end

	return false
end

-- Traversing path
function VFS.Traverse(path: string): Node?
	path = VFS.NormalizePath(path)

	if path == "/" then
		return _root
	end

	if _pathCache[path] then
		return _pathCache[path]
	end

	local nodes = string.split(path, "/")
	local current = _root

	for _, name in ipairs(nodes) do
		if name == "" then
			continue
		end

		if current.Type ~= "DIR" then
			return nil
		end
		if not current.Children then
			return nil
		end

		local nextNode = current.Children[name]
		if not nextNode then
			return nil
		end
		current = nextNode
	end

	_pathCache[path] = current
	return current
end

-- We need a robust path resolver.
-- Userland sends "etc/config" or "/bin".
-- For this prototype, we will be strict:
-- Paths starting with "/" are absolute.
-- Paths without "/" are relative to... we don't know the process env.
-- Kernel usually doesn't track process PWD unless implemented in Process Control Block.
-- Let's implement PCB PWD later.
-- For now, we will handle everything as absolute paths from Root.
-- Userland Shell tracks PWD and sends full paths like "/home/root/file".

function VFS.Init() end

function VFS.Chmod(path: string, mode: number, uid: number, gid: number): boolean
	local node = VFS.Traverse(path)
	if not node then
		return false
	end

	-- Only owner or root can chmod
	if uid ~= 0 and node.UID ~= uid then
		return false
	end

	node.Mode = mode
	invalidatePath(path)
	return true
end

function VFS.Chown(path: string, newUid: number, newGid: number, uid: number, gid: number): boolean
	local node = VFS.Traverse(path)
	if not node then
		return false
	end

	-- Only root can chown (conventionally, some systems allow owner to chgrp)
	if uid ~= 0 then
		return false
	end

	node.UID = newUid
	node.GID = newGid
	invalidatePath(path)
	return true
end

function VFS.List(path: string, uid: number, gid: number): { string }?
	if not VFS.CheckAccess(path, 4, uid, gid) then
		return nil
	end

	local node = VFS.Traverse(path)
	if node and node.Type == "DIR" then
		local names = {}
		for name, _ in pairs(node.Children) do
			table.insert(names, name)
		end
		return names
	end
	return nil
end

function VFS.Write(path: string, content: string, uid: number, gid: number): (boolean, number?)
	-- Get Parent Dir
	local parts = string.split(path, "/")
	local fileName = table.remove(parts) -- Pop last
	if not fileName then
		return false, Errno.ENOENT
	end

	local dirPath = table.concat(parts, "/")
	if dirPath == "" then
		dirPath = "/"
	end

	-- Check write access to parent directory
	if not VFS.CheckAccess(dirPath, 2, uid, gid) then
		return false, Errno.EACCES
	end

	local dir = VFS.Traverse(dirPath)
	if dir and dir.Type == "DIR" then
		local existing = dir.Children[fileName]

		if existing and not VFS.CheckAccess(path, 2, uid, gid) then
			return false, Errno.EACCES -- No permission to overwrite existing file
		end

		dir.Children[fileName] = {
			Type = "FILE",
			Name = fileName,
			Parent = dir,
			Content = content,
			Size = #content,
			UID = existing and existing.UID or (uid or 0),
			GID = existing and existing.GID or (gid or 0),
			Mode = existing and existing.Mode or 420, -- 0644 default for files
		}
		invalidatePath(path)
		return true, nil
	else
		return false, Errno.ENOENT
	end
end

function VFS.Read(path: string, uid: number, gid: number): (string?, number?)
	if not VFS.CheckAccess(path, 4, uid, gid) then
		return nil, Errno.EACCES
	end

	local node = VFS.Traverse(path)
	if node and node.Type == "FILE" then
		return node.Content or "", nil
	end
	return nil, Errno.ENOENT
end

function VFS.MkDir(path: string, uid: number, gid: number)
	local parts = string.split(path, "/")
	local dirName = table.remove(parts)
	if not dirName then
		return
	end

	local parentPath = table.concat(parts, "/")
	if parentPath == "" then
		parentPath = "/"
	end

	-- Check write access to parent directory
	if not VFS.CheckAccess(parentPath, 2, uid, gid) then
		return
	end

	local parent = VFS.Traverse(parentPath)
	if parent and parent.Type == "DIR" then
		if not parent.Children[dirName] then
			parent.Children[dirName] = {
				Type = "DIR",
				Name = dirName,
				Parent = parent,
				Children = {},
				UID = uid,
				GID = gid or 0,
				Mode = 493, -- 0755 default for directories
			}
			invalidatePath(path)
		end
	end
end

-- Mount table for overlay filesystems (e.g., /dev/gpu, /dev/tty, network HDD)
local _mounts: { [string]: any } = {}

function VFS.Mount(path: string, driver: any)
	_mounts[path] = driver
	print("[VFS] Mounted " .. (driver.Name or "Driver") .. " at " .. path)
end

function VFS.Remove(path: string, uid: number, gid: number): boolean
	local parts = string.split(path, "/")
	local nodeName = table.remove(parts)
	if not nodeName then
		return false
	end

	local parentPath = table.concat(parts, "/")
	if parentPath == "" then
		parentPath = "/"
	end

	-- Check write access to parent directory (to remove entry)
	if not VFS.CheckAccess(parentPath, 2, uid, gid) then
		return false
	end

	local parent = VFS.Traverse(parentPath)
	if parent and parent.Type == "DIR" and parent.Children[nodeName] then
		parent.Children[nodeName] = nil
		invalidatePath(path)
		return true
	end
	return false
end

function VFS.Stat(path: string, uid: number, gid: number): any?
	local node = VFS.Traverse(path)
	if not node then
		return nil
	end

	return {
		Type = node.Type,
		UID = node.UID,
		GID = node.GID,
		Mode = node.Mode,
		Name = node.Name,
		Size = node.Content and #node.Content or 0,
	}
end

function VFS.NormalizePath(path: string): string
	if not path or path == "" or path == "/" then
		return "/"
	end

	local parts = string.split(path, "/")
	local stack = {}

	for _, part in ipairs(parts) do
		if part == "" or part == "." then
			continue
		elseif part == ".." then
			if #stack > 0 then
				table.remove(stack)
			end
		else
			table.insert(stack, part)
		end
	end

	local result = "/" .. table.concat(stack, "/")

	-- Remove trailing slash if result is like "/path/"
	if #result > 1 and string.sub(result, -1) == "/" then
		result = string.sub(result, 1, -2)
	end

	return result
end

function VFS.GetDriver(path: string): (any?, string?)
	path = VFS.NormalizePath(path)

	-- Find the longest matching mount point
	local bestMatch = ""
	local bestDriver = nil

	for mountPoint, driver in pairs(_mounts) do
		if path == mountPoint or string.sub(path, 1, #mountPoint + 1) == mountPoint .. "/" then
			if #mountPoint > #bestMatch then
				bestMatch = mountPoint
				bestDriver = driver
			end
		end
	end

	if bestDriver then
		local relPath = string.sub(path, #bestMatch + 1)
		if relPath == "" then
			relPath = "/"
		end
		return bestDriver, relPath
	end

	return nil, path
end

return VFS
