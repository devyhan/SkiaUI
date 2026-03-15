// ForegroundModifier.swift – SkiaUIDSL module
// View extension for setting foreground (text) color.

import SkiaUIElement

extension View {
    public func foregroundColor(_ color: Color) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .foregroundColor(.init(r: color.red, g: color.green, b: color.blue, a: color.alpha)))
    }

    public func foregroundStyle(_ color: Color) -> ModifiedView<Self> {
        foregroundColor(color)
    }
}
