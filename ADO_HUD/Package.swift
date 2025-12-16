// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ADO_HUD",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ADO_HUD", targets: ["ADO_HUD"])
    ],
    targets: [
        .executableTarget(
            name: "ADO_HUD",
            path: "Sources/ADO_HUD"
        )
    ]
)
