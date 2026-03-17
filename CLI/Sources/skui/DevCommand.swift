import ArgumentParser
import Foundation

struct DevCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dev",
        abstract: "Build the project then start the dev server."
    )

    func run() throws {
        let projectRoot = resolveProjectRoot()

        // Step 1: Build
        print("Building SkiaUI for WebAssembly...")
        try shellExec(
            "/usr/bin/env",
            arguments: ["swift", "build", "--swift-sdk", "wasm32-unknown-wasi"],
            currentDirectory: projectRoot
        )
        print("Build succeeded.")

        // Step 2: Start dev server
        let webClientDir = projectRoot.appendingPathComponent("WebClient")
        print("Starting dev server in WebClient...")
        try shellExec(
            "/usr/bin/env",
            arguments: ["pnpm", "dev"],
            currentDirectory: webClientDir
        )
    }
}
