// PaddingModifier.swift – SkiaUIDSL module
// View extension for adding padding around content.

import SkiaUIElement

extension View {
    public func padding(_ value: Float = 16) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .padding(top: value, leading: value, bottom: value, trailing: value))
    }

    public func padding(_ edges: EdgeSet, _ value: Float = 16) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .padding(
            top: edges.contains(.top) ? value : 0,
            leading: edges.contains(.leading) ? value : 0,
            bottom: edges.contains(.bottom) ? value : 0,
            trailing: edges.contains(.trailing) ? value : 0
        ))
    }

    public func padding(top: Float = 0, leading: Float = 0, bottom: Float = 0, trailing: Float = 0) -> ModifiedView<Self> {
        ModifiedView(content: self, modifier: .padding(top: top, leading: leading, bottom: bottom, trailing: trailing))
    }
}
