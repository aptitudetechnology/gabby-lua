package main

import (
	"fmt"
	"net"
)

func sendMessage(address string, message string) {
	conn, err := net.Dial("tcp", address)
	panicIfErrPresent(err)

	messageBytes := []byte(message)
	_, err = conn.Write(messageBytes)
	panicIfErrPresent(err)

	logger.debug(fmt.Sprintf("Message %s has been sent", message))
}
