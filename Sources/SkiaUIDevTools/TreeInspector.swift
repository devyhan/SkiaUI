// TreeInspector.swift – SkiaUIDevTools module
// Developer tool for inspecting element and layout trees.

import SkiaUIElement
import SkiaUILayout

public struct TreeInspector: Sendable {
    public init() {}

    public func dump(element: Element, indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        switch element {
        case .empty:
            lines.append("\(prefix)EmptyView")
        case .text(let text, let props):
            let familyStr = props.fontFamily.map { ", family: \"\($0)\"" } ?? ""
            lines.append("\(prefix)Text(\"\(text)\", fontSize: \(props.fontSize), weight: \(props.fontWeight)\(familyStr))")
        case .rectangle(let props):
            lines.append("\(prefix)Rectangle(color: 0x\(String(props.fillColor.uint32, radix: 16)), radius: \(props.cornerRadius))")
        case .spacer(let minLength):
            let minStr: String = minLength.map { String(describing: $0) } ?? "nil"
            lines.append("\(prefix)Spacer(min: \(minStr))")
        case .image(let props):
            lines.append("\(prefix)Image(source: \(props.source.sourceString), mode: \(props.contentMode))")
        case .container(let props, let children):
            let layoutDesc: String
            switch props.layout {
            case .vstack(let s, let a):
                layoutDesc = "VStack(spacing: \(s), align: \(a))"
            case .hstack(let s, let a):
                layoutDesc = "HStack(spacing: \(s), align: \(a))"
            case .zstack(let a):
                layoutDesc = "ZStack(align: \(a))"
            case .scroll(let axis, let scrollID):
                layoutDesc = "ScrollView(axis: \(axis), id: \(scrollID))"
            }
            lines.append("\(prefix)\(layoutDesc)")
            for child in children {
                lines.append(dump(element: child, indent: indent + 1))
            }
        case .modified(let inner, let modifier):
            lines.append("\(prefix)Modified(\(modifier))")
            lines.append(dump(element: inner, indent: indent + 1))
        }

        return lines.joined(separator: "\n")
    }

    public func dumpLayout(node: LayoutNode, indent: Int = 0) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []
        lines.append("\(prefix)LayoutNode(x: \(node.x), y: \(node.y), w: \(node.width), h: \(node.height))")
        for child in node.children {
            lines.append(dumpLayout(node: child, indent: indent + 1))
        }
        return lines.joined(separator: "\n")
    }
}
