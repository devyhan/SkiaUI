// Image.swift – SkiaUIDSL module
// A view that displays an image from a named resource or URL.

import SkiaUIElement

public struct Image: PrimitiveView {
    var _source: Element.ImageSource
    var _contentMode: Element.ContentMode = .fit
    var _isResizable: Bool = false

    /// Creates an image view from a named resource.
    public init(_ name: String) {
        self._source = .named(name)
    }

    /// Creates an image view from a URL string.
    public init(url: String) {
        self._source = .url(url)
    }

    public func asElement() -> Element {
        .image(.init(source: _source, contentMode: _contentMode))
    }
}

// MARK: - Image modifiers

extension Image {
    /// Makes the image resizable, allowing it to fill its proposed size.
    public func resizable() -> Image {
        var copy = self
        copy._isResizable = true
        return copy
    }

    /// Sets the content mode for how the image fills its bounds.
    public func aspectRatio(contentMode: Element.ContentMode) -> Image {
        var copy = self
        copy._contentMode = contentMode
        return copy
    }
}
