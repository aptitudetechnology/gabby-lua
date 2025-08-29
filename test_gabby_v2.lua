#!/usr/bin/env lua
-- test_gabby_v2.lua
-- Enhanced continuous test script for GabbyLua P2P chat

local socket = require("socket")
local json = require("cjson")
local colors = require("ansicolors")

-- Import GabbyLua modules
local config = require("config")
local logger = require("logger")
local message_writer = require("message_writer")

-- Configuration with fallbacks
local TEST_CONFIG = {
    DISCOVERY_INTERVAL = 5,
    TCP_TEST_INTERVAL = 10,
    UDP_TEST_INTERVAL = 7,
    DISPLAY_REFRESH = 1,
    PEER_TIMEOUT = 30,
    UDP_DISCOVERY_PORT = config.UDP_PORT or 9001,
    TCP_MESSAGE_PORT = config.TCP_PORT or 9002,
    UDP_MESSAGE_PORT = 9003,
    MAX_MESSAGE_LOG = 10,
    MAX_PEERS_DISPLAY = 5
}

-- Test runner state
local TestRunner = {
    start_time = os.time(),
    hostname = socket.dns.gethostname() or "unknown",
    peers = {},
    stats = {
        discovery = {sent = 0, received = 0, peers_found = 0, dupes = 0, errors = 0},
        tcp = {sent = 0, received = 0, success = 0, errors = 0, total_rtt = 0},
        udp = {sent = 0, received = 0, success = 0, errors = 0, total_rtt = 0}
    },
    message_log = {},
    running = true,
    test_sequence = 0,
    sockets = {},
    peer_lock = {}
}

-- Improved colorization
local function colorize(color, text)
    return colors("%{bright}" .. color .. text .. "%{reset}")
end

-- Message logging system
local function log_message(type, direction, peer, message, rtt)
    local timestamp = os.date("[%H:%M:%S]")
    local color_map = {
        discovery = "%{cyan}",
        tcp = "%{green}",
        udp = "%{blue}",
        error = "%{red}"
    }
    
    local icons = {
        discovery = "📡",
        tcp = "🟢",
        udp = "🔵",
        error = "❌"
    }
    
    local arrow = direction == "sent" and "→" or "←"
    local rtt_str = rtt and string.format(" | RTT: %dms", rtt) or ""
    local log_entry = {
        timestamp = timestamp,
        type = type,
        direction = direction,
        peer = peer,
        message = message,
        rtt = rtt,
        formatted = string.format("%s %s %s %s %s: %s%s", 
            timestamp, 
            icons[type] or "📝",
            colorize(color_map[type] or "%{white}", type:upper()),
            arrow,
            peer,
            message,
            rtt_str
        )
    }
    
    table.insert(TestRunner.message_log, 1, log_entry)
    if #TestRunner.message_log > TEST_CONFIG.MAX_MESSAGE_LOG then
        table.remove(TestRunner.message_log)
    end
end

-- Enhanced utilities
local function get_uptime()
    return os.time() - TestRunner.start_time
end

local function format_uptime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds/60), seconds%60)
    else
        return string.format("%dh %dm", math.floor(seconds/3600), math.floor((seconds%3600)/60))
    end
end

local function get_local_ip()
    local udp = socket.udp()
    udp:setpeername("8.8.8.8", 53)
    local ip, _ = udp:getsockname()
    udp:close()
    return ip or "127.0.0.1"
end

local function log_message(type, direction, peer, message, rtt)
    local timestamp = os.date("[%H:%M:%S]")
    local color_map = {
        discovery = "%{cyan}",
        tcp = "%{green}",
        udp = "%{blue}",
        error = "%{red}"
    }
    
    local arrow = direction == "sent" and "→" or "←"
    local rtt_str = rtt and string.format(" | RTT: %dms", rtt) or ""
    local log_entry = {
        timestamp = timestamp,
        type = type,
        direction = direction,
        peer = peer,
        message = message,
        rtt = rtt,
        formatted = string.format("%s %s%s%s %s: %s%s", 
            timestamp, 
            color_map[type] or "%{white}",
            type:upper(),
            "%{reset}",
            arrow,
            peer,
            message,
            rtt_str
        )
    }
    
    table.insert(TestRunner.message_log, 1, log_entry)
    if #TestRunner.message_log > TEST_CONFIG.MAX_MESSAGE_LOG then
        table.remove(TestRunner.message_log)
    end
