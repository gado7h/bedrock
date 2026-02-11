-- Voyager-1 CPU Emulator (v2)
-- 64-bit Instruction Word: [Op:8][Dest:8][S1:8][S2:8][Imm:32]

local RAM = require(script.Parent.RAM)

local CPU = {}
CPU.__index = CPU

export type CPUState = {
	Registers: { number },
	PC: number,
	SP: number,
	Flags: { ZF: boolean, CF: boolean },
	Halted: boolean,
}

export type CPU = typeof(setmetatable(
	{} :: {
		_ram: RAM.RAM,
		_state: CPUState,
		_syscallHandler: (num: number, cpu: CPU) -> (),
	},
	CPU
))

local OP = {
	NOP = 0x00,
	MOV_RR = 0x01,
	MOV_RI = 0x02,
	ADD = 0x03,
	SUB = 0x04,
	LOAD = 0x05,
	STORE = 0x06,
	JMP = 0x07,
	JZ = 0x08,
	JNZ = 0x09,
	CALL = 0x0A,
	RET = 0x0B,
	INT = 0x0C,
	PUSH = 0x0D,
	POP = 0x0E,
	HALT = 0xFF,
}

function CPU.new(ram: RAM.RAM): CPU
	local self = setmetatable({
		_ram = ram,
		_state = {
			Registers = { 0, 0, 0, 0, 0, 0, 0, 0 },
			PC = 0x020000,
			SP = 0x01FFFF,
			Flags = { ZF = false, CF = false },
			Halted = false,
		},
		_syscallHandler = function() end,
	}, CPU)
	return self
end

function CPU:SetSyscallHandler(handler)
	self._syscallHandler = handler
end

function CPU:Step()
	local self = self
	if self._state.Halted then
		return
	end

	local pc = self._state.PC
	-- Instruction is 8 bytes now! [0..3 is Op/Regs] [4..7 is Imm]
	local word1 = self._ram:Read32(pc)
	local imm = self._ram:Read32(pc + 4)
	self._state.PC += 8

	local op = bit32.extract(word1, 24, 8)
	local dest = bit32.extract(word1, 16, 8) + 1
	local s1 = bit32.extract(word1, 8, 8) + 1
	local s2 = bit32.extract(word1, 0, 8) + 1

	if op == OP.NOP then
	elseif op == OP.MOV_RR then
		self._state.Registers[dest] = self._state.Registers[s1]
	elseif op == OP.MOV_RI then
		self._state.Registers[dest] = imm
	elseif op == OP.ADD then
		local val = self._state.Registers[s1] + self._state.Registers[s2]
		self._state.Registers[dest] = val
		self._state.Flags.ZF = (val == 0)
	elseif op == OP.SUB then
		local val = self._state.Registers[s1] - self._state.Registers[s2]
		self._state.Registers[dest] = val
		self._state.Flags.ZF = (val == 0)
	elseif op == OP.LOAD then
		local addr = self._state.Registers[s1] + imm
		self._state.Registers[dest] = self._ram:Read32(addr)
	elseif op == OP.STORE then
		local addr = self._state.Registers[dest] + imm
		self._ram:Write32(addr, self._state.Registers[s1])
	elseif op == OP.JMP then
		self._state.PC = imm
	elseif op == OP.JZ then
		if self._state.Flags.ZF then
			self._state.PC = imm
		end
	elseif op == OP.JNZ then
		if not self._state.Flags.ZF then
			self._state.PC = imm
		end
	elseif op == OP.CALL then
		self._state.SP -= 4
		self._ram:Write32(self._state.SP, self._state.PC)
		self._state.PC = imm
	elseif op == OP.RET then
		self._state.PC = self._ram:Read32(self._state.SP)
		self._state.SP += 4
	elseif op == OP.INT then
		self._syscallHandler(imm, self)
	elseif op == OP.PUSH then
		self._state.SP -= 4
		self._ram:Write32(self._state.SP, self._state.Registers[dest])
	elseif op == OP.POP then
		self._state.Registers[dest] = self._ram:Read32(self._state.SP)
		self._state.SP += 4
	elseif op == OP.HALT then
		self._state.Halted = true
	end
end

return CPU
