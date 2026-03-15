// PrimitiveView.swift – SkiaUIDSL module
// Protocol for views that directly produce Element values without a body.

import SkiaUIElement

public protocol PrimitiveView: View where Body == Never {
    func asElement() -> Element
}

extension PrimitiveView {
    public var body: Never { fatalError() }
}
