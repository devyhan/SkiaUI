// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SkiaUI",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SkiaUI", targets: ["SkiaUI"]),
    ],
    dependencies: [
        // JavaScriptKit dependency is needed only for Wasm builds.
        // Uncomment when building for WebAssembly with a valid fork:
        // .package(url: "https://github.com/nicklimmm/JavaScriptKit.git", branch: "nicklimmm/6.2-nightly"),
    ],
    targets: [
        // MARK: - Core Types
        .target(
            name: "SkiaUIDSL",
            dependencies: ["SkiaUIElement", "SkiaUIText"]
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
                // Uncomment when building for Wasm:
                // .product(name: "JavaScriptKit", package: "JavaScriptKit"),
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
            dependencies: ["SkiaUIDSL", "SkiaUIState", "SkiaUIRuntime"]
        ),

        // MARK: - Preview (native executable for display list generation)
        .executableTarget(
            name: "SkiaUIPreview",
            dependencies: ["SkiaUI"]
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
            dependencies: ["SkiaUIDisplayList"]
        ),
        .testTarget(
            name: "SkiaUISemanticsTests",
            dependencies: ["SkiaUISemantics", "SkiaUIElement", "SkiaUILayout"]
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