end

-- Socket initialization with error handling
local function init_sockets()
    -- UDP Discovery
    local ok, err = xpcall(function()
        TestRunner.sockets.discovery_send = socket.udp()
        TestRunner.sockets.discovery_send:setsockname("*", 0)
        TestRunner.sockets.discovery_send:setoption("broadcast", true)
        TestRunner.sockets.discovery_send:settimeout(0)
        
        TestRunner.sockets.discovery_recv = socket.udp()
        TestRunner.sockets.discovery_recv:setsockname("*", TEST_CONFIG.UDP_DISCOVERY_PORT)
        TestRunner.sockets.discovery_recv:settimeout(0)
    end, debug.traceback)

    if not ok then
        logger.error("Discovery socket init failed: " .. (err or "unknown"))
    end

    -- UDP Messaging
    ok, err = xpcall(function()
        TestRunner.sockets.udp_msg_send = socket.udp()
        TestRunner.sockets.udp_msg_send:setsockname("*", 0)
        TestRunner.sockets.udp_msg_send:settimeout(0)
        
        TestRunner.sockets.udp_msg_recv = socket.udp()
        TestRunner.sockets.udp_msg_recv:setsockname("*", TEST_CONFIG.UDP_MESSAGE_PORT)
        TestRunner.sockets.udp_msg_recv:settimeout(0)
    end, debug.traceback)

    if not ok then
        logger.error("UDP messaging socket init failed: " .. (err or "unknown"))
    end

    logger.info("Test sockets initialized")
end

-- Peer management with deduplication
local function update_peer(ip, port, peer_data)
    local peer_id = ip .. ":" .. port
    
    -- Prevent duplicate processing
    if TestRunner.peer_lock[peer_id] and TestRunner.peer_lock[peer_id] > os.time() - 1 then
        TestRunner.stats.discovery.dupes = TestRunner.stats.discovery.dupes + 1
        return
    end
    
    TestRunner.peer_lock[peer_id] = os.time()
    
    if not TestRunner.peers[peer_id] then
        TestRunner.peers[peer_id] = {
            ip = ip,
            port = port,
            first_seen = os.time(),
            last_seen = os.time(),
            hostname = peer_data.hostname or "unknown",
            status = "online"
        }
        TestRunner.stats.discovery.peers_found = TestRunner.stats.discovery.peers_found + 1
        log_message("discovery", "received", peer_id, "New peer discovered", nil)
    else
        TestRunner.peers[peer_id].last_seen = os.time()
        TestRunner.peers[peer_id].status = "online"
    end
end

local function check_peer_timeouts()
    local current_time = os.time()
    for peer_id, peer in pairs(TestRunner.peers) do
        if current_time - peer.last_seen > TEST_CONFIG.PEER_TIMEOUT then
            if peer.status == "online" then
                peer.status = "offline"
                log_message("discovery", "received", peer_id, "Peer timed out", nil)
            end
        end
    end
end

-- Robust discovery service
local function send_discovery_broadcast()
    local discovery_msg = {
        type = "discovery_test",
        hostname = TestRunner.hostname,
        ip = get_local_ip(),
        port = TEST_CONFIG.TCP_MESSAGE_PORT,
        timestamp = os.time(),
        test_id = "discovery_" .. TestRunner.test_sequence
    }
    
    local msg_json = json.encode(discovery_msg)
    local sent, err = TestRunner.sockets.discovery_send:sendto(msg_json, "255.255.255.255", TEST_CONFIG.UDP_DISCOVERY_PORT)
    
    if sent then
        TestRunner.stats.discovery.sent = TestRunner.stats.discovery.sent + 1
        log_message("discovery", "sent", "broadcast", "Discovery ping", nil)
    else
        TestRunner.stats.discovery.errors = TestRunner.stats.discovery.errors + 1
        log_message("error", "sent", "broadcast", "Discovery failed: " .. (err or "unknown"), nil)
    end
