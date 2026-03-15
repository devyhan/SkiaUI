public struct Color: Equatable, Hashable, Sendable {
    public var red: Float
    public var green: Float
    public var blue: Float
    public var alpha: Float
    public init(red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }
    public init(white: Float, alpha: Float = 1.0) {
        self.red = white; self.green = white; self.blue = white; self.alpha = alpha
    }
    public static let black = Color(white: 0)
    public static let white = Color(white: 1)
    public static let red = Color(red: 1, green: 0, blue: 0)
    public static let green = Color(red: 0, green: 0.8, blue: 0)
    public static let blue = Color(red: 0, green: 0.478, blue: 1)
    public static let yellow = Color(red: 1, green: 0.8, blue: 0)
    public static let orange = Color(red: 1, green: 0.584, blue: 0)
    public static let purple = Color(red: 0.686, green: 0.322, blue: 0.871)
    public static let gray = Color(white: 0.557)
    public static let clear = Color(white: 0, alpha: 0)
    public var uint32: UInt32 {
        let r = UInt32(min(max(red, 0), 1) * 255)
        let g = UInt32(min(max(green, 0), 1) * 255)
        let b = UInt32(min(max(blue, 0), 1) * 255)
        let a = UInt32(min(max(alpha, 0), 1) * 255)
        return (a << 24) | (r << 16) | (g << 8) | b
    }
}
