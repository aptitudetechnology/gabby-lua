package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"strings"
	"time"
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

	myIpv4 := getHostIpv4Address()
	messageListenAddress := fmt.Sprintf("%s:%d", myIpv4, *portToListenPointer)
	go startListeningForMessage(messageListenAddress)

	go discoverGabbies()
	go letGabbiesDiscoverYou(*portToListenPointer)

	var peer hostInfo
	var message string

	fmt.Println("[hostname]:Message for example: jimmy:Hello there friend")
	for {
		userInput := readUserInput()
		if strings.Contains(userInput, ":") {
			args := strings.Split(userInput, ":")
			targetGabby, exists := GabbiesDiscovered[args[0]]
			if !exists {
				fmt.Println("Invalid name!")
				continue
			}
			peer = targetGabby
			message = args[1]
		} else if strings.HasPrefix(userInput, "!") {
			command := userInput[1:]
			switch command {
			case "l":
				fmt.Println("Currently known hosts", GabbiesDiscovered)
			default:
				fmt.Println("Unknown command!")
			}
			continue
		} else {
			message = userInput
		}

		// if peer is it's zero value, that means it's value has not been set
		if (peer == hostInfo{}) {
			fmt.Println("No Peer cached, prefix your message with hostname:")
			continue
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
		time.Sleep(time.Second * 5) // broadcast once in every 30s
	}
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
