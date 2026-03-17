import Foundation

/// Executes a shell command synchronously and forwards its output.
@discardableResult
func shellExec(
    _ executablePath: String,
    arguments: [String],
    currentDirectory: URL? = nil
) throws -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = arguments
    if let dir = currentDirectory {
        process.currentDirectoryURL = dir
    }
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw ExitError(code: process.terminationStatus)
    }
    return process.terminationStatus
}

struct ExitError: Error, CustomStringConvertible {
    let code: Int32
    var description: String { "Process exited with code \(code)" }
}

/// Reads the contents of a file at the given path.
func readFile(at path: String) throws -> String {
    try String(contentsOfFile: path, encoding: .utf8)
}

/// Detects the first executable target name from Package.swift in the current directory.
func detectProductName() throws -> String {
    let packagePath = FileManager.default.currentDirectoryPath + "/Package.swift"
    let content = try readFile(at: packagePath)

    // Look for .executableTarget(name: "...")
    let pattern = #/\.executableTarget\s*\(\s*name:\s*"([^"]+)"/#
    guard let match = content.firstMatch(of: pattern) else {
        throw DetectionError.noExecutableTarget
    }
    return String(match.1)
}

enum DetectionError: Error, CustomStringConvertible {
    case noExecutableTarget

    var description: String {
        switch self {
        case .noExecutableTarget:
            return "No executableTarget found in Package.swift. Use --product to specify one."
        }
    }
}
