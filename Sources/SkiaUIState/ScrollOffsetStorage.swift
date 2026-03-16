// ScrollOffsetStorage.swift – SkiaUIState module
// Thread-safe storage for scroll offsets, keyed by scroll container ID.

import Foundation

public final class ScrollOffsetStorage: @unchecked Sendable {
    public static let shared = ScrollOffsetStorage()

    private var offsets: [Int: Float] = [:]
    private var contentSizes: [Int: Float] = [:]
    private var viewportSizes: [Int: Float] = [:]
    private let lock = NSLock()

    private init() {}

    public func getOffset(id: Int) -> Float {
        lock.lock()
        defer { lock.unlock() }
        return offsets[id] ?? 0
    }

    public func applyDelta(id: Int, delta: Float) {
        lock.lock()
        let current = offsets[id] ?? 0
        let maxScroll = maxScrollValue(id: id)
        offsets[id] = min(max(current + delta, 0), maxScroll)
        lock.unlock()
    }

    public func setContentSize(id: Int, size: Float) {
        lock.lock()
        defer { lock.unlock() }
        contentSizes[id] = size
    }

    public func setViewportSize(id: Int, size: Float) {
        lock.lock()
        defer { lock.unlock() }
        viewportSizes[id] = size
    }

    public func maxScroll(id: Int) -> Float {
        lock.lock()
        defer { lock.unlock() }
        return maxScrollValue(id: id)
    }

    /// All current offsets as a dictionary (for passing to RenderTreeBuilder).
    public func allOffsets() -> [Int: Float] {
        lock.lock()
        defer { lock.unlock() }
        return offsets
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        offsets.removeAll()
        contentSizes.removeAll()
        viewportSizes.removeAll()
    }

    // Must be called with lock held.
    private func maxScrollValue(id: Int) -> Float {
        let content = contentSizes[id] ?? 0
        let viewport = viewportSizes[id] ?? 0
        return max(0, content - viewport)
    }
}
