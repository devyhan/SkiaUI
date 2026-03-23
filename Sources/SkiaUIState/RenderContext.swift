// RenderContext.swift – SkiaUIState module
// Instance-scoped container for all mutable render state.
// Replaces global singletons to support multiple isolated RootHost instances.

import Foundation

public final class RenderContext: @unchecked Sendable {
    public let stateStorage: StateStorage
    public let scrollOffsetStorage: ScrollOffsetStorage
    public let dependencyRecorder: DependencyRecorder

    // Tap handler state
    private let tapLock = NSLock()
    private var _tapHandlers: [Int: () -> Void] = [:]
    private var _nextTapID = 0

    // Long press handler state
    private let longPressLock = NSLock()
    private var _longPressHandlers: [Int: () -> Void] = [:]
    private var _nextLongPressID = 0

    // Drag handler state
    private let dragLock = NSLock()
    private var _dragHandlers: [Int: DragHandler] = [:]
    private var _nextDragID = 0

    // Scroll ID state
    private let scrollLock = NSLock()
    private var _nextScrollID = 0

    public init(
        stateStorage: StateStorage = StateStorage(),
        scrollOffsetStorage: ScrollOffsetStorage = ScrollOffsetStorage(),
        dependencyRecorder: DependencyRecorder = DependencyRecorder()
    ) {
        self.stateStorage = stateStorage
        self.scrollOffsetStorage = scrollOffsetStorage
        self.dependencyRecorder = dependencyRecorder
    }

    // MARK: - Active context

    /// Default context backed by the shared singletons (backward compatibility).
    public static let `default` = RenderContext(
        stateStorage: .shared,
        scrollOffsetStorage: .shared,
        dependencyRecorder: .shared
    )

    /// Returns the currently active render context, or the default if none is set.
    public static var active: RenderContext {
        Thread.current.threadDictionary[_activeRenderContextKey] as? RenderContext ?? .default
    }

    /// Activate this context for the duration of the given closure.
    /// Properly restores the previous context on exit.
    public func activate<T>(body: () throws -> T) rethrows -> T {
        let threadDictionary = Thread.current.threadDictionary
        let previous = threadDictionary[_activeRenderContextKey]
        threadDictionary[_activeRenderContextKey] = self
        defer {
            if let previous {
                threadDictionary[_activeRenderContextKey] = previous
            } else {
                threadDictionary.removeObject(forKey: _activeRenderContextKey)
            }
        }
        return try body()
    }

    // MARK: - Tap handlers

    public var tapHandlers: [Int: () -> Void] {
        get {
            tapLock.lock()
            defer { tapLock.unlock() }
            return _tapHandlers
        }
        set {
            tapLock.lock()
            defer { tapLock.unlock() }
            _tapHandlers = newValue
        }
    }

    public func registerTapHandler(_ action: @escaping () -> Void) -> Int {
        tapLock.lock()
        let id = _nextTapID
        _nextTapID += 1
        _tapHandlers[id] = action
        tapLock.unlock()
        return id
    }

    public func resetTapState() {
        tapLock.lock()
        _nextTapID = 0
        _tapHandlers.removeAll()
        tapLock.unlock()
    }

    // MARK: - Long press handlers

    public var longPressHandlers: [Int: () -> Void] {
        get {
            longPressLock.lock()
            defer { longPressLock.unlock() }
            return _longPressHandlers
        }
    }

    public func registerLongPressHandler(_ action: @escaping () -> Void) -> Int {
        longPressLock.lock()
        let id = _nextLongPressID
        _nextLongPressID += 1
        _longPressHandlers[id] = action
        longPressLock.unlock()
        return id
    }

    public func resetLongPressState() {
        longPressLock.lock()
        _nextLongPressID = 0
        _longPressHandlers.removeAll()
        longPressLock.unlock()
    }

    // MARK: - Drag handlers

    public var dragHandlers: [Int: DragHandler] {
        get {
            dragLock.lock()
            defer { dragLock.unlock() }
            return _dragHandlers
        }
    }

    public func registerDragHandler(_ handler: DragHandler) -> Int {
        dragLock.lock()
        let id = _nextDragID
        _nextDragID += 1
        _dragHandlers[id] = handler
        dragLock.unlock()
        return id
    }

    public func resetDragState() {
        dragLock.lock()
        _nextDragID = 0
        _dragHandlers.removeAll()
        dragLock.unlock()
    }

    // MARK: - Scroll ID counter

    public func nextScrollID() -> Int {
        scrollLock.lock()
        let id = _nextScrollID
        _nextScrollID += 1
        scrollLock.unlock()
        return id
    }

    public func resetScrollIDCounter() {
        scrollLock.lock()
        _nextScrollID = 0
        scrollLock.unlock()
    }
}

/// Value describing the current state of a drag gesture.
public struct DragValue: Sendable {
    public var startX: Float
    public var startY: Float
    public var currentX: Float
    public var currentY: Float
    public var translationX: Float { currentX - startX }
    public var translationY: Float { currentY - startY }

    public init(startX: Float, startY: Float, currentX: Float, currentY: Float) {
        self.startX = startX; self.startY = startY
        self.currentX = currentX; self.currentY = currentY
    }
}

/// Handler callbacks for drag gesture events.
public struct DragHandler: Sendable {
    public var onChanged: @Sendable (DragValue) -> Void
    public var onEnded: @Sendable (DragValue) -> Void

    public init(
        onChanged: @escaping @Sendable (DragValue) -> Void,
        onEnded: @escaping @Sendable (DragValue) -> Void
    ) {
        self.onChanged = onChanged
        self.onEnded = onEnded
    }
}

private let _activeRenderContextKey = "SkiaUI.RenderContext.active"
