package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"strings"
)

type GabbyInfo struct {
	name string
}

var gabbyInfo GabbyInfo
var logger Log

func init() {
	logger = *newLogger(DEBUG)
}

func main() {
	flag.StringVar(&gabbyInfo.name, "name", getHostname(), "Choose how you will be known")
	levelFlagPointer := flag.Int("log", 0, "0=DEBUG 1=INFO 2=ERROR")
	portToListenPointer := flag.Int("port", 8080, "Port to listen on")

	flag.Parse()
	logLevel := LogLevel(*levelFlagPointer)
	logger.setLevel(logLevel)

	myIpv4 := getHostIpv4Address().String()
	messageListenAddress := fmt.Sprintf("%s:%d", myIpv4, *portToListenPointer)
	go startListeningForMessage(messageListenAddress)

	go letGabbiesDiscoverYou(*portToListenPointer)
	go listenForBroadcastMessages()
	go listenForNewHostEvents()

	var peer hostInfo
	var message string

	fmt.Println("[hostname]:Message for example: jimmy:Hello there friend")
	for {
		userInput := readUserInput()
		if strings.Contains(userInput, ":") {
			args := strings.Split(userInput, ":")
			peer = GabbiesDiscovered[args[0]]
			message = args[1]
		} else {
			message = userInput
		}
		address := fmt.Sprintf("%s:%d", peer.ip, peer.port)
		sendMessage(address, message)
	}
}

func discoverGabbies() {
	for {
		listenForBroadcastMessages()
	}
}

func letGabbiesDiscoverYou(port int) {
	for {
		broadcastMessage(port, gabbyInfo.name)
	}
}

func listenForNewHostEvents() {
	newHost := <-HostJoinEventChannel
	fmt.Println("New host joined gabbies", newHost, "Currently known hosts", GabbiesDiscovered)
}

func readUserInput() string {
	reader := bufio.NewReader(os.Stdin)
	line, _ := reader.ReadString('\n')

	// Weirdly enough \n was present in the line and logging was going crazy, removing white space before returning
	return strings.TrimSpace(line)
}

func getHostname() string {
	name, err := os.Hostname()

	// No idea why this might error out, but ok
	if err != nil {
		fmt.Println(err)
	}

	return name
}

func panicIfErrPresent(err error) {
	if err != nil {
		logger.error(err.Error())
	}
}
