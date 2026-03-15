public struct TextColor: Equatable, Hashable, Sendable {
    public var red: Float
    public var green: Float
    public var blue: Float
    public var alpha: Float
    public init(red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }
}

public struct TextStyle: Equatable, Sendable {
    public var font: FontDescriptor
    public var foregroundColor: TextColor?
    public var lineHeight: Float?
    public var letterSpacing: Float?
    public init(
        font: FontDescriptor = FontDescriptor(),
        foregroundColor: TextColor? = nil,
        lineHeight: Float? = nil,
        letterSpacing: Float? = nil
    ) {
        self.font = font
        self.foregroundColor = foregroundColor
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
    }
}
