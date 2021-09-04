// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "MicroPNG",
    products: [
        .library(
            name: "MicroPNG",
            targets: ["MicroPNG"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MicroPNG",
            dependencies: []),
        .testTarget(
            name: "MicroPNGTests",
            dependencies: ["MicroPNG"],
            resources: [
                .copy("Data"),
            ])
    ]
)
