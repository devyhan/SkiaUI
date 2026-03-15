// FontModifier.swift – SkiaUIDSL module
// View extension for setting font properties.

import SkiaUIElement
import SkiaUIText

extension View {
    public func font(_ descriptor: FontDescriptor) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .font(size: descriptor.size, weight: descriptor.weight.rawValue))
    }

    public func font(size: Float, weight: FontWeight = .regular) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .font(size: size, weight: weight.rawValue))
    }
}
