//
//  MCPService.swift
//  MCP SDK
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.
//

import Foundation
import MCPCore
import MCPUtilities

public typealias MCPTool = MCPCore.MCPTool
public typealias ToolSchema = MCPCore.ToolSchema
public typealias SchemaProperty = MCPCore.SchemaProperty
public typealias ToolResult = MCPCore.ToolResult
public typealias TextContent = MCPCore.TextContent
public typealias ImageContent = MCPCore.ImageContent
public typealias EmbeddedResource = MCPCore.EmbeddedResource

// Protocol defining the service API methods
public protocol MCPServiceProtocol {
    func registerTool(_ tool: MCPTool)
    func processRequest(_ jsonString: String) throws -> String?
    func getServerInfo() -> JSONRPC.ServerInfo
}

// A Swift implementation of the MCP service
public class MCPService: MCPServiceProtocol {
    private var tools: [String: MCPTool] = [:]
    private let protocolVersion = "2024-11-05"
    private let serverName: String
    private let serverVersion: String
    
    public init(name: String = "Swift Format Provider", version: String = "1.0.0") {
        MCPLogger.logInfo("MCPService initialized: \(name) v\(version)")
        self.serverName = name
        self.serverVersion = version
    }
    
    public func registerTool(_ tool: MCPTool) {
        MCPLogger.logInfo("Registering tool: \(tool.name)")
        tools[tool.name] = tool
        MCPLogger.logInfo("Total registered tools: \(tools.count)")
    }
    
    public func registerTools(_ tools: [MCPTool]) {
        for tool in tools {
            registerTool(tool)
        }
    }
    
    public func getServerInfo() -> JSONRPC.ServerInfo {
        return JSONRPC.ServerInfo(
            protocolVersion: protocolVersion,
            serverInfo: JSONRPC.ServerDetails(
                name: serverName,
                version: serverVersion,
                apiVersion: protocolVersion
            ),
            capabilities: JSONRPC.Capabilities(
                tools: JSONRPC.Capabilities.Tools(listChanged: false),
                prompts: JSONRPC.Capabilities.Prompts(listChanged: false),
                resources: JSONRPC.Capabilities.Resources(subscribe: true, listChanged: false)
            ),
            instructions: "This service provides MCP capabilities for integration with LLMs."
        )
    }
    
    // 新增 MCPServiceError 定義
    public enum MCPServiceError: Error {
        case parseError(String)
        case decodeError(String)
        case methodNotFound(String)
        case invalidParams
        case toolNotFound(String)
    }
    