end

local function listen_discovery()
    local msg, ip, port = TestRunner.sockets.discovery_recv:receivefrom()
    if msg then
        TestRunner.stats.discovery.received = TestRunner.stats.discovery.received + 1
        local ok, peer_data = pcall(json.decode, msg)
        if ok and peer_data.type == "discovery_test" then
            update_peer(ip, peer_data.port or TEST_CONFIG.TCP_MESSAGE_PORT, peer_data)
        end
    end
end

-- TCP testing with better error handling
local function send_tcp_test(peer_id, peer)
    TestRunner.test_sequence = TestRunner.test_sequence + 1
    local test_msg = {
        type = "tcp_test",
        message = "ping",
        test_id = "tcp_" .. TestRunner.test_sequence,
        timestamp = os.time(),
        from = TestRunner.hostname
    }
    
    local start_time = socket.gettime()
    local success, err = message_writer.send_message(peer.ip, peer.port, json.encode(test_msg))
    local rtt = math.floor((socket.gettime() - start_time) * 1000)
    
    if success then
        TestRunner.stats.tcp.sent = TestRunner.stats.tcp.sent + 1
        TestRunner.stats.tcp.success = TestRunner.stats.tcp.success + 1
        TestRunner.stats.tcp.total_rtt = TestRunner.stats.tcp.total_rtt + rtt
        log_message("tcp", "sent", peer_id, "Ping test message", rtt)
    else
        TestRunner.stats.tcp.sent = TestRunner.stats.tcp.sent + 1
        TestRunner.stats.tcp.errors = TestRunner.stats.tcp.errors + 1
        log_message("error", "sent", peer_id, "TCP failed: " .. (err or "unknown"), nil)
    end
end

-- UDP testing with proper cleanup
local function send_udp_test(peer_id, peer)
    TestRunner.test_sequence = TestRunner.test_sequence + 1
    local test_msg = {
        type = "udp_test",
        payload = "test_data",
        size = 256,
        test_id = "udp_" .. TestRunner.test_sequence,
        timestamp = os.time(),
        from = TestRunner.hostname
    }
    
    local start_time = socket.gettime()
    local sent, err = TestRunner.sockets.udp_msg_send:sendto(json.encode(test_msg), peer.ip, TEST_CONFIG.UDP_MESSAGE_PORT)
    local rtt = math.floor((socket.gettime() - start_time) * 1000)
    
    if sent then
        TestRunner.stats.udp.sent = TestRunner.stats.udp.sent + 1
        TestRunner.stats.udp.success = TestRunner.stats.udp.success + 1
        TestRunner.stats.udp.total_rtt = TestRunner.stats.udp.total_rtt + rtt
        log_message("udp", "sent", peer_id, "UDP test message", rtt)
    else
        TestRunner.stats.udp.sent = TestRunner.stats.udp.sent + 1
        TestRunner.stats.udp.errors = TestRunner.stats.udp.errors + 1
        log_message("error", "sent", peer_id, "UDP failed: " .. (err or "unknown"), nil)
    end
end

local function listen_udp_messages()
    local msg, ip, port = TestRunner.sockets.udp_msg_recv:receivefrom()
    if msg then
        TestRunner.stats.udp.received = TestRunner.stats.udp.received + 1
        local ok, test_data = pcall(json.decode, msg)
        if ok and test_data.type == "udp_test" then
            log_message("udp", "received", ip .. ":" .. port, "UDP test message", nil)
        end
    end
end

-- Enhanced display system
local function clear_screen()
    io.write("\027[H\027[2J")
end

