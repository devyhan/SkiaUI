// Element.swift – SkiaUIElement module
// Core element type representing nodes in the UI element tree.

public indirect enum Element: Equatable, Sendable {
    case empty
    case text(String, TextProperties)
    case rectangle(RectangleProperties)
    case spacer(minLength: Float?)
    case container(ContainerProperties, children: [Element])
    case modified(Element, Modifier)

    public struct TextProperties: Equatable, Sendable {
        public var fontSize: Float
        public var fontWeight: Int
        public var foregroundColor: ElementColor?
        public init(fontSize: Float = 14, fontWeight: Int = 400, foregroundColor: ElementColor? = nil) {
            self.fontSize = fontSize; self.fontWeight = fontWeight; self.foregroundColor = foregroundColor
        }
    }

    public struct RectangleProperties: Equatable, Sendable {
        public var fillColor: ElementColor
        public var cornerRadius: Float
        public init(fillColor: ElementColor = .init(r: 0, g: 0, b: 0), cornerRadius: Float = 0) {
            self.fillColor = fillColor; self.cornerRadius = cornerRadius
        }
    }

    public struct ElementColor: Equatable, Hashable, Sendable {
        public var r: Float, g: Float, b: Float, a: Float
        public init(r: Float, g: Float, b: Float, a: Float = 1) {
            self.r = r; self.g = g; self.b = b; self.a = a
        }
        public var uint32: UInt32 {
            let ri = UInt32(min(max(r, 0), 1) * 255)
            let gi = UInt32(min(max(g, 0), 1) * 255)
            let bi = UInt32(min(max(b, 0), 1) * 255)
            let ai = UInt32(min(max(a, 0), 1) * 255)
            return (ai << 24) | (ri << 16) | (gi << 8) | bi
        }
    }

    public enum ContainerLayout: Equatable, Sendable {
        case vstack(spacing: Float, alignment: Int) // alignment: 0=leading, 1=center, 2=trailing
        case hstack(spacing: Float, alignment: Int) // alignment: 0=top, 1=center, 2=bottom
        case zstack(alignment: Int)                 // 0=center, etc.
    }

    public struct ContainerProperties: Equatable, Sendable {
        public var layout: ContainerLayout
        public init(layout: ContainerLayout) { self.layout = layout }
    }

    public struct FrameProperties: Equatable, Sendable {
        public var minWidth: Float?
        public var idealWidth: Float?
        public var maxWidth: Float?
        public var minHeight: Float?
        public var idealHeight: Float?
        public var maxHeight: Float?
        public var alignment: Int  // 0-8 encoding: vAlign * 3 + hAlign

        public init(
            minWidth: Float? = nil, idealWidth: Float? = nil, maxWidth: Float? = nil,
            minHeight: Float? = nil, idealHeight: Float? = nil, maxHeight: Float? = nil,
            alignment: Int = 4
        ) {
            self.minWidth = minWidth; self.idealWidth = idealWidth; self.maxWidth = maxWidth
            self.minHeight = minHeight; self.idealHeight = idealHeight; self.maxHeight = maxHeight
            self.alignment = alignment
        }

        /// Convenience: check if this is a simple fixed-size frame (min == ideal == max)
        public var fixedWidth: Float? {
            if let w = minWidth, w == idealWidth && w == maxWidth { return w }
            return nil
        }
        public var fixedHeight: Float? {
            if let h = minHeight, h == idealHeight && h == maxHeight { return h }
            return nil
        }
    }

    public enum Modifier: Equatable, Sendable {
        case padding(top: Float, leading: Float, bottom: Float, trailing: Float)
        case frame(FrameProperties)
        case background(ElementColor)
        case foregroundColor(ElementColor)
        case font(size: Float, weight: Int)
        case onTap(id: Int)
        case accessibilityLabel(String)
        case accessibilityRole(String)
        case accessibilityHint(String)
        case accessibilityHidden(Bool)
        case layoutPriority(Double)
        case fixedSize(horizontal: Bool, vertical: Bool)
    }
}
