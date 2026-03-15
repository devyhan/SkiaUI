// DisplayList.swift – SkiaUIDisplayList module
// Serialized list of draw commands for deferred rendering.

public struct DisplayList: Equatable, Sendable {
    public var commands: [DrawCommand]
    public var version: Int

    public init(commands: [DrawCommand] = [], version: Int = 0) {
        self.commands = commands
        self.version = version
    }

    public mutating func append(_ command: DrawCommand) {
        commands.append(command)
    }

    public mutating func append(contentsOf other: [DrawCommand]) {
        commands.append(contentsOf: other)
    }

    public var isEmpty: Bool { commands.isEmpty }
    public var count: Int { commands.count }
}
