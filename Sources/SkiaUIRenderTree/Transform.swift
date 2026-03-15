// Transform.swift – SkiaUIRenderTree module
// 2D transform for positioning render nodes.

public struct Transform: Equatable, Sendable {
    public var translateX: Float
    public var translateY: Float
    public init(translateX: Float = 0, translateY: Float = 0) {
        self.translateX = translateX; self.translateY = translateY
    }
    public static let identity = Transform()
}
