package main

import (
	"fmt"
	"net"
	"strings"
)

var defaultBufferSize int

func init() {
	defaultBufferSize = 1024
}

func startListeningForMessage(address string) {
	listener, err := net.Listen("tcp", address)
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
	remoteName := lookupNameOfHost(con.RemoteAddr())
	fmt.Printf("[%s]-->%s", remoteName, message)
	fmt.Println()
}

func lookupNameOfHost(remoteAddr net.Addr) string {
	parts := strings.Split(remoteAddr.String(), ":")
	host := parts[0] // ignore the ephemeral port

	for _, gabby := range GabbiesDiscovered {
		if gabby.ip == host {
			return gabby.name
		}
	}

	return "Unknown"
}
