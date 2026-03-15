import SkiaUIDisplayList

public protocol RendererBackend: Sendable {
    func submit(_ displayList: DisplayList)
    func requestFrame(_ callback: @escaping @Sendable () -> Void)
    func viewportSize() -> (width: Float, height: Float)
    func dispose()
}
