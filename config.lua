-- config.lua
-- Configuration constants for Gabby Lua

local config = {}

-- Default network settings
config.UDP_PORT = 9001
config.TCP_PORT = 9002
config.BUFFER_SIZE = 4096
config.BROADCAST_ADDR = "255.255.255.255"
config.TIMEOUT = 5 -- seconds

-- Logging
config.LOG_LEVEL = "INFO" -- DEBUG, INFO, ERROR
config.LOG_FILE = "gabby.log"
config.CONSOLE_OUTPUT = true

-- Application constants
config.APP_NAME = "GabbyLua"
config.VERSION = "1.0.0"

return config
