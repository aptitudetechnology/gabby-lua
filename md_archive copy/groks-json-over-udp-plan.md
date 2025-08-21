Yes, you can implement JSON-over-UDP sockets in `gabby-lua` to support your software-defined radio (SDR) and modem testing while maintaining compatibility with existing TCP-based chat functionality. Using UDP for JSON messaging could be advantageous for your SDR/modem experiments, as UDP is lightweight, connectionless, and potentially better suited for real-time or high-throughput scenarios, though it introduces challenges like message loss and ordering. Since you’ve emphasized preserving existing `gabby-lua` client communication and are testing JSON sockets for a new software-defined modem, I’ll outline how to adapt `gabby-lua` to use JSON over UDP while ensuring no loss of current functionality (peer discovery, direct messaging, CLI, etc.). I’ll also address how this aligns with your SDR/modem goals, referencing the provided `LuaRadio-json-socket-integration-plan.md` and Copilot’s revised plan.

### Feasibility and Considerations for JSON over UDP
UDP is already used in `gabby-lua` for peer discovery (via `discovery_service.lua`), so the codebase is familiar with UDP sockets. Replacing or supplementing TCP-based direct messaging with UDP for JSON messages is feasible but requires careful design to handle UDP’s characteristics:
- **Advantages**:
  - Lower latency: No connection setup, ideal for real-time SDR/modem data.
  - Simpler implementation: No need to manage TCP connections or streams.
  - Aligns with peer discovery: UDP is already used, so infrastructure exists.
- **Challenges**:
  - No delivery guarantee: UDP messages may be lost or arrive out of order.
  - Message size limits: UDP packets are typically limited to ~65KB (practical limit ~1.5KB for safe delivery across networks).
  - Parsing complexity: JSON messages must be delimited or sized explicitly, as UDP doesn’t provide stream boundaries like TCP.
- **Impact on Existing Functionality**: The current TCP-based messaging (`message_listener.lua`, `message_writer.lua`) and UDP-based peer discovery (`discovery_service.lua`) can coexist with a new UDP-based JSON messaging system, preserving legacy chat functionality.

To ensure no loss of existing functionality, I’ll propose adding JSON-over-UDP as a parallel messaging system (for SDR/modem and optionally chat) while keeping TCP for legacy clients. This avoids disrupting the existing `send <ip> <port> <message>` command and CLI behavior.

### Proposed Implementation: JSON over UDP in `gabby-lua`
I’ll adapt the approach from the `LuaRadio-json-socket-integration-plan.md` and Copilot’s revised plan, replacing TCP with UDP for JSON messages and adding SDR-specific functionality. The existing TCP-based messaging will remain intact for legacy clients, with UDP handling new JSON-based chat and SDR/modem messages.

#### 1. Extend `discovery_service.lua` for UDP Messaging
Since `discovery_service.lua` already handles UDP for peer discovery, extend it to also manage JSON message sending and receiving over UDP. Create new functions for sending and receiving JSON messages:
```lua
local socket = require("socket")
local cjson = require("cjson")

-- Existing peer discovery code (assumed, not modified)
function discovery.start_discovery(on_peer_discovered)
    -- Current UDP broadcast logic for peer discovery
end

-- New: Send JSON message over UDP
function discovery.send_json_message(ip, port, data)
    local udp = assert(socket.udp())
    local json_msg = cjson.encode(data)
    if #json_msg > 1400 then
        logger.error("UDP message too large: " .. #json_msg .. " bytes")
        return false
    end
    udp:sendto(json_msg, ip, port)
    udp:close()
    return true
end

-- New: Start UDP listener for JSON messages
function discovery.start_message_listener(on_message)
    local udp = assert(socket.udp())
    assert(udp:setsockname("*", config.UDP_MESSAGE_PORT)) -- New port for messages
    udp:settimeout(0) -- Non-blocking
    while true do
        local line, ip, port = udp:receivefrom()
        if line then
            local ok, data = pcall(cjson.decode, line)
            if ok and data.metadata and data.payload then
                on_message(data.metadata, data.payload, ip, port) -- Pass sender info
            else
                on_message({ type = "legacy", timestamp = os.time() }, line, ip, port)
                logger.warn("Non-JSON UDP message from " .. ip .. ":" .. port .. ": " .. tostring(line))
            end
        end
        socket.sleep(0.01) -- Prevent CPU overload
    end
    udp:close()
end
```
- **Details**:
  - **Port**: Use a separate port (`config.UDP_MESSAGE_PORT`) for UDP messages to avoid conflicts with peer discovery’s UDP port.
  - **Size Check**: UDP packets should be kept small (<1.4KB) to avoid fragmentation. Log errors for oversized messages.
  - **Backward Compatibility**: Handle non-JSON messages as `legacy`, supporting potential raw-string UDP messages from older clients (though unlikely, as current messaging is TCP-based).
  - **Non-Blocking**: Use `settimeout(0)` and `socket.sleep` to keep the listener responsive.
- **Preserves Functionality**: Peer discovery remains unchanged, as this adds new functions without altering existing logic.

