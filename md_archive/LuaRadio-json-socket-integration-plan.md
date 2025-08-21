# LuaRadio JSON Socket Integration Plan for gabby-lua

## Overview
This document outlines the steps and code changes required to integrate the JSON-over-TCP socket approach (as described in `LuaRadio-json-socket.md`) into the existing `gabby-lua` codebase. The goal is to enable structured, self-describing message exchange between peers, making debugging and future extensions easier.

## 1. Dependencies
- Ensure a Lua JSON library is installed (e.g., `cjson` or `luajson`).
- Update `install-dependencies.sh` to include installation of the chosen JSON library if not already present.

## 2. Message Structure
- All TCP messages should be Lua tables encoded as JSON strings before sending.
- Message format:
  ```lua
  {
    metadata = { type = "chat", timestamp = os.time(), ... },
    payload = <actual message or data>
  }
  ```

## 3. Code Changes
### a. message_writer.lua
- Replace raw string sending with JSON encoding:
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

### b. message_listener.lua
- Decode incoming JSON messages and pass metadata/payload to handler:
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

### c. main.lua
- Update message handler to accept metadata:
  ```lua
  function handle_message(metadata, msg)
      logger.info("Received message (" .. metadata.type .. "): " .. tostring(msg))
  end
  ```

## 4. Extending for LuaRadio
- If integrating with LuaRadio, use the same JSON structure for signal data and metadata.
- Example: send modulated signal as `payload`, with relevant metadata (sample rate, modulation type, etc.).

## 5. Testing & Validation
- Test sending and receiving JSON messages between peers.
- Validate correct parsing and handling of metadata and payload.
- Ensure backward compatibility or migrate all message exchanges to JSON.

## 6. Benefits
- Easier debugging and extensibility.
- Ability to send additional metadata with each message.
- Consistent message format for future features (e.g., file transfer, signal data).

## 7. Next Steps
- Update code files as described above.
- Test in VM environment.
- Document usage and message format in README.md.

---
This integration plan will make gabby-lua more robust and future-proof for advanced use cases, including LuaRadio experiments between VMs.
