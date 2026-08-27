// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AthanBarV2",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AthanBarV2", targets: ["AthanBarV2"])
    ],
    targets: [
        .executableTarget(
            name: "AthanBarV2",
            path: "Sources/AthanBarV2",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
