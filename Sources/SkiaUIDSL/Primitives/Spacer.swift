// Spacer.swift – SkiaUIDSL module
// A flexible space view that expands along the major axis of a stack.

import SkiaUIElement

public struct Spacer: PrimitiveView {
    public let minLength: Float?

    public init(minLength: Float? = nil) {
        self.minLength = minLength
    }

    public func asElement() -> Element {
        .spacer(minLength: minLength)
    }
}
