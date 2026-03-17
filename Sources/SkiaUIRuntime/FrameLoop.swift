// FrameLoop.swift – SkiaUIRuntime module
// Polling-based render loop that re-renders when state changes.

import SkiaUIState

public final class FrameLoop: @unchecked Sendable {
    private var isRunning = false
    private let renderCallback: @Sendable () -> Void
    private let requestFrame: (@escaping @Sendable () -> Void) -> Void
    private let stateStorage: StateStorage

    public init(
        stateStorage: StateStorage = .shared,
        requestFrame: @escaping (@escaping @Sendable () -> Void) -> Void,
        render: @escaping @Sendable () -> Void
    ) {
        self.stateStorage = stateStorage
        self.requestFrame = requestFrame
        self.renderCallback = render
    }

    public func start() {
        isRunning = true
        scheduleFrame()
    }

    public func stop() {
        isRunning = false
    }

    private func scheduleFrame() {
        guard isRunning else { return }
        requestFrame { [self] in
            if stateStorage.consumeDirty() {
                self.renderCallback()
            }
            self.scheduleFrame()
        }
    }
}
