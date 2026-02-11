local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Hardware Control Panel (UI)
-- Simulates the physical case of the computer.

local HardwareCP = {}
HardwareCP._gui = nil

function HardwareCP.Mount(Motherboard)
    if HardwareCP._gui then return end
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screen = Instance.new("ScreenGui")
    screen.Name = "VoyagerCase"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 100 -- On top of game, below OS probably? Or alongside?
    screen.Parent = playerGui
    
    -- Main Bezel/Frame
    local frame = Instance.new("Frame")
    frame.Name = "CasePanel"
    frame.Size = UDim2.new(0, 200, 0, 80)
    frame.Position = UDim2.new(1, -210, 1, -90) -- Bottom Right
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(20, 20, 25)
    frame.Parent = screen
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 8)
    uicorner.Parent = frame
    
    -- Power Button
    local pwrBtn = Instance.new("TextButton")
    pwrBtn.Name = "PowerBtn"
    pwrBtn.Size = UDim2.new(0, 40, 0, 40)
    pwrBtn.Position = UDim2.new(0, 20, 0, 20)
    pwrBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    pwrBtn.Text = "PWR"
    pwrBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    pwrBtn.Font = Enum.Font.RobotoMono
    pwrBtn.Parent = frame
    
    local pwrCorner = Instance.new("UICorner")
    pwrCorner.CornerRadius = UDim.new(1, 0) -- Circle
    pwrCorner.Parent = pwrBtn
    
    pwrBtn.MouseButton1Click:Connect(function()
        if Motherboard.State.Powered then
            Motherboard.PowerOff()
        else
            Motherboard.PowerOn()
        end
    end)
    
    -- LED Indicators
    local function createLED(name, pos, color)
        local pad = Instance.new("Frame")
        pad.Name = name .. "_Label"
        pad.Size = UDim2.new(0, 40, 0, 15)
        pad.Position = pos
        pad.BackgroundTransparency = 1
        pad.Parent = frame
        
        local led = Instance.new("Frame")
        led.Name = "LED"
        led.Size = UDim2.new(0, 10, 0, 10)
        led.Position = UDim2.new(0, 0, 0, 0)
        led.BackgroundColor3 = Color3.fromRGB(20, 0, 0) -- Off state (dim)
        led.Parent = pad
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = led
        
        local label = Instance.new("TextLabel")
        label.Text = name
        label.Size = UDim2.new(0, 25, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(150, 150, 150)
        label.TextSize = 10
        label.Font = Enum.Font.Code
        label.Parent = pad
        
        return led
    end
    
    local pwrLed = createLED("PWR", UDim2.new(0, 80, 0, 20), Color3.fromRGB(255, 50, 50))
    local hddLed = createLED("HDD", UDim2.new(0, 80, 0, 40), Color3.fromRGB(50, 255, 50))
    local netLed = createLED("NET", UDim2.new(0, 140, 0, 20), Color3.fromRGB(50, 100, 255))
    
    HardwareCP._gui = screen
    
    -- Update Loop
    RunService.Heartbeat:Connect(function()
        -- PWR LED
        if Motherboard.State.Powered then
             pwrLed.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Bright Red
        else
             pwrLed.BackgroundColor3 = Color3.fromRGB(50, 0, 0) -- Dim Red
        end
        
        -- HDD LED (Blink)
        -- We need a way to check activity. 
        -- Motherboard could facilitate "Blink" state or we check a value.
        -- For now, simpler: Motherboard has .State.LEDs
        if Motherboard.State.LEDs.HDD then
            hddLed.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            Motherboard.State.LEDs.HDD = false -- Auto reset after frame (flicker)
        else
            hddLed.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
        end
        
        -- NET LED
        if Motherboard.State.LEDs.NET then
            netLed.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
            Motherboard.State.LEDs.NET = false -- Auto reset
        else
            netLed.BackgroundColor3 = Color3.fromRGB(0, 20, 50)
        end
    end)
end

return HardwareCP
