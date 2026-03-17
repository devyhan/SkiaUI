// SemanticsTreeBuilder.swift – SkiaUISemantics module
// Builds a SemanticsTree from Element + LayoutNode trees.

import SkiaUIElement
import SkiaUILayout

public struct SemanticsTreeBuilder: Sendable {
    public init() {}

    private var nextID = 0

    public mutating func build(element: Element, layout: LayoutNode) -> SemanticsTree {
        nextID = 0
        let root = buildNode(element: element, layout: layout, offsetX: 0, offsetY: 0)
        return SemanticsTree(root: root)
    }

    private mutating func buildNode(element: Element, layout: LayoutNode, offsetX: Float, offsetY: Float) -> SemanticsNode {
        let id = nextID
        nextID += 1
        let absX = offsetX + layout.x
        let absY = offsetY + layout.y
        let frame = SemanticsRect(x: absX, y: absY, width: layout.width, height: layout.height)

        switch element {
        case .empty:
            return SemanticsNode(id: id, role: .none, frame: frame)

        case .text(let text, _):
            return SemanticsNode(id: id, role: .text, label: text, frame: frame)

        case .rectangle:
            return SemanticsNode(id: id, role: .none, frame: frame)

        case .spacer:
            return SemanticsNode(id: id, role: .none, frame: frame, isHidden: true)

        case .image(let props):
            return SemanticsNode(id: id, role: .image, label: props.source.sourceString, frame: frame)

        case .container(_, let children):
            var childNodes: [SemanticsNode] = []
            for (i, child) in children.enumerated() {
                if i < layout.children.count {
                    let childNode = buildNode(element: child, layout: layout.children[i], offsetX: absX, offsetY: absY)
                    childNodes.append(childNode)
                }
            }
            return SemanticsNode(id: id, role: .container, frame: frame, children: childNodes)

        case .modified(let inner, let modifier):
            let innerLayout = layout.children.first ?? layout
            var node = buildNode(element: inner, layout: innerLayout, offsetX: absX, offsetY: absY)
            applyModifier(&node, modifier: modifier)
            node.frame = frame
            return node
        }
    }

    private func applyModifier(_ node: inout SemanticsNode, modifier: Element.Modifier) {
        switch modifier {
        case .onTap:
            node.role = .button
            node.actions.append(.tap)
        case .onLongPress:
            node.actions.append(.longPress)
        case .onDrag:
            break
        case .accessibilityLabel(let label):
            node.label = label
        case .accessibilityRole(let role):
            if let r = SemanticsRole(rawValue: role) {
                node.role = r
            }
        case .accessibilityHint(let hint):
            node.hint = hint
        case .accessibilityHidden(let hidden):
            node.isHidden = hidden
        default:
            break
        }
    }
}
