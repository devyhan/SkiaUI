public struct TextMetrics: Equatable, Sendable {
    public var width: Float
    public var height: Float
    public var ascent: Float
    public var descent: Float
    public init(width: Float = 0, height: Float = 0, ascent: Float = 0, descent: Float = 0) {
        self.width = width; self.height = height; self.ascent = ascent; self.descent = descent
    }
}
