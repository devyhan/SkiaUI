// ZStack.swift – SkiaUIDSL module
// A view that overlays its children, aligning them within the same frame.

import SkiaUIElement

public struct ZStack<Content: View>: PrimitiveView {
    let alignment: Int
    let content: Content

    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        // Encode alignment as a single int for the element tree.
        // Row-major: topLeading=0, top=1, topTrailing=2,
        //            leading=3,   center=4, trailing=5,
        //            bottomLeading=6, bottom=7, bottomTrailing=8
        let h: Int = switch alignment.horizontal {
        case .leading:  0
        case .center:   1
        case .trailing: 2
        }
        let v: Int = switch alignment.vertical {
        case .top:    0
        case .center: 1
        case .bottom: 2
        }
        self.alignment = v * 3 + h
        self.content = content()
    }

    public func asElement() -> Element {
        let children = collectChildren(from: content)
        return .container(
            .init(layout: .zstack(alignment: alignment)),
            children: children
        )
    }
}
