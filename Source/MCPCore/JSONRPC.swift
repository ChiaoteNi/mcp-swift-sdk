//
//  JSONRPC.swift
//  MCP SDK
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.
//

import Foundation

// JSON-RPC specific structures
public struct JSONRPC {
    public struct Request: Codable {
        public let jsonrpc: String
        public let method: String
        public let params: AnyCodable?
        public let id: AnyCodable

        public init(method: String, params: [String: Any]? = nil, id: String) {
            self.jsonrpc = "2.0"
            self.method = method
            self.params = params != nil ? AnyCodable(params!) : nil
            self.id = AnyCodable(id)
        }
    }

    public struct Response: Codable {
        public let jsonrpc: String
        public let result: AnyCodable?
        public let error: ResponseError?
        public let id: AnyCodable

        public init(result: [String: Any]?, error: ResponseError? = nil, id: AnyCodable) {
            self.jsonrpc = "2.0"
            self.result = result != nil ? AnyCodable(result!) : nil
            self.error = error
            self.id = id
        }
    }

    public struct ResponseError: Codable {
        public let code: Int
        public let message: String

        public init(code: Int, message: String) {
            self.code = code
            self.message = message
        }
    }

    public struct ServerInfo: Codable {
        public let protocolVersion: String
        public let serverInfo: ServerDetails
        public let capabilities: Capabilities
        public let instructions: String?

        public init(protocolVersion: String, serverInfo: ServerDetails, capabilities: Capabilities, instructions: String? = nil) {
            self.protocolVersion = protocolVersion
            self.serverInfo = serverInfo
            self.capabilities = capabilities
            self.instructions = instructions
        }
    }

    public struct ServerDetails: Codable {
        public let name: String
        public let version: String
        public let apiVersion: String

        public init(name: String, version: String, apiVersion: String) {
            self.name = name
            self.version = version
            self.apiVersion = apiVersion
        }
    }

    public struct Capabilities: Codable {
        public struct Tools: Codable {
            public let listChanged: Bool

            public init(listChanged: Bool = false) {
                self.listChanged = listChanged
            }
        }

        public struct Prompts: Codable {
            public let listChanged: Bool

            public init(listChanged: Bool = false) {
                self.listChanged = listChanged
            }
        }

        public struct Resources: Codable {
            public let subscribe: Bool
            public let listChanged: Bool

            public init(subscribe: Bool = true, listChanged: Bool = false) {
                self.subscribe = subscribe
                self.listChanged = listChanged
            }
        }

        public let tools: Tools
        public let prompts: Prompts?
        public let resources: Resources?

        public init(tools: Tools = Tools(), prompts: Prompts? = Prompts(), resources: Resources? = Resources()) {
            self.tools = tools
            self.prompts = prompts
            self.resources = resources
        }
    }

    // Tool call structure
    public struct ToolCall: Codable {
        public let name: String
        public let arguments: [String: AnyCodable]

        public init(name: String, arguments: [String: Any]) {
            self.name = name
            self.arguments = arguments.mapValues { AnyCodable($0) }
        }
    }

    public struct Notification: Codable {
        public let jsonrpc: String
        public let method: String
        public let params: AnyCodable?

        public init(method: String, params: [String: Any]? = nil) {
            self.jsonrpc = "2.0"
            self.method = method
            self.params = params != nil ? AnyCodable(params!) : nil
        }
    }
}
