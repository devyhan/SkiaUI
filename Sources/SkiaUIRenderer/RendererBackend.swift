import SkiaUIDisplayList

public protocol RendererBackend: Sendable {
    func submit(_ displayList: DisplayList)
    func requestFrame(_ callback: @escaping @Sendable () -> Void)
    func viewportSize() -> (width: Float, height: Float)
    func measureText(_ text: String, fontSize: Float, fontWeight: Int, fontFamily: String?, maxWidth: Float?) -> TextMetrics
    func dispose()
}

extension RendererBackend {
    /// Default implementation returns zero metrics (backends override for real measurement).
    public func measureText(_ text: String, fontSize: Float, fontWeight: Int, fontFamily: String?, maxWidth: Float?) -> TextMetrics {
        TextMetrics()
    }
}
