local UserInputService = game:GetService("UserInputService")

-- HID (Human Interface Device) Physical Component
-- Handles UserInputService and generates hardware interrupts.

export type Interrupt =
	{ Type: "IRQ_MOUSE", Data: { State: string, X: number, Y: number } }
	| { Type: "IRQ_KEYBOARD", Data: { State: string, Key: Enum.KeyCode } }

local HID = {}
HID.__index = HID

function HID.new()
	local self = setmetatable({
		_interruptQueue = {},
		_connections = {},
		MouseX = 0,
		MouseY = 0,
		Enabled = false,
	}, HID)
	return self
end

function HID:Init()
	self.Enabled = true
	self:_connectHardware()
end

function HID:Shutdown()
	self.Enabled = false
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}
end

function HID:_connectHardware()
	local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gp)
		if not self.Enabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(self._interruptQueue, {
				Type = "IRQ_MOUSE",
				Data = { State = "DOWN", X = self.MouseX, Y = self.MouseY },
			})
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			table.insert(self._interruptQueue, {
				Type = "IRQ_KEYBOARD",
				Data = { State = "DOWN", Key = input.KeyCode },
			})
		end
	end)
	table.insert(self._connections, inputBeganConn)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input, gp)
		if not self.Enabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(self._interruptQueue, {
				Type = "IRQ_MOUSE",
				Data = { State = "UP", X = self.MouseX, Y = self.MouseY },
			})
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			table.insert(self._interruptQueue, {
				Type = "IRQ_KEYBOARD",
				Data = { State = "UP", Key = input.KeyCode },
			})
		end
	end)
	table.insert(self._connections, inputEndedConn)

	local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local mouseLoc = UserInputService:GetMouseLocation()
			if mouseLoc then
				self.MouseX = mouseLoc.X
				self.MouseY = mouseLoc.Y
			end
		end
	end)
	table.insert(self._connections, inputChangedConn)
end

function HID:Poll()
	local batch = self._interruptQueue
	self._interruptQueue = {}
	return batch
end

return HID
