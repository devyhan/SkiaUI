// SemanticsNode.swift – SkiaUISemantics module
// Semantics tree node for accessibility and testing.

public struct SemanticsNode: Equatable, Sendable, Codable {
    public var id: Int
    public var role: SemanticsRole
    public var label: String?
    public var hint: String?
    public var frame: SemanticsRect
    public var actions: [SemanticsAction]
    public var children: [SemanticsNode]
    public var isHidden: Bool

    public init(
        id: Int = 0,
        role: SemanticsRole = .none,
        label: String? = nil,
        hint: String? = nil,
        frame: SemanticsRect = .zero,
        actions: [SemanticsAction] = [],
        children: [SemanticsNode] = [],
        isHidden: Bool = false
    ) {
        self.id = id; self.role = role; self.label = label; self.hint = hint
        self.frame = frame; self.actions = actions; self.children = children; self.isHidden = isHidden
    }
}

public struct SemanticsRect: Equatable, Sendable, Codable {
    public var x: Float, y: Float, width: Float, height: Float
    public init(x: Float = 0, y: Float = 0, width: Float = 0, height: Float = 0) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
    public static let zero = SemanticsRect()
}
