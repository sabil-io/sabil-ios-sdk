// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SabilSDK",
    platforms: [.iOS(.v14)],
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
