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
    case noWasmSDK

    var description: String {
        switch self {
        case .noExecutableTarget:
            return "No executableTarget found in Package.swift. Use --product to specify one."
        case .noWasmSDK:
            return "No WASM SDK found. Install one with: swift sdk install <url>"
        }
    }
}

/// Executes a command and captures its stdout as a String.
func shellOutput(_ executablePath: String, arguments: [String]) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = arguments

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw ExitError(code: process.terminationStatus)
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

/// Detects an installed WASM SDK from `swift sdk list`.
/// Filters for `_wasm` suffixed entries, excludes `-embedded`.
/// If multiple SDKs match, picks the one closest to the current Swift major.minor version.
func detectWasmSDK() throws -> String {
    let output = try shellOutput("/usr/bin/env", arguments: ["swift", "sdk", "list"])

    let candidates = output
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { $0.hasSuffix("_wasm") && !$0.contains("embedded") }

    guard !candidates.isEmpty else {
        throw DetectionError.noWasmSDK
    }

    if candidates.count == 1 {
        return candidates[0]
    }

    // Multiple candidates — try to match current Swift version
    let versionOutput = (try? shellOutput("/usr/bin/env", arguments: ["swift", "--version"])) ?? ""
    let versionPattern = #/Swift version (\d+)\.(\d+)/#
    if let match = versionOutput.firstMatch(of: versionPattern) {
        let major = String(match.1)
        let minor = String(match.2)
        let prefix = "swift-\(major).\(minor)"
        if let matched = candidates.first(where: { $0.hasPrefix(prefix) }) {
            return matched
        }
    }

    // Fallback: pick the last (most recent) entry
    return candidates.last!
}
