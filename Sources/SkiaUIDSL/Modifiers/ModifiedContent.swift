// ModifiedContent.swift – SkiaUIDSL module
// A view wrapper that applies an Element.Modifier to its content.

import SkiaUIElement

public struct ModifiedView<Content: View>: PrimitiveView {
    let content: Content
    let modifier: Element.Modifier

    public init(content: Content, modifier: Element.Modifier) {
        self.content = content
        self.modifier = modifier
    }

    public func asElement() -> Element {
        .modified(ViewToElementConverter.convert(content), modifier)
    }
}
