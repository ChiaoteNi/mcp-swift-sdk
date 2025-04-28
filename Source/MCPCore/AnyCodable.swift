//
//  AnyCodable.swift
//  MCP SDK
//
//  Created by Chiaote Ni on 2025/5/4.
//  Copyright (c) 2025 iOS@Taipei Chiaote Ni. All rights reserved.
//

import Foundation

// A simple wrapper to allow encoding/decoding heterogeneous JSON payloads
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        do {
            let intVal = try container.decode(Int.self)
            value = intVal
            return
        } catch {}
        
        do {
            let doubleVal = try container.decode(Double.self)
            value = doubleVal
            return
        } catch {}
        
        do {
            let boolVal = try container.decode(Bool.self)
            value = boolVal
            return
        } catch {}
        
        do {
            let stringVal = try container.decode(String.self)
            value = stringVal
            return
        } catch {}
        
        do {
            let arrayVal = try container.decode([AnyCodable].self)
            value = arrayVal.map { $0.value }
            return
        } catch {}
        
        do {
            let dictVal = try container.decode([String: AnyCodable].self)
            var dict: [String: Any] = [:]
            for (key, val) in dictVal {
                dict[key] = val.value
            }
            value = dict
            return
        } catch {}
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intVal as Int:
            try container.encode(intVal)
            
        case let doubleVal as Double:
            try container.encode(doubleVal)
            
        case let boolVal as Bool:
            try container.encode(boolVal)
            
        case let stringVal as String:
            try container.encode(stringVal)
            
        case let arrayVal as [Any]:
            let encodableArray = arrayVal.map { AnyCodable($0) }
            try container.encode(encodableArray)
            
        case let dictVal as [String: Any]:
            let encodableDict = dictVal.mapValues { AnyCodable($0) }
            try container.encode(encodableDict)
            
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type")
            throw EncodingError.invalidValue(value, context)
        }
    }
    
    // For debugging: create a string representation of the value
    public func debugDescription() -> String {
        switch value {
        case let dict as [String: Any]:
            var result = "{"
            for (key, val) in dict {
                result += "\(key): \(val), "
            }
            if result.count > 1 {
                result.removeLast(2)
            }
            result += "}"
            return result
            
        case let array as [Any]:
            return "[Array with \(array.count) items]"
            
        default:
            return String(describing: value)
        }
    }
}