#### 2. Create `udp_message_writer.lua` for Sending
To keep the codebase modular (mirroring `message_writer.lua`), create a new `udp_message_writer.lua` for JSON-over-UDP sending:
```lua
local socket = require("socket")
local cjson = require("cjson")
local b64 = require("base64") -- Install via `luarocks install luaossl`

local writer = {}

function writer.send_message(ip, port, msg)
    local data = {
        metadata = { type = "chat", timestamp = os.time() },
        payload = msg
    }
    return discovery.send_json_message(ip, port, data)
end

function writer.send_signal(ip, port, signal_data, sample_rate, modulation)
    local payload = type(signal_data) == "string" and signal_data or b64.encode(signal_data)
    local data = {
        metadata = { type = "signal", timestamp = os.time(), sample_rate = sample_rate, modulation = modulation },
        payload = payload
    }
    return discovery.send_json_message(ip, port, data)
end

return writer
```
- **Details**:
  - Reuses `discovery.send_json_message` to send JSON-encoded messages over UDP.
  - Supports both chat (`type = "chat"`) and SDR/modem (`type = "signal"`) messages.
  - Base64-encodes binary signal data for JSON compatibility.
- **Preserves Functionality**: Doesn’t touch TCP-based `message_writer.lua`, so legacy clients continue using TCP for chat.

#### 3. Update `main.lua` for UDP Message Handling
Modify `main.lua` to start the UDP listener and handle both TCP and UDP messages. Extend the CLI for UDP-based commands:
```lua
local discovery = require("discovery_service")
local udp_writer = require("udp_message_writer")
local message_listener = require("message_listener") -- Existing TCP listener
local message_writer = require("message_writer") -- Existing TCP writer

-- Unified message handler
function handle_message(metadata, msg, ip, port)
    if metadata.type == "signal" then
        logger.info("Received signal from " .. (ip or "TCP") .. ":" .. (port or "TCP") .. 
                    " (sample_rate: " .. (metadata.sample_rate or "unknown") .. 
                    ", modulation: " .. (metadata.modulation or "unknown") .. ")")
        -- Add SDR/modem processing (e.g., save payload to file)
    else
        local prefix = metadata.type == "legacy" and "[Legacy] " or ""
        logger.info(prefix .. "Received message (" .. metadata.type .. ") from " .. 
                    (ip or "TCP") .. ":" .. (port or "TCP") .. ": " .. tostring(msg))
    end
end

-- Start listeners (TCP and UDP)
function start_listeners()
    -- Start TCP listener (existing)
    message_listener.start(function(metadata, msg) 
        handle_message(metadata, msg, nil, nil) -- No IP/port for TCP
    end)
    -- Start UDP listener (new)
    discovery.start_message_listener(handle_message)
end

-- CLI loop (partial example)
function run_cli()
    while true do
        local input = io.read()
        local command, args = parse_command(input) -- Assumed existing function
        if command == "send" then
            local ip, port, msg = args[1], tonumber(args[2]), args[3]
            message_writer.send_message(ip, port, msg) -- TCP (legacy)
        elseif command == "send_udp" then
            local ip, port, msg = args[1], tonumber(args[2]), args[3]
            udp_writer.send_message(ip, port, msg) -- UDP (JSON chat)
        elseif command == "send_signal" then
            local ip, port, sample_rate, modulation, file = args[1], tonumber(args[2]), 
                                                           tonumber(args[3]), args[4], args[5]
            if ip and port and sample_rate and modulation and file then
                local file_content = assert(io.open(file, "rb")):read("*all")
                udp_writer.send_signal(ip, port, file_content, sample_rate, modulation)
                logger.info("Sent signal to " .. ip .. ":" .. port)
            else
                logger.error("Usage: send_signal <ip> <port> <sample_rate> <modulation> <file>")
            end
        elseif command == "quit" then
            break
        elseif command == "peers" then
            -- Existing peer discovery logic
        elseif command == "help" then
            print("Commands: send, send_udp, send_signal, peers, quit, help")
        end
    end
end
```
- **Details**:
  - **Unified Handler**: Processes TCP (legacy/JSON) and UDP (JSON) messages, including `type = "signal"` for SDR/modem.
  - **CLI Commands**:
    - `send`: Uses TCP for legacy compatibility.
    - `send_udp`: Sends JSON chat messages over UDP.
    - `send_signal`: Sends SDR/modem data over UDP with metadata.
  - **IP/Port**: UDP handler includes sender `ip` and `port` for logging or replies.
- **Preserves Functionality**: TCP-based messaging (`send`) and peer discovery (`peers`) remain unchanged. UDP adds new functionality without disrupting existing code.

#### 4. Update `config.lua`
Add a new UDP port for messaging to avoid conflicts with peer discovery:
```lua
local config = {
    TCP_PORT = 12345, -- Existing
    UDP_DISCOVERY_PORT = 12346, -- Existing (assumed)
    UDP_MESSAGE_PORT = 12347 -- New for JSON messages
}
return config
```

#### 5. Dependencies
Update `install-dependencies.sh` for `lua-cjson` and `base64`:
```bash
#!/bin/sh
luarocks install luasocket
luarocks install lua-cjson
luarocks install luaossl
```

