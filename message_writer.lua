-- message_writer.lua
-- TCP message sending for Gabby Lua

local socket = require("socket")
local config = require("config")
local logger = require("logger")

local writer = {}

function writer.send_message(ip, port, message)
    local client, err = socket.tcp()
    if not client then
        logger.error("TCP socket creation failed: " .. tostring(err))
        return false, err
    end
    local ok, err = client:connect(ip, port)
    if not ok then
        logger.error("TCP connect failed: " .. tostring(err))
        client:close()
        return false, err
    end
    local sent, err = client:send(message)
    if not sent then
        logger.error("TCP send failed: " .. tostring(err))
        client:close()
        return false, err
    end
    client:close()
    return true
end

return writer
