public enum HorizontalAlignment: Sendable {
    case leading, center, trailing
}

public enum VerticalAlignment: Sendable {
    case top, center, bottom
}

public struct Alignment: Equatable, Sendable {
    public var horizontal: HorizontalAlignment
    public var vertical: VerticalAlignment
    public init(horizontal: HorizontalAlignment = .center, vertical: VerticalAlignment = .center) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
    public static let center = Alignment()
    public static let leading = Alignment(horizontal: .leading)
    public static let trailing = Alignment(horizontal: .trailing)
    public static let top = Alignment(vertical: .top)
    public static let bottom = Alignment(vertical: .bottom)
    public static let topLeading = Alignment(horizontal: .leading, vertical: .top)
    public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)
    public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)
    public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)
}
