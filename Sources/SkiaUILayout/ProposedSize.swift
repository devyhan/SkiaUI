// ProposedSize.swift – SkiaUILayout module
// SwiftUI-compatible proposed size type for layout negotiation.

public struct ProposedSize: Equatable, Sendable {
    public var width: Float?   // nil = "use ideal size"
    public var height: Float?

    public init(width: Float? = nil, height: Float? = nil) {
        self.width = width
        self.height = height
    }

    public static let zero = ProposedSize(width: 0, height: 0)
    public static let unspecified = ProposedSize(width: nil, height: nil)
    public static let infinity = ProposedSize(width: .infinity, height: .infinity)
}
