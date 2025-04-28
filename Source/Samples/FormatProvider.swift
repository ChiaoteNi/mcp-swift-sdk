import Foundation
import MCPServer

/// Sample implementation of a Format Provider using the Swift MCP SDK
public class FormatProvider {
    private let service: MCPService
    private let provider: MCPProvider
    
    private let formatTemplates: [String: String] = [
        "commit": "feat(scope): concise description\n\nMore detailed explanatory text if needed.",
        "pr-title": "feat(scope): concise description",
        "pr-description": "## What changes were made\n- Change 1\n- Change 2\n\n## Testing performed\n- Test description\n\n## Related issues\n- #123",
        "branch": "feature/description",
        "code-review": "## Overall impression\nClear and concise code.\n\n## Suggestions\n- Consider adding more tests\n- Documentation could be improved"
    ]
    
    public init() {
        // Configure the service
        service = MCPService(name: "Swift Format Provider", version: "1.0.0")
        
        // Create the provider with the service
        provider = MCPProvider(service: service)
        
        // Now that all properties are initialized, we can register tools
        registerTools()
        
        // Log initialization
        MCPLogger.logInfo("FormatProvider initialized with \(formatTemplates.count) templates")
    }
    
    private func registerTools() {
        // Register the get_format_template tool
        let getFormatTemplateTool = MCPTool(
            name: "get_format_template",
            description: "Get format template for a specific type",
            inputSchema: [
                "type": "object",
                "properties": [
                    "formatType": [
                        "type": "string",
                        "description": "Format type",
                        "enum": Array(formatTemplates.keys)
                    ]
                ],
                "required": ["formatType"]
            ],
            outputSchema: [
                "type": "object",
                "properties": [
                    "template": [
                        "type": "string",
                        "description": "The template for the format type"
                    ]
                ],
                "required": ["template"]
            ],
            handler: { [weak self] arguments in
                // Handle the tool call
                guard let self = self,
                      let formatType = arguments["formatType"] as? String,
                      let template = self.formatTemplates[formatType] else {
                    return [
                        "content": [
                            ["type": "text", "text": "Format type not found"]
                        ],
                        "isError": true
                    ]
                }
                
                return [
                    "content": [
                        ["type": "text", "text": template]
                    ]
                ]
            }
        )
        
        service.registerTool(getFormatTemplateTool)
        MCPLogger.logInfo("Registered get_format_template tool")
    }
    
    /// Start the format provider
    public func start() {
        MCPLogger.logInfo("Starting FormatProvider")
        provider.start()
    }
} 
