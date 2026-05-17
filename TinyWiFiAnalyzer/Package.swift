// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TinyWiFiAnalyzer",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TinyWiFiAnalyzer", targets: ["TinyWiFiAnalyzer"])
    ],
    targets: [
        .executableTarget(
            name: "TinyWiFiAnalyzer"
        ),
        .testTarget(
            name: "TinyWiFiAnalyzerTests",
            dependencies: ["TinyWiFiAnalyzer"]
        ),
    ]
)
