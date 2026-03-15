public struct EdgeInsets: Equatable, Sendable {
    public var top: Float
    public var leading: Float
    public var bottom: Float
    public var trailing: Float
    public init(top: Float = 0, leading: Float = 0, bottom: Float = 0, trailing: Float = 0) {
        self.top = top; self.leading = leading; self.bottom = bottom; self.trailing = trailing
    }
    public init(all value: Float) {
        self.top = value; self.leading = value; self.bottom = value; self.trailing = value
    }
    public static let zero = EdgeInsets()
    public var horizontalTotal: Float { leading + trailing }
    public var verticalTotal: Float { top + bottom }
}

public struct EdgeSet: OptionSet, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let top = EdgeSet(rawValue: 1 << 0)
    public static let leading = EdgeSet(rawValue: 1 << 1)
    public static let bottom = EdgeSet(rawValue: 1 << 2)
    public static let trailing = EdgeSet(rawValue: 1 << 3)
    public static let horizontal: EdgeSet = [.leading, .trailing]
    public static let vertical: EdgeSet = [.top, .bottom]
    public static let all: EdgeSet = [.top, .leading, .bottom, .trailing]
}
