// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Click",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Click",
            path: "Sources/Click",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
            ]
        )
    ]
)
