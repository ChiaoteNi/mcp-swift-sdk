import XCTest
@testable import MCPCore
@testable import MCPNetwork
@testable import API
@testable import Utilities

final class MCPTests: XCTestCase {
    func testExample() {
        // TODO: Write tests for MCP message encoding/decoding
        let message = MCPMessage(type: "test", headers: ["key": "value"], payload: nil)
        XCTAssertEqual(message.type, "test")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
