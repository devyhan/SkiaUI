// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BasicApp",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/devyhan/SkiaUI.git", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", exact: "0.47.1"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "SkiaUI", package: "SkiaUI"),
                .product(name: "SkiaUIWebBridge", package: "SkiaUI"),
            ]
        ),
    ]
)
