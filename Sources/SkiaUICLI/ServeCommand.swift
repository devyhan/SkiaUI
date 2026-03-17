import ArgumentParser
import Foundation

struct ServeCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Serve the dist/ directory with a local HTTP server."
    )

    @Option(name: .long, help: "Port to serve on.")
    var port: Int = 8080

    func run() throws {
        let fm = FileManager.default
        let distDir = fm.currentDirectoryPath + "/dist"

        guard fm.fileExists(atPath: distDir) else {
            throw ValidationError("dist/ directory not found. Run 'skiaui build' first.")
        }

        print("Serving dist/ on http://localhost:\(port)")
        try shellExec(
            "/usr/bin/env",
            arguments: ["python3", "-m", "http.server", "\(port)", "-d", "dist"]
        )
    }
}
