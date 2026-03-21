import PackagePlugin
import Foundation

@main
struct SkiaPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {
        guard let subcommand = arguments.first else {
            printUsage()
            return
        }

        let subArgs = Array(arguments.dropFirst())

        switch subcommand {
        case "build":
            try BuildAction.run(context: context, arguments: subArgs)
        case "export":
            try ExportAction.run(context: context, arguments: subArgs)
        case "create":
            try CreateAction.run(context: context, arguments: subArgs)
        case "--help", "-h", "help":
            printUsage()
        default:
            throw PluginError.unknownSubcommand(subcommand)
        }
    }

    private func printUsage() {
        print("""
        USAGE: swift package skia <subcommand> [options]

        SUBCOMMANDS:
          build       Build the current project for WebAssembly
          export      Build and compress for production deployment
          create      Create a new SkiaUI WASM project

        BUILD OPTIONS:
          --product <name>      Executable target name (auto-detected if omitted)
          --swift-sdk <sdk>     WASM SDK identifier (auto-detected if omitted)
          --toolchain <id>      Toolchain identifier (auto-detected if omitted)
          --output <dir>        Output directory (default: dist)
          -c <config>           Build configuration (default: release)
          --skip-optimize       Skip wasm-opt optimization

        EXPORT OPTIONS:
          (same as build, plus brotli/gzip compression)

        CREATE OPTIONS:
          <name>                Name of the new project

        EXAMPLES:
          swift run skia build
          swift run skia build --product MyApp
          swift package skia create MyApp
        """)
    }
}
