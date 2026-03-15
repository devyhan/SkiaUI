// HStack.swift – SkiaUIDSL module
// A view that arranges its children in a horizontal line.

import SkiaUIElement

public struct HStack<Content: View>: PrimitiveView {
    let alignment: Int // 0=top, 1=center, 2=bottom
    let spacing: Float
    let content: Content

    public init(
        alignment: VerticalAlignment = .center,
        spacing: Float = 8,
        @ViewBuilder content: () -> Content
    ) {
        switch alignment {
        case .top:    self.alignment = 0
        case .center: self.alignment = 1
        case .bottom: self.alignment = 2
        }
        self.spacing = spacing
        self.content = content()
    }

    public func asElement() -> Element {
        let children = collectChildren(from: content)
        return .container(
            .init(layout: .hstack(spacing: spacing, alignment: alignment)),
            children: children
        )
    }
}