    public func processRequest(_ jsonString: String) throws -> String? {
        MCPLogger.logInfo("processRequest raw JSON: \(jsonString)")
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw MCPServiceError.parseError("Failed to convert string to data")
        }
        let decoder = JSONDecoder()
        if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            let method = json["method"] as? String ?? ""
            if json["id"] == nil {
                MCPLogger.logInfo("Received notification: \(method)")
                if method == "notifications/initialized" {
                    MCPLogger.logInfo("Client initialization complete")
                    return nil
                }
                return nil
            }
        }
        let request: JSONRPC.Request
        do {
            request = try decoder.decode(JSONRPC.Request.self, from: jsonData)
        } catch {
            throw MCPServiceError.decodeError("Failed to decode JSON-RPC request: \(error)")
        }
        MCPLogger.logInfo("Decoded RPC request: method=\(request.method), id=\(request.id)")
        switch request.method {
            case "initialize":
                MCPLogger.logInfo("Invoking initialize handler (id=\(request.id))")
                return handleInitialize(request: request)
            case "list_tools", "tools/list":
                MCPLogger.logInfo("Invoking list tools handler (id=\(request.id))")
                return handleListTools(request: request)
            case "tools/call":
                MCPLogger.logInfo("Invoking tool call handler (id=\(request.id))")
                return try handleToolCall(request: request)
            case "exit":
                MCPLogger.logInfo("Received exit request")
                return createJsonRpcResponse(result: ["status": "ok"], id: request.id)
            default:
                throw MCPServiceError.methodNotFound(request.method)
        }
    }
    
    private func handleInitialize(request: JSONRPC.Request) -> String {
        MCPLogger.logInfo("Handling initialize request")
        
        // Get complete server info object
        let completeServerInfo = getServerInfo()
        
        // Build capabilities dictionary
        var capabilitiesDict: [String: Any] = [
            "tools": [
                "listChanged": completeServerInfo.capabilities.tools.listChanged
            ]
        ]
        
        if let prompts = completeServerInfo.capabilities.prompts {
            capabilitiesDict["prompts"] = [
                "listChanged": prompts.listChanged
            ]
        }
        
        if let resources = completeServerInfo.capabilities.resources {
            capabilitiesDict["resources"] = [
                "subscribe": resources.subscribe,
                "listChanged": resources.listChanged
            ]
        }
        
        // Build result dictionary
        var resultDict: [String: Any] = [
            "protocolVersion": completeServerInfo.protocolVersion,
            "serverInfo": [
                "name": completeServerInfo.serverInfo.name,
                "version": completeServerInfo.serverInfo.version,
                "apiVersion": completeServerInfo.serverInfo.apiVersion
            ],
            "capabilities": capabilitiesDict
        ]
        
        // Add instructions if available
        if let instructions = completeServerInfo.instructions {
            resultDict["instructions"] = instructions
        }
        
        // Return full initialize response
        return createJsonRpcResponse(
            result: resultDict,
            id: request.id
        )
    }
    
    private func handleListTools(request: JSONRPC.Request) -> String {
        MCPLogger.logInfo("Handling list_tools request")
        
        let toolsArray = tools.values.map { tool -> [String: Any] in
            // Build function dictionary
            var functionDict: [String: Any] = [
                "name": tool.name,
                "description": tool.description
            ]
            
            // Convert ToolSchema object to dictionary
            let inputSchemaDict = tool.inputSchema.toDictionary()
            let outputSchemaDict = tool.outputSchema?.toDictionary()
            
            // Add parameter schema to function dictionary
            functionDict["parameters"] = inputSchemaDict
            
            // Add return value schema to function dictionary
            if let outputSchemaDict = outputSchemaDict {
                functionDict["returns"] = outputSchemaDict
            }
            
            // Final tool dictionary, including top-level inputSchema and outputSchema
            var toolDict: [String: Any] = [
                "name": tool.name,
                "description": tool.description,
                "function": functionDict
            ]
            
            // Add top-level schema, this is the format expected by Cursor
            toolDict["inputSchema"] = inputSchemaDict
            
            if let outputSchemaDict = outputSchemaDict {
                toolDict["outputSchema"] = outputSchemaDict
            }
            
            return toolDict
        }
        
        MCPLogger.logInfo("Returning \(toolsArray.count) tools")
        
        return createJsonRpcResponse(result: ["tools": toolsArray], id: request.id)
    }
    
    private func handleToolCall(request: JSONRPC.Request) throws -> String {
        MCPLogger.logInfo("Handling tool call request")
        guard let params = request.params?.value as? [String: Any],
              let toolName = params["name"] as? String,
              let arguments = params["arguments"] as? [String: Any] else {
            throw MCPServiceError.invalidParams
        }
        guard let tool = tools[toolName] else {
            throw MCPServiceError.toolNotFound(toolName)
        }
        if let handler = tool.handler {
            let toolResult = handler(arguments)
            let resultDict = toolResult.toDictionary()
            return createJsonRpcResponse(result: resultDict, id: request.id)
        } else {
            let errorText = "Tool handler not implemented for: \(toolName)"
            MCPLogger.logWarning(errorText)
            let defaultContent = TextContent(text: errorText)
            let defaultResult = ToolResult(content: [defaultContent])
            return createJsonRpcResponse(result: defaultResult.toDictionary(), id: request.id)
        }
    }
    
    // Helper methods for creating JSON-RPC responses
    private func createJsonRpcResponse(result: [String: Any], id: AnyCodable) -> String {
        let response = JSONRPC.Response(result: result, id: id)
        return encodeToJsonString(response) ?? createErrorResponse(code: -32603, message: "Internal JSON encoding error", id: id)
    }
    
    private func createErrorResponse(code: Int, message: String, id: AnyCodable?) -> String {
        let error = JSONRPC.ResponseError(code: code, message: message)
        let response = JSONRPC.Response(result: nil, error: error, id: id ?? AnyCodable("null"))
        return encodeToJsonString(response) ?? "{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32603,\"message\":\"Internal JSON encoding error\"},\"id\":null}"
    }
    
    private func encodeToJsonString<T: Encodable>(_ value: T) -> String? {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8)
        } catch {
            MCPLogger.logError("Failed to encode JSON: \(error)")
            return nil
        }
    }
}
