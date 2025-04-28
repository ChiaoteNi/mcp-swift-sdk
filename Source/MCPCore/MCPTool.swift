//
//  MCPTool.swift
//  MCP SDK
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.
//

import Foundation

/// Represents the schema types supported by MCP
public indirect enum SchemaType: Codable {
    case string

    case stringEnum([String])

    case number

    case integer

    case boolean

    case array(SchemaType)

    case object(ToolSchema)

    private enum CodingKeys: String, CodingKey {
        case type
        case enumValues = "enum"
        case items
        case properties
        case required
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeValue = try container.decode(String.self, forKey: .type)
        switch typeValue {
        case "string":
            if let vals = try? container.decode([String].self, forKey: .enumValues) {
                self = .stringEnum(vals)
            } else {
                self = .string
            }

        case "number":
            self = .number

        case "integer":
            self = .integer

        case "boolean":
            self = .boolean

        case "array":
            let itemType = try container.decode(SchemaType.self, forKey: .items)
            self = .array(itemType)

        case "object":
            let propertiesDict = try container.decode([String: SchemaProperty].self, forKey: .properties)
            let requiredArray = try container.decode([String].self, forKey: .required)
            let schema = ToolSchema(properties: propertiesDict, required: requiredArray)
            self = .object(schema)

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unsupported SchemaType '\(typeValue)'"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string:
            try container.encode("string", forKey: .type)

        case .stringEnum(let vals):
            try container.encode("string", forKey: .type)
            try container.encode(vals, forKey: .enumValues)

        case .number:
            try container.encode("number", forKey: .type)

        case .integer:
            try container.encode("integer", forKey: .type)

        case .boolean:
            try container.encode("boolean", forKey: .type)

        case .array(let itemType):
            try container.encode("array", forKey: .type)
            try container.encode(itemType, forKey: .items)

        case .object(let schema):
            try container.encode("object", forKey: .type)
            try container.encode(schema.properties, forKey: .properties)
            try container.encode(schema.required, forKey: .required)
        }
    }

    public func toDictionary() -> [String: Any] {
        switch self {
        case .string:
            return ["type": "string"]

        case .stringEnum(let vals):
            return ["type": "string", "enum": vals]

        case .number:
            return ["type": "number"]

        case .integer:
            return ["type": "integer"]

        case .boolean:
            return ["type": "boolean"]

        case .array(let itemType):
            return ["type": "array", "items": itemType.toDictionary()]

        case .object(let schema):
            return schema.toDictionary()
        }
    }
}

/// Represents a tool schema property
public struct SchemaProperty: Codable {
    public let type: SchemaType
    public let description: String
    public let required: Bool

    public init(type: SchemaType, description: String, required: Bool = false) {
        self.type = type
        self.description = description
        self.required = required
    }

    private enum CodingKeys: String, CodingKey {
        case type, description, required
    }

    public func toDictionary() -> [String: Any] {
        var dict = type.toDictionary()
        dict["description"] = description
        return dict
    }
}

/// Represents a tool schema
public final class ToolSchema: Codable {
    public let properties: [String: SchemaProperty]
    public let required: [String]
    
    public init(properties: [String: SchemaProperty], required: [String]) {
        self.properties = properties
        self.required = required
    }
    
    private enum CodingKeys: String, CodingKey {
        case properties, required
    }
    
    public func toDictionary() -> [String: Any] {
        var propertiesDict: [String: Any] = [:]
        
        for (key, property) in properties {
            propertiesDict[key] = property.toDictionary()
        }
        
        return [
            "type": "object",
            "properties": propertiesDict,
            "required": required
        ]
    }
}

/// Represents a content item type in a tool result
public enum ContentType: String, Codable {
    case text
    case image
    case resource
}

/// Base protocol for all content types
public protocol ContentItem: Codable {
    var type: ContentType { get }
}

/// Represents text content in a tool result
public struct TextContent: ContentItem, Codable {
    public let type: ContentType = .text
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, text
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": type.rawValue,
            "text": text
        ]
    }
}

/// Represents image content in a tool result
public struct ImageContent: ContentItem, Codable {
    public let type: ContentType = .image
    public let data: String
    public let mimeType: String
    
    public init(data: String, mimeType: String) {
        self.data = data
        self.mimeType = mimeType
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, data, mimeType
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": type.rawValue,
            "data": data,
            "mimeType": mimeType
        ]
    }
}

/// Represents a resource content in a tool result
public struct EmbeddedResource: ContentItem, Codable {
    public let type: ContentType = .resource
    public let resource: ResourceContents
    
    public init(resource: ResourceContents) {
        self.resource = resource
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, resource
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": type.rawValue,
            "resource": resource.toDictionary()
        ]
    }
}

/// Represents resource contents
public struct ResourceContents: Codable {
    public let text: String
    public let uri: String
    public let mimeType: String?
    
