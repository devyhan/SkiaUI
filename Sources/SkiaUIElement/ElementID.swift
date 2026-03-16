// ElementID.swift – SkiaUIElement module
// Unique identifier for UI elements in the element tree.

import Foundation

public struct ElementID: Hashable, Sendable {
    public let rawValue: Int
    public init(_ rawValue: Int) { self.rawValue = rawValue }

    private nonisolated(unsafe) static var _counter = 0
    private static let _lock = NSLock()
    public static func generate() -> ElementID {
        _lock.lock()
        defer { _lock.unlock() }
        _counter += 1
        return ElementID(_counter)
    }

    public static func resetCounter() {
        _lock.lock()
        _counter = 0
        _lock.unlock()
    }
}
