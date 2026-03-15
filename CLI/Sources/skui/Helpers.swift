import ArgumentParser
import Foundation

/// Resolves the project root directory (parent of the CLI directory).
func resolveProjectRoot() -> URL {
    let cliDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // Sources/skui
        .deletingLastPathComponent() // Sources
        .deletingLastPathComponent() // CLI
    return cliDir
}

/// Executes a shell command synchronously and forwards its output.
@discardableResult
func shellExec(
    _ executablePath: String,
    arguments: [String],
    currentDirectory: URL
) throws -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = arguments
    process.currentDirectoryURL = currentDirectory
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw ExitCode(process.terminationStatus)
    }
    return process.terminationStatus
}
