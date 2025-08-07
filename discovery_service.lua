-- discovery_service.lua
-- UDP broadcast peer discovery for Gabby Lua

local socket = require("socket")
local config = require("config")
local logger = require("logger")
local cjson = require("cjson.safe")

local discovery = {}

function discovery.encode_message(port, hostname)
    return cjson.encode({ port = port, name = hostname })
end

function discovery.decode_message(buffer)
    local ok, msg = pcall(cjson.decode, buffer)
    if ok then return msg else return nil end
end

function discovery.broadcast_message(port, hostname)
    local udp = assert(socket.udp())
    udp:setoption("broadcast", true)
    local msg = discovery.encode_message(port, hostname)
    local ok, err = udp:sendto(msg, config.BROADCAST_ADDR, config.UDP_PORT)
    if not ok then logger.error("Broadcast failed: " .. tostring(err)) end
    udp:close()
end

function discovery.listen_for_broadcast_messages(on_peer)
    local udp = assert(socket.udp())
    assert(udp:setsockname("*", config.UDP_PORT))
    udp:settimeout(0)
    logger.info("Listening for UDP broadcasts on port " .. config.UDP_PORT)
    while true do
        local buffer, ip, port = udp:receivefrom()
        if buffer then
            local peer = discovery.decode_message(buffer)
            if peer and on_peer then
                on_peer(ip, peer.port, peer.name)
            end
        end
        socket.sleep(0.1)
    end
    udp:close()
end

return discovery
