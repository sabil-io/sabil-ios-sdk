// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SabilSDK",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "SabilSDK",
            targets: ["SabilSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LaunchDarkly/swift-eventsource.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
        .target(
            name: "SabilSDK",
            dependencies: [.product(name: "LDSwiftEventSource", package: "swift-eventsource")],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
