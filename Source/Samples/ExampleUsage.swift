import Foundation

// Import the SDK modules as needed
// For illustration, assuming the modules are accessible via the package

// Example usage of the Swift MCP SDK
class ExampleUsage {
    func run() {
        // Example: Perform handshake using SessionManager
        SessionManager.shared.performHandshake(clientId: "client-12345", authToken: "abcdef123456") { handshakeAccepted in
            if handshakeAccepted {
                print("Handshake accepted")
                
                // Send initialization notification after handshake
                SessionManager.shared.sendInitialization(meta: ["clientVersion": "1.0"]) { initAckReceived in
                    if initAckReceived {
                        print("Initialization acknowledged by the server.")
                    } else {
                        print("Initialization acknowledgment not received.")
                    }
                }
            } else {
                print("Handshake failed.")
            }
        }

        // Async/await version example
        Task {
            let handshakeOk = await SessionManager.shared.performHandshake(clientId: "client-12345", authToken: "abcdef123456")
            if handshakeOk {
                print("(Async) Handshake accepted")
                let initOk = await SessionManager.shared.sendInitialization(meta: ["clientVersion": "1.0"])
                print(initOk ? "(Async) Initialization acknowledged" : "(Async) Initialization ack not received")
            } else {
                print("(Async) Handshake failed")
            }
        }
    }
}

// To run the example, create an instance of ExampleUsage and call run()
let example = ExampleUsage()
example.run()
