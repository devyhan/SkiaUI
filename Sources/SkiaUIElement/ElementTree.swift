// ElementTree.swift – SkiaUIElement module
// Utilities for traversing and transforming element trees.

public enum ElementTree {
    public static func childCount(_ element: Element) -> Int {
        switch element {
        case .container(_, let children): return children.count
        case .modified(let inner, _): return childCount(inner)
        default: return 0
        }
    }

    public static func walk(_ element: Element, visitor: (Element, Int) -> Void, depth: Int = 0) {
        visitor(element, depth)
        switch element {
        case .container(_, let children):
            for child in children { walk(child, visitor: visitor, depth: depth + 1) }
        case .modified(let inner, _):
            walk(inner, visitor: visitor, depth: depth + 1)
        default: break
        }
    }

    public static func map(_ element: Element, transform: (Element) -> Element) -> Element {
        let transformed = transform(element)
        switch transformed {
        case .container(let props, let children):
            return .container(props, children: children.map { map($0, transform: transform) })
        case .modified(let inner, let modifier):
            return .modified(map(inner, transform: transform), modifier)
        default:
            return transformed
        }
    }
}
