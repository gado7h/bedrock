-- Kernel logging with severity levels
-- Usage: Log.info("VFS", "Mounted driver at %s", path)

local Log = {}

export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR" | "FATAL"

local LEVELS: { [LogLevel]: number } = {
	DEBUG = 0,
	INFO = 1,
	WARN = 2,
	ERROR = 3,
	FATAL = 4,
}

Log.MinLevel = LEVELS["INFO" :: any]

local MAX_LOGS = 500
local _klog: { string } = table.create(MAX_LOGS, "")
local _head = 1
local _count = 0

function Log.Clear()
	_klog = table.create(MAX_LOGS, "")
	_head = 1
	_count = 0
end

local function formatMessage(level: LogLevel, subsystem: string, msg: string, ...): string
	local formatted = string.format(msg, ...)
	return `[{string.format("%.4f", os.clock())}] [{level}] [{subsystem}] {formatted}`
end

local function log(level: LogLevel, subsystem: string, msg: string, ...: any)
	if LEVELS[level] < Log.MinLevel then
		return
	end

	local formatted = formatMessage(level, subsystem, msg, ...)

	if level == "ERROR" or level == "FATAL" then
		warn(formatted)
	else
		print(formatted)
	end

	if _count < MAX_LOGS then
		_klog[_head] = formatted
		_head += 1
		_count += 1
	else
		_klog[_head] = formatted
		_head = (_head % MAX_LOGS) + 1
	end
end

function Log.dmesg(): { string }
	local result = table.create(_count)
	if _count < MAX_LOGS then
		for i = 1, _count do
			result[i] = _klog[i]
		end
	else
		local idx = 1
		for i = _head, MAX_LOGS do
			result[idx] = _klog[i]
			idx += 1
		end
		for i = 1, _head - 1 do
			result[idx] = _klog[i]
			idx += 1
		end
	end
	return result :: { string }
end

function Log.debug(subsystem: string, msg: string, ...: any)
	log("DEBUG", subsystem, msg, ...)
end

function Log.info(subsystem: string, msg: string, ...: any)
	log("INFO", subsystem, msg, ...)
end

function Log.warn(subsystem: string, msg: string, ...: any)
	log("WARN", subsystem, msg, ...)
end

function Log.error(subsystem: string, msg: string, ...: any)
	log("ERROR", subsystem, msg, ...)
end

function Log.fatal(subsystem: string, msg: string, ...: any)
	log("FATAL", subsystem, msg, ...)
end

function Log.SetDebug()
	Log.MinLevel = LEVELS["DEBUG" :: any]
end

return Log
