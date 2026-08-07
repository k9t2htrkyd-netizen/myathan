// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AthanBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AthanBar", targets: ["AthanBar"])
    ],
    targets: [
        .executableTarget(
            name: "AthanBar",
            path: "Sources/AthanBar",
            exclude: ["Resources/._athan-amman-jordan.mp3"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
