Since we're working on the `gabby-lua` project and referencing the `LuaRadio-json-socket-integration-plan.md`, I'll provide a focused response based on the provided documents. The GitHub repository (`aptitudetechnology/gabby-lua`) describes a Lua-based P2P chat application, and the integration plan outlines how to enhance it with JSON-over-TCP messaging for structured communication, particularly for future LuaRadio integration. If you have a specific question or task related to this, please clarify, and I’ll tailor the response. For now, I’ll assume you want assistance implementing or understanding the integration plan.

### Summary of the Integration Plan
The plan aims to replace raw string messaging in `gabby-lua` with JSON-encoded messages to improve structure, debugging, and extensibility. Key changes involve updating `message_writer.lua`, `message_listener.lua`, and `main.lua` to handle JSON messages with a defined structure (`metadata` and `payload`). It also prepares the system for LuaRadio integration by using consistent JSON formats for signal data.

### Implementation Guidance
Based on the provided `LuaRadio-json-socket-integration-plan.md`, here’s a step-by-step approach to implement the changes:

#### 1. **Dependencies**
- Ensure `lua-cjson` is installed, as it’s already referenced in the GitHub README.
- Update `install-dependencies.sh` to include:
  ```bash
  luarocks install lua-cjson
  ```
  If `install-dependencies.sh` already includes this, verify it runs correctly:
  ```bash
  chmod +x install-dependencies.sh
  ./install-dependencies.sh
  ```

#### 2. **Update `message_writer.lua`**
Modify the `send_message` function to encode messages as JSON. The plan provides the following code:
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
- **Action**: Replace the existing `send_message` function in `message_writer.lua` with this code.
- **Note**: The `\n` delimiter ensures messages are separated when received. Ensure the receiving end handles this correctly.

#### 3. **Update `message_listener.lua`**
Modify the `start` function to decode JSON messages and pass `metadata` and `payload` to a handler:
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
            if ok and data.payload then
                on_message(data.metadata, data.payload)
            end
        end
        client:close()
    end
end
```
- **Action**: Replace the existing `start` function in `message_listener.lua` with this code.
- **Note**: The `pcall` handles potential JSON decoding errors gracefully. You may want to add error logging:
  ```lua
  if not ok then
      logger.error("Failed to decode JSON: " .. tostring(data))
  end
  ```

#### 4. **Update `main.lua`**
Update the message handler to process `metadata` and `payload`:
```lua
function handle_message(metadata, msg)
    logger.info("Received message (" .. metadata.type .. "): " .. tostring(msg))
end
```
- **Action**: Ensure the `handle_message` function in `main.lua` matches this signature and integrates with the existing CLI logic.
- **Note**: Verify that `logger.info` is defined in `logger.lua`. If additional metadata fields (e.g., `timestamp`) need display, modify the log message accordingly:
  ```lua
  logger.info("Received message (" .. metadata.type .. ", " .. metadata.timestamp .. "): " .. tostring(msg))
  ```

#### 5. **Testing**
- **Setup**: Run two instances of `gabby-lua` on different VMs or local ports:
  ```bash
  lua main.lua
  ```
- **Test Commands**:
  - Use `peers` to verify peer discovery.
  - Use `send <ip> <port> <message>` to send a test message (e.g., `send 127.0.0.1 12345 Hello`).
  - Check logs for JSON-encoded messages and correct metadata/payload handling.
- **Validation**: Ensure the receiver logs the message with its type (e.g., "chat") and timestamp, and that the payload matches the sent message.
- **Backward Compatibility**: If older peers use raw strings, add fallback logic in `message_listener.lua`:
  ```lua
  if not ok or not data.payload then
      on_message({ type = "legacy" }, line) -- Treat as raw string
  end
  ```

#### 6. **LuaRadio Integration**
- For LuaRadio, extend the JSON structure in `message_writer.lua` to include signal-specific metadata:
  ```lua
  local data = {
      metadata = { type = "signal", timestamp = os.time(), sample_rate = 44100, modulation = "AM" },
      payload = signal_data -- Base64-encoded signal or other format
  }
  ```
- Ensure `message_listener.lua` can handle `type = "signal"` and pass it to a LuaRadio-specific handler.

#### 7. **Documentation**
- Update `README.md` to include the new JSON message format and CLI usage for signal data (if applicable).
- Example addition:
  ```
  ### Message Format
  Messages are JSON-encoded with the following structure:
  ```json
  {
    "metadata": { "type": "chat", "timestamp": 1697051234 },
    "payload": "Hello, peer!"
  }
  ```
  Signal data (for LuaRadio) uses the same format with `type = "signal"` and additional metadata like `sample_rate`.
  ```

### Additional Notes
- **Error Handling**: Add robust error handling in `message_listener.lua` for malformed JSON or network issues.
- **Performance**: JSON encoding/decoding adds overhead. For high-frequency LuaRadio signals, consider compressing payloads or using a binary format like MessagePack (requires additional dependencies).
- **LuaRadio Context**: Since LuaRadio involves signal processing, ensure the VM environment has sufficient resources (CPU, memory) for real-time processing.
- **Testing Environment**: Use VMs with distinct IPs for peer discovery testing. Configure `config.lua` to set appropriate `TCP_PORT` and UDP broadcast settings.

### Questions for Clarification
- Are you actively implementing this integration, or do you need help with a specific part (e.g., debugging, testing, or LuaRadio specifics)?
- Do you want me to generate a sample JSON message or simulate a test case?
- Should I analyze the `gabby-lua` repository further for specific code details or issues?
- Are you planning to integrate LuaRadio immediately, or is this preparatory work?

Let me know your next steps or specific needs, and I’ll provide a more targeted response!