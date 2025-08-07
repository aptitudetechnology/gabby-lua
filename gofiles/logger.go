package main

import (
	"fmt"
	"log"
	"os"
)

type LogLevel int

const (
	DEBUG LogLevel = iota
	INFO
	ERROR
)

const CallDepthToSkip = 2

type Log struct {
	debugLogger *log.Logger
	infoLogger  *log.Logger
	errorLogger *log.Logger
	logLevel    LogLevel
}

func newLogger(logLevel LogLevel) *Log {
	validateLogLevel(logLevel)
	return &Log{
		debugLogger: log.New(os.Stdout, "[DEBUG] ", log.Ltime|log.Lshortfile),
		infoLogger:  log.New(os.Stdout, "[INFO] ", log.Ltime|log.Lshortfile),
		errorLogger: log.New(os.Stderr, "[ERROR] ", log.Ltime|log.Lshortfile),
		logLevel:    logLevel,
	}
}

// This is something called receiver method, this is basically a way to attach method to the struct
// coming from the java background this blows my mind🤯
func (l *Log) setLevel(level LogLevel) {
	validateLogLevel(level)
	l.logLevel = level
}

func (l *Log) debug(message string) {
	if l.shouldLog(DEBUG) {
		// I've been calling logger.printLn so far but the problem with println is (similar to this method 😁) it has
		// hardcoded calldepth set to 2, which basically means that logger.go was always selected as the file name
		// because this is on the 2nd index of the stack, therefore I found this method that gives you ability to override
		// callDepthToSkip, since we are calling output directly setting 2 is what we want in this case, so caller of this
		// method will be logged as a source.
		_ = l.debugLogger.Output(CallDepthToSkip, message)
	}
}

func (l *Log) info(message string) {
	if l.shouldLog(INFO) {
		_ = l.infoLogger.Output(CallDepthToSkip, message)
	}
}

func (l *Log) error(message string) {
	if l.shouldLog(ERROR) {
		_ = l.errorLogger.Output(CallDepthToSkip, message)
	}
}

func (l *Log) shouldLog(level LogLevel) bool {
	return level >= l.logLevel
}

func validateLogLevel(level LogLevel) {
	if level < DEBUG || level > ERROR {
		panic(fmt.Sprintf("invalid log level: %d", level))
	}
}
