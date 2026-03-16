// RenderTreeBuilder.swift – SkiaUIRenderTree module
// Converts LayoutNode + Element trees into a RenderNode tree for painting.

import SkiaUIElement
import SkiaUILayout

public struct RenderTreeBuilder: Sendable {
    public init() {}

    public func build(element: Element, layout: LayoutNode, scrollOffsets: [Int: Float] = [:]) -> RenderNode {
        return buildNode(element: element, layout: layout, inheritedColor: 0xFF000000, scrollOffsets: scrollOffsets)
    }

    private func buildNode(element: Element, layout: LayoutNode, inheritedColor: UInt32, scrollOffsets: [Int: Float] = [:]) -> RenderNode {
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
                    color: color
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
            let childNodes = zip(children, layout.children).map { (childEl, childLayout) in
                buildNode(element: childEl, layout: childLayout, inheritedColor: inheritedColor, scrollOffsets: scrollOffsets)
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
            return buildModified(inner: inner, modifier: modifier, layout: layout, inheritedColor: inheritedColor, scrollOffsets: scrollOffsets)
        }
    }

    private func buildModified(inner: Element, modifier: Element.Modifier, layout: LayoutNode, inheritedColor: UInt32, scrollOffsets: [Int: Float] = [:]) -> RenderNode {
        var color = inheritedColor

        switch modifier {
        case .background(let bgColor):
            let innerNode = buildNode(element: inner, layout: layout, inheritedColor: color, scrollOffsets: scrollOffsets)
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
            return buildNode(element: inner, layout: layout, inheritedColor: color, scrollOffsets: scrollOffsets)

        case .font(let size, let weight):
            let node = buildNode(element: inner, layout: layout, inheritedColor: color, scrollOffsets: scrollOffsets)
            applyFont(to: node, size: size, weight: weight)
            return node

        case .padding, .frame:
            let innerLayout = layout.children.first ?? layout
            let innerNode = buildNode(element: inner, layout: innerLayout, inheritedColor: color, scrollOffsets: scrollOffsets)
            return RenderNode(
                frame: (layout.x, layout.y, layout.width, layout.height),
                children: [innerNode]
            )

        case .onTap, .accessibilityLabel, .accessibilityRole, .accessibilityHint, .accessibilityHidden,
             .layoutPriority, .fixedSize:
            return buildNode(element: inner, layout: layout, inheritedColor: color, scrollOffsets: scrollOffsets)
        }
    }

    private func applyFont(to node: RenderNode, size: Float, weight: Int) {
        if var tc = node.textContent {
            tc.fontSize = size
            tc.fontWeight = weight
            node.textContent = tc
        }
        for child in node.children {
            applyFont(to: child, size: size, weight: weight)
        }
    }
}
