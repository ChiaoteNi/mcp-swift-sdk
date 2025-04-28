import Foundation

// Sample server demonstrating registration of endpoints and handling of incoming messages using the Swift MCP SDK

class SampleServer {
    let service = MCPService()
    
    init() {
        // Register an endpoint with message type "echo"
        service.registerEndpoint("echo") { message in
            // Echo back the same payload as response
            print("Server received echo request: \(message)")
            return MCPMessage(
                type: "echo_response",
                headers: ["timestamp": ISO8601DateFormatter().string(from: Date())],
                payload: message.payload
            )
        }
    }
    
    func start() {
        // Simulate an incoming message targeting the "echo" endpoint
        let sampleMessage = MCPMessage(
            type: "echo",
            headers: ["client": "client-001"],
            payload: ["data": AnyCodable("Hello, server!")]
        )
        
        if let response = service.handleIncomingMessage(sampleMessage) {
            print("Server response: \(response)")
        } else {
            print("No handler registered for message type \(sampleMessage.type)")
        }
    }
}

// Instantiate and start the sample server
let server = SampleServer()
server.start()

// Keep the application running
RunLoop.main.run()
