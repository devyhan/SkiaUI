// BackgroundModifier.swift – SkiaUIDSL module
// View extension for setting background color.

import SkiaUIElement

extension View {
    public func background(_ color: Color) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .background(.init(r: color.red, g: color.green, b: color.blue, a: color.alpha)))
    }
}
