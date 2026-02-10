
local Players = game:GetService("Players")
local AssetService = game:GetService("AssetService")

local RAM = require(script.Parent.RAM)
local MemoryMap = require(script.Parent.Parent.Core.Memory.MemoryMap)

-- The GPU (Graphics Processing Unit) Abstraction
-- Now maps to physical RAM addresses!

local GPU = {}
GPU.__index = GPU

export type GPU = {
	_editableImage: EditableImage?,
	_ram: any,
	_vramOffset: number,
	_paletteOffset: number,
	_rgbaBuffer: buffer,
	_player: Player?,
	Width: number,
	Height: number,
	_frameCount: number,
	Init: (self: GPU) -> (boolean, string?),
	Shutdown: (self: GPU) -> (),
	InitPalette: (self: GPU) -> (),
	Flush: (self: GPU, x: number?, y: number?, w: number?, h: number?) -> (),
	Clear: (self: GPU, colorIndex: number) -> (),
	Reset: (self: GPU) -> (),
	Scroll: (self: GPU, dy: number, colorIndex: number) -> (),
}

-- Memory Map constants
local VRAM_ADDR = MemoryMap.VRAM_BASE
local PALETTE_ADDR = MemoryMap.PALETTE_BASE

function GPU.new(ram: RAM.RAM, width: number, height: number, AssetServiceOverride: any?, PlayersOverride: any?): GPU
	local _AssetService = AssetServiceOverride or AssetService
	local _Players = PlayersOverride or Players

	local self = setmetatable({
		_editableImage = nil,
		_ram = ram,
		_vramOffset = VRAM_ADDR,
		_paletteOffset = PALETTE_ADDR,
		_rgbaBuffer = buffer.create(width * height * 4),
		_player = _Players.LocalPlayer,
		Width = width,
		Height = height,
		_frameCount = 0,
	}, GPU)

	return (self :: any) :: GPU
end

function GPU.Init(self: GPU): (boolean, string?)
	local player = self._player
	local playerGui = player and player:FindFirstChild("PlayerGui")

	if playerGui then
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "VOYAGER_DISPLAY"
		screenGui.ResetOnSpawn = false
		screenGui.Enabled = true
		screenGui.DisplayOrder = 999999
		screenGui.Parent = playerGui

		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Size = UDim2.fromScale(1, 1)
		imageLabel.Position = UDim2.fromScale(0, 0)
		imageLabel.BackgroundColor3 = Color3.new(0, 0, 0)
		imageLabel.BackgroundTransparency = 1
		imageLabel.ImageTransparency = 0
		imageLabel.Visible = true
		imageLabel.ZIndex = 100
		imageLabel.ResampleMode = Enum.ResamplerMode.Pixelated
		imageLabel.Parent = screenGui

		self._editableImage = AssetService:CreateEditableImage({
			Size = Vector2.new(self.Width, self.Height),
		})
		if self._editableImage then
			imageLabel.ImageContent = Content.fromObject(self._editableImage)
		end
	else
		-- Headless / Testing
		local w: number = self.Width
		local h: number = self.Height
		self._editableImage = {
			WritePixelsBuffer = function() end,
			WritePixels = function() end,
			ReadPixels = function()
				return buffer.create(w * h * 4)
			end,
		} :: any
	end

	self:InitPalette()
	self:Clear(0)
	return true, nil
end

function GPU.Shutdown(self: GPU)
	local player = self._player
	local gui = player and player:FindFirstChild("PlayerGui")
	if gui then
		local display = gui:FindFirstChild("VOYAGER_DISPLAY")
		if display then
			display:Destroy()
		end
	end
end

function GPU.InitPalette(self: GPU)
	-- 16-color CGA/Studio-compatible palette
	local colors = {
		{ 0, 0, 0 }, -- 0: Black
		{ 0, 0, 170 }, -- 1: Low Blue
		{ 0, 170, 0 }, -- 2: Low Green
		{ 0, 170, 170 }, -- 3: Low Cyan
		{ 170, 0, 0 }, -- 4: Low Red
		{ 170, 0, 170 }, -- 5: Low Magenta
		{ 170, 85, 0 }, -- 6: Brown
		{ 170, 170, 170 }, -- 7: Light Gray
		{ 85, 85, 85 }, -- 8: Dark Gray
		{ 85, 85, 255 }, -- 9: High Blue
		{ 85, 255, 85 }, -- 10: High Green
		{ 85, 255, 255 }, -- 11: High Cyan
		{ 255, 85, 85 }, -- 12: High Red
		{ 255, 85, 255 }, -- 13: High Magenta
		{ 255, 255, 85 }, -- 14: Yellow
		{ 255, 255, 255 }, -- 15: White
	}
	for i, c in ipairs(colors) do
		local addr = self._paletteOffset + (i - 1) * 4
		self._ram:Write8(addr, c[1])
		self._ram:Write8(addr + 1, c[2])
		self._ram:Write8(addr + 2, c[3])
		self._ram:Write8(addr + 3, 255)
	end
