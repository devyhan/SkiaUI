public struct RendererConfig: Equatable, Sendable {
    public var canvasWidth: Float
    public var canvasHeight: Float
    public var devicePixelRatio: Float
    public init(canvasWidth: Float = 800, canvasHeight: Float = 600, devicePixelRatio: Float = 1.0) {
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.devicePixelRatio = devicePixelRatio
    }
}
