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
	logger.info("Somethin from the main")

	flag.StringVar(&gabbyInfo.name, "name", getHostname(), "Choose how you will be known")
	levelFlag := *flag.Int("logLevel", 0, "0=DEBUG 1=INFO 2=ERROR")
	portToListen := *flag.Int("port", 8080, "Port to listen on")

	flag.Parse()

	logLevel := LogLevel(levelFlag)
	logger.setLevel(logLevel)

	go startListening(portToListen)

	for {
		message := readUserInput()
		sendMessage(portToListen, message)
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
