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
    public var subtreeID: Int?
    public var subtreeVersion: Int

    public init(
        frame: (x: Float, y: Float, width: Float, height: Float) = (0, 0, 0, 0),
        paintStyle: PaintStyle? = nil,
        textContent: TextContent? = nil,
        children: [RenderNode] = [],
        clipToBounds: Bool = false,
        scrollOffset: (x: Float, y: Float)? = nil,
        subtreeID: Int? = nil,
        subtreeVersion: Int = 0
    ) {
        self.frame = frame
        self.paintStyle = paintStyle
        self.textContent = textContent
        self.children = children
        self.clipToBounds = clipToBounds
        self.scrollOffset = scrollOffset
        self.subtreeID = subtreeID
        self.subtreeVersion = subtreeVersion
    }
}

public struct TextContent: Equatable, Sendable {
    public var text: String
    public var fontSize: Float
    public var fontWeight: Int
    public var color: UInt32
    public var fontFamily: String?
    public init(text: String, fontSize: Float = 14, fontWeight: Int = 400, color: UInt32 = 0xFF000000, fontFamily: String? = nil) {
        self.text = text; self.fontSize = fontSize; self.fontWeight = fontWeight; self.color = color; self.fontFamily = fontFamily
    }
}
