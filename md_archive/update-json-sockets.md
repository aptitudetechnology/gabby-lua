# Gabby LuaRadio Integration - GitHub Copilot Instructions

## Project Context

You are working on **Gabby**, a Lua-based P2P chat application (https://github.com/aptitudetechnology/gabby-lua) that uses UDP for peer discovery and TCP for direct messaging. The project is being extended to support **LuaRadio** functionality for software-defined radio (SDR) communication between peers.

## Current Gabby Architecture

- **main.lua** - Entry point with interactive CLI
- **discovery_service.lua** - UDP broadcast logic for peer discovery
- **message_listener.lua** - TCP message receiving
- **message_writer.lua** - TCP message sending
- **logger.lua** - Logging system
- **config.lua** - Configuration management

## LuaRadio Integration Requirements

### Core Concept
Extend Gabby to support structured JSON-over-UDP communication for LuaRadio signal processing between VMs/peers. This allows sending both signal data and metadata (sample rates, modulation types, etc.) in a self-describing format.

### Technical Specifications

#### 1. UDP JSON Protocol
- Use JSON encoding for structured data transmission
- Include metadata alongside signal data:
  ```lua
  {
    sequence = 1,
    chunk_id = 1,
    total_chunks = 3,
    metadata = {
      sample_rate = 4000,
      modulation = 'BPSK',
      frequency = 915000000
    },
    payload = { /* signal data array */ }
  }
  ```

#### 2. Message Chunking
- UDP packet size limit: ~1472 bytes (Ethernet MTU)
- Implement chunking for large signal data blocks
- Add sequence numbers for packet ordering
- Include reassembly logic on receiver side

#### 3. Required Dependencies
```bash
luarocks install luasocket
luarocks install lua-cjson  # or luajson, dkjson
# LuaRadio installation per platform requirements
```

#### 4. New Gabby Components to Implement

**radio_transmitter.lua** - LuaRadio signal generation and UDP JSON transmission
```lua
-- Should include:
-- - Signal source creation (square wave, sine wave, etc.)
-- - Modulation (BPSK, QPSK, FSK)
-- - JSON packaging with metadata
-- - UDP chunked transmission
-- - Integration with Gabby's peer discovery
```

**radio_receiver.lua** - UDP JSON reception and LuaRadio signal processing
```lua
-- Should include:
-- - UDP socket listening
-- - JSON parsing and validation
-- - Packet reassembly logic
-- - Signal demodulation
-- - Error handling for malformed packets
```

**radio_manager.lua** - Coordinate radio operations with main Gabby system
```lua
-- Should include:
-- - Radio peer capability announcement
-- - Command routing (radio_send, radio_listen, radio_peers)
-- - Integration with existing logger and config systems
```

#### 5. CLI Extensions
Add new commands to main.lua:
- `radio_peers` - List peers with radio capabilities
- `radio_send <ip> <port> <signal_type> <modulation>` - Send radio signal
- `radio_listen <port>` - Start radio receiver
- `radio_stop` - Stop radio operations
- `radio_config` - Show/set radio parameters

#### 6. Configuration Extensions
Extend config.lua with radio-specific settings:
```lua
radio_config = {
  default_port = 12346,  -- Separate from chat port
  chunk_size = 100,      -- Samples per UDP packet
  timeout = 0.1,         -- UDP socket timeout
  buffer_size = 1000,    -- Reassembly buffer size
  supported_modulations = {'BPSK', 'QPSK', 'FSK'},
  default_sample_rate = 4000
}
```

### Implementation Guidelines

#### Error Handling
- Wrap JSON parsing in pcall() for error safety
- Handle UDP socket timeouts gracefully  
- Validate packet sequence and chunk completeness
- Log radio errors through existing logger.lua

#### Performance Considerations
- Use non-blocking UDP sockets (settimeout(0))
- Implement circular buffers for packet reassembly
- Consider memory usage for large signal buffers
- Rate limiting for UDP transmission

#### Integration Points
- Extend discovery_service.lua to announce radio capabilities
- Reuse existing UDP socket infrastructure where possible
- Integrate with current peer management system
- Maintain consistent logging format

#### Code Style
- Follow existing Gabby Lua conventions
- Use local variables for performance
- Include comprehensive error messages
- Add inline documentation for complex radio operations

### Example Usage Flow
1. Peer A discovers Peer B has radio capabilities via enhanced UDP discovery
2. User runs: `radio_send 192.168.1.100 12346 square_wave BPSK`
3. Gabby creates LuaRadio flowgraph, modulates signal, chunks into JSON packets
4. Peer B receives UDP JSON packets, reassembles, demodulates via LuaRadio
5. Both peers log radio communication through existing logger

### Testing Strategy
- Test between two VMs with known IP addresses
- Verify JSON packet structure and chunking
- Test packet loss scenarios and reassembly
- Validate LuaRadio flowgraph creation and execution
- Ensure integration doesn't break existing chat functionality

## Key Implementation Notes for Copilot

When generating code:
- Always include proper error handling with pcall()
- Use Gabby's existing logger for all output
- Maintain non-blocking operation to preserve CLI responsiveness
- Follow the existing modular structure (separate .lua files)
- Include sequence numbers and chunk tracking
- Validate JSON structure before processing
- Use consistent variable naming with existing codebase