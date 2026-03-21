// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "GenericServerExample",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../../../") // Local SkiaUI dependency
    ],
    targets: [
        .executableTarget(
            name: "GenericServer",
            dependencies: [
                .product(name: "SkiaUI", package: "SkiaUI")
            ]
        )
    ]
)
