// SemanticsUpdate.swift – SkiaUISemantics module
// Semantics tree container with JSON serialization support.

import Foundation

public struct SemanticsTree: Equatable, Sendable {
    public var root: SemanticsNode
    public var version: Int

    public init(root: SemanticsNode = SemanticsNode(), version: Int = 0) {
        self.root = root; self.version = version
    }

    public func toJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(root)
    }

    public static func fromJSON(_ data: Data) -> SemanticsTree? {
        guard let root = try? JSONDecoder().decode(SemanticsNode.self, from: data) else { return nil }
        return SemanticsTree(root: root)
    }
}
