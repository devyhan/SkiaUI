// FixedSizeModifier.swift – SkiaUIDSL module
// View extension for ignoring proposed size and using ideal size.

import SkiaUIElement

extension View {
    public func fixedSize() -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .fixedSize(horizontal: true, vertical: true))
    }

    public func fixedSize(horizontal: Bool, vertical: Bool) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .fixedSize(horizontal: horizontal, vertical: vertical))
    }
}
