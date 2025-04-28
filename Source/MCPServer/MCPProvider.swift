//
//  MCPProvider.swift
//  MCP SDK
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.
//

import Foundation
import MCPCore
import MCPUtilities

/// Main entry point for an MCP Provider
public class MCPProvider {
    private var service: MCPService
    private var isRunning = false
    private let standardInput = FileHandle.standardInput
    private let standardOutput = FileHandle.standardOutput
    
    private let enableFileLogging: Bool
    private let enableConsoleLogging: Bool
    
    public init(
        service: MCPService,
        enableFileLogging: Bool = true,
        enableConsoleLogging: Bool = false
    ) {
        self.service = service
        self.enableFileLogging = enableFileLogging
        self.enableConsoleLogging = enableConsoleLogging
        setupLogging()
    }
    
    private func setupLogging() {
        MCPLogger.enableFileLogging = enableFileLogging
        MCPLogger.enableConsoleLogging = enableConsoleLogging
        MCPLogger.logInfo("MCPProvider initialized")
    }
    
    /// Start the MCP provider loop
    public func start() {
        MCPLogger.logInfo("Start MCP service")
        MCPLogger.logInfo("MCP service initialized successfully")
        MCPLogger.logInfo("Registered get_format_template tool")
        MCPLogger.logInfo("Process ID: \(ProcessInfo.processInfo.processIdentifier)")
        if let workingDirectory = ProcessInfo.processInfo.environment["PWD"] {
            MCPLogger.logInfo("Working directory: \(workingDirectory)")
        }
        if let processPath = ProcessInfo.processInfo.environment["PATH"] {
            MCPLogger.logInfo("Process PATH: \(processPath)")
        }
        // If there is a logFile path, you can add it here
        // MCPLogger.logInfo("Log file location: ...")
        MCPLogger.logInfo("Starting MCP provider loop")
        isRunning = true
        
        processRequests()
    }
    
    /// Process requests from standard input
    private func processRequests() {
        // Set up standard input for reading
        standardInput.readabilityHandler = { [weak self] fileHandle in
            guard let self = self, self.isRunning else {
                return
            }
            
            let data = fileHandle.availableData
            
            // Check if standard input has been closed
            if data.isEmpty {
                MCPLogger.logInfo("Standard input closed, exiting provider loop")
                self.isRunning = false
                return
            }
            
            if let inputString = String(data: data, encoding: .utf8) {
                // Process each line as a separate request
                let lines = inputString.split(separator: "\n")
                
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedLine.isEmpty {
                        MCPLogger.logInfo("Received request: \(trimmedLine)")
                        
                        // Process the request and get a response
                        if let response = self.service.processRequest(trimmedLine) {
                            // Write the response to standard output
                            MCPLogger.logInfo("Sending response: \(response)")
                            if let responseData = response.data(using: .utf8) {
                                self.standardOutput.write(responseData)
                                self.standardOutput.write("\n".data(using: .utf8)!)
                            }
                        }
                    }
                }
            }
        }
        
        // Keep the process running
        RunLoop.current.run()
    }
    
    /// Stop the MCP provider loop
    public func stop() {
        MCPLogger.logInfo("Stopping MCP provider loop")
        isRunning = false
        standardInput.readabilityHandler = nil
    }
} 
