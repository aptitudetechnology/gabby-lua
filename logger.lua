-- logger.lua
-- Simple logger for Gabby Lua

local config = require("config")
local logger = {}

local levels = { DEBUG = 1, INFO = 2, ERROR = 3 }
local log_file

local function open_log()
    if not log_file and config.LOG_FILE then
        log_file = io.open(config.LOG_FILE, "a")
    end
end

local function format_msg(level, msg)
    return string.format("[%s] %s: %s", os.date("%Y-%m-%d %H:%M:%S"), level, msg)
end

function logger.log(level, msg)
    if levels[level] >= levels[config.LOG_LEVEL] then
        local formatted = format_msg(level, msg)
        if config.CONSOLE_OUTPUT then
            print(formatted)
        end
        open_log()
        if log_file then
            log_file:write(formatted .. "\n")
            log_file:flush()
        end
    end
end

function logger.debug(msg)
    logger.log("DEBUG", msg)
end

function logger.info(msg)
    logger.log("INFO", msg)
end

function logger.error(msg)
    logger.log("ERROR", msg)
end

function logger.close()
    if log_file then log_file:close() end
end

return logger
