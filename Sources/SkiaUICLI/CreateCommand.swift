import ArgumentParser
import Foundation

public struct CreateCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new SkiaUI WASM project."
    )
    public init() {}

    @Argument(help: "Name of the project to create.")
    var name: String

    public func run() throws {
        let fm = FileManager.default
        let projectDir = fm.currentDirectoryPath + "/\(name)"

        guard !fm.fileExists(atPath: projectDir) else {
            throw ValidationError("Directory '\(name)' already exists.")
        }

        // Create directory structure
        try fm.createDirectory(atPath: projectDir + "/Sources", withIntermediateDirectories: true)
        try fm.createDirectory(atPath: projectDir + "/WebHost", withIntermediateDirectories: true)

        // Write files
        try Templates.packageSwift(name: name).write(
            toFile: projectDir + "/Package.swift", atomically: true, encoding: .utf8
        )
        try Templates.appSwift(name: name).write(
            toFile: projectDir + "/Sources/App.swift", atomically: true, encoding: .utf8
        )
        try Templates.indexHTML.write(
            toFile: projectDir + "/WebHost/index.html", atomically: true, encoding: .utf8
        )
        try Templates.displayListPlayerMJS.write(
            toFile: projectDir + "/WebHost/displayListPlayer.mjs", atomically: true, encoding: .utf8
        )
        try Templates.buildSH.write(
            toFile: projectDir + "/build.sh", atomically: true, encoding: .utf8
        )

        // Make build.sh executable
        try fm.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: projectDir + "/build.sh"
        )

        print("Created '\(name)/' with the following structure:")
        print("  \(name)/")
        print("  ├── Package.swift")
        print("  ├── Sources/")
        print("  │   └── App.swift")
        print("  ├── WebHost/")
        print("  │   ├── index.html")
        print("  │   └── displayListPlayer.mjs")
        print("  └── build.sh")
        print("")
        print("Next steps:")
        print("  cd \(name)")
        print("  skia build")
    }
}
