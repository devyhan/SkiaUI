import ArgumentParser
import Foundation

struct LintCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lint",
        abstract: "Lint Swift sources with SwiftFormat."
    )

    func run() throws {
        let projectRoot = resolveProjectRoot()

        print("Linting Swift sources...")
        try shellExec(
            "/usr/bin/env",
            arguments: ["swiftformat", "--lint", "."],
            currentDirectory: projectRoot
        )
        print("Lint passed.")
    }
}