#### 6. Testing Plan
To ensure no loss of functionality and validate UDP for SDR/modem:
- **Legacy TCP Chat**:
  - Run an old client (TCP) and a new client.
  - Use `send <ip> <port> Hello` from the old client and verify the new client logs `[Legacy] Received message (legacy) from TCP:TCP: Hello`.
- **UDP JSON Chat**:
  - Run two new clients.
  - Use `send_udp <ip> <port> Hello` and verify logs show `Received message (chat) from <ip>:<port>: Hello`.
- **SDR/Modem Test**:
  - Create a `test_signal.bin` (e.g., 1KB of mock data).
  - Use `send_signal <ip> <port> 44100 AM test_signal.bin` and verify logs show `Received signal from <ip>:<port> (sample_rate: 44100, modulation: AM)`.
- **Peer Discovery**:
  - Run `peers` to confirm UDP discovery is unaffected.
- **Error Handling**:
  - Send a malformed UDP JSON packet and verify `logger.warn`.
  - Send a large (>1.4KB) JSON payload and verify `logger.error`.
- **Performance**:
  - Test with 1MB signal data (split into multiple UDP packets if needed, see below).

#### 7. Documentation
Update `README.md`:
```markdown
### Message Format
Messages over UDP/TCP are JSON-encoded:
```json
{
  "metadata": { "type": "chat" | "signal" | "legacy", "timestamp": number, "sample_rate"?: number, "modulation"?: string },
  "payload": "<message or base64-encoded signal>"
}
```

### CLI Commands
- `send <ip> <port> <message>`: Send chat message over TCP (legacy/JSON).
- `send_udp <ip> <port> <message>`: Send chat message over UDP (JSON).
- `send_signal <ip> <port> <sample_rate> <modulation> <file>`: Send SDR/modem signal over UDP.
```

### Addressing UDP Challenges for SDR/Modem
- **Message Loss**: UDP doesn’t guarantee delivery. For SDR/modem, add a simple acknowledgment mechanism:
  - Include a `message_id` in `metadata`.
  - Receiver sends a UDP reply with `{ type = "ack", message_id = <id> }`.
  - Sender retries if no ack is received within a timeout (e.g., 1s).
- **Message Size**: UDP packets are limited. For large SDR payloads (e.g., >1.4KB), split into chunks:
  ```lua
  function discovery.send_large_signal(ip, port, signal_data, sample_rate, modulation, chunk_size)
      chunk_size = chunk_size or 1000 -- Bytes
      local message_id = os.time() .. math.random(1000, 9999)
      for i = 1, #signal_data, chunk_size do
          local chunk = signal_data:sub(i, i + chunk_size - 1)
          local data = {
              metadata = {
                  type = "signal",
                  timestamp = os.time(),
                  sample_rate = sample_rate,
                  modulation = modulation,
                  message_id = message_id,
                  chunk_id = i,
                  total_chunks = math.ceil(#signal_data / chunk_size)
              },
              payload = b64.encode(chunk)
          }
          discovery.send_json_message(ip, port, data)
      end
  end
  ```
  - Update `handle_message` to reassemble chunks based on `message_id` and `chunk_id`.
- **Ordering**: UDP packets may arrive out of order. Use `chunk_id` to reorder chunks in the receiver.

### Preserving Existing Functionality
- **Peer Discovery**: Unchanged (uses `UDP_DISCOVERY_PORT`).
- **Direct Messaging**: TCP-based `send` remains for legacy clients; `send_udp` adds JSON-over-UDP for new clients.
- **CLI**: Existing commands (`peers`, `send`, `quit`, `help`) are unaffected; `send_udp` and `send_signal` are added.
- **Peer Management, Logger, Settings**: Unchanged, as UDP messaging is isolated to new functions.

### SDR/Modem Alignment
- **JSON-over-UDP**: Suitable for your SDR/modem tests due to low latency. The `send_signal` command supports metadata (e.g., `sample_rate`, `modulation`) and base64-encoded payloads.
- **Modem Testing**: For your new modem, UDP’s connectionless nature may align with real-time requirements. If large payloads or reliability are critical, the chunking and acknowledgment mechanisms above address this.
- **Performance**: Test UDP with small (1KB) and large (1MB) payloads to ensure suitability for your modem.

### Next Steps and Clarifications Needed
- **Implementation**: Add the code to `discovery_service.lua`, create `udp_message_writer.lua`, and update `main.lua` and `config.lua`. Run `install-dependencies.sh`.
- **Testing**: Use two VMs to test TCP (legacy), UDP chat, and SDR payloads.
- **Modem Details**: Could you specify your modem’s requirements (e.g., payload size, latency tolerance, or metadata fields)? This will help refine chunking or acknowledgment logic.
- **Questions**: Do you want to fully replace TCP with UDP for JSON, or keep both (as proposed)? Need help with chunking, acks, or test data generation?

Let me know your preference or specific needs (e.g., code for acknowledgments, VM setup, or modem-specific tweaks)!