// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SkiaUI",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SkiaUI", targets: ["SkiaUI"]),
        .library(name: "SkiaUIWebBridge", targets: ["SkiaUIWebBridge"]),
        .library(name: "SkiaUIBuildTool", targets: ["SkiaUIBuildTool"]),
        .executable(name: "SkiaUIDocsSite", targets: ["SkiaUIDocsSite"]),
        .executable(name: "skia", targets: ["skia"]),
        .plugin(name: "SkiaPlugin", targets: ["SkiaPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", exact: "0.47.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        // MARK: - Core Types
        .target(
            name: "SkiaUIDSL",
            dependencies: ["SkiaUIElement", "SkiaUIText", "SkiaUIState"]
        ),
        .target(
            name: "SkiaUIText",
            dependencies: []
        ),
        .target(
            name: "SkiaUIElement",
            dependencies: []
        ),

        // MARK: - State Management
        .target(
            name: "SkiaUIState",
            dependencies: []
        ),

        // MARK: - Reconciler
        .target(
            name: "SkiaUIReconciler",
            dependencies: ["SkiaUIElement"]
        ),

        // MARK: - Layout
        .target(
            name: "SkiaUILayout",
            dependencies: ["SkiaUIElement"]
        ),

        // MARK: - Render Tree
        .target(
            name: "SkiaUIRenderTree",
            dependencies: ["SkiaUIElement", "SkiaUILayout", "SkiaUIDisplayList"]
        ),

        // MARK: - Semantics
        .target(
            name: "SkiaUISemantics",
            dependencies: ["SkiaUIElement", "SkiaUILayout"]
        ),

        // MARK: - Display List
        .target(
            name: "SkiaUIDisplayList",
            dependencies: []
        ),

        // MARK: - Renderer
        .target(
            name: "SkiaUIRenderer",
            dependencies: ["SkiaUIDisplayList"]
        ),

        // MARK: - Runtime
        .target(
            name: "SkiaUIRuntime",
            dependencies: [
                "SkiaUIDSL",
                "SkiaUIState",
                "SkiaUIElement",
                "SkiaUIReconciler",
                "SkiaUILayout",
                "SkiaUIRenderTree",
                "SkiaUIDisplayList",
                "SkiaUIRenderer",
                "SkiaUISemantics",
            ]
        ),

        // MARK: - Web Bridge (JavaScriptKit dependency isolated here)
        .target(
            name: "SkiaUIWebBridge",
            dependencies: [
                "SkiaUIRuntime",
                "SkiaUIDisplayList",
                "SkiaUISemantics",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ]
        ),

        // MARK: - DevTools
        .target(
            name: "SkiaUIDevTools",
            dependencies: [
                "SkiaUIElement",
                "SkiaUILayout",
                "SkiaUISemantics",
                "SkiaUIRenderTree",
                "SkiaUIDisplayList",
            ]
        ),

        // MARK: - Umbrella module (single import for all public APIs)
        .target(
            name: "SkiaUI",
            dependencies: ["SkiaUIDSL", "SkiaUIState", "SkiaUIRuntime"],
            path: "Sources/SkiaUI"
        ),

        // MARK: - Docs Site (WASM demo app)
        .executableTarget(
            name: "SkiaUIDocsSite",
            dependencies: ["SkiaUI", "SkiaUIWebBridge"]
        ),

        // MARK: - Plugin (SwiftPM command plugin)
        .plugin(
            name: "SkiaPlugin",
            capability: .command(
                intent: .custom(verb: "skia", description: "Build, export, and scaffold SkiaUI WASM apps"),
                permissions: [.writeToPackageDirectory(reason: "Write build output to dist/")]
            ),
            path: "Plugins/SkiaPlugin"
        ),

        // MARK: - CLI (user-facing WASM workflow tool)
        .target(
            name: "SkiaUIBuildTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/SkiaUICLI"
        ),

        .executableTarget(
            name: "skia",
            dependencies: ["SkiaUIBuildTool"],
            path: "Sources/skia"
        ),

        // MARK: - Tests
        .testTarget(
            name: "SkiaUIDSLTests",
            dependencies: ["SkiaUIDSL"]
        ),
        .testTarget(
            name: "SkiaUIElementTests",
            dependencies: ["SkiaUIElement"]
        ),
        .testTarget(
            name: "SkiaUILayoutTests",
            dependencies: ["SkiaUILayout", "SkiaUIElement"]
        ),
        .testTarget(
            name: "SkiaUIReconcilerTests",
            dependencies: ["SkiaUIReconciler", "SkiaUIElement"]
        ),
        .testTarget(
            name: "SkiaUIStateTests",
            dependencies: ["SkiaUIState"]
        ),
        .testTarget(
            name: "SkiaUIDisplayListTests",
            dependencies: ["SkiaUIDisplayList", "SkiaUIRenderTree"]
        ),
        .testTarget(
            name: "SkiaUISemanticsTests",
            dependencies: ["SkiaUISemantics", "SkiaUIElement", "SkiaUILayout"]
        ),
        .testTarget(
            name: "SkiaUIRuntimeTests",
            dependencies: [
                "SkiaUIRuntime",
                "SkiaUIDSL",
                "SkiaUIElement",
                "SkiaUIState",
                "SkiaUIDisplayList",
                "SkiaUIReconciler",
                "SkiaUIRenderTree",
                "SkiaUILayout",
            ]
        ),
        .testTarget(
            name: "GoldenTests",
            dependencies: [
                "SkiaUI",
                "SkiaUIDSL",
                "SkiaUIElement",
                "SkiaUILayout",
                "SkiaUIRenderTree",
                "SkiaUIDisplayList",
                "SkiaUIState",
            ],
            exclude: ["__snapshots__"]
        ),
    ]
)
