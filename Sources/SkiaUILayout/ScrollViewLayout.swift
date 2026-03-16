// ScrollViewLayout.swift – SkiaUILayout module
// Layout strategy for ScrollView: unconstrains the scroll axis.

import SkiaUIElement

public struct ScrollViewLayout: LayoutStrategy, Sendable {
    public let axis: Element.ScrollAxis

    public init(axis: Element.ScrollAxis) {
        self.axis = axis
    }

    public func layout(children: [Element], proposal: ProposedSize,
                       measure: (Element, ProposedSize) -> LayoutNode) -> LayoutNode {
        guard let child = children.first else { return LayoutNode() }

        let childProposal: ProposedSize = switch axis {
        case .vertical:   ProposedSize(width: proposal.width, height: nil)
        case .horizontal: ProposedSize(width: nil, height: proposal.height)
        }

        var childNode = measure(child, childProposal)
        childNode.x = 0
        childNode.y = 0

        return LayoutNode(
            width: proposal.width ?? childNode.width,
            height: proposal.height ?? childNode.height,
            children: [childNode]
        )
    }
}
