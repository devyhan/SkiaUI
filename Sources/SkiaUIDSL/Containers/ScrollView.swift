// ScrollView.swift – SkiaUIDSL module
// A view that provides scrollable content along a single axis.

import SkiaUIElement
import Foundation

nonisolated(unsafe) var _nextScrollID = 0
let _scrollLock = NSLock()

/// Resets the scroll ID counter so that deterministic IDs are assigned each render cycle.
/// Must be called before `ViewToElementConverter.convert()` to ensure stable scroll IDs.
public func resetScrollIDCounter() {
    _scrollLock.lock()
    _nextScrollID = 0
    _scrollLock.unlock()
}

public struct ScrollView<Content: View>: PrimitiveView {
    let axis: Element.ScrollAxis
    let content: Content

    public init(_ axes: Axis.Set = .vertical, @ViewBuilder content: () -> Content) {
        self.axis = axes.contains(.horizontal) ? .horizontal : .vertical
        self.content = content()
    }

    public func asElement() -> Element {
        _scrollLock.lock()
        let id = _nextScrollID
        _nextScrollID += 1
        _scrollLock.unlock()

        let children = collectChildren(from: content)
        let innerStack: Element = switch axis {
        case .vertical:
            .container(.init(layout: .vstack(spacing: 8, alignment: 1)), children: children)
        case .horizontal:
            .container(.init(layout: .hstack(spacing: 8, alignment: 1)), children: children)
        }
        return .container(.init(layout: .scroll(axis: axis, scrollID: id)), children: [innerStack])
    }
}
