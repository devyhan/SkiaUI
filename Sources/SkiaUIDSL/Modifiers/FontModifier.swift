// FontModifier.swift – SkiaUIDSL module
// View extension for setting font properties.

import SkiaUIElement
import SkiaUIText

extension View {
    public func font(_ descriptor: FontDescriptor) -> ModifiedView<Self> {
        let family: String? = descriptor.family == "system-ui" ? nil : descriptor.family
        return ModifiedView(content: self, modifier: .font(size: descriptor.size, weight: descriptor.weight.rawValue, family: family))
    }

    public func font(size: Float, weight: FontWeight = .regular) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .font(size: size, weight: weight.rawValue, family: nil))
    }

    public func font(_ font: Font) -> ModifiedView<Self> {
        self.font(font.descriptor)
    }
}
