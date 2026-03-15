// AccessibilityModifier.swift – SkiaUIDSL module
// View extensions for applying accessibility modifiers.

import SkiaUIElement

extension View {
    public func accessibilityLabel(_ label: String) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .accessibilityLabel(label))
    }

    public func accessibilityRole(_ role: String) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .accessibilityRole(role))
    }

    public func accessibilityHint(_ hint: String) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .accessibilityHint(hint))
    }

    public func accessibilityHidden(_ hidden: Bool = true) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .accessibilityHidden(hidden))
    }
}
