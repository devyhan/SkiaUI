// DirtyTracker.swift – SkiaUIReconciler module
// Tracks which parts of the element tree need re-rendering.

public struct DirtyTracker: Sendable {
    private var dirtyPaths: Set<[Int]> = []

    public init() {}

    public mutating func markDirty(_ path: ElementPath) {
        dirtyPaths.insert(path.indices)
        // Also mark all ancestors as dirty
        var current = path.indices
        while !current.isEmpty {
            current.removeLast()
            dirtyPaths.insert(current)
        }
    }

    public func isDirty(_ path: ElementPath) -> Bool {
        dirtyPaths.contains(path.indices)
    }

    public mutating func clear() {
        dirtyPaths.removeAll()
    }

    public var isEmpty: Bool { dirtyPaths.isEmpty }
}
