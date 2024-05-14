// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftLiveView",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "SwiftLiveView",
            targets: ["SwiftLiveView"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "SwiftLiveView",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SwiftLiveViewTests",
            dependencies: ["SwiftLiveView"],
            resources: [
                .copy("TestFiles")
            ]
        )
    ]
)
