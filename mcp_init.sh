#!/bin/bash

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Please provide a project name:"
    echo "Usage: ./init-mcp-project.sh YourProjectName"
    exit 1
fi

# Initialize a Swift executable package
swift package init --type executable --name "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# Add MCP Swift SDK to Package.swift dependencies
sed -i '' '/dependencies: \[/a\
        .package(url: "https://github.com/ChiaoteNi/mcp-swift-sdk.git", from: "0.1.0"),
' Package.swift

# Add MCP product to target dependencies
sed -i '' "/\.target(/,/dependencies: \[/ s/dependencies: \[/dependencies: \[\n                .product(name: \"MCP\", package: \"mcp-swift-sdk\"),/" Package.swift

# Replace main.swift content (so it compiles)
cat > "Sources/$PROJECT_NAME/main.swift" <<EOF
import MCP

@main
struct SwiftAppFormatProvider {
    static func main() {
        print("🔧 MCP Provider is ready to start (not implemented yet)")
        // TODO: Start using MCP SDK here...
    }
}
EOF

# Create the build.sh script
cat > build.sh <<'EOF'
#!/bin/bash
# Minimal startup script for the MCP provider

# Go to the folder of this script
cd "$(dirname "$0")" > /dev/null 2>&1

# Build the app (optional — comment this out if already built)
swift build -q -c release > /dev/null 2>&1

# Run the built app
.build/release/SwiftAppFormatProvider

# Return the app's exit code
exit $?
EOF

chmod +x build.sh

echo "✅ Done! Run ./build.sh to build and start the MCP project."