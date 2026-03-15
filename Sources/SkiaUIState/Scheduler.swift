// Scheduler.swift – SkiaUIState module
// Frame scheduling abstraction for the render loop.

public struct FrameScheduler: Sendable {
    private let requestFrame: @Sendable (@escaping @Sendable () -> Void) -> Void

    public init(requestFrame: @escaping @Sendable (@escaping @Sendable () -> Void) -> Void) {
        self.requestFrame = requestFrame
    }

    public func scheduleFrame(_ work: @escaping @Sendable () -> Void) {
        requestFrame(work)
    }
}
