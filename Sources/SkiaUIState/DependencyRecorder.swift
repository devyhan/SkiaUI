// DependencyRecorder.swift – SkiaUIState module
// Callback bridge for recording @State reads and writes.

import Foundation

public final class DependencyRecorder: @unchecked Sendable {
    public static let shared = DependencyRecorder()

    private let lock = NSLock()
    private var _onStateRead: ((Int) -> Void)?
    private var _onStateWrite: ((Int) -> Void)?

    /// Creates a new recorder. Use `.shared` for production.
    /// Visible for `@testable import` unit tests.
    internal init() {}

    public func setCallbacks(
        onRead: @escaping (Int) -> Void,
        onWrite: @escaping (Int) -> Void
    ) {
        lock.lock()
        defer { lock.unlock() }
        _onStateRead = onRead
        _onStateWrite = onWrite
    }

    public func clearCallbacks() {
        lock.lock()
        defer { lock.unlock() }
        _onStateRead = nil
        _onStateWrite = nil
    }

    public func notifyRead(stateID: Int) {
        lock.lock()
        let callback = _onStateRead
        lock.unlock()
        callback?(stateID)
    }

    public func notifyWrite(stateID: Int) {
        lock.lock()
        let callback = _onStateWrite
        lock.unlock()
        callback?(stateID)
    }
}
