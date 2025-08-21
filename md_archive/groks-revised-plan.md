Thanks for the context! I understand you’re testing JSON-over-TCP sockets in the context of software-defined radio (SDR), specifically using `gabby-lua` as a testbed, with the goal of eventually applying this to a new software-defined modem. Your priority is to ensure that `gabby-lua` clients maintain their existing chat functionality (peer discovery and direct messaging) while integrating the JSON socket approach outlined in `LuaRadio-json-socket-integration-plan.md`. This JSON structure will support both current chat functionality and future SDR modem experiments, likely involving structured signal data.

Based on your clarification and the concern raised in your previous question about potential loss of functionality in `message_listener.lua`, I’ll focus on ensuring that the JSON integration preserves `gabby-lua`’s existing client communication while enabling SDR testing. I’ll also address how to align this with your SDR and modem goals.

### Ensuring Existing Gabby-Lua Client Communication
The core concern is that the JSON-over-TCP changes in `message_listener.lua` (and related files) could break communication for existing `gabby-lua` clients, which likely send raw string messages over TCP. The integration plan’s `message_listener.lua` code only processes JSON messages with a `{metadata, payload}` structure, potentially discarding raw strings from older clients. Below, I’ll outline how to preserve existing functionality while supporting JSON for SDR testing.

#### 1. Backward Compatibility in `message_listener.lua`
To ensure existing `gabby-lua` clients can still communicate, modify `message_listener.lua` to handle both JSON and raw string messages. Here’s an updated version of the `start` function from the integration plan, with fallback logic:
```lua
local cjson = require("cjson")
function listener.start(on_message)
    local server = assert(socket.tcp())
    assert(server:bind("*", config.TCP_PORT))
    server:listen(5)
    while true do
        local client = server:accept()
        local line = client:receive("*l")
        if line then
            local ok, data = pcall(cjson.decode, line)
            if ok and data.metadata and data.payload then
                on_message(data.metadata, data.payload) -- JSON message
            else
                on_message({ type = "legacy", timestamp = os.time() }, line) -- Raw string fallback
                logger.warn("Received non-JSON message: " .. tostring(line))
            end
        end
        client:close()
    end
end
```
- **What This Does**:
  - Attempts to decode incoming messages as JSON.
  - If decoding succeeds and the message has `metadata` and `payload`, it processes it as a JSON message (for new clients or SDR data).
  - If decoding fails or the structure is invalid, it treats the message as a raw string (legacy `gabby-lua` client) and passes it to the `on_message` handler with a `legacy` type.
  - Logs non-JSON messages for debugging.
- **Impact**: This ensures older clients sending raw strings (e.g., "Hello, peer!") are still processed, preserving chat functionality.

#### 2. Update `message_writer.lua` for Dual Support
The integration plan’s `message_writer.lua` sends only JSON messages:
```lua
local cjson = require("cjson")
function writer.send_message(ip, port, msg)
    local sock = assert(socket.tcp())
    assert(sock:connect(ip, port))
    local data = {
        metadata = { type = "chat", timestamp = os.time() },
        payload = msg
    }
    local json_msg = cjson.encode(data)
    sock:send(json_msg .. "\n")
    sock:close()
end
```
- **Consideration**: Existing clients expect raw strings. To support them, you could add a configuration flag in `config.lua` to toggle between JSON and raw string sending, but this complicates the CLI. Instead, since the receiver (`message_listener.lua`) now handles both formats, new clients can send JSON, and old clients will still receive and process it as "legacy" messages.
- **Action**: Use the provided `message_writer.lua` code as is, as it’s forward-compatible with JSON-based SDR data. Older clients won’t send JSON, but the receiver’s fallback ensures compatibility.

#### 3. Update `main.lua` Handler
The integration plan updates `main.lua`’s `handle_message` to process `metadata` and `payload`:
```lua
function handle_message(metadata, msg)
    logger.info("Received message (" .. metadata.type .. "): " .. tostring(msg))
end
```
- **Ensuring Compatibility**: This handler works for both JSON (`type = "chat"`) and legacy (`type = "legacy"`) messages, as the `msg` parameter receives either the JSON `payload` or the raw string. No further changes are needed unless you want to display additional `metadata` fields (e.g., `timestamp`).
- **Optional Enhancement**: For clarity in logs or CLI output, differentiate legacy messages:
  ```lua
  function handle_message(metadata, msg)
      local prefix = metadata.type == "legacy" and "[Legacy] " or ""
      logger.info(prefix .. "Received message (" .. metadata.type .. "): " .. tostring(msg))
  end
  ```

#### 4. Preserving CLI Commands
The CLI commands (`peers`, `send <ip> <port> <message>`, `quit`, `help`) rely on `main.lua`, `discovery_service.lua`, and `message_writer.lua`. Since `message_listener.lua` now handles both JSON and raw strings, and `message_writer.lua` sends JSON (which is backward-compatible with the updated listener), CLI functionality remains intact. Test the `send` command to confirm messages display correctly on both old and new clients.

### Supporting SDR and Modem Testing
Your goal is to test JSON sockets for SDR (e.g., LuaRadio) and a new software-defined modem. The JSON structure in the integration plan (`{metadata, payload}`) is well-suited for this:
- **Chat Messages**: `{ metadata = { type = "chat", timestamp = os.time() }, payload = "Hello" }`
- **SDR Data**: `{ metadata = { type = "signal", timestamp = os.time(), sample_rate = 44100, modulation = "AM" }, payload = <signal_data> }`
- **Modem Data**: Similar structure, with `metadata` fields like `bitrate`, `encoding`, or `protocol`.