local function draw_header()
    local uptime = get_uptime()
    
    print(colorize("%{white}", string.rep("═", 80)))
    print(colorize("%{cyan}", string.format("        🚀 GabbyLua Network Test - Running %s", format_uptime(uptime))))
    print(colorize("%{white}", string.rep("═", 80)))
    
    local status_tcp = TestRunner.stats.tcp.sent > 0 and TestRunner.stats.tcp.errors < TestRunner.stats.tcp.sent and "✓" or "✗"
    local status_udp = TestRunner.stats.udp.sent > 0 and TestRunner.stats.udp.errors < TestRunner.stats.udp.sent and "✓" or "✗"
    local status_discovery = TestRunner.stats.discovery.sent > 0 and "✓" or "✗"
    
    print(string.format("[%s] | Host: %s | Discovery: %s | TCP: %s | UDP: %s | Uptime: %s",
        os.date("%H:%M:%S"),
        TestRunner.hostname,
        colorize(status_discovery == "✓" and "%{green}" or "%{red}", status_discovery),
        colorize(status_tcp == "✓" and "%{green}" or "%{red}", status_tcp),
        colorize(status_udp == "✓" and "%{green}" or "%{red}", status_udp),
        format_uptime(uptime)
    ))
    print()
end

local function draw_peers()
    local online_count = 0
    local offline_count = 0
    for _, peer in pairs(TestRunner.peers) do
        if peer.status == "online" then online_count = online_count + 1 end
        if peer.status == "offline" then offline_count = offline_count + 1 end
    end
    
    print(colorize("%{blue}", string.format("📡 DISCOVERED PEERS (%d online, %d offline) - Refresh every %ds:",
        online_count, offline_count, TEST_CONFIG.DISCOVERY_INTERVAL)))
    
    if online_count + offline_count == 0 then
        print(colorize("%{yellow}", "  └─ No peers discovered yet..."))
    else
        local displayed = 0
        for peer_id, peer in pairs(TestRunner.peers) do
            if displayed >= TEST_CONFIG.MAX_PEERS_DISPLAY then
                print(colorize("%{yellow}", string.format("  └─ ... and %d more peers", 
                    (online_count + offline_count) - TEST_CONFIG.MAX_PEERS_DISPLAY)))
                break
            end
            
            local status_icon = peer.status == "online" and "🟢" or "🔴"
            local alive_time = format_uptime(os.time() - peer.first_seen)
            local last_seen = peer.status == "online" and "Active" or string.format("Lost %ds ago", os.time() - peer.last_seen)
            
            print(string.format("  └─ %s %s (%s) - %s %s", 
                status_icon,
                peer.hostname,
                peer_id,
                last_seen,
                peer.status == "online" and "| Alive " .. alive_time or "| Last seen " .. format_uptime(os.time() - peer.last_seen)
            ))
            displayed = displayed + 1
        end
    end
    print()
end

local function draw_messages()
    print(colorize("%{magenta}", string.format("📨 CONTINUOUS MESSAGE STREAM (Last %d):", TEST_CONFIG.MAX_MESSAGE_LOG)))
    
    if #TestRunner.message_log == 0 then
        print(colorize("%{yellow}", "  └─ No messages yet..."))
    else
        for i, log_entry in ipairs(TestRunner.message_log) do
            print("  " .. log_entry.formatted)
        end
    end
    print()
end

