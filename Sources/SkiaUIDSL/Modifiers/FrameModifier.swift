// FrameModifier.swift – SkiaUIDSL module
// View extension for specifying explicit frame dimensions.

import SkiaUIElement

private func encodeAlignment(_ alignment: Alignment) -> Int {
    let h: Int = switch alignment.horizontal {
    case .leading:  0
    case .center:   1
    case .trailing: 2
    }
    let v: Int = switch alignment.vertical {
    case .top:    0
    case .center: 1
    case .bottom: 2
    }
    return v * 3 + h
}

extension View {
    /// Fixed frame: sets exact width/height (backward compatible).
    public func frame(width: Float? = nil, height: Float? = nil, alignment: Alignment = .center) -> ModifiedView<Self> {
        let a = encodeAlignment(alignment)
        let props = Element.FrameProperties(
            minWidth: width, idealWidth: width, maxWidth: width,
            minHeight: height, idealHeight: height, maxHeight: height,
            alignment: a
        )
        return ModifiedView(content: self, modifier: .frame(props))
    }

    /// Flexible frame: SwiftUI-compatible min/ideal/max per axis.
    public func frame(
        minWidth: Float? = nil, idealWidth: Float? = nil, maxWidth: Float? = nil,
        minHeight: Float? = nil, idealHeight: Float? = nil, maxHeight: Float? = nil,
        alignment: Alignment = .center
    ) -> ModifiedView<Self> {
        let a = encodeAlignment(alignment)
        let props = Element.FrameProperties(
            minWidth: minWidth, idealWidth: idealWidth, maxWidth: maxWidth,
            minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight,
            alignment: a
        )
        return ModifiedView(content: self, modifier: .frame(props))
    }
}
