// ViewToElement.swift – SkiaUIDSL module
// Converts any View into an Element tree representation.

import SkiaUIElement

public enum ViewToElementConverter {
    /// Convert any View into its Element representation.
    /// PrimitiveViews produce elements directly; composite views recurse through body.
    public static func convert<V: View>(_ view: V) -> Element {
        if let prim = view as? any PrimitiveView {
            return prim.asElement()
        }
        return convert(view.body)
    }
}

// MARK: - Internal helper for collecting children from content views

/// Collects children from a view, flattening TupleView structures into a flat array.
func collectChildren<V: View>(from content: V) -> [Element] {
    if let tuple = content as? any TupleViewProtocol {
        return tuple.flattenedElements()
    }
    return [ViewToElementConverter.convert(content)]
}
