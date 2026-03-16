// DisplayListBuilder.swift – SkiaUIRenderTree module
// Converts RenderNode tree into a flat DisplayList of draw commands.

import SkiaUIDisplayList

public struct DisplayListBuilder: Sendable {
    public var retainedCache: RetainedSubtreeCache

    public init(retainedCache: RetainedSubtreeCache = RetainedSubtreeCache()) {
        self.retainedCache = retainedCache
    }

    public mutating func build(from root: RenderNode) -> DisplayList {
        var list = DisplayList()
        emitNode(root, into: &list)
        return list
    }

    private mutating func emitNode(_ node: RenderNode, into list: inout DisplayList) {
        let (x, y, w, h) = node.frame

        // Retained subtree optimization: skip inner commands if cache is valid
        if let subtreeID = node.subtreeID {
            let version = node.subtreeVersion
            if retainedCache.isValid(id: subtreeID, version: version) {
                // Cache hit — emit markers only, skip inner draw commands
                list.append(.retainedSubtreeBegin(id: subtreeID, version: version))
                list.append(.retainedSubtreeEnd)
                return
            }
            // Cache miss — emit full content with markers
            list.append(.retainedSubtreeBegin(id: subtreeID, version: version))
        }

        list.append(.save)
        if x != 0 || y != 0 {
            list.append(.translate(x: x, y: y))
        }

        if node.clipToBounds {
            list.append(.clipRect(x: 0, y: 0, width: w, height: h))
        }

        if let scroll = node.scrollOffset, (scroll.x != 0 || scroll.y != 0) {
            list.append(.translate(x: scroll.x, y: scroll.y))
        }

        // Draw background/fill
        if let paint = node.paintStyle, let color = paint.fillColor {
            if paint.cornerRadius > 0 {
                list.append(.drawRRect(x: 0, y: 0, width: w, height: h, radius: paint.cornerRadius, color: color))
            } else {
                list.append(.drawRect(x: 0, y: 0, width: w, height: h, color: color))
            }
        }

        // Draw text
        if let text = node.textContent {
            list.append(.drawText(text: text.text, x: 0, y: text.fontSize, fontSize: text.fontSize, fontWeight: text.fontWeight, color: text.color, boundsWidth: w, fontFamily: text.fontFamily))
        }

        // Draw children
        for child in node.children {
            emitNode(child, into: &list)
        }

        list.append(.restore)

        if node.subtreeID != nil {
            list.append(.retainedSubtreeEnd)
        }
    }
}
