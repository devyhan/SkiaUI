// RenderNode.swift – SkiaUIRenderTree module
// Render tree node representing a paintable object in the scene.

import SkiaUIElement

public final class RenderNode: @unchecked Sendable {
    public var frame: (x: Float, y: Float, width: Float, height: Float)
    public var paintStyle: PaintStyle?
    public var textContent: TextContent?
    public var children: [RenderNode]
    public var clipToBounds: Bool
    public var scrollOffset: (x: Float, y: Float)?

    public init(
        frame: (x: Float, y: Float, width: Float, height: Float) = (0, 0, 0, 0),
        paintStyle: PaintStyle? = nil,
        textContent: TextContent? = nil,
        children: [RenderNode] = [],
        clipToBounds: Bool = false,
        scrollOffset: (x: Float, y: Float)? = nil
    ) {
        self.frame = frame
        self.paintStyle = paintStyle
        self.textContent = textContent
        self.children = children
        self.clipToBounds = clipToBounds
        self.scrollOffset = scrollOffset
    }
}

public struct TextContent: Equatable, Sendable {
    public var text: String
    public var fontSize: Float
    public var fontWeight: Int
    public var color: UInt32
    public init(text: String, fontSize: Float = 14, fontWeight: Int = 400, color: UInt32 = 0xFF000000) {
        self.text = text; self.fontSize = fontSize; self.fontWeight = fontWeight; self.color = color
    }
}
