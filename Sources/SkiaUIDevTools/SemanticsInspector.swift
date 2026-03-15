// SemanticsInspector.swift – SkiaUIDevTools module
// Developer tool for inspecting semantics tree nodes.

import SkiaUISemantics

public struct SemanticsInspector: Sendable {
    public init() {}

    public func dump(node: SemanticsNode, indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        var desc = "\(prefix)SemanticsNode(id: \(node.id), role: \(node.role.rawValue)"
        if let label = node.label { desc += ", label: \"\(label)\"" }
        if let hint = node.hint { desc += ", hint: \"\(hint)\"" }
        if !node.actions.isEmpty { desc += ", actions: [\(node.actions.map(\.rawValue).joined(separator: ", "))]" }
        if node.isHidden { desc += ", hidden" }
        desc += ")"
        lines.append(desc)

        for child in node.children {
            lines.append(dump(node: child, indent: indent + 1))
        }

        return lines.joined(separator: "\n")
    }
}
