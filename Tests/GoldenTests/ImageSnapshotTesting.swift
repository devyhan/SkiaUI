// ImageSnapshotTesting.swift – GoldenTests
// Captures a View's display list, renders it via Node.js + CanvasKit,
// and compares the resulting PNG against a reference snapshot.

import Testing
import Foundation
import SkiaUIDSL
import SkiaUIDisplayList

func assertImageSnapshot<V: View>(
    _ view: V,
    named name: String,
    width: Float = 200,
    height: Float = 100,
    file: String = #filePath,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    // 1. Capture display list and encode to binary
    let runner = GoldenTestRunner(goldensDir: "")
    let displayList = runner.captureDisplayList(view, width: width, height: height)
    let binary = CommandEncoder().encode(displayList)

    // 2. Resolve paths
    let testFileURL = URL(fileURLWithPath: file)
    let goldenTestsDir = testFileURL.deletingLastPathComponent()
    let projectRoot = goldenTestsDir
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let renderScript = projectRoot
        .appendingPathComponent("WebHost/scripts/render.mjs").path
    let webHostDir = projectRoot
        .appendingPathComponent("WebHost").path
    let snapshotsDir = goldenTestsDir
        .appendingPathComponent("__snapshots__")

    // 3. Ensure snapshots directory exists
    try? FileManager.default.createDirectory(
        at: snapshotsDir, withIntermediateDirectories: true
    )

    // 4. Run Node.js renderer
    let nodeResult = runNodeRenderer(
        binary: binary,
        renderScript: renderScript,
        workingDirectory: webHostDir,
        width: Int(width),
        height: Int(height)
    )

    guard let pngData = nodeResult else {
        Issue.record(
            "Node.js renderer failed — is Node.js installed and are WebHost dependencies available? Run: cd WebHost && pnpm install",
            sourceLocation: sourceLocation
        )
        return
    }

    // 5. Compare or save snapshot
    let update = ProcessInfo.processInfo.environment["UPDATE_SNAPSHOTS"] == "1"
    let refPath = snapshotsDir.appendingPathComponent("\(name).png")
    let actualPath = snapshotsDir.appendingPathComponent("\(name).actual.png")

    if update || !FileManager.default.fileExists(atPath: refPath.path) {
        try? pngData.write(to: refPath)
        // Clean up stale actual file
        try? FileManager.default.removeItem(at: actualPath)
        return
    }

    guard let refData = try? Data(contentsOf: refPath) else {
        Issue.record(
            "Failed to read reference snapshot at \(refPath.path)",
            sourceLocation: sourceLocation
        )
        return
    }

    if pngData != refData {
        try? pngData.write(to: actualPath)
        Issue.record(
            "Snapshot mismatch for \"\(name)\". Actual saved to \(actualPath.lastPathComponent). Run with UPDATE_SNAPSHOTS=1 to update.",
            sourceLocation: sourceLocation
        )
    } else {
        // Match — remove any stale actual file
        try? FileManager.default.removeItem(at: actualPath)
    }
}

// MARK: - Node.js Process Runner

private func runNodeRenderer(
    binary: [UInt8],
    renderScript: String,
    workingDirectory: String,
    width: Int,
    height: Int
) -> Data? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["node", renderScript]
    process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

    // Add mise shims to PATH for Node.js discovery
    var env = ProcessInfo.processInfo.environment
    let miseShims = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".local/share/mise/shims").path
    if let existingPath = env["PATH"] {
        env["PATH"] = "\(miseShims):\(existingPath)"
    } else {
        env["PATH"] = miseShims
    }
    env["RENDER_WIDTH"] = "\(width)"
    env["RENDER_HEIGHT"] = "\(height)"
    process.environment = env

    let stdinPipe = Pipe()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardInput = stdinPipe
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
        try process.run()
    } catch {
        return nil
    }

    // Write binary to stdin and close
    stdinPipe.fileHandleForWriting.write(Data(binary))
    stdinPipe.fileHandleForWriting.closeFile()

    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrStr = String(decoding: stderrData, as: UTF8.self)
        if !stderrStr.isEmpty {
            print("render.mjs stderr: \(stderrStr)")
        }
        return nil
    }

    let output = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    return output.isEmpty ? nil : output
}
