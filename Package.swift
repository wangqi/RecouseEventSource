// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RecouseEventSource",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "RecouseEventSource", targets: ["RecouseEventSource"]),
    ],
    targets: [
        .target(name: "RecouseEventSource"),
        .testTarget(name: "RecouseEventSourceTests", dependencies: ["RecouseEventSource"]),
    ]
)
