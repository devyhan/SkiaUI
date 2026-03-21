import ArgumentParser
import Foundation

public struct BuildCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the current project for WebAssembly."
    )
    public init() {}

    @Option(name: .long, help: "Executable target name (auto-detected from Package.swift if omitted).")
    var product: String?

    @Option(name: .long, help: "WASM SDK identifier (auto-detected if omitted).")
    var swiftSdk: String?

    @Option(name: .shortAndLong, help: "Output directory (default: dist).")
    var output: String = "dist"

    public func run() throws {
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath

        let productName: String
        if let explicit = product {
            productName = explicit
        } else {
            productName = try detectProductName()
            print("Detected product: \(productName)")
        }

        let sdk: String
        if let explicit = swiftSdk {
            sdk = explicit
        } else {
            sdk = try detectWasmSDK()
            print("Detected WASM SDK: \(sdk)")
        }

        // Resolve toolchain: explicit > auto-detect from SDK > none
        var env: [String: String]? = nil
        if let explicit = toolchain {
            env = ["TOOLCHAINS": explicit]
            print("Using toolchain: \(explicit)")
        } else if let identifier = detectToolchainIdentifier(for: sdk) {
            env = ["TOOLCHAINS": identifier]
            print("Detected toolchain: \(identifier)")
        }

        // Auto-install matching toolchain if compiler/SDK versions mismatch
        if env == nil, let sdkVersion = extractVersion(from: sdk) {
            if let compilerVersion = detectSwiftVersion(), sdkVersion != compilerVersion {
                try installMatchingToolchain(version: sdkVersion)

                if let identifier = findToolchainIdentifier(version: sdkVersion) {
                    env = ["TOOLCHAINS": identifier]
                    print("Using installed toolchain: \(identifier)")
                } else {
                    throw DetectionError.toolchainInstallFailed(version: sdkVersion)
                }
            }
        }

        print("Building \(productName) for WebAssembly...")
        let scratchPath = cwd + "/.build/skia-wasm"
        try shellExec(
            "/usr/bin/env",
            arguments: [
                "swift", "package",
                "--disable-sandbox",
                "--scratch-path", scratchPath,
                "--swift-sdk", sdk,
                "js",
                "--product", productName,
                "-c", "release",
            ],
            environment: env
        )

        // Create output directory
        let distDir: String
        if output.hasPrefix("/") {
            distDir = output
        } else {
            distDir = cwd + "/" + output
        }

        if fm.fileExists(atPath: distDir) {
            try fm.removeItem(atPath: distDir)
        }
        try fm.createDirectory(atPath: distDir, withIntermediateDirectories: true)

        // Copy PackageToJS output
        let packageJSOutput = scratchPath + "/plugins/PackageToJS/outputs/Package"
        if fm.fileExists(atPath: packageJSOutput) {
            try fm.copyItem(atPath: packageJSOutput, toPath: distDir + "/package")
        }

        // Copy WebHost files
        let webHostDir = cwd + "/WebHost"
        if fm.fileExists(atPath: webHostDir) {
            let webHostFiles = try fm.contentsOfDirectory(atPath: webHostDir)
            for file in webHostFiles {
                try fm.copyItem(
                    atPath: webHostDir + "/\(file)",
                    toPath: distDir + "/\(file)"
                )
            }
        }

        print("Build complete! Output in \(output)/")
    }
}
