import Foundation

enum PluginError: Error, CustomStringConvertible {
    case noSubcommand
    case unknownSubcommand(String)
    case noExecutableTarget
    case noWasmSDK
    case missingProjectName
    case directoryExists(String)
    case toolchainInstallFailed(version: String)
    case processExit(code: Int32)

    var description: String {
        switch self {
        case .noSubcommand:
            return "No subcommand specified. Use 'skia --help' for usage."
        case .unknownSubcommand(let cmd):
            return "Unknown subcommand '\(cmd)'. Use 'skia --help' for usage."
        case .noExecutableTarget:
            return "No executableTarget found in package. Use --product to specify one."
        case .noWasmSDK:
            return "No WASM SDK found. Install one with: swift sdk install <url>"
        case .missingProjectName:
            return "Missing project name. Usage: swift package skia create <name>"
        case .directoryExists(let name):
            return "Directory '\(name)' already exists."
        case .toolchainInstallFailed(let version):
            return "Failed to install Swift \(version) toolchain. Please install manually from https://swift.org/install"
        case .processExit(let code):
            return "Process exited with code \(code)"
        }
    }
}
