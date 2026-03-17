// StateStorage.swift – SkiaUIState module
// Thread-safe storage for reactive state values.

import Foundation

public final class StateStorage: @unchecked Sendable {
    public static let shared = StateStorage()

    private var values: [Int: Any] = [:]
    private var nextID = 0
    private let lock = NSLock()
    private var isDirty = false
    private var onDirty: (@Sendable () -> Void)?

    public init() {}

    public func allocate<T>(initialValue: T) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let id = nextID
        nextID += 1
        if values[id] == nil {
            values[id] = initialValue
        }
        return id
    }

    public func resetSlotCounter() {
        lock.lock()
        defer { lock.unlock() }
        nextID = 0
    }

    public func get<T>(id: Int) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return values[id] as? T
    }

    public func set<T>(id: Int, value: T) {
        lock.lock()
        defer { lock.unlock() }
        values[id] = value
    }

    public func markDirty() {
        lock.lock()
        isDirty = true
        let callback = onDirty
        lock.unlock()
        callback?()
    }

    public func consumeDirty() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let was = isDirty
        isDirty = false
        return was
    }

    public func setOnDirty(_ callback: @escaping @Sendable () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        onDirty = callback
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        values.removeAll()
        nextID = 0
        isDirty = false
    }
}
