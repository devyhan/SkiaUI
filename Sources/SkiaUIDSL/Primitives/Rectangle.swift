// Rectangle.swift – SkiaUIDSL module
// A view that fills its frame with a solid color.

import SkiaUIElement

public struct Rectangle: PrimitiveView {
    var _fillColor: Element.ElementColor?
    var _cornerRadius: Float = 0

    public init() {}

    public func asElement() -> Element {
        .rectangle(.init(
            fillColor: _fillColor ?? .init(r: 0, g: 0, b: 0),
            cornerRadius: _cornerRadius
        ))
    }
}

// MARK: - Rectangle modifiers

extension Rectangle {
    /// Fills the rectangle with the given color.
    public func fill(_ color: Color) -> Rectangle {
        var copy = self
        copy._fillColor = .init(r: color.red, g: color.green, b: color.blue, a: color.alpha)
        return copy
    }

    /// Sets the corner radius for the rectangle.
    public func cornerRadius(_ radius: Float) -> Rectangle {
        var copy = self
        copy._cornerRadius = radius
        return copy
    }
}
