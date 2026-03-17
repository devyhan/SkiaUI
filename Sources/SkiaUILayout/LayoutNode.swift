// LayoutNode.swift – SkiaUILayout module
// Result of layout computation, representing positioned geometry.

public struct LayoutNode: Hashable, Sendable {
    public var x: Float
    public var y: Float
    public var width: Float
    public var height: Float
    public var children: [LayoutNode]

    public init(x: Float = 0, y: Float = 0, width: Float = 0, height: Float = 0, children: [LayoutNode] = []) {
        self.x = x; self.y = y; self.width = width; self.height = height; self.children = children
    }
}
