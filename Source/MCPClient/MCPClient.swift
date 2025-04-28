//import Foundation
//import MCPCore
//import MCPUtilities
//import MCPNetworking
//
//public typealias ToolSchema = MCPCore.ToolSchema
//public typealias SchemaProperty = MCPCore.SchemaProperty
//public typealias SchemaType = MCPCore.SchemaType
//
//// Protocol defining the client API methods
//public protocol MCPClientProtocol {
//    func initialize() throws -> JSONRPC.ServerInfo?
//    func listTools() throws -> [MCPTool]
//    func callTool(name: String, arguments: [String: Any]) throws -> [String: Any]
//    
//    // Async versions
//    func initialize() async throws -> JSONRPC.ServerInfo?
//    func listTools() async throws -> [MCPTool]
//    func callTool(name: String, arguments: [String: Any]) async throws -> [String: Any]
//}
//
//// A Swift implementation of the MCP client
//public class MCPClient: MCPClientProtocol {
//    private let standardInput = FileHandle.standardInput
//    private let standardOutput = FileHandle.standardOutput
//    private var nextRequestId = 0
//    
//    public init() {
//        MCPLogger.logInfo("MCPClient initialized")
//    }
//    
//    // Synchronous methods (using semaphore internally)
//    public func initialize() throws -> JSONRPC.ServerInfo? {
//        let semaphore = DispatchSemaphore(value: 0)
//        var result: JSONRPC.ServerInfo?
//        var capturedError: Error?
//        
//        Task {
//            do {
//                result = try await initialize()
//                semaphore.signal()
//            } catch {
//                capturedError = error
//                semaphore.signal()
//            }
//        }
//        
//        semaphore.wait()
//        
//        if let error = capturedError {
//            throw error
//        }
//        
//        return result
//    }
//    
//    public func listTools() throws -> [MCPTool] {
//        let semaphore = DispatchSemaphore(value: 0)
//        var result: [MCPTool] = []
//        var capturedError: Error?
//        
//        Task {
//            do {
//                result = try await listTools()
//                semaphore.signal()
//            } catch {
//                capturedError = error
//                semaphore.signal()
//            }
//        }
//        
//        semaphore.wait()
//        
//        if let error = capturedError {
//            throw error
//        }
//        
//        return result
//    }
//    
//    public func callTool(name: String, arguments: [String: Any]) throws -> [String: Any] {
//        let semaphore = DispatchSemaphore(value: 0)
//        var result: [String: Any] = [:]
//        var capturedError: Error?
//        
//        Task {
//            do {
//                result = try await callTool(name: name, arguments: arguments)
//                semaphore.signal()
//            } catch {
//                capturedError = error
//                semaphore.signal()
//            }
//        }
//        
//        semaphore.wait()
//        
//        if let error = capturedError {
//            throw error
//        }
//        
//        return result
//    }
//    
//    // Async methods
//    public func initialize() async throws -> JSONRPC.ServerInfo? {
//        let request = JSONRPC.Request(
//            method: "initialize",
//            params: [
//                "protocolVersion": "2024-11-05",
//                "capabilities": [
//                    "tools": [
//                        "listChanged": false
//                    ],
//                    "prompts": [
//                        "listChanged": false
//                    ],
//                    "resources": [
//                        "subscribe": true,
//                        "listChanged": false
//                    ]
//                ],
//                "clientInfo": [
//                    "name": "MCPClient",
//                    "version": "1.0.0",
//                    "apiVersion": "2024-11-05"
//                ]
//            ],
//            id: "init"
//        )
//        
//        let response = try await sendRequest(request)
//        
//        if let error = response.error {
//            throw MCPError.rpcError(code: error.code, message: error.message)
//        }
//        
//        // Parse the response
//        if let result = response.result?.value as? [String: Any],
//           let protocolVersion = result["protocolVersion"] as? String,
//           let serverInfo = result["serverInfo"] as? [String: Any],
//           let capabilities = result["capabilities"] as? [String: Any] {
//            
//            guard let name = serverInfo["name"] as? String,
//                  let version = serverInfo["version"] as? String,
//                  let apiVersion = serverInfo["apiVersion"] as? String else {
//                throw MCPError.parsingError(description: "Missing required serverInfo fields")
//            }
//            
//            let serverDetails = JSONRPC.ServerDetails(
//                name: name,
//                version: version,
//                apiVersion: apiVersion
//            )
//            
//            // Parse tools capabilities
//            let toolsCapabilities: JSONRPC.Capabilities.Tools
//            if let toolsDict = capabilities["tools"] as? [String: Any],
//               let listChanged = toolsDict["listChanged"] as? Bool {
//                toolsCapabilities = JSONRPC.Capabilities.Tools(listChanged: listChanged)
//            } else {
//                toolsCapabilities = JSONRPC.Capabilities.Tools()
//            }
//            
//            // Parse prompts capabilities
//            let promptsCapabilities: JSONRPC.Capabilities.Prompts?
//            if let promptsDict = capabilities["prompts"] as? [String: Any],
//               let listChanged = promptsDict["listChanged"] as? Bool {
//                promptsCapabilities = JSONRPC.Capabilities.Prompts(listChanged: listChanged)
//            } else {
//                promptsCapabilities = nil
//            }
//            
//            // Parse resources capabilities
//            let resourcesCapabilities: JSONRPC.Capabilities.Resources?
//            if let resourcesDict = capabilities["resources"] as? [String: Any],
//               let subscribe = resourcesDict["subscribe"] as? Bool,
//               let listChanged = resourcesDict["listChanged"] as? Bool {
//                resourcesCapabilities = JSONRPC.Capabilities.Resources(subscribe: subscribe, listChanged: listChanged)
//            } else {
//                resourcesCapabilities = nil
//            }
//            
//            let serverCapabilities = JSONRPC.Capabilities(
//                tools: toolsCapabilities,
//                prompts: promptsCapabilities,
//                resources: resourcesCapabilities
//            )
//            
//            // Get optional instructions
//            let instructions = result["instructions"] as? String
//            
//            MCPLogger.logInfo("Successfully initialized with server: \(name) v\(version)")
//            
//            return JSONRPC.ServerInfo(
//                protocolVersion: protocolVersion,
//                serverInfo: serverDetails,
//                capabilities: serverCapabilities,
//                instructions: instructions
//            )
//        } else {
//            throw MCPError.parsingError(description: "Invalid server info format")
//        }
//    }
//    
//    public func listTools() async throws -> [MCPTool] {
//        let request = JSONRPC.Request(
//            method: "tools/list",
//            id: "list-tools-\(nextRequestId)"
//        )
//        nextRequestId += 1
//        
//        let response = try await sendRequest(request)
//        
//        if let error = response.error {
//            throw MCPError.rpcError(code: error.code, message: error.message)
//        }
//        
//        guard let result = response.result?.value as? [String: Any],
//              let toolsArray = result["tools"] as? [[String: Any]] else {
//            throw MCPError.parsingError(description: "Invalid tools list format")
//        }
//        
//        var tools: [MCPTool] = []
//        
//        for toolDict in toolsArray {
//            guard let name = toolDict["name"] as? String,
//                  let description = toolDict["description"] as? String,
//                  let inputSchema = toolDict["inputSchema"] as? [String: Any] else {
//                MCPLogger.logWarning("Skipping invalid tool entry")
//                continue
//            }
//            
//            let outputSchema = toolDict["outputSchema"] as? [String: Any]
//            
//            // 將字典轉換為ToolSchema結構
//            let inputSchemaObj = convertDictionaryToToolSchema(inputSchema)
//            let outputSchemaObj = outputSchema.map { convertDictionaryToToolSchema($0) }
//            
//            let tool = MCPTool(
//                name: name,
//                description: description,
//                inputSchema: inputSchemaObj,
//                outputSchema: outputSchemaObj
//            )
//            
//            tools.append(tool)
//        }
//        
//        return tools
//    }
//    
//    // 輔助方法：將架構字典轉換為ToolSchema
//    private func convertDictionaryToToolSchema(_ schema: [String: Any]) -> ToolSchema {
//        var properties: [String: SchemaProperty] = [:]
//        
//        if let propertiesDict = schema["properties"] as? [String: [String: Any]] {
//            for (key, propertyDict) in propertiesDict {
//                if let typeString = propertyDict["type"] as? String,
//                   let type = SchemaType(rawValue: typeString),
//                   let description = propertyDict["description"] as? String {
//                    
//                    let enumValues = propertyDict["enum"] as? [String]
//                    let required = (schema["required"] as? [String])?.contains(key) ?? false
//                    
//                    let property = SchemaProperty(
//                        type: type,
//                        description: description,
//                        required: required,
//                        enumValues: enumValues
//                    )
//                    
//                    properties[key] = property
//                }
//            }
//        }
//        
//        let required = schema["required"] as? [String] ?? []
//        return ToolSchema(properties: properties, required: required)
//    }
//    
//    public func callTool(name: String, arguments: [String: Any]) async throws -> [String: Any] {
//        let request = JSONRPC.Request(
//            method: "tools/call",
//            params: [
//                "name": name,
//                "arguments": arguments
//            ],
//            id: "tool-call-\(nextRequestId)"
//        )
//        nextRequestId += 1
//        
//        let response = try await sendRequest(request)
//        
//        if let error = response.error {
//            throw MCPError.rpcError(code: error.code, message: error.message)
//        }
//        
//        guard let result = response.result?.value as? [String: Any] else {
//            throw MCPError.parsingError(description: "Invalid tool call result format")
//        }
//        
//        return result
//    }
//    
//    // Helper method to send a request and get a response
//    private func sendRequest(_ request: JSONRPC.Request) async throws -> JSONRPC.Response {
//        let encoder = JSONEncoder()
//        let jsonData = try encoder.encode(request)
//        
//        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
//            throw MCPError.parsingError(description: "Failed to encode request as UTF-8")
//        }
//        
//        // Write the request to standard output
//        try await writeToStdout(jsonString + "\n")
//        
//        // Read the response from standard input
//        let responseString = try await readLine()
//        
//        guard let responseData = responseString.data(using: .utf8) else {
//            throw MCPError.parsingError(description: "Failed to parse response as UTF-8")
//        }
//        
//        let decoder = JSONDecoder()
//        return try decoder.decode(JSONRPC.Response.self, from: responseData)
//    }
//    
//    // Helper method to read a line from standard input
//    private func readLine() async throws -> String {
//        try await withCheckedThrowingContinuation { continuation in
//            DispatchQueue.global().async {
//                do {
//                    let data = self.standardInput.availableData
//                    
//                    if data.isEmpty {
//                        continuation.resume(throwing: MCPError.communicationError(description: "End of input"))
//                        return
//                    }
//                    
//                    if let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) {
//                        continuation.resume(returning: line)
//                    } else {
//                        continuation.resume(throwing: MCPError.parsingError(description: "Failed to decode input"))
//                    }
//                } catch {
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//    
//    // Helper method to write to standard output
//    private func writeToStdout(_ string: String) async throws {
//        guard let data = string.data(using: .utf8) else {
//            throw MCPError.parsingError(description: "Failed to encode as UTF-8")
//        }
//        
//        try await withCheckedThrowingContinuation { continuation in
//            DispatchQueue.global().async {
//                do {
//                    self.standardOutput.write(data)
//                    continuation.resume()
//                } catch {
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//}
