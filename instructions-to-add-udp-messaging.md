# GitHub Copilot Prompt: Implement UDP Messaging in GabbyLua

## Context
GabbyLua is a Lua-based P2P chat application with existing UDP peer discovery and TCP direct messaging. We need to extend it to support general JSON messaging over UDP while maintaining the existing architecture patterns.

## Current Architecture Analysis
- **Discovery**: UDP broadcasts on port 9001 (`discovery_service.lua`) using JSON with cjson
- **TCP Messaging**: Port 9002 via `message_writer.lua` and `message_listener.lua`
- **Non-blocking**: All services use `settimeout(0)` with polling loops and `socket.sleep(0.1)`
- **Error Handling**: Consistent `logger.error()` calls with graceful failures
- **CLI**: Simple command parsing in `main.lua` with `peers`, `send <ip> <port> <msg>`, `quit`, `help`
- **Coroutines**: Network services run as coroutines, CLI runs in main thread

## Implementation Requirements

### 1. Configuration Updates (`config.lua`)
Add these new configuration options:
```lua
config.UDP_MESSAGE_PORT = 9003  -- Separate from discovery port
config.MAX_UDP_MESSAGE_SIZE = 1024  -- Prevent fragmentation
config.UDP_MESSAGE_TIMEOUT = 1  -- Quick timeout for responsiveness
```

### 2. Message Writer Extension (`message_writer.lua`)
Add new function `writer.send_udp_message(ip, port, message)`:
- Create UDP socket with `socket.udp()`
- Encode message as JSON using `cjson.encode()`
- Check message size against `config.MAX_UDP_MESSAGE_SIZE`
- Send to specified IP and port
- Handle errors with `logger.error()` calls
- Close socket properly
- Return success/failure boolean like existing `send_message()`

### 3. Message Listener Extension (`message_listener.lua`)
Add new function `listener.start_udp(on_udp_message)`:
- Create UDP socket bound to `config.UDP_MESSAGE_PORT`
- Use `settimeout(0)` for non-blocking operation
- Polling loop with `receivefrom()` and `socket.sleep(0.1)`
- Decode JSON messages with `cjson.decode()` (handle parse errors)
- Call `on_udp_message(sender_ip, decoded_message)` callback
- Log received messages with `logger.info()`
- Match the architecture pattern of existing `start()` function

### 4. CLI Integration (`main.lua`)
Add these new CLI commands:
- `udp <ip> <port> <message>` - Send UDP message to specific peer
- `udp <ip> <message>` - Send UDP message using default UDP_MESSAGE_PORT
- Update `help` command to show new UDP commands
- Add message handler `handle_udp_message(sender_ip, decoded_msg)` that logs incoming UDP messages

### 5. Coroutine Integration (`main.lua`)
Create new coroutine for UDP message listening:
```lua
local co_udp_listener = coroutine.create(function()
    listener.start_udp(handle_udp_message)
end)
coroutine.resume(co_udp_listener)
```

## Code Style Requirements
- **Follow existing patterns**: Match error handling, logging, and socket management from current code
- **JSON structure**: Use simple `{message = "text", sender = hostname, timestamp = os.time()}` format
- **Error messages**: Use same format as existing code: `"UDP send failed: " .. tostring(err)`
- **Non-blocking**: All UDP operations must be non-blocking like current implementation
- **Resource cleanup**: Always close sockets in success and error cases

## Message Size Handling
- Check encoded JSON size before sending
- If message exceeds `MAX_UDP_MESSAGE_SIZE`, log error and refuse to send
- Consider chunking for future enhancement but implement size limit first

## Testing Approach
- Test UDP messaging between two instances on localhost using different UDP_MESSAGE_PORTs
- Verify non-blocking operation doesn't interfere with existing discovery/TCP
- Test error cases: invalid IP, unreachable peer, oversized messages
- Confirm JSON encoding/decoding works correctly

## Integration Notes
- Keep UDP messaging completely separate from discovery broadcasts
- Don't modify existing discovery_service.lua functionality
- Maintain backward compatibility with existing CLI commands
- Log all UDP messaging events for debugging

## Expected Outcome
After implementation:
1. Users can send UDP messages: `udp 192.168.1.100 9003 Hello World`
2. UDP messages appear in logs when received
3. All existing functionality (discovery, TCP messaging) continues working
4. Non-blocking operation maintained throughout
5. Proper error handling and logging for all UDP operations

Follow the existing code patterns precisely - the current implementation is clean and well-structured.