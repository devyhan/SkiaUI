// LayoutProtocol.swift – SkiaUILayout module
// Strategy protocol for pluggable layout algorithms.

import SkiaUIElement

public protocol LayoutStrategy: Sendable {
    func layout(children: [Element], constraints: Constraints, measure: (Element, Constraints) -> LayoutNode) -> LayoutNode
    func layout(children: [Element], proposal: ProposedSize, measure: (Element, ProposedSize) -> LayoutNode) -> LayoutNode
}

extension LayoutStrategy {
    // Default bridge: old → new (convert constraints to proposal, delegate)
    public func layout(children: [Element], constraints: Constraints, measure: (Element, Constraints) -> LayoutNode) -> LayoutNode {
        layout(children: children, proposal: constraints.proposedSize) { element, proposal in
            measure(element, Constraints(proposed: proposal))
        }
    }
}
