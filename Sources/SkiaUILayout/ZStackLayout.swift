// ZStackLayout.swift – SkiaUILayout module
// ZStack layout strategy: overlapping children centered by default.

import SkiaUIElement

public struct ZStackLayout: LayoutStrategy, Sendable {
    public let alignment: Int

    public init(alignment: Int = 4) { self.alignment = alignment }

    public func layout(children: [Element], proposal: ProposedSize, measure: (Element, ProposedSize) -> LayoutNode) -> LayoutNode {
        guard !children.isEmpty else { return LayoutNode() }

        var childNodes = children.map { measure($0, proposal) }
        let maxW = childNodes.reduce(Float(0)) { max($0, $1.width) }
        let maxH = childNodes.reduce(Float(0)) { max($0, $1.height) }

        let hAlign = alignment % 3  // 0=leading, 1=center, 2=trailing
        let vAlign = alignment / 3  // 0=top, 1=center, 2=bottom
        for i in 0..<childNodes.count {
            childNodes[i].x = switch hAlign {
            case 0: Float(0)
            case 2: maxW - childNodes[i].width
            default: (maxW - childNodes[i].width) / 2
            }
            childNodes[i].y = switch vAlign {
            case 0: Float(0)
            case 2: maxH - childNodes[i].height
            default: (maxH - childNodes[i].height) / 2
            }
        }

        return LayoutNode(width: maxW, height: maxH, children: childNodes)
    }
}
