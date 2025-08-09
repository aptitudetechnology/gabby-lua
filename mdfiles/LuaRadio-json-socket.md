Yes, you could definitely use a JSON socket instead of the raw TCP socket for testing LuaRadio between two VMs. This approach offers a significant advantage: it allows you to send structured, self-describing data between the VMs, making debugging and data interpretation much easier.

### 1\. The Advantage of JSON

Using JSON over a raw TCP stream means you are not just sending a stream of bytes. You are sending data that can be easily parsed and understood. For a LuaRadio application, this means you can send metadata, such as sample rates or modem settings, along with the actual signal data.

### 2\. Modifying the LuaRadio Scripts

You would need to modify your LuaRadio scripts on both the transmitter and receiver VMs to use JSON encoding and decoding. Since Lua has a native table structure, it's very easy to convert a Lua table to a JSON string and back again. The standard Lua `json` library is often used for this.

-----

### Transmitter VM (VM1)

On the transmitter side, you'll create a table, encode it into a JSON string, and then send that string over the TCP socket.

  * **Create the Lua Script:** `transmitter_json.lua`

<!-- end list -->

```lua
#!/usr/bin/env luaradio

-- Import necessary libraries
local radio = require('radio')
local json = require('json') -- You'll need to install this library (e.g., `luarocks install luajson`)

-- Create a flow graph
local flowgraph = radio.CompositeFlowGraph()

-- 1. Create a signal source (a simple square wave)
local square_wave = radio.SignalSource(radio.ComplexFloat32, { 0, 1, 0, -1 })

-- 2. Modulate the signal
local bpsk_mod = radio.BPSKModulator(4)

-- 3. Create a block to package the data into a JSON object
local json_packer = radio.Block(function(input_data)
    -- This function will be called with the modulated data
    local data_to_send = {
        metadata = {
            sample_rate = 4,
            modulation = 'BPSK'
        },
        payload = input_data -- The actual signal data
    }
    return { json.encode(data_to_send) } -- Return the encoded JSON string
end)

-- 4. Open a TCP socket to send the JSON string
local tcp_sink = radio.TCPSink('192.168.56.102', 12345)

-- 5. Connect the blocks
flowgraph:connect(square_wave, bpsk_mod, json_packer, tcp_sink)

-- 6. Start the flow graph
flowgraph:run()
```

-----

### Receiver VM (VM2)

On the receiver side, you'll listen for the TCP data, parse it as a JSON string, and then extract the signal data to pass to the demodulator.

  * **Create the Lua Script:** `receiver_json.lua`

<!-- end list -->

```lua
#!/usr/bin/env luaradio

-- Import necessary libraries
local radio = require('radio')
local json = require('json')

-- Create a flow graph
local flowgraph = radio.CompositeFlowGraph()

-- 1. Create a TCP source to listen for data
local tcp_source = radio.TCPSource(radio.String, '192.168.56.102', 12345)

-- 2. Create a block to parse the JSON and extract the payload
local json_unpacker = radio.Block(function(input_data)
    local decoded = json.decode(input_data[1])
    print('Received metadata:', decoded.metadata.modulation, 'with sample rate', decoded.metadata.sample_rate)
    return { decoded.payload } -- Return the actual signal data
end)

-- 3. Demodulate the signal
local bpsk_demod = radio.BPSKDemodulator(4)

-- 4. Print the demodulated data
local print_sink = radio.Sink(function(data)
    print('Received demodulated data:', table.unpack(data))
end)

-- 5. Connect the blocks
flowgraph:connect(tcp_source, json_unpacker, bpsk_demod, print_sink)

-- 6. Start the flow graph
flowgraph:run()
```

### 3\. Installation

You'll need to install a Lua JSON library on both VMs. A common one is `luajson`. You can install it using `luarocks`, the Lua package manager.

```bash
luarocks install luajson
```

This JSON-based approach makes the communication more robust and extensible, especially if you plan to send more complex information than just the raw signal data.
