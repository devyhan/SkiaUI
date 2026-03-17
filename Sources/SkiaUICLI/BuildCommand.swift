import ArgumentParser
import Foundation

struct BuildCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the current project for WebAssembly."
    )

    @Option(name: .long, help: "Executable target name (auto-detected from Package.swift if omitted).")
    var product: String?

    @Option(name: .long, help: "WASM SDK identifier (auto-detected if omitted).")
    var swiftSdk: String?

    func run() throws {
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

        print("Building \(productName) for WebAssembly...")
        try shellExec(
            "/usr/bin/env",
            arguments: [
                "swift", "package",
                "--swift-sdk", sdk,
                "js",
                "--product", productName,
                "-c", "release",
            ]
        )

        // Create dist/ directory
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let distDir = cwd + "/dist"

        if fm.fileExists(atPath: distDir) {
            try fm.removeItem(atPath: distDir)
        }
        try fm.createDirectory(atPath: distDir, withIntermediateDirectories: true)

        // Copy PackageToJS output
        let packageJSOutput = cwd + "/.build/plugins/PackageToJS/outputs/Package"
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

        print("Build complete! Output in dist/")
        print("Run 'skiaui serve' to start a local server.")
    }
}
