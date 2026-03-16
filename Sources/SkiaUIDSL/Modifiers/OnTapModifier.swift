// OnTapModifier.swift – SkiaUIDSL module
// View extension for handling tap/click gestures.

import SkiaUIElement
import Foundation

nonisolated(unsafe) var _nextTapID = 0
let _tapLock = NSLock()

public nonisolated(unsafe) var tapHandlers: [Int: () -> Void] = [:]

public func resetTapState() {
    _tapLock.lock()
    _nextTapID = 0
    _tapLock.unlock()
    tapHandlers.removeAll()
}

extension View {
    public func onTapGesture(perform action: @escaping () -> Void) -> ModifiedView<Self> {
        _tapLock.lock()
        let id = _nextTapID
        _nextTapID += 1
        _tapLock.unlock()
        tapHandlers[id] = action
        return ModifiedView(content: self, modifier: .onTap(id: id))
    }
}
