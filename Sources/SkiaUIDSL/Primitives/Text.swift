// Text.swift – SkiaUIDSL module
// A view that displays one or more lines of read-only text.

import SkiaUIElement

public struct Text: PrimitiveView {
    public let content: String
    var _fontSize: Float = 14
    var _fontWeight: Int = 400
    var _foregroundColor: Element.ElementColor?
    var _fontFamily: String?

    public init(_ content: String) {
        self.content = content
    }

    public func asElement() -> Element {
        .text(content, .init(
            fontSize: _fontSize,
            fontWeight: _fontWeight,
            foregroundColor: _foregroundColor,
            fontFamily: _fontFamily
        ))
    }
}

// MARK: - Text modifiers

extension Text {
    /// Sets the font size for this text view.
    public func fontSize(_ size: Float) -> Text {
        var copy = self
        copy._fontSize = size
        return copy
    }

    /// Sets the font weight for this text view.
    public func fontWeight(_ weight: Int) -> Text {
        var copy = self
        copy._fontWeight = weight
        return copy
    }

    /// Sets the font weight using a named weight.
    public func bold() -> Text {
        fontWeight(700)
    }

    /// Sets the foreground color for this text view.
    public func foregroundColor(_ color: Color) -> Text {
        var copy = self
        copy._foregroundColor = .init(r: color.red, g: color.green, b: color.blue, a: color.alpha)
        return copy
    }

    /// Sets the font family for this text view.
    public func fontFamily(_ family: String) -> Text {
        var copy = self
        copy._fontFamily = family
        return copy
    }
}
