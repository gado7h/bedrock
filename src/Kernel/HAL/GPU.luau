
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

		local container = Instance.new("Frame")
		container.Name = "DisplayContainer"
		container.Size = UDim2.fromScale(1, 1)
		container.BackgroundTransparency = 0
		container.BackgroundColor3 = Color3.new(0, 0, 0)
		container.Parent = screenGui

		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = "Screen"
		imageLabel.Size = UDim2.fromScale(1, 1)
		imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		imageLabel.Position = UDim2.fromScale(0.5, 0.5)
		imageLabel.BackgroundColor3 = Color3.new(0, 0, 0)
		imageLabel.BackgroundTransparency = 1
		imageLabel.ImageTransparency = 0
		imageLabel.Visible = true
		imageLabel.ZIndex = 100
		imageLabel.ResampleMode = Enum.ResamplerMode.Pixelated
		imageLabel.Parent = container

		-- Preserve Aspect Ratio
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = self.Width / self.Height
		aspect.AspectType = Enum.AspectType.FitWithinMaxSize
		aspect.DominantAxis = Enum.DominantAxis.Width
		aspect.Parent = imageLabel

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

	-- self:InitPalette() -- No longer needed for 32-bit
	self:Clear(0x000000FF) -- Clear to Black (RGBA)
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
    -- Deprecated in 32-bit mode
end

-- Directly copies 32-bit RGBA data from RAM to the display buffer
function GPU.Flush(self: GPU, x: number?, y: number?, w: number?, h: number?)
	local ramBuf = self._ram:GetBuffer()
	local rgbaBuf = self._rgbaBuffer
	local vram = self._vramOffset
	local width: number = (self :: any).Width :: number
	local height: number = (self :: any).Height :: number

	-- 32-bit mode: RAM is already in RGBA8 format. 
	-- Always do full full copy to prevent sync issues with partial dirty rects
    -- and scrolling.
    buffer.copy(rgbaBuf, 0, ramBuf, vram, width * height * 4)

	-- Upload full RGBA buffer to EditableImage
	if self._editableImage then
		(self._editableImage :: any):WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(width, height), rgbaBuf)
	end
end

function GPU.Clear(self: GPU, colorRGBA: number)
	local w, h = self.Width :: number, self.Height :: number
	self._ram:Fill32(self._vramOffset, colorRGBA or 0, w * h * 4)
	self:Flush()
end

function GPU.Reset(self: GPU)
	self:Clear(0x000000FF)
end

function GPU.Scroll(self: GPU, dy: number, colorRGBA: number)
	if dy <= 0 then
		return
	end
	local width = self.Width
	local stride = width * 4
	local copySize = (self.Height - dy) * stride
	local offset = dy * stride

	self._ram:Copy(self._vramOffset, self._vramOffset + offset, copySize)
	self._ram:Fill32(self._vramOffset + copySize, colorRGBA or 0, offset)
end

function GPU.FillRect(self: GPU, x: number, y: number, w: number, h: number, colorRGBA: number)
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

	local rectWidth = (x2 - x1) * 4
	for py = y1, y2 - 1 do
		local rowOffset = (py * width + x1) * 4
		self._ram:Fill32(vram + rowOffset, colorRGBA, rectWidth)
	end
end

function GPU.BitBlt(self: GPU, dx: number, dy: number, sx: number, sy: number, w: number, h: number)
	local width, height = self.Width, self.Height
	local vram = self._vramOffset
	local ramBuf = self._ram:GetBuffer()

	if sx < 0 or sy < 0 or dx < 0 or dy < 0 then return end
	if sx + w > width or sy + h > height or dx + w > width or dy + h > height then return end

	local rowWidth = w * 4
	for i = 0, h - 1 do
		local srcOffset = ((sy + i) * width + sx) * 4
		local destOffset = ((dy + i) * width + dx) * 4
		buffer.copy(ramBuf, vram + destOffset, ramBuf, vram + srcOffset, rowWidth)
	end
end

return GPU
