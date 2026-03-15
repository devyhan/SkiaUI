public enum FontWeight: Int, Sendable, Equatable {
    case ultraLight = 100
    case thin = 200
    case light = 300
    case regular = 400
    case medium = 500
    case semibold = 600
    case bold = 700
    case heavy = 800
    case black = 900
}

public struct FontDescriptor: Equatable, Sendable {
    public var family: String
    public var size: Float
    public var weight: FontWeight
    public init(family: String = "system-ui", size: Float = 14, weight: FontWeight = .regular) {
        self.family = family; self.size = size; self.weight = weight
    }
    public static func system(size: Float, weight: FontWeight = .regular) -> FontDescriptor {
        FontDescriptor(family: "system-ui", size: size, weight: weight)
    }
}
