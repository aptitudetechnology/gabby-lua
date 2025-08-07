# Refactoring Gabby from Go to Lua: Complete Guide

## Project Overview
Refactor the existing Go-based P2P chat application "Gabby" to Lua while maintaining all core functionality and improving where possible.

## Core Requirements

### 1. Maintain Existing Features
- **Peer Discovery**: UDP broadcast mechanism for automatic peer discovery on local network
- **Direct Messaging**: TCP-based reliable message delivery between peers
- **Command-line Interface**: Interactive CLI for user interaction
- **Peer Management**: Track discovered peers with IP, port, and hostname

### 2. Lua-Specific Considerations

#### Dependencies and Libraries
- Use **LuaSocket** for networking (UDP/TCP operations)
- Consider **lua-cjson** or similar for message encoding/decoding
- Use **luafilesystem** if file operations are needed
- Implement proper module structure with `require()` statements

#### Language Adaptations
- Convert Go's struct types to Lua tables
- Replace Go's goroutines with Lua coroutines or threading library
- Adapt Go's error handling (`panicIfErrPresent`) to Lua's `pcall/xpcall` pattern
- Convert Go's maps to Lua tables with proper key-value structure

### 3. File Structure Translation

Convert the existing Go files to Lua equivalents:

```
gabby-lua/
├── main.lua                 -- Entry point (from main.go)
├── discovery_service.lua    -- UDP broadcast logic (from discovery-service.go)
├── message_listener.lua     -- TCP message receiving (from message-listener.go)
├── message_writer.lua       -- TCP message sending (from message-writer.go)
├── logger.lua              -- Custom logging system (from logger.go)
├── config.lua              -- Configuration constants
└── README.md               -- Updated documentation
```

## Implementation Details

### 4. Core Components to Implement

#### Discovery Service (`discovery_service.lua`)
```lua
-- Implement these key functions:
-- broadcast_message(port, hostname)
-- listen_for_broadcast_messages()
-- encode_message(port, hostname) 
-- decode_message(buffer)
```

#### Peer Management
```lua
-- Convert Go's hostInfo struct to Lua table:
local peer_info = {
    ip = "192.168.1.100",
    port = 8080,
    name = "hostname"
}

-- Convert Go's global map to Lua table:
local gabby_discovered = {}
```

#### Message Handling
```lua
-- TCP message sending and receiving
-- Error handling with pcall/xpcall
-- Connection management with proper cleanup
```

#### Custom Logger (`logger.lua`)
```lua
-- Implement log levels: DEBUG, INFO, ERROR
-- Custom formatting and output control
-- File and console output options
```

### 5. Networking Implementation

#### UDP Broadcasting
- Use LuaSocket's UDP functionality
- Implement broadcast address resolution
- Handle network interface discovery for broadcast

#### TCP Messaging  
- Establish reliable TCP connections
- Implement message framing if needed
- Handle connection timeouts and errors gracefully

### 6. Concurrency Strategy

Choose one approach for handling concurrent operations:

**Option A: Coroutines**
- Use Lua's native coroutine system
- Implement cooperative multitasking
- Handle UDP listening and CLI input concurrently

**Option B: Threading Library**
- Use `lanes` or similar Lua threading library
- Separate threads for network operations and UI
- Proper synchronization between threads

### 7. Error Handling Improvements

Replace Go's panic-based error handling with Lua best practices:
```lua
local function safe_network_call(operation, ...)
    local success, result = pcall(operation, ...)
    if not success then
        logger:error("Network operation failed: " .. result)
        return nil, result
    end
    return result
end
```

### 8. Configuration Management

Create `config.lua` for:
- Default ports and network settings
- Buffer sizes and timeouts
- Logging levels and output formats
- Application constants

### 9. Enhanced Features to Consider

#### Improvements over Go version:
- **Graceful shutdown**: Proper cleanup of network resources
- **Peer health checking**: Implement heartbeat mechanism
- **Message history**: Store recent messages
- **Configuration file**: External config file support
- **Better CLI**: Enhanced command parsing and help system

#### Security considerations:
- Input validation for network messages
- Basic message sanitization
- Network address validation

### 10. Testing Strategy

Implement basic testing:
- Unit tests for core functions
- Network simulation for discovery testing
- Error condition handling verification

## Development Phases

### Phase 1: Foundation
1. Set up Lua environment with required dependencies
2. Implement basic logger and configuration system
3. Create core module structure

### Phase 2: Networking Core
1. Implement UDP broadcast discovery
2. Create TCP message handling
3. Develop peer management system

### Phase 3: User Interface
1. Build CLI interface
2. Implement command parsing
3. Add user interaction features

### Phase 4: Integration & Testing
1. Integration testing of all components
2. Error handling and edge case testing
3. Performance optimization

### Phase 5: Enhancement
1. Add improved features beyond Go version
2. Documentation and code cleanup
3. Deployment preparation

## Success Criteria

The Lua version should:
- ✅ Maintain feature parity with Go version
- ✅ Run on standard Lua 5.3+ installations
- ✅ Handle network operations reliably
- ✅ Provide clear error messages and logging
- ✅ Support the same P2P chat functionality
- ✅ Include proper documentation and setup instructions

## Additional Considerations

- **Cross-platform compatibility**: Ensure it works on Linux, macOS, and Windows
- **Memory management**: Proper cleanup of network resources
- **Performance**: Optimize for local network operations
- **Maintainability**: Clear code structure and documentation
- **Extensibility**: Design for future feature additions

This refactoring should result in a fully functional Lua-based P2P chat application that maintains the simplicity and effectiveness of the original Go version while taking advantage of Lua's strengths and ecosystem.