# Enabling General Messaging Over UDP in Gabby

## Prompt for Implementation

Extend Gabby to support sending and receiving general chat or data messages over UDP, in addition to the existing peer discovery. Messages should be structured (preferably JSON), support configurable ports, and handle message size limits to avoid fragmentation. Implement error handling, logging, and non-blocking sockets for responsiveness. Integrate with the CLI to allow users to send UDP messages to specific peers and listen for incoming UDP messages.

### Key Requirements
- Use LuaSocket for UDP communication
- Support sending arbitrary JSON messages to a peer's IP and port
- Add CLI commands for sending and listening to UDP messages
- Handle message size limits and chunking if needed
- Log all UDP messaging events and errors
- Ensure non-blocking operation
- Update configuration to include UDP messaging settings

## Files to Update
- `main.lua` (add CLI commands for UDP messaging)
- `message_writer.lua` (implement UDP message sending)
- `message_listener.lua` (implement UDP message receiving)
- `config.lua` and/or `gabby-lua-config.lua` (add UDP messaging config)
- `logger.lua` (ensure logging for UDP events)
- `README.md` (document new UDP messaging features)
- Optionally: create `udp_message_service.lua` for modular UDP messaging logic

---
This prompt and file list will guide the implementation of general UDP messaging in Gabby.
