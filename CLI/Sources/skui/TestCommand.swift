import ArgumentParser
import Foundation

struct TestCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Run the SkiaUI test suite."
    )

    func run() throws {
        let projectRoot = resolveProjectRoot()

        print("Running tests...")
        try shellExec(
            "/usr/bin/env",
            arguments: ["swift", "test"],
            currentDirectory: projectRoot
        )
        print("Tests passed.")
    }
}
