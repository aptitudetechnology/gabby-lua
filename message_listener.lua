-- message_listener.lua
-- TCP message receiving for Gabby Lua

local socket = require("socket")
local config = require("config")
local logger = require("logger")

local listener = {}

function listener.start(on_message)
    local server = assert(socket.tcp())
    assert(server:bind("*", config.TCP_PORT))
    assert(server:listen(5))
    server:settimeout(0)
    logger.info("Listening for TCP messages on port " .. config.TCP_PORT)
    while true do
        local client = server:accept()
        if client then
            client:settimeout(config.TIMEOUT)
            local msg, err = client:receive(config.BUFFER_SIZE)
            if msg then
                if on_message then on_message(client:getpeername(), msg) end
            elseif err ~= "timeout" then
                logger.error("TCP receive error: " .. tostring(err))
            end
            client:close()
        end
        socket.sleep(0.1)
    end
    server:close()
end

return listener
