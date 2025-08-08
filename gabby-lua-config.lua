-- config.lua: Configuration file for gabby-lua, a P2P chat application with planned SDR and modem testing capabilities.
-- This file defines settings for TCP-based messaging, UDP-based peer discovery and messaging, logging, and a plug-in architecture
-- for Software-Defined Radio (SDR) support. The SDR plug-in functionality, including dynamic loading of SDR modules (e.g., RTL-SDR,
-- HackRF, custom modem) for JSON-over-UDP signal transmission, is planned but not yet implemented. Existing chat functionality
-- (peer discovery, direct messaging, CLI) is fully supported, with UDP messaging and SDR features to be added in future updates.

local config = {
    -- TCP settings for legacy and JSON-based chat messaging
    TCP_PORT = 12345, -- Port for TCP message listener (message_listener.lua)

    -- UDP settings for peer discovery
    UDP_DISCOVERY_PORT = 12346, -- Port for UDP broadcast peer discovery (discovery_service.lua)

    -- UDP settings for JSON-based messaging (chat and SDR/modem)
    UDP_MESSAGE_PORT = 12347, -- Port for UDP JSON message listener (discovery_service.lua)

    -- Message size limits (for UDP to avoid fragmentation)
    MAX_UDP_MESSAGE_SIZE = 1400, -- Max bytes for UDP packets (safe limit for JSON payloads)

    -- Logging settings
    LOG_LEVEL = "info", -- Options: "debug", "info", "warn", "error"
    LOG_FILE = "gabby.log", -- Log file path for logger.lua

    -- SDR/modem-specific settings
    DEFAULT_SDR_PLUGIN = "rtl-sdr", -- Default SDR plug-in to use if not specified
    MAX_SIGNAL_PAYLOAD = 1000000, -- Max bytes for SDR signal payload (before chunking)

    -- Timeout and retry settings for UDP reliability (for SDR/modem)
    UDP_ACK_TIMEOUT = 1.0, -- Seconds to wait for acknowledgment
    UDP_MAX_RETRIES = 3, -- Max retry attempts for unacknowledged UDP messages

    -- Peer discovery settings
    DISCOVERY_INTERVAL = 5, -- Seconds between UDP broadcast pings
    PEER_TIMEOUT = 30, -- Seconds before a peer is considered inactive

    -- SDR plug-in configurations
    SDR_PLUGINS = {
        ["rtl-sdr"] = {
            name = "RTL-SDR",
            module = "sdr_rtlsdr", -- Lua module name (e.g., sdr_rtlsdr.lua)
            sample_rate = 44100, -- Hz
            modulation = "AM", -- Modulation type
            frequency = 100000000, -- 100 MHz
            bandwidth = 200000, -- 200 kHz
            protocol = "standard", -- Protocol or mode
            description = "Low-cost USB RTL-SDR for general-purpose radio",
            init_function = "init", -- Function to initialize plug-in
            send_function = "send_signal", -- Function to send signal data
            params = { -- Additional plug-in-specific parameters
                gain = 20, -- dB
                device_index = 0 -- Index for multiple RTL-SDR devices
            }
        },
        ["hackrf"] = {
            name = "HackRF One",
            module = "sdr_hackrf", -- Lua module name (e.g., sdr_hackrf.lua)
            sample_rate = 1000000, -- 1 MHz
            modulation = "FM",
            frequency = 900000000, -- 900 MHz
            bandwidth = 1000000, -- 1 MHz
            protocol = "standard",
            description = "HackRF One for wideband SDR applications",
            init_function = "init",
            send_function = "send_signal",
            params = {
                tx_gain = 40, -- dB
                antenna = "ANT500" -- Antenna type
            }
        },
        ["custom-modem"] = {
            name = "Custom Modem",
            module = "sdr_custom_modem", -- Lua module name (e.g., sdr_custom_modem.lua)
            sample_rate = 96000, -- 96 kHz
            modulation = "QPSK", -- Quadrature Phase Shift Keying
            frequency = 2400000000, -- 2.4 GHz (e.g., Wi-Fi band)
            bandwidth = 500000, -- 500 kHz
            protocol = "custom", -- Custom modem protocol
            description = "Experimental software-defined modem",
            init_function = "init",
            send_function = "send_signal",
            params = {
                bitrate = 1000000, -- 1 Mbps
                encoding = "NRZ" -- Non-Return-to-Zero encoding
            }
        }
    }
}

return config