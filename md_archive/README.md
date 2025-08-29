
# GabbyLua

A Lua-based P2P chat application refactored from Go, supporting UDP peer discovery and TCP direct messaging.


## Features
- Peer discovery via UDP broadcast
- Direct messaging via TCP
- Interactive CLI
- Peer management
- Custom logger
- Configurable settings


## Getting Started

### 1. Install Dependencies

You need Lua 5.3+ and the following modules:

```bash
luarocks install luasocket
luarocks install lua-cjson
```

or chmod +x install-dependencies.sh
./ininstall-dependencies.sh

### 2. Run GabbyLua

Start the application:

```bash
lua main.lua
```

### 3. CLI Commands
- `peers` — List discovered peers
- `send <ip> <port> <message>` — Send message to peer
- `quit` — Exit
- `help` — Show commands


## File Structure
- `main.lua` — Entry point
- `discovery_service.lua` — UDP broadcast logic
- `message_listener.lua` — TCP message receiving
- `message_writer.lua` — TCP message sending
- `logger.lua` — Logging system
- `config.lua` — Configuration


## License
MIT
