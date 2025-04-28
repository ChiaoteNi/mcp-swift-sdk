import Foundation
import MCPCore
import MCPUtilities
import MCPNetworking

// Configure logging
MCPLogger.enableFileLogging = true
MCPLogger.logInfo("Starting Swift MCP Format Provider")

// Create the format provider
let formatProvider = FormatProvider()

// Log startup information
MCPLogger.logInfo("Swift MCP Format Provider is starting")
MCPLogger.logInfo("Process ID: \(ProcessInfo.processInfo.processIdentifier)")
if let workingDirectory = ProcessInfo.processInfo.environment["PWD"] {
    MCPLogger.logInfo("Working directory: \(workingDirectory)")
}

// Start the provider - this will block until terminated
formatProvider.start()

// This line will only be reached if the provider stops
MCPLogger.logInfo("Swift MCP Format Provider has exited") 
