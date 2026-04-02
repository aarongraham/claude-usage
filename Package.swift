// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeUsage",
    platforms: [.macOS(.v15)],
    targets: [
        .target(
            name: "ClaudeUsageCore",
            path: "Sources/ClaudeUsageCore",
            linkerSettings: [.linkedFramework("Security")]
        ),
        .executableTarget(
            name: "ClaudeUsage",
            dependencies: ["ClaudeUsageCore"],
            path: "Sources/ClaudeUsage",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "ClaudeUsageCoreTests",
            dependencies: ["ClaudeUsageCore"],
            path: "Tests/ClaudeUsageCoreTests"
        ),
    ]
)
