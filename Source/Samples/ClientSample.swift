import Foundation

// Sample client demonstrating handshake and initialization using the Swift MCP SDK

func runClientSample() {
    let clientId = "client-001"
    
    // Perform handshake and initialization using async/await
    Task {
        let handshakeResult = await SessionManager.shared.performHandshake(clientId: clientId, authToken: "secret-token")
        if handshakeResult {
            print("Handshake succeeded.")
            let initResult = await SessionManager.shared.sendInitialization(meta: ["clientVersion": "1.0"])
            if initResult {
                print("Initialization acknowledged by server.")
            } else {
                print("Initialization acknowledgment not received.")
            }
        } else {
            print("Handshake failed.")
        }
    }
}

// Run the sample client
runClientSample()

// Keep the application alive to wait for async tasks
RunLoop.main.run()
