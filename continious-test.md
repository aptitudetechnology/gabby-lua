# GitHub Copilot Prompt: Create GabbyLua Multi-Machine Test Script

## Context
GabbyLua is a Lua P2P chat application with UDP peer discovery, TCP direct messaging, and the new UDP messaging feature. We need a comprehensive test script that can run on multiple machines to validate all messaging functionality with rich, colorful terminal output.

## Current GabbyLua Architecture
- **UDP Discovery**: Port 9001, JSON broadcasts for peer discovery
- **TCP Messaging**: Port 9002, direct reliable messaging
- **UDP Messaging**: Port 9003, JSON messages over UDP (new feature)
- **Dependencies**: luasocket, lua-cjson, ansicolors (for rich output)
- **Logging**: Structured logging to file and console

## Test Script Requirements

### File: `test_gabby.lua`
Create a standalone test script that validates GabbyLua functionality across multiple machines.

### Core Testing Features
1. **Automated Peer Discovery Testing**
   - Continuously broadcast and listen for peers
   - Display discovered peers in real-time with colors
   - Show peer connection status (online/offline)

2. **TCP Messaging Tests**
   - Send periodic test messages via TCP
   - Verify message delivery and responses
   - Test error handling (unreachable peers)

3. **UDP Messaging Tests** 
   - Send periodic JSON messages via UDP
   - Test different message types and sizes
   - Verify non-blocking operation

4. **Rich Terminal Display**
   - Use `ansicolors` library for colored output
   - Real-time status dashboard
   - Message logs with different colors for different types
   - Network statistics and health indicators

### Terminal UI Requirements

#### Color Scheme
```lua
-- Use ansicolors for rich display
local colors = require("ansicolors")
-- Discovery: cyan
-- TCP messages: green  
-- UDP messages: blue
-- Errors: red
-- Success: bright green
-- Warnings: yellow
-- Peer info: magenta
```

#### Display Layout (Updates Every Second)
```
═══════════════════════════════════════════════════════════════
        🚀 GabbyLua Continuous Network Test - Running 2h 15m 32s
═══════════════════════════════════════════════════════════════
[12:34:56] | Host: hostname | Discovery: ✓ | TCP: ✓ | UDP: ✓ | Uptime: 2h 15m

📡 DISCOVERED PEERS (3) - Auto-refresh every 5s:
  └─ 🟢 peer1 (192.168.1.100:9002) - Alive 2h 12m | Last ping: 847ms
  └─ 🟢 peer2 (192.168.1.101:9002) - Alive 1h 45m | Last ping: 623ms  
  └─ 🔴 peer3 (192.168.1.102:9002) - Lost 2m 15s ago | Retrying...

📨 CONTINUOUS MESSAGE STREAM (Last 10):
  [12:34:56] 🔵 UDP → peer1: {"ping": 1567, "seq": 245} | RTT: 45ms
  [12:34:55] 🟢 TCP ← peer2: {"pong": 1566, "status": "ok"} | RTT: 78ms
  [12:34:54] 🔵 UDP ← peer1: {"ping": 1565, "seq": 244} | Auto-reply sent
  [12:34:50] 🟢 TCP → peer2: {"ping": 1564, "test_id": "tcp_001"}

📊 CONTINUOUS STATS (Live counters):
  ⏱️  Runtime: 2h 15m 32s | Messages/min: TCP: 12, UDP: 18
  🔄 Discovery: 1,634 sent | 2,401 received | Peers found: 47 total
  🟢 TCP: 1,456 sent | 1,398 received | Success: 98.7% | Avg RTT: 124ms
  🔵 UDP: 2,234 sent | 2,187 received | Success: 97.9% | Avg RTT: 67ms
  ❌ Errors: 23 timeouts | 5 connection failures | Last error: 47s ago

🎯 ACTIVE CONTINUOUS TESTS:
  ✅ Discovery heartbeat every 5s | Next: 3s
  ✅ TCP ping/pong every 10s | Next: 7s  
  ✅ UDP message burst every 7s | Next: 2s
  ⏳ Long message test (1000 chars) | Running...
  📈 Performance monitoring | CPU: 2.3% | Memory: 45MB
```

### Continuous Test Scenarios
1. **Continuous Discovery Testing**
   - Broadcast discovery messages every 5 seconds
   - Monitor peer heartbeats and detect disconnections
   - Track peer uptime and availability over time

2. **Continuous Message Exchange**
   - Send TCP ping/pong messages every 10 seconds to all peers
   - Send UDP test messages every 7 seconds with sequence numbers
   - Automatic response generation to incoming test messages
   - Round-trip time measurements

