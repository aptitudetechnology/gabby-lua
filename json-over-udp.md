Let's refine the implementation to include JSON sockets over both UDP and TCP, maintaining your existing architectural patterns:

### 1. Config Updates (`config.lua`)

```lua
-- Add to your existing config.lua
config.UDP_MESSAGE_PORT = 9003        -- New UDP messaging port
config.MAX_UDP_MESSAGE_SIZE = 1024    -- Prevent fragmentation  
config.UDP_MESSAGE_TIMEOUT = 1        -- Shorter timeout for UDP
config.HOSTNAME = socket.dns.gethostname()  -- Add this for message identification
```

### 2. Enhanced Message Writer (`message_writer.lua`)

```lua
-- Update send_message to use JSON
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
    
    -- JSON encode the message
    local message_obj = {
        message = message,
        sender = config.HOSTNAME,
        timestamp = os.time()
    }
    
    local encoded_msg = cjson.encode(message_obj)
    local sent, err = client:send(encoded_msg)
    
    if not sent then
        logger.error("TCP send failed: " .. tostring(err))
        client:close()
        return false, err
    end
    
    client:close()
    return true
end

-- Add UDP JSON messaging
function writer.send_udp_message(ip, port, message)
    local udp_socket = socket.udp()
    udp_socket:settimeout(config.UDP_MESSAGE_TIMEOUT)
    
    local message_obj = {
        message = message,
        sender = config.HOSTNAME,
        timestamp = os.time()
    }
    
    local encoded_msg = cjson.encode(message_obj)
    local msg_size = #encoded_msg
    
    if msg_size > config.MAX_UDP_MESSAGE_SIZE then
        logger.error("UDP message too large: " .. msg_size .. " bytes (max " .. 
                    config.MAX_UDP_MESSAGE_SIZE .. ")")
        udp_socket:close()
        return false
    end
    
    local success, err = udp_socket:sendto(encoded_msg, ip, port)
    udp_socket:close()  
    
    if not success then
        logger.error("UDP send failed to " .. ip .. ":" .. port .. ": " .. tostring(err))
        return false
    end
    
    logger.info("UDP sent to " .. ip .. ":" .. port .. ": " .. message)
    return true
end
```

### 3. Enhanced Message Listener (`message_listener.lua`)

```lua
-- Update TCP listener to handle JSON
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
                -- JSON decode the message
                local ok, decoded_msg = pcall(cjson.decode, msg)
                if ok then
                    if on_message then on_message(client:getpeername(), decoded_msg) end
                else
                    logger.error("TCP JSON decode failed")
                end
            elseif err ~= "timeout" then
                logger.error("TCP receive error: " .. tostring(err))
            end
            client:close()
        end
        socket.sleep(0.1)
    end
    server:close()
end

-- Add UDP JSON listener
function listener.start_udp(on_udp_message)
    local udp_socket = socket.udp()
    udp_socket:setsockname("*", config.UDP_MESSAGE_PORT)
    udp_socket:settimeout(0)  
    
    logger.info("UDP listener started on port " .. config.UDP_MESSAGE_PORT)
    
    while true do
        local data, ip, port = udp_socket:receivefrom()
        
        if data then
            local ok, decoded_msg = pcall(cjson.decode, data)
            if ok then
                on_udp_message(ip, port, decoded_msg)
            else
                logger.error("UDP JSON decode failed from " .. ip .. ":" .. port)
            end
        else
            socket.sleep(0.1)  
        end
    end
end
```

### 4. CLI Integration (`main.lua`)

```lua
-- Update message handler for JSON
local function handle_message(peer_addr, msg)
    logger.info("Received message from " .. tostring(peer_addr) .. ": " .. tostring(msg.message))
end

-- Add UDP message handler
local function handle_udp_message(sender_ip, sender_port, decoded_msg)
    logger.info("UDP received from " .. sender_ip .. ":" .. sender_port .. 
               ": " .. decoded_msg.message)
end

-- Update command parsing
if line:match("^send ") then
    local _, _, ip, port, msg = line:find("^send%s+(%S+)%s+(%d+)%s+(.+)$")
    if ip and port and msg then
        writer.send_message(ip, tonumber(port), msg)
    else
        print("Usage: send <ip> <port> <message>")
    end
    return
elseif line:match("^udp ") then
    local _, _, ip, port, msg = line:find("^udp%s+(%S+)%s+(%d+)%s+(.+)$")
    if not port then
        _, _, ip, msg = line:find("^udp%s+(%S+)%s+(.+)$")
        port = config.UDP_MESSAGE_PORT
    end
    
    if ip and port and msg then
        writer.send_udp_message(ip, tonumber(port), msg)
    else
        print("Usage: udp <ip> [port] <message>")
    end
    return
end

-- Update help text
if line == "help" then
    print("Commands: peers, send <ip> <port> <message>, udp <ip> [port] <message>, quit")
end
```

### 5. Coroutine Integration (`main.lua`)

```lua
-- Add UDP listener coroutine
local co_udp_listener = coroutine.create(function()
    listener.start_udp(handle_udp_message)
end)

coroutine.resume(co_udp_listener)
```

### Key Improvements:

1. **JSON Sockets**: Both TCP and UDP now use JSON-encoded messages
2. **Consistent Format**: All messages use the same JSON structure
3. **Error Handling**: Improved error handling for JSON decoding
4. **Architecture**: Maintains your existing patterns while adding JSON support
5. **Backward Compatibility**: Existing discovery service remains unchanged

### Testing Recommendations:

1. Test JSON messaging over both TCP and UDP
2. Verify message integrity after encoding/decoding
3. Test with special characters in messages
4. Verify error handling for invalid JSON
5. Test maximum message size handling

This implementation gives you JSON sockets over both UDP and TCP while maintaining your clean architectural patterns and non