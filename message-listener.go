package main

import (
	"fmt"
	"net"
)

var defaultBufferSize int

func init() {
	defaultBufferSize = 1024
}

func startListening(port int) {
	logger.debug(fmt.Sprintf("Starting message listener on port %d", port))

	listener, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", port))
	panicIfErrPresent(err)

	for {
		con, err := listener.Accept()
		panicIfErrPresent(err)

		handleConnection(con)
	}
}

func handleConnection(con net.Conn) {
	buffer := make([]byte, defaultBufferSize)
	numberOfBytes, err := con.Read(buffer)
	panicIfErrPresent(err)

	// we will assemble message in this slice, since the message can be bigger then our buffer size...
	messageHolder := make([]byte, defaultBufferSize)
	copy(messageHolder, buffer)

	for numberOfBytes == defaultBufferSize {
		numberOfBytes, err = con.Read(buffer)
		messageHolder = append(messageHolder, buffer[:numberOfBytes]...)
	}

	message := string(messageHolder[:])
	logger.debug(fmt.Sprintf("Received message: %s", message))
}
