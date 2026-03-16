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

public struct Font: Equatable, Sendable {
    public var descriptor: FontDescriptor

    public init(descriptor: FontDescriptor) {
        self.descriptor = descriptor
    }

    // MARK: - Factory methods

    public static func system(size: Float, weight: FontWeight = .regular, design: Design = .default) -> Font {
        Font(descriptor: FontDescriptor(family: design.familyName, size: size, weight: weight))
    }

    public static func custom(_ name: String, size: Float) -> Font {
        Font(descriptor: FontDescriptor(family: name, size: size))
    }

    // MARK: - Semantic styles (SwiftUI-matching sizes)

    public static var largeTitle: Font { .system(size: 34) }
    public static var title: Font { .system(size: 28) }
    public static var title2: Font { .system(size: 22) }
    public static var title3: Font { .system(size: 20) }
    public static var headline: Font { .system(size: 17, weight: .semibold) }
    public static var subheadline: Font { .system(size: 15) }
    public static var body: Font { .system(size: 17) }
    public static var callout: Font { .system(size: 16) }
    public static var footnote: Font { .system(size: 13) }
    public static var caption: Font { .system(size: 12) }
    public static var caption2: Font { .system(size: 11) }

    // MARK: - Chaining modifiers

    public func weight(_ weight: FontWeight) -> Font {
        var copy = self
        copy.descriptor.weight = weight
        return copy
    }

    public func bold() -> Font {
        weight(.bold)
    }

    // MARK: - Design

    public enum Design: Equatable, Sendable {
        case `default`
        case monospaced
        case rounded
        case serif

        var familyName: String {
            switch self {
            case .default: return "system-ui"
            case .monospaced: return "monospace"
            case .rounded: return "system-ui"
            case .serif: return "serif"
            }
        }
    }
}
