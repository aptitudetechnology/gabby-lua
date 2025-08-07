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

type hostInfo struct {
	ip   string
	port int
	name string
}

var GabbiesDiscovered map[string]hostInfo

func init() {
	GabbiesDiscovered = make(map[string]hostInfo)
}

func encodeMessage(port int, hostname string) []byte {
	encodedStr := fmt.Sprintf("%d%s%s", port, messageDelimiter, hostname)
	return []byte(encodedStr)
}

func decodeMessage(encoded []byte) (int, string) {
	encodedStr := string(encoded)

	encodedArr := strings.Split(encodedStr, messageDelimiter)
	port, _ := strconv.Atoi(encodedArr[0])
	return port, encodedArr[1]
}

// The function will broadcast information needed to communicate with this host
func broadcastMessage(port int, hostname string) {

	addr := getFullBroadcastAddress()
	logger.debug(fmt.Sprintf("sending broadcast message to: %s", addr))

	udpConnection, _ := net.DialUDP("udp", nil, addr)
	defer udpConnection.Close()

	buffer := encodeMessage(port, hostname)
	_, err := udpConnection.Write(buffer)

	panicIfErrPresent(err)
}

// in previous version I was fetching the network interface from os and it's ip address
// but it is hard to determine correct network interface, so trick is to connect to common known address
// like googles dns, let os choose network interface automatically and read the local address 😅
func getHostIpv4Address() string {
	udpConnection, err := net.Dial("udp", "8.8.8.8:53")
	panicIfErrPresent(err)
	return strings.Split(udpConnection.LocalAddr().String(), ":")[0]
}

func listenForBroadcastMessages() {
	// So my initial thought was that we should listen on broadcastAddress... 😅 After giving it some thought
	// listening to all interfaces make sense, 0.0.0.0 is kind of an alias to all network interfaces
	addressStr := fmt.Sprintf("0.0.0.0:%d", broadcastPort)
	addr, _ := net.ResolveUDPAddr("udp", addressStr)

	logger.debug(fmt.Sprintf("listening broadcast message on: %s", addr))

	conn, _ := net.ListenUDP("udp", addr)
	defer conn.Close() // this closes the connection before the function returns

	// TODO I should either make sure that buffer is never longer then 1024, or I should write code for the scenario which handles bigger buffer
	buffer := make([]byte, bufferSize)

	bytesRead, remoteAddr, err := conn.ReadFromUDP(buffer)
	panicIfErrPresent(err)

	port, hostname := decodeMessage(buffer[:bytesRead])
	GabbiesDiscovered[hostname] = hostInfo{
		ip:   strings.Split(remoteAddr.String(), ":")[0], // ignore ephemeral port
		port: port,
		name: hostname,
	}
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
