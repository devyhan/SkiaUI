import Foundation
import PackagePlugin

enum BuildAction {
    struct Options {
        var product: String?
        var swiftSDK: String?
        var toolchain: String?
        var outputDir: String = "dist"
        var configuration: String = "release"
        var skipOptimize: Bool = false
    }

    static func parseOptions(from arguments: [String]) -> Options {
        var extractor = ArgumentExtractor(arguments)
        var opts = Options()
        opts.product = extractor.extractOption(named: "product").last
        opts.swiftSDK = extractor.extractOption(named: "swift-sdk").last
        opts.toolchain = extractor.extractOption(named: "toolchain").last
        opts.outputDir = extractor.extractOption(named: "output").last ?? "dist"
        opts.configuration = extractor.extractOption(named: "c").last ?? "release"
        opts.skipOptimize = extractor.extractFlag(named: "skip-optimize") > 0
        return opts
    }

    static func run(context: PluginContext, arguments: [String]) throws {
        let opts = parseOptions(from: arguments)

        // 1. Resolve product name
        let productName: String
        if let explicit = opts.product {
            productName = explicit
        } else {
            productName = try detectExecutableTarget(context: context)
            print("Detected product: \(productName)")
        }

        // 2. Resolve WASM SDK
        let sdk: String
        if let explicit = opts.swiftSDK {
            sdk = explicit
        } else {
            sdk = try ToolchainResolver.detectWasmSDK()
            print("Detected WASM SDK: \(sdk)")
        }

        // 3. Resolve toolchain environment
        let env = try ToolchainResolver.resolveEnvironment(
            explicitToolchain: opts.toolchain,
            sdk: sdk
        )

        // 4. Run PackageToJS build
        print("Building \(productName) for WebAssembly...")
        
        let scratchPath = context.package.directoryURL.appendingPathComponent(".build/skia-wasm").path
        
        try ProcessRunner.exec(
            "/usr/bin/env",
            arguments: [
                "swift", "package",
                "--disable-sandbox",
                "--scratch-path", scratchPath,
                "--swift-sdk", sdk,
                "js",
                "--product", productName,
                "-c", opts.configuration,
            ],
            currentDirectory: context.package.directoryURL,
            environment: env
        )

        // 5. wasm-opt optimization (if available and not skipped)
        if !opts.skipOptimize {
            optimizeWasm(packageDirectory: context.package.directoryURL)
        }

        // 6. Assemble dist/
        try DistAssembler.assemble(
            packageDirectory: context.package.directoryURL,
            outputDirectory: opts.outputDir
        )

        print("Build complete! Output in \(opts.outputDir)/")
    }

    /// Auto-detect the first executable target in the package.
    private static func detectExecutableTarget(context: PluginContext) throws -> String {
        for target in context.package.targets {
            if let sourceModule = target as? SwiftSourceModuleTarget,
               sourceModule.kind == .executable {
                return target.name
            }
        }
        throw PluginError.noExecutableTarget
    }

    /// Try to run wasm-opt on the built .wasm file (best-effort).
    private static func optimizeWasm(packageDirectory: URL) {
        let wasmOptPath = "/usr/local/bin/wasm-opt"
        guard FileManager.default.fileExists(atPath: wasmOptPath) else { return }

        let packageJSOutput = packageDirectory.path + "/.build/skia-wasm/plugins/PackageToJS/outputs/Package"
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: packageJSOutput) else { return }

        for file in files where file.hasSuffix(".wasm") {
            let wasmPath = packageJSOutput + "/\(file)"
            print("Optimizing \(file)...")
            _ = try? ProcessRunner.exec(wasmOptPath, arguments: [
                "-Os", "--enable-bulk-memory", "--strip-debug",
                wasmPath, "-o", wasmPath,
            ])
        }
    }
}
