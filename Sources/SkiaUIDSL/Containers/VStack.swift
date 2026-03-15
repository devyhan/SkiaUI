// VStack.swift – SkiaUIDSL module
// A view that arranges its children in a vertical line.

import SkiaUIElement

public struct VStack<Content: View>: PrimitiveView {
    let alignment: Int // 0=leading, 1=center, 2=trailing
    let spacing: Float
    let content: Content

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: Float = 8,
        @ViewBuilder content: () -> Content
    ) {
        switch alignment {
        case .leading:  self.alignment = 0
        case .center:   self.alignment = 1
        case .trailing: self.alignment = 2
        }
        self.spacing = spacing
        self.content = content()
    }

    public func asElement() -> Element {
        let children = collectChildren(from: content)
        return .container(
            .init(layout: .vstack(spacing: spacing, alignment: alignment)),
            children: children
        )
    }
}