3. **Long-Running Stress Testing**
   - Gradual ramp-up of message frequency over hours
   - Memory usage monitoring
   - Connection stability over extended periods
   - Automatic recovery from network interruptions

4. **24/7 Network Health Monitoring**
   - Continuous statistics collection
   - Peer availability tracking over time
   - Network partition detection and recovery
   - Performance degradation alerts

### Continuous Operation Architecture
```lua
-- test_gabby.lua continuous testing structure
local TestRunner = {
    peers = {},
    stats = {
        start_time = os.time(),
        discovery = {sent = 0, received = 0, peers_found = 0},
        tcp = {sent = 0, received = 0, errors = 0, total_rtt = 0},
        udp = {sent = 0, received = 0, errors = 0, total_rtt = 0}
    },
    display = {},
    continuous_tests = {},
    running = true
}

function TestRunner:start_continuous_tests()
    -- Coroutine 1: Discovery heartbeat every 5s
    -- Coroutine 2: TCP ping/pong every 10s to all peers
    -- Coroutine 3: UDP message bursts every 7s
    -- Coroutine 4: Display refresh every 1s
    -- Coroutine 5: Statistics collection every 30s
end

function TestRunner:continuous_discovery()
    while self.running do
        -- Broadcast discovery and listen
        -- Update peer status and last-seen times
        -- Detect peer timeouts (mark as offline after 30s)
        socket.sleep(5)
    end
end

function TestRunner:continuous_tcp_testing()
    while self.running do
        for peer_id, peer in pairs(self.peers) do
            -- Send ping, measure RTT, update stats
            -- Handle automatic pong responses
        end
        socket.sleep(10)
    end
end

function TestRunner:continuous_udp_testing()
    while self.running do
        for peer_id, peer in pairs(self.peers) do
            -- Send UDP test messages with sequence numbers
            -- Track delivery and responses
        end
        socket.sleep(7)
    end
end

function TestRunner:continuous_display_update()
    while self.running do
        -- Clear screen with os.execute("clear") or ansicolors
        -- Redraw entire dashboard with live data
        -- Show running counters and real-time stats
        socket.sleep(1)
    end
end
```

### Configuration Options for Continuous Testing
Allow test script configuration via command line for different continuous test profiles:
```bash
# Gentle continuous testing (default)
lua test_gabby.lua --mode=continuous --profile=gentle

# Stress testing mode - high frequency messaging  
lua test_gabby.lua --mode=continuous --profile=stress --duration=24h

# Network monitoring mode - focus on peer discovery and health
lua test_gabby.lua --mode=monitor --refresh=5s

# Multi-role testing - act as both sender and responder
lua test_gabby.lua --mode=full --auto-respond=true

# Specific peer testing - target specific machines
lua test_gabby.lua --mode=continuous --targets=192.168.1.100,192.168.1.101
```

### Automatic Response Handling
- When receiving TCP test messages, automatically send appropriate responses
- When receiving UDP test messages, send acknowledgments  
- Generate realistic test data and varied message content
- Implement ping/pong patterns for round-trip time measurement

### Statistics Persistence
- Save running statistics every 5 minutes to `test_results_TIMESTAMP.json`
- Track long-term trends: peer availability, message success rates, network performance
- Generate hourly/daily summaries
- Export data for analysis

### Clean Shutdown
- Handle Ctrl+C gracefully with `signal` handling if available
- Save final statistics report
- Display test summary with total runtime, messages sent/received, error rates
- Clean up all network resources

### Dependencies
- Ensure script can install: `luarocks install ansicolors`
- Use existing GabbyLua modules for actual networking
- Handle missing dependencies gracefully

### Message Types for Testing
```lua
-- Discovery test messages
{type = "discovery_test", hostname = hostname, timestamp = os.time()}

-- TCP test messages  
{type = "tcp_test", message = "ping", id = test_id, timestamp = os.time()}

-- UDP test messages
{type = "udp_test", payload = "test_data", size = 256, id = test_id}
```

### Error Handling
- Gracefully handle network failures
- Continue testing even if some peers are unreachable
- Display clear error messages with red coloring
- Log all test results for post-analysis

### Success Criteria
- All peers discovered within 10 seconds
- TCP messages delivered with <1s latency
- UDP messages sent without errors
- Rich display updates smoothly without flickering
- Clean shutdown on Ctrl+C

## Output Requirements
Create a script that provides visual confirmation that GabbyLua networking works perfectly across multiple machines with beautiful, informative real-time display that makes network testing engaging and clear.