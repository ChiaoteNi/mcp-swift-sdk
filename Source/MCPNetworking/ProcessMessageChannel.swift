//
//  ProcessMessageChannel.swift
//  MCP
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.

import Foundation
import MCPUtilities

/// MessageChannel abstracts message transport for MCPProvider
/// Handles bi-directional message flow between components
public final class ProcessMessageChannel: MessageChannelProtocol {
    private let inputHandle: FileHandle
    private let outputHandle: FileHandle

    /// Closure invoked when new data is received
    public var onReceive: ((Data) -> Void)?

    public init(input: FileHandle = .standardInput,
                output: FileHandle = .standardOutput) {
        self.inputHandle = input
        self.outputHandle = output
    }

    public func start() {
        setupRead()
    }

    public func stop() {
        inputHandle.readabilityHandler = nil
    }

    private func setupRead() {
        inputHandle.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }
            let data = handle.availableData
            // Log raw input for debugging
            if let text = String(data: data, encoding: .utf8) {
                MCPLogger.logInfo("ProcessChannel raw receive: \(text)")
            }
            // Forward to consumer
            self.onReceive?(data)
        }
    }

    /// Write raw data to output
    public func write(_ data: Data) {
        outputHandle.write(data)
    }

    /// Write string with newline to output
    public func writeLine(_ string: String) {
        if let data = (string + "\n").data(using: .utf8) {
            write(data)
        }
    }
} 
