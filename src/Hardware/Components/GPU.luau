local Players = game:GetService("Players")
local AssetService = game:GetService("AssetService")

-- The GPU (Graphics Processing Unit) Physical Component
-- Directly manages the EditableImage and ScreenGui.

local GPU = {}
GPU.__index = GPU

export type GPU = {
    _editableImage: EditableImage?,
    _ram: any,
    _vramOffset: number,
    _rgbaBuffer: buffer,
    _player: Player?,
    Width: number,
    Height: number,
}

function GPU.new(ram: any, width: number, height: number, vramOffset: number): GPU
    local self = setmetatable({
        _editableImage = nil,
        _ram = ram,
        _vramOffset = vramOffset,
        _rgbaBuffer = buffer.create(width * height * 4),
        _player = Players.LocalPlayer,
        Width = width,
        Height = height,
    }, GPU)

    return (self :: any) :: GPU
end

function GPU:Init()
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
        imageLabel.ResampleMode = Enum.ResamplerMode.Pixelated
        imageLabel.Parent = container

        local aspect = Instance.new("UIAspectRatioConstraint")
        aspect.AspectRatio = self.Width / self.Height
        aspect.AspectType = Enum.AspectType.FitWithinMaxSize
        aspect.Parent = imageLabel

        self._editableImage = AssetService:CreateEditableImage({
            Size = Vector2.new(self.Width, self.Height),
        })
        if self._editableImage then
            imageLabel.ImageContent = Content.fromObject(self._editableImage)
        end
    end
end

function GPU:Flush()
    if not self._editableImage then return end
    
    local ramBuf = self._ram:GetBuffer()
    local rgbaBuf = self._rgbaBuffer
    local vram = self._vramOffset
    local width, height = self.Width, self.Height

    buffer.copy(rgbaBuf, 0, ramBuf, vram, width * height * 4)
    self._editableImage:WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(width, height), rgbaBuf)
end

function GPU:Clear(colorRGBA: number)
    local w, h = self.Width, self.Height
    self._ram:Fill32(self._vramOffset, colorRGBA or 0, w * h * 4)
    self:Flush()
end

function GPU:Rect(x, y, w, h, rgba)
    local vram = self._vramOffset
    local sw = self.Width
    local ram = self._ram
    
    -- Clip to screen bounds
    if x < 0 then w = w + x; x = 0 end
    if y < 0 then h = h + y; y = 0 end
    if x + w > sw then w = sw - x end
    if y + h > self.Height then h = self.Height - y end
    if w <= 0 or h <= 0 then return end

    for i = 0, h - 1 do
        local rowAddr = vram + ((y + i) * sw + x) * 4
        ram:Fill32(rowAddr, rgba, w * 4)
    end
    self:Flush()
end

function GPU:Scroll(dy, rgba)
    local vram = self._vramOffset
    local sw = self.Width
    local sh = self.Height
    local ram = self._ram
    local rowSize = sw * 4
    
    if dy == 0 then return end

    if dy > 0 then
        -- Scroll up
        ram:Copy(vram, vram + dy * rowSize, (sh - dy) * rowSize)
        -- Clear bottom
        ram:Fill32(vram + (sh - dy) * rowSize, rgba, dy * rowSize)
    elseif dy < 0 then
        -- Scroll down
        local ady = math.abs(dy)
        ram:Copy(vram + ady * rowSize, vram, (sh - ady) * rowSize)
        -- Clear top
        ram:Fill32(vram, rgba, ady * rowSize)
    end
    self:Flush()
end

return GPU
