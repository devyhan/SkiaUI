// DrawingGroupModifier.swift – SkiaUIDSL module
// View extension for drawingGroup (render caching boundary).

import SkiaUIElement

extension View {
    public func drawingGroup() -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .drawingGroup)
    }
}
