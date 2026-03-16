// ViewToElement.swift – SkiaUIDSL module
// Converts any View into an Element tree representation.

import SkiaUIElement
import Foundation

/// Interceptor closure: receives the structural path and a lazy evaluator,
/// returns the Element (possibly from cache).
public typealias ViewInterceptor = ([Int], () -> Element) -> Element

// Module-level state for interceptor (single-threaded rendering, same pattern as _nextScrollID).
// Protected by _interceptorLock to prevent concurrent corruption during tests.
nonisolated(unsafe) var _activeInterceptor: ViewInterceptor? = nil
nonisolated(unsafe) var _pathStack: [Int] = []
nonisolated(unsafe) var _childCounterStack: [Int] = [0]
let _interceptorLock = NSLock()

public enum ViewToElementConverter {
    /// Convert any View into its Element representation.
    /// PrimitiveViews produce elements directly; composite views recurse through body.
    public static func convert<V: View>(_ view: V) -> Element {
        if let prim = view as? any PrimitiveView {
            if _activeInterceptor != nil {
                _childCounterStack[_childCounterStack.count - 1] += 1
            }
            return prim.asElement()
        }

        guard let interceptor = _activeInterceptor else {
            return convert(view.body)
        }

        // Composite View — graph node boundary
        let childIndex = _childCounterStack[_childCounterStack.count - 1]
        _childCounterStack[_childCounterStack.count - 1] += 1
        let nodePath = _pathStack + [childIndex]

        return interceptor(nodePath) {
            let outerPath = _pathStack
            _pathStack = nodePath
            _childCounterStack.append(0)
            let result = Self.convert(view.body)
            _childCounterStack.removeLast()
            _pathStack = outerPath
            return result
        }
    }

    /// Execute a view conversion with an active interceptor.
    /// Serialized via lock to prevent concurrent corruption of module-level state.
    public static func withInterceptor<V: View>(
        _ interceptor: @escaping ViewInterceptor, convert view: V
    ) -> Element {
        _interceptorLock.lock()
        _activeInterceptor = interceptor
        _pathStack = []
        _childCounterStack = [0]
        let result = convert(view)
        _activeInterceptor = nil
        _interceptorLock.unlock()
        return result
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
