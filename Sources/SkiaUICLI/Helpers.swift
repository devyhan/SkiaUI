import Foundation

/// Executes a shell command synchronously and forwards its output.
@discardableResult
func shellExec(
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
    case toolchainInstallFailed(version: String)

    var description: String {
        switch self {
        case .noExecutableTarget:
            return "No executableTarget found in Package.swift. Use --product to specify one."
        case .noWasmSDK:
            return "No WASM SDK found. Install one with: swift sdk install <url>"
        case .toolchainInstallFailed(let version):
            return "Failed to install Swift \(version) toolchain. Please install manually from https://swift.org/install"
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

/// Extracts the version string from a WASM SDK name.
/// e.g. "swift-6.2.4-RELEASE_wasm" → "6.2.4"
func extractVersion(from sdk: String) -> String? {
    let pattern = #/swift-(\d+\.\d+(?:\.\d+)?)-/#
    guard let match = sdk.firstMatch(of: pattern) else { return nil }
    return String(match.1)
}

/// Detects the current Swift compiler version (e.g. "6.2" or "6.2.4").
func detectSwiftVersion() -> String? {
    guard let output = try? shellOutput("/usr/bin/env", arguments: ["swift", "--version"]) else {
        return nil
    }
    let pattern = #/Swift version (\d+\.\d+(?:\.\d+)?)/#
    guard let match = output.firstMatch(of: pattern) else { return nil }
    return String(match.1)
}

/// Finds a matching toolchain's CFBundleIdentifier for the given SDK version.
/// Searches both system and user toolchain directories.
func detectToolchainIdentifier(for sdk: String) -> String? {
    guard let version = extractVersion(from: sdk) else { return nil }
    return findToolchainIdentifier(version: version)
}

/// Searches for an xctoolchain bundle by version and returns its CFBundleIdentifier.
func findToolchainIdentifier(version: String) -> String? {
    let toolchainName = "swift-\(version)-RELEASE.xctoolchain"
    let searchPaths = [
        NSHomeDirectory() + "/Library/Developer/Toolchains/" + toolchainName,
        "/Library/Developer/Toolchains/" + toolchainName,
    ]

    for path in searchPaths {
        let plistPath = path + "/Info.plist"
        guard FileManager.default.fileExists(atPath: plistPath),
              let data = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let identifier = plist["CFBundleIdentifier"] as? String
        else { continue }
        return identifier
    }
    return nil
}

/// Downloads and installs a Swift toolchain to ~/Library/Developer/Toolchains/.
/// Extracts the .pkg payload without requiring sudo.
func installMatchingToolchain(version: String) throws {
    let fm = FileManager.default
    let toolchainName = "swift-\(version)-RELEASE.xctoolchain"

    // Skip if already installed (check both user and system paths)
    let checkPaths = [
        NSHomeDirectory() + "/Library/Developer/Toolchains/" + toolchainName,
        "/Library/Developer/Toolchains/" + toolchainName,
    ]
    for path in checkPaths {
        if fm.fileExists(atPath: path) { return }
    }

    let url = "https://download.swift.org/swift-\(version)-release/xcode/swift-\(version)-RELEASE/swift-\(version)-RELEASE-osx.pkg"
    let tmpDir = NSTemporaryDirectory() + "skiaui-toolchain-\(version)"
    let pkgPath = tmpDir + "/swift.pkg"
    let expandedPath = tmpDir + "/expanded"
    let payloadDir = tmpDir + "/payload"

    defer {
        try? fm.removeItem(atPath: tmpDir)
    }

    try fm.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)

    print("")
    print("Swift compiler (\(detectSwiftVersion() ?? "unknown")) does not match WASM SDK (\(version)).")
    print("Auto-installing Swift \(version) toolchain...")
    print("")

    try shellExec("/usr/bin/curl", arguments: [
        "-f", "-L", "--progress-bar",
        "-o", pkgPath, url,
    ])

    print("Extracting toolchain...")

    // Step 1: Expand pkg structure (decomposes distribution, does NOT extract payloads)
    try shellExec("/usr/sbin/pkgutil", arguments: [
        "--expand", pkgPath, expandedPath,
    ])

    // Step 2: Extract payload (contents are the xctoolchain bundle internals)
    try fm.createDirectory(atPath: payloadDir, withIntermediateDirectories: true)

    try shellExec("/bin/bash", arguments: ["-c", """
        PAYLOAD="$(find '\(expandedPath)' -name 'Payload' -type f | head -1)"
        if [ -z "$PAYLOAD" ]; then
            echo "Error: No Payload found in package"
            exit 1
        fi
        cd '\(payloadDir)'
        gunzip -dc "$PAYLOAD" 2>/dev/null | cpio -id 2>/dev/null
        if [ -f Info.plist ]; then exit 0; fi
        cpio -id < "$PAYLOAD" 2>/dev/null
        if [ -f Info.plist ]; then exit 0; fi
        xz -dc "$PAYLOAD" 2>/dev/null | cpio -id 2>/dev/null
        if [ -f Info.plist ]; then exit 0; fi
        if command -v aa >/dev/null 2>&1; then
            aa extract -i "$PAYLOAD" -o . 2>/dev/null
            if [ -f Info.plist ]; then exit 0; fi
        fi
        echo "Error: Could not extract toolchain payload"
        exit 1
    """])

    // Step 3: Move extracted contents as .xctoolchain bundle to user directory
    let toolchainsDir = NSHomeDirectory() + "/Library/Developer/Toolchains"
    let destination = toolchainsDir + "/" + toolchainName
    try fm.createDirectory(atPath: toolchainsDir, withIntermediateDirectories: true)

    guard fm.fileExists(atPath: payloadDir + "/Info.plist") else {
        throw DetectionError.toolchainInstallFailed(version: version)
    }

    if fm.fileExists(atPath: destination) {
        try fm.removeItem(atPath: destination)
    }
    try fm.moveItem(atPath: payloadDir, toPath: destination)

    print("Installed toolchain: \(destination)")
    print("")
}
