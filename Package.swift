// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Clippable",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Clippable",
            path: "Sources/Clippable",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
            ]
        )
    ]
)
