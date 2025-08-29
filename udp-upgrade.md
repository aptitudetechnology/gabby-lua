Perfect! Now I have a complete understanding of your architecture. Here's the final UDP implementation that perfectly integrates with your existing code:

### 1. Config Additions (`config.lua`)

```lua
-- Add to your existing config.lua
config.UDP_MESSAGE_PORT = 9003        -- New UDP messaging port
config.MAX_UDP_MESSAGE_SIZE = 1024    -- Prevent fragmentation  
config.UDP_MESSAGE_TIMEOUT = 1        -- Shorter timeout for UDP
config.HOSTNAME = socket.dns.gethostname()  -- Add this for message identification
```

### 2. Message Writer Extension (`message_writer.lua`)

```lua
-- Add this function to your existing message_writer.lua
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
    
    -- Check message size against your new config option
    if msg_size > config.MAX_UDP_MESSAGE_SIZE then
        logger.error("UDP message too large: " .. msg_size .. " bytes (max " .. 
                    config.MAX_UDP_MESSAGE_SIZE .. ")")
        udp_socket:close()
        return false
    end
    
    local success, err = udp_socket:sendto(encoded_msg, ip, port)
    udp_socket:close()  -- Always close socket like your TCP pattern
    
    if not success then
        logger.error("UDP send failed to " .. ip .. ":" .. port .. ": " .. tostring(err))
        return false
    end
    
    logger.info("UDP sent to " .. ip .. ":" .. port .. ": " .. message)
    return true
end
```

### 3. Message Listener Extension (`message_listener.lua`)

```lua
-- Add this function to your existing message_listener.lua
function listener.start_udp(on_udp_message)
    local udp_socket = socket.udp()
    udp_socket:setsockname("*", config.UDP_MESSAGE_PORT)
    udp_socket:settimeout(0)  -- Non-blocking like your TCP listener
    
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
            socket.sleep(0.1)  -- Yield like your TCP pattern
        end
    end
end
```

### 4. CLI Integration (`main.lua`)

```lua
-- Add this message handler function to main.lua
local function handle_udp_message(sender_ip, sender_port, decoded_msg)
    logger.info("UDP received from " .. sender_ip .. ":" .. sender_port .. 
               ": " .. decoded_msg.message)
end

-- Add to your command parsing function
if line:match("^udp ") then
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

-- Update your help function
if line == "help" then
    print("Commands: peers, send <ip> <port> <message>, udp <ip> [port] <message>, quit")
end
```

### 5. Coroutine Integration (`main.lua`)

```lua
-- Add this with your other coroutine startups
local co_udp_listener = coroutine.create(function()
    listener.start_udp(handle_udp_message)
end)

coroutine.resume(co_udp_listener)
```

### Integration Notes:

1. **Architecture Matching**: Uses same patterns as your existing TCP implementation
2. **Port Separation**: UDP uses 9003 (avoids conflict with discovery on 9001)
3. **Error Handling**: Matches your existing logger.error() pattern
4. **Non-blocking**: Same settimeout(0) and socket.sleep(0.1) approach
5. **JSON Format**: Same structure as your discovery messages for consistency
6. **CLI Integration**: Extends your existing command pattern naturally

### Testing Recommendations:

1. Start two instances of GabbyLua
2. Use `udp 127.0.0.1 9003 "Hello UDP"` to test messaging
3. Verify discovery still works on port 9001
4. Test TCP messaging continues working on port 9002
5. Test error cases (invalid IP, unreachable port, etc.)

The implementation follows your existing patterns precisely while adding the requested UDP functionality. The solution maintains clean separation between discovery, TCP, and UDP services while ensuring non-blocking operation and proper resource management.

Would you like me to help you test the implementation or explain any part in more detail?