// PaintStyle.swift – SkiaUIRenderTree module
// Paint properties for rendering nodes (fill color, corner radius, etc.).

public struct PaintStyle: Equatable, Sendable {
    public var fillColor: UInt32?
    public var cornerRadius: Float
    public init(fillColor: UInt32? = nil, cornerRadius: Float = 0) {
        self.fillColor = fillColor; self.cornerRadius = cornerRadius
    }
}
