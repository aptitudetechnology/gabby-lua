package main

import (
	"fmt"
	"net"
)

func sendMessage(port int, message string) {
	conn, err := net.Dial("tcp", fmt.Sprintf("127.0.0.1:%d", port))
	panicIfErrPresent(err)

	messageBytes := []byte(message)
	_, err = conn.Write(messageBytes)
	panicIfErrPresent(err)

	logger.debug("Message:", message, "has been sent")
}