local function draw_stats()
    local uptime = get_uptime()
    local tcp_avg_rtt = TestRunner.stats.tcp.success > 0 and math.floor(TestRunner.stats.tcp.total_rtt / TestRunner.stats.tcp.success) or 0
    local udp_avg_rtt = TestRunner.stats.udp.success > 0 and math.floor(TestRunner.stats.udp.total_rtt / TestRunner.stats.udp.success) or 0
    local tcp_success_rate = TestRunner.stats.tcp.sent > 0 and (TestRunner.stats.tcp.success / TestRunner.stats.tcp.sent * 100) or 0
    local udp_success_rate = TestRunner.stats.udp.sent > 0 and (TestRunner.stats.udp.success / TestRunner.stats.udp.sent * 100) or 0
    
    print(colorize("%{green}", "📊 CONTINUOUS STATS (Live counters):"))
    print(string.format("  ⏱️  Runtime: %s | TCP: %d sent | UDP: %d sent | Discovered: %d peers",
        format_uptime(uptime),
        TestRunner.stats.tcp.sent,
        TestRunner.stats.udp.sent,
        TestRunner.stats.discovery.peers_found
    ))
    print(string.format("  🔄 Discovery: %d sent | %d received | %d dupes | Errors: %d",
        TestRunner.stats.discovery.sent,
        TestRunner.stats.discovery.received,
        TestRunner.stats.discovery.dupes,
        TestRunner.stats.discovery.errors
    ))
    print(string.format("  🟢 TCP: %d sent | %d received | Success: %.1f%% | Avg RTT: %dms | Errors: %d",
        TestRunner.stats.tcp.sent,
        TestRunner.stats.tcp.received,
        tcp_success_rate,
        tcp_avg_rtt,
        TestRunner.stats.tcp.errors
    ))
    print(string.format("  🔵 UDP: %d sent | %d received | Success: %.1f%% | Avg RTT: %dms | Errors: %d",
        TestRunner.stats.udp.sent,
        TestRunner.stats.udp.received,
        udp_success_rate,
        udp_avg_rtt,
        TestRunner.stats.udp.errors
    ))
    print()
end

local function draw_active_tests()
    print(colorize("%{yellow}", "🎯 ACTIVE CONTINUOUS TESTS:"))
    print(string.format("  ✅ Discovery heartbeat every %ds", TEST_CONFIG.DISCOVERY_INTERVAL))
    print(string.format("  ✅ TCP ping/pong every %ds", TEST_CONFIG.TCP_TEST_INTERVAL))
    print(string.format("  ✅ UDP message test every %ds", TEST_CONFIG.UDP_TEST_INTERVAL))
    print("  📈 Performance monitoring | " .. colorize("%{green}", "Running..."))
    print()
    print(colorize("%{yellow}", "Press Ctrl+C to stop and see final report"))
end

local function update_display()
    clear_screen()
    draw_header()
    draw_peers()
    draw_messages()
    draw_stats()
    draw_active_tests()
endtime = uptime
    
    print(colorize("%{bright}%{white}", string.rep("═", 80)))
    print(colorize("%{bright}%{cyan}", string.format("        🚀 GabbyLua Continuous Network Test - Running %s", format_uptime(uptime))))
    print(colorize("%{bright}%{white}", string.rep("═", 80)))
    
    local status_tcp = TestRunner.stats.tcp.sent > 0 and TestRunner.stats.tcp.errors < TestRunner.stats.tcp.sent and "✓" or "✗"
    local status_udp = TestRunner.stats.udp.sent > 0 and TestRunner.stats.udp.errors < TestRunner.stats.udp.sent and "✓" or "✗"
    local status_discovery = TestRunner.stats.discovery.sent > 0 and "✓" or "✗"
    
    print(string.format("[%s] | Host: %s | Discovery: %s | TCP: %s | UDP: %s | Uptime: %s",
        os.date("%H:%M:%S"),
        TestRunner.hostname,
        colorize(status_discovery == "✓" and "%{green}" or "%{red}", status_discovery),
        colorize(status_tcp == "✓" and "%{green}" or "%{red}", status_tcp),
        colorize(status_udp == "✓" and "%{green}" or "%{red}", status_udp),
        format_uptime(uptime)
    ))
    print()
end

local function draw_peers()
    local peer_count = 0
    for _, peer in pairs(TestRunner.peers) do
        if peer.status == "online" then peer_count = peer_count + 1 end
    end
    
    print(colorize("%{bright}%{blue}", string.format("📡 DISCOVERED PEERS (%d) - Auto-refresh every %ds:", peer_count, TEST_CONFIG.DISCOVERY_INTERVAL)))
    
    if peer_count == 0 then
        print(colorize("%{yellow}", "  └─ No active peers discovered yet..."))
    else
        for peer_id, peer in pairs(TestRunner.peers) do
            local status_icon = peer.status == "online" and "🟢" or "🔴"
            local alive_time = format_uptime(os.time() - peer.first_seen)
            local last_seen = peer.status == "online" and "Active" or string.format("Lost %ds ago", os.time() - peer.last_seen)
            
            print(string.format("  └─ %s %s (%s) - %s %s", 
                status_icon,
                peer.hostname,
                peer_id,
                last_seen,
                peer.status == "online" and "| Alive " .. alive_time or "| Retrying..."
            ))
        end
    end
    print()
