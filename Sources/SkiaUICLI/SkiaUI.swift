import ArgumentParser

@main
struct SkiaUICLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "skiaui",
        abstract: "SkiaUI – Create, build, and serve WASM apps.",
        subcommands: [
            CreateCommand.self,
            BuildCommand.self,
            ServeCommand.self,
        ]
    )
}
