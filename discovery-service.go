package main

import (
	"fmt"
	"net"
	"strconv"
	"strings"
)

const broadcastPort = 8888
const bufferSize = 1024      // buffer size for broadcast message
const messageDelimiter = ";" // We should make sure user nicknames does not contain this symbol

func encodeMessage(address string, port int, hostname string) []byte {
	encodedStr := fmt.Sprintf("%s%s%d%s%s", address, messageDelimiter, port, messageDelimiter, hostname)
	return []byte(encodedStr)
}

func decodeMessage(encoded []byte) (string, int, string) {
	encodedStr := string(encoded)

	encodedArr := strings.Split(encodedStr, messageDelimiter)
	port, _ := strconv.Atoi(encodedArr[1])
	return encodedArr[0], port, encodedArr[2]
}

// The function will broadcast information needed to communicate with this host
func broadcastMessage(port int, hostname string) {
	hostAddress := getHostIpv4Address().String()

	addr := getFullBroadcastAddress()
	logger.debug(fmt.Sprintf("sending broadcast message to: %s", addr))

	udpConnection, _ := net.DialUDP("udp", nil, addr)

	buffer := encodeMessage(hostAddress, port, hostname)
	_, err := udpConnection.Write(buffer)

	panicIfErrPresent(err)
}

func getHostIpv4Address() net.IP {
	var wifiInterface *net.Interface

	wifiInterface, _ = net.InterfaceByName("Wi-Fi") // TODO this is basically hack that only works for windows 🥲 Need to find out int name for linux too

	addresses, _ := wifiInterface.Addrs()

	for _, address := range addresses {
		ipNet, ok := address.(*net.IPNet)
		if !ok {
			logger.error("Unknown address type:" + address.String())
			continue
		}

		// specifically looking for ipv4
		if ipNet.IP.To4() != nil {
			logger.debug("Found wifi address: " + ipNet.IP.String())
			return ipNet.IP
		}
	}

	panic("No Wi-Fi address found")
}

func listenForBroadcastMessages() {
	// So my initial thought was that we should listen on broadcastAddress... 😅 After giving it some thought
	// listening to all interfaces make sense, 0.0.0.0 is kind of an alias to all network interfaces
	addressStr := fmt.Sprintf("0.0.0.0:%d", broadcastPort)
	addr, _ := net.ResolveUDPAddr("udp", addressStr)

	logger.debug(fmt.Sprintf("listening broadcast message to: %s", addr))

	conn, _ := net.ListenUDP("udp", addr)
	// TODO I should either make sure that buffer is never longer then 1024, or I should write code for the scenario which handles bigger buffer
	buffer := make([]byte, bufferSize)

	bytesRead, _ := conn.Read(buffer)
	message := string(buffer[:bytesRead])

	logger.info(fmt.Sprintf("message received: %s", message))

	address, port, hostname := decodeMessage(buffer[:bytesRead])
	logger.info(fmt.Sprintf("found new host: %s:%d with nickname:%s", address, port, hostname))
	// TODO introduce a new data structure where you will save found hosts
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
