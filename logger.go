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

func (l *Log) debug(message ...any) {
	if l.shouldLog(DEBUG) {
		l.debugLogger.Println(message)
	}
}

func (l *Log) info(message ...any) {
	if l.shouldLog(INFO) {
		l.infoLogger.Println(message)
	}
}

func (l *Log) error(message ...any) {
	if l.shouldLog(ERROR) {
		l.errorLogger.Println(message)
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