    public init(text: String, uri: String, mimeType: String? = nil) {
        self.text = text
        self.uri = uri
        self.mimeType = mimeType
    }
    
    private enum CodingKeys: String, CodingKey {
        case text, uri, mimeType
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "text": text,
            "uri": uri
        ]
        
        if let mimeType = mimeType {
            dict["mimeType"] = mimeType
        }
        
        return dict
    }
}

/// Represents a tool result
public struct ToolResult: Codable {
    public let content: [ContentItem]
    public let isError: Bool
    
    public init(content: [ContentItem], isError: Bool = false) {
        self.content = content
        self.isError = isError
    }
    
    public func toDictionary() -> [String: Any] {
        let contentArray = content.compactMap { (item) -> [String: Any]? in
            switch item {
            case let textContent as TextContent:
                return textContent.toDictionary()
            case let imageContent as ImageContent:
                return imageContent.toDictionary()
            case let resourceContent as EmbeddedResource:
                return resourceContent.toDictionary()
            default:
                return nil
            }
        }
        
        var result: [String: Any] = [
            "content": contentArray
        ]
        
        if isError {
            result["isError"] = true
        }
        
        return result
    }
    
    // Custom encoding to handle the polymorphic ContentItem
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isError, forKey: .isError)
        
        var contentContainer = container.nestedUnkeyedContainer(forKey: .content)
        for item in content {
            switch item {
            case let textContent as TextContent:
                try contentContainer.encode(textContent)
            case let imageContent as ImageContent:
                try contentContainer.encode(imageContent)
            case let resourceContent as EmbeddedResource:
                try contentContainer.encode(resourceContent)
            default:
                throw EncodingError.invalidValue(item, EncodingError.Context(
                    codingPath: [CodingKeys.content],
                    debugDescription: "不支持的內容類型"
                ))
            }
        }
    }
    
    // Custom decoding to handle the polymorphic ContentItem
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isError = try container.decodeIfPresent(Bool.self, forKey: .isError) ?? false
        
        var contentItems = [ContentItem]()
        var contentContainer = try container.nestedUnkeyedContainer(forKey: .content)
        
        while !contentContainer.isAtEnd {
            let contentItem = try contentContainer.nestedContainer(keyedBy: ContentTypeCodingKeys.self)
            let type = try contentItem.decode(String.self, forKey: .type)
            
            switch type {
            case ContentType.text.rawValue:
                contentContainer = try container.nestedUnkeyedContainer(forKey: .content)
                let textContent = try contentContainer.decode(TextContent.self)
                contentItems.append(textContent)
            case ContentType.image.rawValue:
                contentContainer = try container.nestedUnkeyedContainer(forKey: .content)
                let imageContent = try contentContainer.decode(ImageContent.self)
                contentItems.append(imageContent)
            case ContentType.resource.rawValue:
                contentContainer = try container.nestedUnkeyedContainer(forKey: .content)
                let resourceContent = try contentContainer.decode(EmbeddedResource.self)
                contentItems.append(resourceContent)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .type,
                    in: contentItem, 
                    debugDescription: "不支持的內容類型: \(type)"
                )
            }
        }
        
        content = contentItems
    }
    
    private enum CodingKeys: String, CodingKey {
        case content, isError
    }
    
    private enum ContentTypeCodingKeys: String, CodingKey {
        case type
    }
}

/// Represents a tool in the MCP service
public struct MCPTool: Codable {
    /// The name of the tool
    public let name: String
    
    /// A description of what the tool does
    public let description: String
    
    /// The schema defining the tool's input parameters
    public let inputSchema: ToolSchema
    
    /// The schema defining the tool's output format (optional)
    public let outputSchema: ToolSchema?
    
    /// The handler function that processes the tool call
    public let handler: (([String: Any]) -> ToolResult)?
    
    private enum CodingKeys: String, CodingKey {
        case name, description, inputSchema, outputSchema
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        inputSchema = try container.decode(ToolSchema.self, forKey: .inputSchema)
        outputSchema = try container.decodeIfPresent(ToolSchema.self, forKey: .outputSchema)
        handler = nil // handler is not codable and will always be nil when decoded
    }
    
    public init(
        name: String,
        description: String,
        inputSchema: ToolSchema,
        outputSchema: ToolSchema? = nil,
        handler: (([String: Any]) -> ToolResult)? = nil
    ) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
        self.handler = handler
    }
    
    // For debugging: get a string representation of the tool
    public func debugDescription() -> String {
        var result = "MCPTool(name: \(name), description: \(description)"
        result += ", inputSchema: \(inputSchema)"
        if let outputSchema = outputSchema {
            result += ", outputSchema: \(outputSchema)"
        }
        result += ", handler: \(handler != nil ? "present" : "nil")"
        result += ")"
        return result
    }
} 
