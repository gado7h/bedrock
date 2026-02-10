--!strict
local UserInputService = game:GetService("UserInputService")

-- HID (Human Interface Device) Abstraction
-- Generates "Hardware Interrupts" for the Kernel.

export type Interrupt = {
	Type: "IRQ_MOUSE" | "IRQ_KEYBOARD",
	Data: any,
}

local HID = {}
HID.__index = HID

export type HID = typeof(setmetatable(
	{} :: {
		_interruptQueue: { Interrupt },
		MouseX: number,
		MouseY: number,
	},
	HID
))

function HID.new(UserInputServiceOverride: any?): HID
	local _UIS = UserInputServiceOverride or UserInputService
	local self = setmetatable({
		_interruptQueue = {},
		MouseX = 0,
		MouseY = 0,
		Enabled = true,
		_uis = _UIS,
	}, HID)

	self:_connectHardware()

	return self
end

function HID:_connectHardware()
	local uis = self._uis
	if not uis or not uis.InputBegan then
		return
	end

	uis.InputBegan:Connect(function(input, gp)
		if not self.Enabled then
			return
		end
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

	uis.InputEnded:Connect(function(input, gp)
		if not self.Enabled then
			return
		end
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

	uis.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local mouseLoc = uis:GetMouseLocation()
			if mouseLoc then
				self.MouseX = mouseLoc.X
				self.MouseY = mouseLoc.Y
			end
		end
	end)
end

-- Kernel reads interrupts from here
function HID:PollInterrupts(): { Interrupt }
	local batch = self._interruptQueue
	self._interruptQueue = {}
	return batch
end

function HID:Reset()
	self._interruptQueue = {}
	-- Note: We don't reset MouseX/Y as that would be jarring
end

return HID
