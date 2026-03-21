import ArgumentParser
public struct SkiaUICLI: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "skia",
        abstract: "SkiaUI – Create and build WASM apps.",
        subcommands: [
            CreateCommand.self,
            BuildCommand.self,
        ]
    )
    public init() {}
}
