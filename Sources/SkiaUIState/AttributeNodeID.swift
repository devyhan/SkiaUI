// AttributeNodeID.swift – SkiaUIState module
// Identifier for nodes in the attribute dependency graph.

public struct AttributeNodeID: Hashable, Sendable {
    public let path: [Int]
    public let kind: Kind

    public enum Kind: Hashable, Sendable {
        case source
        case computed
    }

    public init(path: [Int], kind: Kind) {
        self.path = path
        self.kind = kind
    }

    /// Convenience for source nodes keyed by @State slot ID.
    public init(sourcePath: [Int]) {
        self.path = sourcePath
        self.kind = .source
    }

    /// Convenience for computed nodes keyed by View structural path.
    public init(viewPath: [Int]) {
        self.path = viewPath
        self.kind = .computed
    }
}
