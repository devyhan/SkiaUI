// RetainedSubtree.swift – SkiaUIDisplayList module
// Cache for retained subtree versioning to skip unchanged subtrees.

public struct RetainedSubtreeCache: Sendable {
    private var cache: [Int: Int] = [:] // subtree id -> version

    public init() {}

    public mutating func isValid(id: Int, version: Int) -> Bool {
        if let cached = cache[id], cached == version {
            return true
        }
        cache[id] = version
        return false
    }

    public mutating func invalidate(id: Int) {
        cache.removeValue(forKey: id)
    }

    public mutating func clear() {
        cache.removeAll()
    }
}
