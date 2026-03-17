// OnTapModifier.swift – SkiaUIDSL module
// View extension for handling tap/click gestures.

import SkiaUIElement
import SkiaUIState

/// Access to the active context's tap handlers (backward compatibility).
public var tapHandlers: [Int: () -> Void] {
    get { RenderContext.active.tapHandlers }
    set { RenderContext.active.tapHandlers = newValue }
}

public func resetTapState() {
    RenderContext.active.resetTapState()
}

extension View {
    public func onTapGesture(perform action: @escaping () -> Void) -> ModifiedView<Self> {
        let id = RenderContext.active.registerTapHandler(action)
        return ModifiedView(content: self, modifier: .onTap(id: id))
    }
}
