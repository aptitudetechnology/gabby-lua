# Copilot's Revised Gabby-Lua JSON Socket & SDR Integration Plan

## Goals
- Preserve legacy chat functionality for all existing gabby-lua clients.
- Integrate JSON-over-TCP sockets for structured messaging and SDR/modem testing.
- Support new commands (e.g., `send_signal`) for SDR payloads with metadata.
- Ensure backward compatibility and robust error handling.

## 1. Message Listener: Backward-Compatible Design
- Update `message_listener.lua` to handle both JSON and raw string messages:
  - Try to decode incoming TCP messages as JSON.
  - If valid JSON with `metadata` and `payload`, process as structured message.
  - If not, treat as legacy raw string and pass with `{ type = "legacy" }` metadata.
  - Log non-JSON messages for debugging.

## 2. Message Writer: Forward-Compatible Sending
- Update `message_writer.lua` to send all messages as JSON (with metadata and payload).
- Legacy clients will still be supported by the listener's fallback logic.
- Add a new function `send_signal` for SDR/modem payloads:
  - Accepts signal data, sample rate, modulation, and encodes payload as base64 if binary.

## 3. Main Handler: Unified Message Processing
- Update `main.lua`'s handler to process both legacy and JSON messages:
  - Display metadata (type, timestamp, etc.) for JSON messages.
  - Prefix legacy messages for clarity in logs.
  - Add logic to handle `type = "signal"` for SDR/modem data.

## 4. CLI Extension: SDR Command
- Add `send_signal <ip> <port> <sample_rate> <modulation> <file>` to CLI.
- Read file contents, encode as base64 if needed, and send as JSON with metadata.

## 5. Testing & Validation
- Test legacy chat between old and new clients.
- Test JSON chat between new clients.
- Test SDR/modem payloads using `send_signal`.
- Validate peer discovery and CLI commands.
- Test error handling for malformed messages and large payloads.

## 6. Documentation & Dependencies
- Update `README.md` to document new message formats and CLI commands.
- Ensure `lua-cjson` and a base64 library (e.g., `luaossl`) are installed via `install-dependencies.sh`.

## 7. Additional Considerations
- For large binary SDR/modem payloads, consider hybrid approach: JSON for metadata, separate TCP stream for raw data if needed.
- Monitor performance and optimize for large payloads.
- Maintain clear code structure for future extensibility.

---
This plan ensures gabby-lua remains compatible with legacy clients while enabling advanced SDR/modem testing and structured messaging via JSON sockets. All changes are designed for minimal disruption and maximum future flexibility.
