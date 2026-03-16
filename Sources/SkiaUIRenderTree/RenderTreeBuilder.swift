// RenderTreeBuilder.swift – SkiaUIRenderTree module
// Converts LayoutNode + Element trees into a RenderNode tree for painting.

import SkiaUIElement
import SkiaUILayout

public struct RenderTreeBuilder: Sendable {
    private let renderCache: RenderCache

    public init(renderCache: RenderCache = RenderCache()) {
        self.renderCache = renderCache
    }

    public func build(element: Element, layout: LayoutNode, scrollOffsets: [Int: Float] = [:]) -> RenderNode {
        let node = buildNode(element: element, layout: layout, inheritedColor: 0xFF000000, scrollOffsets: scrollOffsets, pathIndex: 0)
        node.subtreeID = 0
        return node
    }

    private func buildNode(element: Element, layout: LayoutNode, inheritedColor: UInt32, scrollOffsets: [Int: Float] = [:], pathIndex: Int = 0) -> RenderNode {
        switch element {
        case .empty:
            return RenderNode(frame: (layout.x, layout.y, layout.width, layout.height))

        case .text(let text, let props):
            let color = props.foregroundColor?.uint32 ?? inheritedColor
            return RenderNode(
                frame: (layout.x, layout.y, layout.width, layout.height),
                textContent: TextContent(
                    text: text,
                    fontSize: props.fontSize,
                    fontWeight: props.fontWeight,
                    color: color,
                    fontFamily: props.fontFamily
                )
            )

        case .rectangle(let props):
            return RenderNode(
                frame: (layout.x, layout.y, layout.width, layout.height),
                paintStyle: PaintStyle(fillColor: props.fillColor.uint32, cornerRadius: props.cornerRadius)
            )

        case .spacer:
            return RenderNode(frame: (layout.x, layout.y, layout.width, layout.height))

        case .container(let props, let children):
            let childNodes = zip(children, layout.children).enumerated().map { (i, pair) in
                let (childEl, childLayout) = pair
                let childID = (pathIndex &* 31 &+ (i + 1)) & 0x7FFFFFFF
                let node = buildNode(element: childEl, layout: childLayout, inheritedColor: inheritedColor, scrollOffsets: scrollOffsets, pathIndex: childID)
                node.subtreeID = childID
                return node
            }
            if case .scroll(let axis, let scrollID) = props.layout {
                let offset = scrollOffsets[scrollID] ?? 0
                let scrollOff: (x: Float, y: Float) = switch axis {
                case .vertical:   (0, -offset)
                case .horizontal: (-offset, 0)
                }
                return RenderNode(
                    frame: (layout.x, layout.y, layout.width, layout.height),
                    children: childNodes,
                    clipToBounds: true,
                    scrollOffset: scrollOff
                )
            }
            return RenderNode(
                frame: (layout.x, layout.y, layout.width, layout.height),
                children: childNodes
            )

        case .modified(let inner, let modifier):
            return buildModified(inner: inner, modifier: modifier, layout: layout, inheritedColor: inheritedColor, scrollOffsets: scrollOffsets, pathIndex: pathIndex)
        }
    }

    private func buildModified(inner: Element, modifier: Element.Modifier, layout: LayoutNode, inheritedColor: UInt32, scrollOffsets: [Int: Float] = [:], pathIndex: Int = 0) -> RenderNode {
        var color = inheritedColor

        switch modifier {
        case .background(let bgColor):
            let innerNode = buildNode(element: inner, layout: layout, inheritedColor: color, scrollOffsets: scrollOffsets, pathIndex: pathIndex)
            let bgRect = RenderNode(
                frame: (0, 0, innerNode.frame.width, innerNode.frame.height),
                paintStyle: PaintStyle(fillColor: bgColor.uint32)
            )
            let wrapper = RenderNode(
                frame: innerNode.frame,
                children: [bgRect, innerNode]
            )
            innerNode.frame = (0, 0, innerNode.frame.width, innerNode.frame.height)
            return wrapper

        case .foregroundColor(let fgColor):
            color = fgColor.uint32
            return buildNode(element: inner, layout: layout, inheritedColor: color, scrollOffsets: scrollOffsets, pathIndex: pathIndex)

        case .font(let size, let weight, let family):
            let node = buildNode(element: inner, layout: layout, inheritedColor: color, scrollOffsets: scrollOffsets, pathIndex: pathIndex)
            applyFont(to: node, size: size, weight: weight, family: family)
            return node

        case .padding, .frame:
            let innerLayout = layout.children.first ?? layout
            let innerNode = buildNode(element: inner, layout: innerLayout, inheritedColor: color, scrollOffsets: scrollOffsets, pathIndex: pathIndex)
            return RenderNode(
                frame: (layout.x, layout.y, layout.width, layout.height),
                children: [innerNode]
            )

        case .drawingGroup:
            // Check render cache for this subtree
            let cacheID = pathIndex
            if let cached = renderCache.get(id: cacheID, element: .modified(inner, modifier), layout: layout) {
                return cached
            }
            let node = buildNode(element: inner, layout: layout, inheritedColor: color, scrollOffsets: scrollOffsets, pathIndex: pathIndex)
            renderCache.set(id: cacheID, element: .modified(inner, modifier), layout: layout, node: node)
            return node

        case .onTap, .accessibilityLabel, .accessibilityRole, .accessibilityHint, .accessibilityHidden,
             .layoutPriority, .fixedSize:
            return buildNode(element: inner, layout: layout, inheritedColor: color, scrollOffsets: scrollOffsets, pathIndex: pathIndex)
        }
    }

    private func applyFont(to node: RenderNode, size: Float, weight: Int, family: String? = nil) {
        if var tc = node.textContent {
            tc.fontSize = size
            tc.fontWeight = weight
            if let family { tc.fontFamily = family }
            node.textContent = tc
        }
        for child in node.children {
            applyFont(to: child, size: size, weight: weight, family: family)
        }
    }
}

// MARK: - Render Cache

/// Reference-type cache for RenderNode subtrees marked with `.drawingGroup`.
/// Caches nodes keyed by (id, element, layout) so unchanged subtrees skip RenderNode construction.
public final class RenderCache: @unchecked Sendable {
    struct Entry {
        let element: Element
        let layout: LayoutNode
        let node: RenderNode
    }

    private var entries: [Int: Entry] = [:]

    public init() {}

    func get(id: Int, element: Element, layout: LayoutNode) -> RenderNode? {
        guard let entry = entries[id],
              entry.element == element,
              entry.layout == layout else { return nil }
        return entry.node
    }

    func set(id: Int, element: Element, layout: LayoutNode, node: RenderNode) {
        entries[id] = Entry(element: element, layout: layout, node: node)
    }

    public func clear() {
        entries.removeAll()
    }
}
