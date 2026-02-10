--!strict
local Players = game:GetService("Players")
local AssetService = game:GetService("AssetService")

local RAM = require(script.Parent.RAM)
local MemoryMap = require(script.Parent.Parent.Core.Memory.MemoryMap)

-- The GPU (Graphics Processing Unit) Abstraction
-- Now maps to physical RAM addresses!

local GPU = {}
GPU.__index = GPU

export type GPU = typeof(setmetatable(
	{} :: {
		_editableImage: EditableImage,
		_ram: RAM.RAM,
		_vramOffset: number,
		_paletteOffset: number,
		_rgbaBuffer: buffer, -- Internal buffer for EditableImage upload
		Width: number,
		Height: number,
		_frameCount: number,
	},
	GPU
))

-- Memory Map constants
local VRAM_ADDR = MemoryMap.VRAM_BASE
local PALETTE_ADDR = MemoryMap.PALETTE_BASE

function GPU.new(ram: RAM.RAM, width: number, height: number, AssetServiceOverride: any?, PlayersOverride: any?): GPU
	local _AssetService = AssetServiceOverride or AssetService
	local _Players = PlayersOverride or Players

	local player = _Players.LocalPlayer
	local playerGui = player and player:FindFirstChild("PlayerGui")

	local editableImage
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

		editableImage = _AssetService:CreateEditableImage({
			Size = Vector2.new(width, height),
		})
		imageLabel.ImageContent = Content.fromObject(editableImage)
	else
		-- Headless / Testing context or override
		-- If override provides its own CreateEditableImage, use it
		if _AssetService and _AssetService.CreateEditableImage then
			editableImage = _AssetService:CreateEditableImage({
				Size = Vector2.new(width, height),
			})
		else
			editableImage = {
				WritePixelsBuffer = function() end,
				WritePixels = function() end,
				ReadPixels = function()
					return buffer.create(width * height * 4)
				end,
			} :: any
		end
	end

	local self = setmetatable({
		_editableImage = editableImage,
		_ram = ram,
		_vramOffset = VRAM_ADDR,
		_paletteOffset = PALETTE_ADDR,
		_rgbaBuffer = buffer.create(width * height * 4),
		Width = width,
		Height = height,
		_frameCount = 0,
	}, GPU)

	self:InitPalette()
	self:Clear(0)
	return self
end

function GPU:InitPalette()
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
function GPU:Flush(x: number?, y: number?, w: number?, h: number?)
	self._frameCount += 1
	local ramBuf = self._ram:GetBuffer()
	local rgbaBuf = self._rgbaBuffer
	local vram = self._vramOffset
	local pal = self._paletteOffset
	local width = self.Width
	local height = self.Height

	-- If dirty region provided, only convert those pixels (VRAM->RGBA)
	-- Still upload full buffer since EditableImage doesn't support partial writes with offset
	if x and y and w and h and w > 0 and h > 0 then
		local startX = math.clamp(x, 0, width)
		local startY = math.clamp(y, 0, height)
		local endX = math.clamp(x + w, 0, width)
		local endY = math.clamp(y + h, 0, height)

		-- Only convert dirty pixels from indexed to RGBA
		for py = startY, endY - 1 do
			local rowOffset = py * width
			for px = startX, endX - 1 do
				local i = rowOffset + px
				local colorIndex = buffer.readu8(ramBuf, vram + i)
				local rgba = buffer.readu32(ramBuf, pal + (colorIndex * 4))
				buffer.writeu32(rgbaBuf, i * 4, rgba)
			end
		end
	else
		-- Full frame conversion (fallback)
		local pixelCount = width * height
		for i = 0, pixelCount - 1 do
			local colorIndex = buffer.readu8(ramBuf, vram + i)
			local rgba = buffer.readu32(ramBuf, pal + (colorIndex * 4))
			buffer.writeu32(rgbaBuf, i * 4, rgba)
		end
	end

	-- Upload full RGBA buffer to EditableImage
	(self._editableImage :: any):WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(width, height), rgbaBuf)
end

function GPU:Clear(colorIndex: number)
	self._ram:Fill(self._vramOffset, colorIndex or 0, self.Width * self.Height)
	self:Flush()
end

function GPU:Reset()
	self:InitPalette()
	self:Clear(0)
end

function GPU:Scroll(dy: number, colorIndex: number)
	if dy <= 0 then
		return
	end
	local stride = self.Width
	local copySize = (self.Height - dy) * stride
	local offset = dy * stride

	self._ram:Copy(self._vramOffset, self._vramOffset + offset, copySize)
	self._ram:Fill(self._vramOffset + copySize, colorIndex or 0, offset)
end

return GPU
