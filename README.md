# MCP Swift SDK

This SDK helps you build MCP (Message Channel Protocol) services in Swift.
It provides a set of core abstractions and utilities for defining, registering, and running MCP-compatible services and tools.

## Features

- Register and expose MCP tools
- Handle requests and responses via process or SSE channels
- Logging support (file and console)
- Extensible service and provider architecture

## Installation

### Using Swift Package Manager

```swift
# Add to your Package.swift dependencies:
.package(url: "https://github.com/your-org/swift-sdk.git", from: "1.0.0")
```

## Quickstart

```swift
import swift-sdk

let service = MyMCPService()
let provider = MCPProvider(service: service)
provider.start()
```

## Usage

### Registering a Tool

```swift
```swift
import MCPServer

// 1. Define your tool's input/output schema
let inputSchema = ToolSchema(
    properties: [
        "name": SchemaProperty(type: .string, description: "User name", required: true)
    ],
    required: ["name"]
)
let outputSchema = ToolSchema(
    properties: [
        "greeting": SchemaProperty(type: .string, description: "Greeting message", required: true)
    ],
    required: ["greeting"]
)

// 2. Create the tool
let greetTool = MCPTool(
    name: "greet",
    description: "Say hello to a user",
    inputSchema: inputSchema,
    outputSchema: outputSchema
) { args in
    let name = args["name"] as? String ?? "Guest"
    let message = "Hello, \(name)!"
    return ToolResult(content: [TextContent(text: message)])
}

// 3. Register the tool and start the service
let service = MCPService(name: "Greeting Service", version: "1.0.0")
service.registerTool(greetTool)
```

### Logging

Enable or disable file/console logging via `MCPProvider` initializer.

## Advanced
- **Channel Types:** Supports `.process`, `.sse(URL)`, and `.custom(MessageChannelProtocol)`
- **Custom Message Channels:** Implement `MessageChannelProtocol` for custom transport

## How to Build Your Own MCP Service

1. Define your tools (input/output schema, handler).
2. Register tools to an `MCPService`.
3. Create an `MCPProvider` with the service.
4. Call `provider.start()` to run the service.

## Key Concepts

### MCPService

- The main entry point for registering tools and handling requests.
- You create an `MCPService` instance, register your tools, and pass it to an `MCPProvider`.

### MCPProvider

- Handles the message channel (process/stdin-stdout or SSE).
- Starts the main run loop and dispatches requests to the service.

### MCPTool

- Represents a callable tool (function) with a name, description, input schema, output schema, and a handler closure.
- The handler receives a `[String: Any]` dictionary of arguments and returns a `ToolResult`.

### ToolSchema & SchemaProperty

- Used to define the input and output structure for each tool.
- Supports types: string, stringEnum, number, integer, boolean, array, object.

### ToolResult & ContentItem

- The result of a tool call, containing one or more content items (text, image, resource).
- Can indicate error status.


## Protocol Compatibility

This SDK supports MCP protocol version: **2024-11-05**

Please ensure your client/server uses a compatible protocol version.

## Contributing

We welcome contributions from the community! If you would like to help improve the Swift MCP SDK, please follow the guidelines below to ensure a smooth and productive collaboration.

### How to Contribute

- **Report Issues:**  
  If you encounter bugs, unexpected behavior, or have feature requests, please [open an issue](https://github.com/your-org/swift-sdk/issues) with a clear description and, if possible, steps to reproduce.

- **Submit Pull Requests:**  
  1. Fork this repository and create a new branch for your feature or bugfix.
  2. Make your changes, following the coding standards described below.
  3. Add or update tests as appropriate.
  4. Ensure all tests pass and the codebase builds successfully.
  5. Submit a pull request with a clear description of your changes and reference any related issues.

### Coding Standards

- Please follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- All code must pass [SwiftLint](https://github.com/realm/SwiftLint) checks.  
  Key rules include:
  - No trailing whitespace
  - Use shorthand syntax for optional binding
  - Single trailing newline at end of file
  - Single empty line between switch cases
- Write clear, concise comments in English (B1/B2 level).
- Keep lines reasonably short for readability.

### Testing

- All new features and bugfixes should include appropriate unit tests.
- Run `swift test` to ensure all tests pass before submitting your pull request.
- If you are adding a new feature, consider adding documentation and usage examples.

### Communication

- For major changes or design discussions, please open an issue to discuss your ideas before starting work.
- For questions, you may also contact the maintainers via [email](mailto:maintainer@email.com).

### License

By contributing, you agree that your contributions will be licensed under the MIT License, the same as this project.

## License

MIT License

## Contact

For questions, open an issue or contact [maintainer@email.com](mailto:maintainer@email.com)