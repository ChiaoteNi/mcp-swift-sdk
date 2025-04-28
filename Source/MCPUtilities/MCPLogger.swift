//
//  MCPLogger.swift
//  MCP SDK
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.
//

import os
import Foundation

public struct MCPLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "MCP"

    public static let general = OSLog(subsystem: subsystem, category: "General")
    public static let network = OSLog(subsystem: subsystem, category: "Network")
    public static let error = OSLog(subsystem: subsystem, category: "Error")
    
    // Log file URL
    public static let logFileURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let logDirectory = documentsDirectory.appendingPathComponent("MCPLogs")
        
        // Create logs directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: logDirectory.path) {
            try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let logFile = logDirectory.appendingPathComponent("mcp_log_\(timestamp).txt")
        return logFile
    }()
    
    // Enable file logging
    public static var enableFileLogging = true
    
    // Enable console logging via OSLog (disabled by default for MCP providers)
    public static var enableConsoleLogging = false
    
    // Log a message to both console and file
    private static func log(_ message: String, type: String, category: OSLog) {
        let formattedMessage = "\(Date()): [\(type)] \(message)"
        
        // Log to console if enabled
        if enableConsoleLogging {
            os_log("%@", log: category, type: .debug, formattedMessage)
        }
        
        // Log to file if enabled
        if enableFileLogging {
            logToFile(formattedMessage)
        }
    }
    
    // Write log message to file
    private static func logToFile(_ message: String) {
        let messageWithNewline = message + "\n"
        if let data = messageWithNewline.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL, options: .atomic)
            }
        }
    }
    
    // Return current log file path
    public static func getLogFilePath() -> String {
        return logFileURL.path
    }

    public static func logDebug(_ message: String, category: OSLog = general) {
        log(message, type: "DEBUG", category: category)
    }

    public static func logError(_ message: String, category: OSLog = error) {
        log(message, type: "ERROR", category: category)
    }
    
    public static func logInfo(_ message: String, category: OSLog = general) {
        log(message, type: "INFO", category: category)
    }
    
    public static func logWarning(_ message: String, category: OSLog = general) {
        log(message, type: "WARNING", category: category)
    }
    
    public static func logJSON(_ label: String, jsonObject: Any, category: OSLog = general) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            log("\(label): \(jsonString)", type: "JSON", category: category)
        } else {
            logError("Failed to serialize JSON for \(label)")
        }
    }
}
