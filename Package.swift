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
    targets: [
        .target(
            name: "SabilSDK",
            dependencies: [])
    ]
)
