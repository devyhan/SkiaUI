import Foundation

enum ToolchainResolver {
    /// Detects an installed WASM SDK from `swift sdk list`.
    /// Filters for `_wasm` suffixed entries, excludes `-embedded`.
    /// If multiple SDKs match, picks the one closest to the current Swift major.minor version.
    static func detectWasmSDK() throws -> String {
        let output = try ProcessRunner.output("/usr/bin/env", arguments: ["swift", "sdk", "list"])

        let candidates = output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasSuffix("_wasm") && !$0.contains("embedded") }

        guard !candidates.isEmpty else {
            throw PluginError.noWasmSDK
        }

        if candidates.count == 1 {
            return candidates[0]
        }

        // Multiple candidates — try to match current Swift version
        let versionOutput = (try? ProcessRunner.output("/usr/bin/env", arguments: ["swift", "--version"])) ?? ""
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
    /// e.g. "swift-6.2.4-RELEASE_wasm" -> "6.2.4"
    static func extractVersion(from sdk: String) -> String? {
        let pattern = #/swift-(\d+\.\d+(?:\.\d+)?)-/#
        guard let match = sdk.firstMatch(of: pattern) else { return nil }
        return String(match.1)
    }

    /// Detects the current Swift compiler version (e.g. "6.2" or "6.2.4").
    static func detectSwiftVersion() -> String? {
        guard let output = try? ProcessRunner.output("/usr/bin/env", arguments: ["swift", "--version"]) else {
            return nil
        }
        let pattern = #/Swift version (\d+\.\d+(?:\.\d+)?)/#
        guard let match = output.firstMatch(of: pattern) else { return nil }
        return String(match.1)
    }

    /// Searches for an xctoolchain bundle by version and returns its CFBundleIdentifier.
    static func findToolchainIdentifier(version: String) -> String? {
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
    static func installMatchingToolchain(version: String) throws {
        let fm = FileManager.default
        let toolchainName = "swift-\(version)-RELEASE.xctoolchain"

        // Skip if already installed
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

        try ProcessRunner.exec("/usr/bin/curl", arguments: [
            "-f", "-L", "--progress-bar",
            "-o", pkgPath, url,
        ])

        print("Extracting toolchain...")

        try ProcessRunner.exec("/usr/sbin/pkgutil", arguments: [
            "--expand", pkgPath, expandedPath,
        ])

        try fm.createDirectory(atPath: payloadDir, withIntermediateDirectories: true)

        try ProcessRunner.exec("/bin/bash", arguments: ["-c", """
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

        let toolchainsDir = NSHomeDirectory() + "/Library/Developer/Toolchains"
        let destination = toolchainsDir + "/" + toolchainName
        try fm.createDirectory(atPath: toolchainsDir, withIntermediateDirectories: true)

        guard fm.fileExists(atPath: payloadDir + "/Info.plist") else {
            throw PluginError.toolchainInstallFailed(version: version)
        }

        if fm.fileExists(atPath: destination) {
            try fm.removeItem(atPath: destination)
        }
        try fm.moveItem(atPath: payloadDir, toPath: destination)

        print("Installed toolchain: \(destination)")
        print("")
    }

    /// Orchestrator: resolves the environment dict needed for WASM builds.
    /// Returns `[String: String]` with TOOLCHAINS set, or nil if no override needed.
    static func resolveEnvironment(
        explicitToolchain: String?,
        sdk: String
    ) throws -> [String: String]? {
        // Explicit toolchain takes priority
        if let explicit = explicitToolchain {
            print("Using toolchain: \(explicit)")
            return ["TOOLCHAINS": explicit]
        }

        // Try auto-detect from SDK version
        if let version = extractVersion(from: sdk),
           let identifier = findToolchainIdentifier(version: version) {
            print("Detected toolchain: \(identifier)")
            return ["TOOLCHAINS": identifier]
        }

        // Auto-install if compiler/SDK versions mismatch
        if let sdkVersion = extractVersion(from: sdk) {
            if let compilerVersion = detectSwiftVersion(), sdkVersion != compilerVersion {
                try installMatchingToolchain(version: sdkVersion)

                if let identifier = findToolchainIdentifier(version: sdkVersion) {
                    print("Using installed toolchain: \(identifier)")
                    return ["TOOLCHAINS": identifier]
                } else {
                    throw PluginError.toolchainInstallFailed(version: sdkVersion)
                }
            }
        }

        return nil
    }
}
