import Foundation
import PackagePlugin

enum ExportAction {
    static func run(context: PluginContext, arguments: [String]) throws {
        // Run the full build first
        try BuildAction.run(context: context, arguments: arguments)

        let opts = BuildAction.parseOptions(from: arguments)
        let distDir = context.package.directoryURL.path + "/" + opts.outputDir
        let packageDir = distDir + "/package"

        guard let files = try? FileManager.default.contentsOfDirectory(atPath: packageDir) else {
            print("No package output found to compress.")
            return
        }

        let wasmFiles = files.filter { $0.hasSuffix(".wasm") }

        // Brotli compression
        compressFiles(wasmFiles, in: packageDir, tool: "brotli", arguments: ["-q", "11", "-f", "-k"], ext: ".br")

        // Gzip compression
        compressFiles(wasmFiles, in: packageDir, tool: "gzip", arguments: ["-9", "-k", "-f"], ext: ".gz")

        // File size report
        printSizeReport(wasmFiles: wasmFiles, directory: packageDir)
    }

    private static func compressFiles(
        _ files: [String],
        in directory: String,
        tool: String,
        arguments: [String],
        ext: String
    ) {
        // Check if tool is available
        let whichResult = try? ProcessRunner.output("/usr/bin/which", arguments: [tool])
        guard let toolPath = whichResult, !toolPath.isEmpty else {
            print("Warning: '\(tool)' not found, skipping \(ext) compression.")
            return
        }

        for file in files {
            let filePath = directory + "/\(file)"
            let args = arguments + [filePath]
            do {
                try ProcessRunner.exec(toolPath, arguments: args)
            } catch {
                print("Warning: Failed to compress \(file) with \(tool): \(error)")
            }
        }
    }

    private static func printSizeReport(wasmFiles: [String], directory: String) {
        let fm = FileManager.default
        print("")
        print("Export complete! File sizes:")

        for file in wasmFiles {
            let basePath = directory + "/\(file)"
            let sizes: [(String, String)] = [
                (file, basePath),
                (file + ".br", basePath + ".br"),
                (file + ".gz", basePath + ".gz"),
            ]

            for (name, path) in sizes {
                if let attrs = try? fm.attributesOfItem(atPath: path),
                   let size = attrs[.size] as? UInt64 {
                    print("  \(name): \(formatSize(size))")
                }
            }
        }
    }

    private static func formatSize(_ bytes: UInt64) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
}
