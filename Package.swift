// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MCP",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MCPClient",
            targets: ["MCPClient"]
        ),
        .library(
            name: "MCPServer",
            targets: ["MCPServer"]
        )
    ],
    targets: [
        .target(
            name: "MCPCore"
        ),
        .target(
            name: "MCPUtilities",
            dependencies: ["MCPCore"]
        ),
        .target(
            name: "MCPNetworking",
            dependencies: ["MCPCore", "MCPUtilities"]
        ),
        .target(
            name: "MCPClient",
            dependencies: ["MCPCore", "MCPNetworking", "MCPUtilities"]
        ),
        .target(
            name: "MCPServer",
            dependencies: ["MCPCore", "MCPNetworking", "MCPUtilities"]
        )
    ]
)