end

-- Converts indexed VRAM to RGBA for display
-- Accepts optional dirty region (x, y, w, h) for partial pixel conversion
-- Converts indexed VRAM to RGBA for display
-- Accepts optional dirty region (x, y, w, h) for partial pixel conversion
function GPU.Flush(self: GPU, x: number?, y: number?, w: number?, h: number?)
	local frameCount = (self :: any)._frameCount :: number
	(self :: any)._frameCount = frameCount + 1
	local ramBuf = self._ram:GetBuffer()
	local rgbaBuf = self._rgbaBuffer
	local vram = self._vramOffset
	local pal = self._paletteOffset
	local width: number = (self :: any).Width :: number
	local height: number = (self :: any).Height :: number

	-- If dirty region provided, only convert those pixels (VRAM->RGBA)
	-- Still upload full buffer since EditableImage doesn't support partial writes with offset
	if x and y and w and h and w > 0 and h > 0 then
		local startX = math.clamp(x, 0, width)
		local startY = math.clamp(y, 0, height)
		local endX = math.clamp(x + w, 0, width)
		local endY = math.clamp(y + h, 0, height)

		-- Only convert dirty pixels from indexed to RGBA
		local w_val: number = width :: any
		local sx: number = startX :: any
		local ex: number = endX :: any
		local sy: number = startY :: any
		local ey: number = endY :: any

		for py = sy, ey - 1 do
			local rowOffset = py * w_val
			for px = sx, ex - 1 do
				local i = rowOffset + px
				local colorIndex = buffer.readu8(ramBuf, vram + i)
				local rgba = buffer.readu32(ramBuf, pal + (colorIndex * 4))
				buffer.writeu32(rgbaBuf, i * 4, rgba)
			end
		end
	else
		-- Full frame conversion (fallback)
		local w_val: number = width :: any
		local h_val: number = height :: any
		local pixelCount = w_val * h_val
		for i = 0, pixelCount - 1 do
			local colorIndex = buffer.readu8(ramBuf, vram + i)
			local rgba = buffer.readu32(ramBuf, pal + (colorIndex * 4))
			buffer.writeu32(rgbaBuf, i * 4, rgba)
		end
	end

	-- Upload full RGBA buffer to EditableImage
	if self._editableImage then
		(self._editableImage :: any):WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(width, height), rgbaBuf)
	end
end

function GPU.Clear(self: GPU, colorIndex: number)
	local w, h = self.Width :: number, self.Height :: number
	self._ram:Fill(self._vramOffset, colorIndex or 0, w * h)
	self:Flush()
end

function GPU.Reset(self: GPU)
	self:InitPalette()
	self:Clear(0)
end

function GPU.Scroll(self: GPU, dy: number, colorIndex: number)
	if dy <= 0 then
		return
	end
	local stride = self.Width
	local copySize = (self.Height - dy) * stride
	local offset = dy * stride

	self._ram:Copy(self._vramOffset, self._vramOffset + offset, copySize)
	self._ram:Fill(self._vramOffset + copySize, colorIndex or 0, offset)
end

function GPU.FillRect(self: GPU, x: number, y: number, w: number, h: number, colorIndex: number)
	local width, height = self.Width, self.Height
	local vram = self._vramOffset
	local ramBuf = self._ram:GetBuffer()

	-- Clipping
	local x1 = math.max(0, x)
	local y1 = math.max(0, y)
	local x2 = math.min(width, x + w)
	local y2 = math.min(height, y + h)

	if x1 >= x2 or y1 >= y2 then
		return
	end

	for py = y1, y2 - 1 do
		local rowOffset = py * width
		buffer.fill(ramBuf, vram + rowOffset + x1, colorIndex, x2 - x1)
	end
end

function GPU.BitBlt(self: GPU, dx: number, dy: number, sx: number, sy: number, w: number, h: number)
	local width, height = self.Width, self.Height
	local vram = self._vramOffset
	local ramBuf = self._ram:GetBuffer()

	-- Very basic clipping for source and dest
	-- Real implementation would handle partial overlaps better
	if sx < 0 or sy < 0 or dx < 0 or dy < 0 then
		return
	end
	if sx + w > width or sy + h > height or dx + w > width or dy + h > height then
		return
	end

	-- Row by row copy using buffer.copy
	-- buffer.copy handles overlapping memory correctly
	for i = 0, h - 1 do
		local srcOffset = (sy + i) * width + sx
		local destOffset = (dy + i) * width + dx
		buffer.copy(ramBuf, vram + destOffset, ramBuf, vram + srcOffset, w)
	end
end

return GPU
