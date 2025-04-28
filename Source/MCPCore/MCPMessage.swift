//
//  MCPMessage.swift
//  MCP SDK
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.
//

import Foundation

/// Represents a generic MCP message
public struct MCPMessage: Codable {
    public let type: String
    public let headers: [String: String]?
    public let payload: [String: AnyCodable]?

    public init(type: String, headers: [String: String]? = nil, payload: [String: AnyCodable]? = nil) {
        self.type = type
        self.headers = headers
        self.payload = payload
    }
}
