import Foundation

enum ProcessRunner {
    /// Executes a command synchronously, streaming stdout/stderr via Pipe + print().
    /// SwiftPM plugins cannot inherit FileHandle.standardOutput directly,
    /// so we read from pipes and forward through print().
    @discardableResult
    static func exec(
        _ executablePath: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String]? = nil
    ) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        if let dir = currentDirectory {
            process.currentDirectoryURL = dir
        }
        if let env = environment {
            var merged = ProcessInfo.processInfo.environment
            for (key, value) in env { merged[key] = value }
            process.environment = merged
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Stream output asynchronously as it arrives
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                print(str, terminator: "")
            }
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                print(str, terminator: "")
            }
        }

        try process.run()
        process.waitUntilExit()

        // Clean up handlers
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        // Drain any remaining data
        if let remaining = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8),
           !remaining.isEmpty {
            print(remaining, terminator: "")
        }
        if let remaining = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8),
           !remaining.isEmpty {
            print(remaining, terminator: "")
        }

        guard process.terminationStatus == 0 else {
            throw PluginError.processExit(code: process.terminationStatus)
        }
        return process.terminationStatus
    }

    /// Executes a command and captures its stdout as a String.
    static func output(
        _ executablePath: String,
        arguments: [String]
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PluginError.processExit(code: process.terminationStatus)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
