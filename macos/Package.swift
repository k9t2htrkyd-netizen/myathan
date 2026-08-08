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
            exclude: [
                "Resources/._athan-amman-jordan.mp3",
                "Resources/alarms/._alert-alarm.mp3",
                "Resources/alarms/._classic-alarm.mp3",
                "Resources/alarms/._correct-answer-tone.mp3",
                "Resources/alarms/._digital-clock-beep.mp3",
                "Resources/alarms/._facility-alarm.mp3",
                "Resources/alarms/._game-notification-wave.mp3",
                "Resources/alarms/._positive-notification.mp3",
                "Resources/alarms/._software-interface-start.mp3",
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