#### Steps for SDR/Modem Integration
1. **Extend `message_writer.lua` for SDR**:
   Add a function to send signal data:
   ```lua
   function writer.send_signal(ip, port, signal_data, sample_rate, modulation)
       local sock = assert(socket.tcp())
       assert(sock:connect(ip, port))
       local data = {
           metadata = { type = "signal", timestamp = os.time(), sample_rate = sample_rate, modulation = modulation },
           payload = signal_data -- Consider base64 encoding if binary
       }
       local json_msg = cjson.encode(data)
       sock:send(json_msg .. "\n")
       sock:close()
   end
   ```
   - **Note**: If `signal_data` is binary (e.g., raw samples), encode it as base64 to ensure JSON compatibility:
     ```lua
     local b64 = require("base64") -- Install via luarocks if needed
     payload = b64.encode(signal_data)
     ```

2. **Handle SDR in `message_listener.lua`**:
   Update the `on_message` handler in `main.lua` to process `type = "signal"`:
   ```lua
   function handle_message(metadata, msg)
       if metadata.type == "signal" then
           logger.info("Received signal (sample_rate: " .. (metadata.sample_rate or "unknown") .. ", modulation: " .. (metadata.modulation or "unknown") .. ")")
           -- Pass to LuaRadio or modem handler
       else
           local prefix = metadata.type == "legacy" and "[Legacy] " or ""
           logger.info(prefix .. "Received message (" .. metadata.type .. "): " .. tostring(msg))
       end
   end
   ```
   - **Note**: For binary payloads, decode if necessary:
     ```lua
     if metadata.type == "signal" then
         local b64 = require("base64")
         local decoded_payload = b64.decode(msg)
         -- Process decoded_payload with SDR/modem
     end
     ```

3. **CLI Extension**:
   Add a new CLI command for SDR testing, e.g., `send_signal <ip> <port> <sample_rate> <modulation> <file>`:
   ```lua
   -- In main.lua
   if command == "send_signal" then
       local ip, port, sample_rate, modulation, file = args[1], tonumber(args[2]), tonumber(args[3]), args[4], args[5]
       local signal_data = read_file(file) -- Implement file reading
       writer.send_signal(ip, port, signal_data, sample_rate, modulation)
   end
   ```

4. **Testing JSON Sockets for SDR**:
   - Use two VMs running `gabby-lua` with the updated code.
   - Send chat messages (`send <ip> <port> Hello`) to verify legacy and JSON compatibility.
   - Send mock SDR data (`send_signal <ip> <port> 44100 AM test_signal.bin`) to test JSON socket handling for large payloads.
   - Monitor logs for correct metadata and payload processing.

### Testing Plan to Verify No Loss
To ensure existing `gabby-lua` functionality is preserved while supporting SDR:
- **Legacy Client Test**:
  - Run an old `gabby-lua` client (pre-JSON) and a new client.
  - Send messages from the old client to the new client and verify they appear as `type = "legacy"` in logs.
- **New Client Test**:
  - Run two updated clients.
  - Use `send <ip> <port> <message>` to confirm JSON messages (`type = "chat"`) are sent and received correctly.
- **Peer Discovery**:
  - Use the `peers` command to ensure UDP discovery still works.
- **SDR Test**:
  - Send a mock signal payload with `type = "signal"` and verify metadata (e.g., `sample_rate`, `modulation`) is logged.
- **Error Handling**:
  - Send malformed JSON to `message_listener.lua` and check for `logger.warn` or `logger.error` output.
- **Performance**:
  - Test with large payloads (e.g., 1MB signal data) to ensure JSON encoding/decoding doesn’t cause delays.

### Additional Considerations
- **Binary Payloads for SDR/Modem**: JSON isn’t ideal for large binary data (e.g., raw signal samples). Base64 encoding works but increases size by ~33%. For your modem, consider a hybrid approach: use JSON for metadata and a separate TCP stream for raw binary data, signaled via a JSON control message.
- **Dependencies**: Ensure `lua-cjson` is installed. For base64, install `luarocks install luaossl` or a similar library.
- **Documentation**: Update `README.md` to document the `send_signal` command and JSON format for SDR data:
  ```
  ### SDR Support
  Use `send_signal <ip> <port> <sample_rate> <modulation> <file>` to send signal data. Messages use JSON:
  ```json
  {
    "metadata": { "type": "signal", "timestamp": 1697051234, "sample_rate": 44100, "modulation": "AM" },
    "payload": "<base64-encoded signal>"
  }
  ```
  ```

### Answers to Your Goals
- **Preserving Gabby-Lua Communication**: The modified `message_listener.lua` with fallback logic ensures old clients can still send and receive raw string messages, maintaining chat functionality.
- **SDR/Modem Testing**: The JSON structure supports structured metadata (e.g., `sample_rate`, `modulation`) and payloads, ideal for LuaRadio and your modem experiments. The `send_signal` function and handler extensions prepare `gabby-lua` for this.
- **Next Steps**: Implement the code changes, test with both legacy and new clients, and add the `send_signal` command for SDR testing.

If you need specific code (e.g., file reading for `send_signal`), help setting up VMs, or a test script for SDR data, let me know! I can also analyze the `gabby-lua` repository further if you share specific files (e.g., original `message_listener.lua`) or clarify your modem’s requirements (e.g., payload size, real-time needs). What’s your next step?