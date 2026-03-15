public struct ParagraphSpec: Equatable, Sendable {
    public var maxLines: Int?
    public var textAlign: TextAlign
    public var overflow: TextOverflow
    public init(maxLines: Int? = nil, textAlign: TextAlign = .start, overflow: TextOverflow = .clip) {
        self.maxLines = maxLines; self.textAlign = textAlign; self.overflow = overflow
    }
}

public enum TextAlign: Sendable {
    case start, center, end
}

public enum TextOverflow: Sendable {
    case clip, ellipsis
}
