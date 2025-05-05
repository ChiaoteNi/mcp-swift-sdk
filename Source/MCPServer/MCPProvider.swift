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
import MCPNetworking

/// Main entry point for an MCP Provider
public class MCPProvider {
    /// Defines the type of message channel to use
    public enum ChannelType {
        /// Standard process I/O (stdin/stdout)
        case process
        /// Server-Sent Events
        case sse(URL)
        /// Custom channel
        case custom(MessageChannelProtocol)
    }

    private var service: MCPService
    private var isRunning = false
    private var channel: MessageChannelProtocol

    private let enableFileLogging: Bool
    private let enableConsoleLogging: Bool

    public init(
        service: MCPService,
        channelType: ChannelType = .process,
        enableFileLogging: Bool = true,
        enableConsoleLogging: Bool = false
    ) {
        self.service = service
        self.enableFileLogging = enableFileLogging
        self.enableConsoleLogging = enableConsoleLogging

        // Initialize the appropriate channel based on type
        self.channel = MCPProvider.createChannel(type: channelType)
        MCPLogger.logInfo("Created channel of type: \(channelType)")

        setupLogging()
    }

    /// Factory method to create the appropriate channel type
    private static func createChannel(type: ChannelType) -> MessageChannelProtocol {
        switch type {
        case .process:
            return ProcessMessageChannel()
        case .sse(let url):
            return SSEMessageChannel(serverURL: url)
        case .custom(let customChannel):
            return customChannel
        }
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

        // Set up message handler
        channel.onReceive = { [weak self] data in
            if let text = String(data: data, encoding: .utf8) {
                MCPLogger.logInfo("Channel onReceive raw: \(text)")
            } else {
                MCPLogger.logInfo("Channel onReceive raw data: \(data.count) bytes")
            }
            self?.handleData(data)
        }
        channel.start()
        // MCPProvider loop now driven by MessageChannel
        RunLoop.current.run()
    }

    private func handleData(_ data: Data) {
        guard isRunning else { return }
        let text = String(decoding: data, as: UTF8.self)
        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            MCPLogger.logInfo("Received request: \(trimmed)")
            if let response = service.processRequest(trimmed) {
                MCPLogger.logInfo("Sending response: \(response)")
                channel.writeLine(response)
            }
        }
    }

    /// Stop the MCP provider loop
    public func stop() {
        MCPLogger.logInfo("Stopping MCP provider loop")
        isRunning = false
        channel.onReceive = nil
        channel.stop()
    }
}
