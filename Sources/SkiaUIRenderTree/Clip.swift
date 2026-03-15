// Clip.swift – SkiaUIRenderTree module
// Clipping region for render nodes.

public enum Clip: Equatable, Sendable {
    case none
    case rect(x: Float, y: Float, width: Float, height: Float)
}
