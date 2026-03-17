// OnLongPressModifier.swift – SkiaUIDSL module
// View extension for handling long press gestures.

import SkiaUIElement
import SkiaUIState

extension View {
    public func onLongPressGesture(perform action: @escaping () -> Void) -> ModifiedView<Self> {
        let id = RenderContext.active.registerLongPressHandler(action)
        return ModifiedView(content: self, modifier: .onLongPress(id: id))
    }
}
