// Constraints.swift – SkiaUILayout module
// Layout constraints for bounding element geometry.

public struct Constraints: Equatable, Sendable {
    public var minWidth: Float
    public var maxWidth: Float
    public var minHeight: Float
    public var maxHeight: Float

    public init(
        minWidth: Float = 0,
        maxWidth: Float = .infinity,
        minHeight: Float = 0,
        maxHeight: Float = .infinity
    ) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }

    public static let unconstrained = Constraints()

    public func constrain(width: Float, height: Float) -> (width: Float, height: Float) {
        (
            width: min(max(width, minWidth), maxWidth),
            height: min(max(height, minHeight), maxHeight)
        )
    }

    public func inset(top: Float = 0, leading: Float = 0, bottom: Float = 0, trailing: Float = 0) -> Constraints {
        Constraints(
            minWidth: max(0, minWidth - leading - trailing),
            maxWidth: max(0, maxWidth - leading - trailing),
            minHeight: max(0, minHeight - top - bottom),
            maxHeight: max(0, maxHeight - top - bottom)
        )
    }

    public func withExactWidth(_ width: Float) -> Constraints {
        Constraints(minWidth: width, maxWidth: width, minHeight: minHeight, maxHeight: maxHeight)
    }

    public func withExactHeight(_ height: Float) -> Constraints {
        Constraints(minWidth: minWidth, maxWidth: maxWidth, minHeight: height, maxHeight: height)
    }
}

extension Constraints {
    public var proposedSize: ProposedSize {
        ProposedSize(
            width: maxWidth.isInfinite ? nil : maxWidth,
            height: maxHeight.isInfinite ? nil : maxHeight
        )
    }

    public init(proposed: ProposedSize) {
        self.init(
            minWidth: 0, maxWidth: proposed.width ?? .infinity,
            minHeight: 0, maxHeight: proposed.height ?? .infinity
        )
    }
}
