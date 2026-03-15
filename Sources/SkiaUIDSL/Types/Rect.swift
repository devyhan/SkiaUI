public struct Point: Equatable, Hashable, Sendable {
    public var x: Float
    public var y: Float
    public init(x: Float = 0, y: Float = 0) { self.x = x; self.y = y }
    public static let zero = Point()
}

public struct Size: Equatable, Hashable, Sendable {
    public var width: Float
    public var height: Float
    public init(width: Float = 0, height: Float = 0) { self.width = width; self.height = height }
    public static let zero = Size()
}

public struct Rect: Equatable, Hashable, Sendable {
    public var origin: Point
    public var size: Size
    public init(origin: Point = .zero, size: Size = .zero) { self.origin = origin; self.size = size }
    public init(x: Float, y: Float, width: Float, height: Float) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }
    public static let zero = Rect()
    public var minX: Float { origin.x }
    public var minY: Float { origin.y }
    public var maxX: Float { origin.x + size.width }
    public var maxY: Float { origin.y + size.height }
    public var width: Float { size.width }
    public var height: Float { size.height }
    public func contains(_ point: Point) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }
}
