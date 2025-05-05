//
//  MessageChannelProtocol.swift
//  MCP
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.

import Foundation

/// Protocol defining the required interface for message channels
public protocol MessageChannelProtocol {
    /// Closure invoked when new data is received
    var onReceive: ((Data) -> Void)? { get set }

    /// Start the channel
    func start()

    /// Stop the channel
    func stop()

    /// Write raw data to output
    func write(_ data: Data)

    /// Write string with newline to output
    func writeLine(_ string: String)
}