end

local function draw_messages()
    print(colorize("%{bright}%{magenta}", string.format("📨 CONTINUOUS MESSAGE STREAM (Last %d):", TEST_CONFIG.MAX_MESSAGE_LOG)))
    
    if #TestRunner.message_log == 0 then
        print(colorize("%{yellow}", "  └─ No messages yet..."))
    else
        for i, log_entry in ipairs(TestRunner.message_log) do
            print("  " .. log_entry.formatted)
        end
    end
    print()
end

local function draw_stats()
    local uptime = TestRunner.stats.uptime
    local tcp_avg_rtt = TestRunner.stats.tcp.success > 0 and math.floor(TestRunner.stats.tcp.total_rtt / TestRunner.stats.tcp.success) or 0
    local udp_avg_rtt = TestRunner.stats.udp.success > 0 and math.floor(TestRunner.stats.udp.total_rtt / TestRunner.stats.udp.success) or 0
    local tcp_success_rate = TestRunner.stats.tcp.sent > 0 and (TestRunner.stats.tcp.success / TestRunner.stats.tcp.sent * 100) or 0
    local udp_success_rate = TestRunner.stats.udp.sent > 0 and (TestRunner.stats.udp.success / TestRunner.stats.udp.sent * 100) or 0
    
    print(colorize("%{bright}%{green}", "📊 CONTINUOUS STATS (Live counters):"))
    print(string.format("  ⏱️  Runtime: %s | TCP: %d sent | UDP: %d sent | Discovered: %d peers",
        format_uptime(uptime),
        TestRunner.stats.tcp.sent,
        TestRunner.stats.udp.sent,
        TestRunner.stats.discovery.peers_found
    ))
    print(string.format("  🔄 Discovery: %d sent | %d received | Errors: %d",
        TestRunner.stats.discovery.sent,
        TestRunner.stats.discovery.received,
        TestRunner.stats.discovery.errors
    ))
    print(string.format("  🟢 TCP: %d sent | %d received | Success: %.1f%% | Avg RTT: %dms | Errors: %d",
        TestRunner.stats.tcp.sent,
        TestRunner.stats.tcp.received,
        tcp_success_rate,
        tcp_avg_rtt,
        TestRunner.stats.tcp.errors
    ))
    print(string.format("  🔵 UDP: %d sent | %d received | Success: %.1f%% | Avg RTT: %dms | Errors: %d",
        TestRunner.stats.udp.sent,
        TestRunner.stats.udp.received,
        udp_success_rate,
        udp_avg_rtt,
        TestRunner.stats.udp.errors
    ))
    print()
end

local function draw_active_tests()
    print(colorize("%{bright}%{yellow}", "🎯 ACTIVE CONTINUOUS TESTS:"))
    print(string.format("  ✅ Discovery heartbeat every %ds", TEST_CONFIG.DISCOVERY_INTERVAL))
    print(string.format("  ✅ TCP ping/pong every %ds", TEST_CONFIG.TCP_TEST_INTERVAL))
    print(string.format("  ✅ UDP message test every %ds", TEST_CONFIG.UDP_TEST_INTERVAL))
    print("  📈 Performance monitoring | " .. colorize("%{green}", "Running..."))
    print()
    print(colorize("%{yellow}", "Press Ctrl+C to stop and see final report"))
end

local function update_display()
    clear_screen()
    draw_header()
    draw_peers()
    draw_messages()
    draw_stats()
    draw_active_tests()
end

-- Main test loops with timing
local last_discovery = 0
local last_tcp_test = 0
local last_udp_test = 0
local last_display = 0

