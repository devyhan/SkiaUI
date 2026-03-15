// DebugOverlay.swift – SkiaUIDevTools module
// Generates a display list overlay showing layout bounding boxes.

import SkiaUILayout
import SkiaUIDisplayList

public struct DebugOverlay: Sendable {
    public init() {}

    public func generateOverlay(layout: LayoutNode) -> DisplayList {
        var list = DisplayList()
        emitBounds(layout, into: &list, offsetX: 0, offsetY: 0)
        return list
    }

    private func emitBounds(_ node: LayoutNode, into list: inout DisplayList, offsetX: Float, offsetY: Float) {
        let absX = offsetX + node.x
        let absY = offsetY + node.y

        // Draw bounding box outline (red, semi-transparent)
        list.append(.save)
        list.append(.translate(x: absX, y: absY))
        // Draw top edge
        list.append(.drawRect(x: 0, y: 0, width: node.width, height: 1, color: 0x80FF0000))
        // Draw bottom edge
        list.append(.drawRect(x: 0, y: node.height - 1, width: node.width, height: 1, color: 0x80FF0000))
        // Draw left edge
        list.append(.drawRect(x: 0, y: 0, width: 1, height: node.height, color: 0x80FF0000))
        // Draw right edge
        list.append(.drawRect(x: node.width - 1, y: 0, width: 1, height: node.height, color: 0x80FF0000))
        list.append(.restore)

        for child in node.children {
            emitBounds(child, into: &list, offsetX: absX, offsetY: absY)
        }
    }
}
