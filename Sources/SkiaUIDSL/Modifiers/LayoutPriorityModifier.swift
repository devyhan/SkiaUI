// LayoutPriorityModifier.swift – SkiaUIDSL module
// View extension for specifying layout priority in stacks.

import SkiaUIElement

extension View {
    public func layoutPriority(_ value: Double) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .layoutPriority(value))
    }
}
