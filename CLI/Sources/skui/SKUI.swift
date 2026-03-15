import ArgumentParser

@main
struct SKUI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "skui",
        abstract: "SkiaUI development CLI tool.",
        subcommands: [
            BuildCommand.self,
            DevCommand.self,
            TestCommand.self,
            LintCommand.self,
        ]
    )
}
