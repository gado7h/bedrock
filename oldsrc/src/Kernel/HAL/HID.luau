local UserInputService = game:GetService("UserInputService")

-- HID (Human Interface Device) Abstraction
-- Generates "Hardware Interrupts" for the Kernel.

export type Interrupt =
	{ Type: "IRQ_MOUSE", Data: { State: string, X: number, Y: number } }
	| { Type: "IRQ_KEYBOARD", Data: { State: string, Key: Enum.KeyCode } }

local HID = {}
HID.__index = HID

export type HID = typeof(setmetatable(
	{} :: {
		_interruptQueue: { Interrupt },
		_connections: { RBXScriptConnection },
		MouseX: number,
		MouseY: number,
		Enabled: boolean,
		_uis: any,
	},
	HID
))

function HID.new(UserInputServiceOverride: any?): HID
	local _UIS = UserInputServiceOverride or UserInputService
	local self = setmetatable({
		_interruptQueue = {},
		_connections = {},
		MouseX = 0,
		MouseY = 0,
		Enabled = false,
		_uis = _UIS,
	}, HID)

	return self
end

function HID.Init(self: HID): (boolean, string?)
	self.Enabled = true
	self:_connectHardware()
	return true, nil
end

function HID.Shutdown(self: HID)
	self.Enabled = false
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}
end

function HID._connectHardware(self: HID)
	local uis = self._uis
	if not uis or not uis.InputBegan then
		return
	end

	local inputBeganConn = (uis :: any).InputBegan:Connect(function(input, gp)
		if not self.Enabled then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(
				self._interruptQueue,
				{
					Type = "IRQ_MOUSE",
					Data = { State = "DOWN", X = self.MouseX, Y = self.MouseY },
				} :: Interrupt
			)
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			table.insert(
				self._interruptQueue,
				{
					Type = "IRQ_KEYBOARD",
					Data = { State = "DOWN", Key = input.KeyCode },
				} :: Interrupt
			)
		end
	end)
	table.insert(self._connections, inputBeganConn :: RBXScriptConnection)

	local inputEndedConn = uis.InputEnded:Connect(function(input, gp)
		if not self.Enabled then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			table.insert(
				self._interruptQueue,
				{
					Type = "IRQ_MOUSE",
					Data = { State = "UP", X = self.MouseX, Y = self.MouseY },
				} :: Interrupt
			)
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			table.insert(
				self._interruptQueue,
				{
					Type = "IRQ_KEYBOARD",
					Data = { State = "UP", Key = input.KeyCode },
				} :: Interrupt
			)
		end
	end)
	table.insert(self._connections, inputEndedConn :: RBXScriptConnection)

	local inputChangedConn = uis.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local mouseLoc = uis:GetMouseLocation()
			if mouseLoc then
				self.MouseX = mouseLoc.X
				self.MouseY = mouseLoc.Y
			end
		end
	end)
	table.insert(self._connections, inputChangedConn :: RBXScriptConnection)
end

-- Kernel reads interrupts from here
function HID.PollInterrupts(self: HID): { Interrupt }
	local batch = self._interruptQueue
	self._interruptQueue = {}
	return batch
end

function HID.Reset(self: HID)
	self._interruptQueue = {}
	-- Note: We don't reset MouseX/Y as that would be jarring
end

return HID