local function run_continuous_tests()
    local current_time = socket.gettime()
    
    -- Discovery heartbeat
    if current_time - last_discovery >= TEST_CONFIG.DISCOVERY_INTERVAL then
        send_discovery_broadcast()
        last_discovery = current_time
    end
    
    -- Check for incoming discovery messages
    listen_discovery()
    
    -- TCP testing
    if current_time - last_tcp_test >= TEST_CONFIG.TCP_TEST_INTERVAL then
        for peer_id, peer in pairs(TestRunner.peers) do
            if peer.status == "online" then
                send_tcp_test(peer_id, peer)
            end
        end
        last_tcp_test = current_time
    end
    
    -- UDP messaging testing
    if current_time - last_udp_test >= TEST_CONFIG.UDP_TEST_INTERVAL then
        for peer_id, peer in pairs(TestRunner.peers) do
            if peer.status == "online" then
                send_udp_test(peer_id, peer)
            end
        end
        last_udp_test = current_time
    end
    
    -- Check for incoming UDP messages
    listen_udp_messages()
    
    -- Display refresh
    if current_time - last_display >= TEST_CONFIG.DISPLAY_REFRESH then
        check_peer_timeouts()
        update_display()
        last_display = current_time
    end
end

-- Signal handling for clean shutdown
local function setup_signal_handler()
    -- This is a simple approach - in production you might want more sophisticated signal handling
    local function cleanup()
        TestRunner.running = false
        clear_screen()
        print(colorize("%{bright}%{green}", "🏁 GabbyLua Continuous Test - Final Report"))
        print(colorize("%{bright}%{white}", string.rep("═", 60)))
        print(string.format("Total Runtime: %s", format_uptime(get_uptime())))
        print(string.format("Peers Discovered: %d", TestRunner.stats.discovery.peers_found))
        print(string.format("TCP Messages: %d sent, %d errors (%.1f%% success)", 
            TestRunner.stats.tcp.sent, 
            TestRunner.stats.tcp.errors,
            TestRunner.stats.tcp.sent > 0 and ((TestRunner.stats.tcp.sent - TestRunner.stats.tcp.errors) / TestRunner.stats.tcp.sent * 100) or 0
        ))
        print(string.format("UDP Messages: %d sent, %d errors (%.1f%% success)", 
            TestRunner.stats.udp.sent, 
            TestRunner.stats.udp.errors,
            TestRunner.stats.udp.sent > 0 and ((TestRunner.stats.udp.sent - TestRunner.stats.udp.errors) / TestRunner.stats.udp.sent * 100) or 0
        ))
        print(colorize("%{bright}%{cyan}", "Thank you for testing GabbyLua! 🚀"))
        
        -- Close sockets
        for name, sock in pairs(TestRunner.sockets) do
            if sock then sock:close() end
        end
        
        logger.close()
        os.exit(0)
    end
    
    -- Set up basic Ctrl+C handling
    signal = pcall(require, "signal")
    if signal then
        signal.signal(signal.SIGINT, cleanup)
    end
    
    return cleanup
end

-- Main execution
local function main()
    print(colorize("%{bright}%{green}", "🚀 Starting GabbyLua Continuous Test..."))
    print(colorize("%{yellow}", "Installing ansicolors if needed..."))
    os.execute("luarocks install ansicolors --quiet 2>/dev/null")
    
    local cleanup = setup_signal_handler()
    
    -- Initialize
    init_sockets()
    
    print(colorize("%{green}", "✅ Test environment ready!"))
    print(colorize("%{cyan}", "Testing TCP (implemented), Discovery & UDP messaging (not implemented yet)"))
    print(colorize("%{yellow}", "Press Ctrl+C to stop"))
    socket.sleep(2)
    
    -- Main test loop
    while TestRunner.running do
        local ok, err = pcall(run_continuous_tests)
        if not ok then
            logger.error("Test loop error: " .. tostring(err))
            socket.sleep(1)
        else
            socket.sleep(0.1) -- Small sleep to prevent excessive CPU usage
        end
    end
    
    cleanup()
end

-- Execute
main()