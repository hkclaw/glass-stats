// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlassStatsCore",
    products: [
        .library(name: "GlassStatsCore", targets: ["GlassStatsCore"]),
    ],
    targets: [
        .target(
            name: "GlassStatsCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "GlassStatsCoreTests",
            dependencies: ["GlassStatsCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
