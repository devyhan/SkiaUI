// OnDragModifier.swift – SkiaUIDSL module
// View extension for handling drag gestures.

import SkiaUIElement
import SkiaUIState

extension View {
    public func onDrag(
        onChanged: @escaping @Sendable (DragValue) -> Void,
        onEnded: @escaping @Sendable (DragValue) -> Void
    ) -> ModifiedView<Self> {
        let handler = DragHandler(onChanged: onChanged, onEnded: onEnded)
        let id = RenderContext.active.registerDragHandler(handler)
        return ModifiedView(content: self, modifier: .onDrag(id: id))
    }
}
