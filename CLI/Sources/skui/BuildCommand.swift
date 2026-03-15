import ArgumentParser
import Foundation

struct BuildCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the SkiaUI project for WebAssembly."
    )

    func run() throws {
        let projectRoot = resolveProjectRoot()

        print("Building SkiaUI for WebAssembly...")
        try shellExec(
            "/usr/bin/env",
            arguments: ["swift", "build", "--swift-sdk", "wasm32-unknown-wasi"],
            currentDirectory: projectRoot
        )
        print("Build succeeded.")
    }
}
