package main

import (
	"fmt"
	"net"
)

const broadcastPort = 8888

// The program will broadcast what port it is using
// TODO we should broadcast name of the device too
func broadcastMessage(portToBroadcast int) {
	addr := getFullBroadcastAddress()
	logger.debug(fmt.Sprintf("sending broadcast message to: %s", addr))

	udpConnection, _ := net.DialUDP("udp", nil, addr)

	port := fmt.Sprintf("%d", portToBroadcast)
	buffer := []byte(port)
	_, err := udpConnection.Write(buffer)

	panicIfErrPresent(err)
}

// TODO we should parse name of the device too
func listenForBroadcastMessages() {
	// So my initial thought was that we should listen on broadcastAddress... 😅 After giving it some thought
	// listening to all interfaces make sense, 0.0.0.0 is kind of an alias to all network interfaces
	addressStr := fmt.Sprintf("0.0.0.0:%d", broadcastPort)
	addr, _ := net.ResolveUDPAddr("udp", addressStr)

	logger.debug(fmt.Sprintf("listening broadcast message to: %s", addr))

	conn, _ := net.ListenUDP("udp", addr)
	buffer := make([]byte, 1024)

	bytesRead, _ := conn.Read(buffer)
	logger.info(fmt.Sprintf("message: %s bytes read: %d", string(buffer[:bytesRead]), bytesRead))
}

func getFullBroadcastAddress() *net.UDPAddr {
	broadcastAddr := getBroadcastAddr().String()

	address := fmt.Sprintf("%s:%d", broadcastAddr, broadcastPort)
	addr, _ := net.ResolveUDPAddr("udp", address)
	return addr
}

func getBroadcastAddr() net.IP {
	// I am not certain that this broadcast address will work 100%, I might have to find the way to calculate accurate broadcast address
	return net.IPv4bcast
}

func byteArrayToString(b []byte) string {
	return string(b)
}
