// EmptyView.swift – SkiaUIDSL module
// A view that displays nothing and occupies no space.

import SkiaUIElement

public struct EmptyView: PrimitiveView {
    public init() {}

    public func asElement() -> Element {
        .empty
    }
}
