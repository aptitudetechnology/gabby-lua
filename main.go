package main

import (
	"flag"
	"fmt"
	"os"
	"time"
)

type GabbyInfo struct {
	name string
}

var gabbyInfo GabbyInfo
var logger Log

// This function is executed before the main, Keeping it here in case I use it.
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
		time.Sleep(time.Second * 5)
		sendMessage(portToListen, "hello friend")
	}
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
