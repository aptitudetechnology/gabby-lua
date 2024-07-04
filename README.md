# Gabby - P2P Chat Application

Gabby is a peer-to-peer chat application written in Go. It allows users to discover and communicate with each other on a
local network using UDP broadcasts and TCP connections.

## Features

- Automatic peer discovery using UDP broadcasts
- Direct messaging between peers
- Command-line interface for interaction
- Configurable logging levels

## Usage

1. Build the application: ```go build -o gabby```
2. Run the application: ```./gabby -name YourName -port 8080 -log 0```
   Options:

- `-name`: Your display name (default: system hostname)
- `-port`: Port to listen on for incoming messages (default: 8080)
- `-log`: Logging level (0=DEBUG, 1=INFO, 2=ERROR, default: 0)

3. Commands:

- Send a message: `PeerName:Your message here`
- List known peers: `!l`

## How It Works

- The application uses UDP broadcasts on port 8888 for peer discovery.
- Direct messages are sent using TCP connections.
- Peers are automatically discovered and added to a list of known hosts.

## Notes

- Ensure your firewall allows UDP broadcasts and incoming TCP connections on the specified port.
- The application is designed for use on local networks.

## Limitations

This project was primarily developed as a learning exercise to gain familiarity with Go programming. As such, there are
several areas that could be optimized or improved:

- Peer availability checks
- Handling of username uniqueness
- More robust error handling and recovery
- Improved network efficiency

However, as the main purpose of this project was educational, no further optimizations are planned at this time. The
current implementation serves as a functional demonstration of peer-to-peer networking concepts in Go.