//
//  MCPError.swift
//  MCP SDK
//
//  Created by Chiaote Ni on 2025/5/2.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.
//

import Foundation

// Define the possible errors for the MCP service
public enum MCPError: Error {
    case parsingError(description: String)
    case rpcError(code: Int, message: String)
    case communicationError(description: String)
    case authenticationError(description: String)
    case validationError(description: String)
    case serviceError(description: String)
}
