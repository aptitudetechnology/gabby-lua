-- main.lua
-- Entry point for Gabby Lua P2P chat

local config = require("config")
local logger = require("logger")
local discovery = require("discovery_service")
local listener = require("message_listener")
local writer = require("message_writer")

local peers = {}
local hostname = socket.dns.gethostname() or "unknown"

local function add_peer(ip, port, name)
    peers[ip .. ":" .. tostring(port)] = { ip = ip, port = port, name = name }
    logger.info("Discovered peer: " .. name .. " (" .. ip .. ":" .. port .. ")")
end

local function handle_message(peer_addr, msg)
    logger.info("Received message from " .. tostring(peer_addr) .. ": " .. tostring(msg))
end

local function cli()
    print("Welcome to GabbyLua! Type 'help' for commands.")
    while true do
        io.write("> ")
        local line = io.read()
        if line == "quit" then break
        elseif line == "peers" then
            for _, peer in pairs(peers) do
                print(peer.name .. " (" .. peer.ip .. ":" .. peer.port .. ")")
            end
        elseif line:match("^send ") then
            local _, _, ip, port, msg = line:find("^send%s+(%S+)%s+(%d+)%s+(.+)$")
            if ip and port and msg then
                writer.send_message(ip, tonumber(port), msg)
            else
                print("Usage: send <ip> <port> <message>")
            end
        elseif line == "help" then
            print("Commands: peers, send <ip> <port> <message>, quit")
        else
            print("Unknown command. Type 'help'.")
        end
    end
end

-- Start UDP broadcast and TCP listener in coroutines
local socket = require("socket")
local co_discovery = coroutine.create(function()
    discovery.listen_for_broadcast_messages(add_peer)
end)
local co_listener = coroutine.create(function()
    listener.start(handle_message)
end)

-- Broadcast our presence
coroutine.wrap(function()
    while true do
        discovery.broadcast_message(config.TCP_PORT, hostname)
        socket.sleep(5)
    end
end)()

-- Run coroutines for network services
coroutine.resume(co_discovery)
coroutine.resume(co_listener)

-- Run CLI in main thread
cli()

logger.close()
