// View.swift – SkiaUIDSL module
// Core View protocol defining the declarative UI hierarchy.

import SkiaUIElement

public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}

extension Never: View {
    public typealias Body = Never
    public var body: Never { fatalError() }
}

// MARK: - AnyView

/// A type-erased wrapper around any View, converting it to an Element on demand.
public struct AnyView: View {
    public typealias Body = Never
    public var body: Never { fatalError() }

    let _asElement: @Sendable () -> Element

    public init<V: View>(_ view: V) {
        if let prim = view as? any PrimitiveView {
            // Capture the element eagerly to avoid storing the view
            let element = prim.asElement()
            self._asElement = { element }
        } else {
            let anyBody = AnyView(view.body)
            self._asElement = anyBody._asElement
        }
    }
}

extension AnyView: PrimitiveView {
    public func asElement() -> Element {
        _asElement()
    }
}

extension AnyView: @unchecked Sendable {}
