// TextMeasurer.swift – SkiaUILayout module
// Protocol for measuring text dimensions, abstracting away platform-specific APIs.

import SkiaUIElement

/// Result of measuring a text string.
public struct TextMeasurement: Equatable, Sendable {
    public var width: Float
    public var height: Float
    public init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }
}

/// Protocol for measuring text dimensions given text properties and optional constraints.
public protocol TextMeasurer: Sendable {
    func measure(text: String, fontSize: Float, fontWeight: Int, fontFamily: String?, maxWidth: Float?, lineLimit: Int?) -> TextMeasurement
}

/// Estimated text measurer using character-count heuristics.
/// This is the original SkiaUI text sizing strategy: `fontSize * 0.6 * charCount` width.
public struct EstimatedTextMeasurer: TextMeasurer {
    public init() {}

    public func measure(text: String, fontSize: Float, fontWeight: Int, fontFamily: String?, maxWidth: Float?, lineLimit: Int? = nil) -> TextMeasurement {
        let charWidth = fontSize * 0.6
        let estimatedWidth = charWidth * Float(text.count)
        let lineHeight = fontSize * 1.2

        guard let maxW = maxWidth, estimatedWidth > maxW, maxW > 0 else {
            // Single line — apply lineLimit (1 means single line regardless)
            let clampedHeight: Float
            if let limit = lineLimit, limit == 1 {
                clampedHeight = lineHeight
            } else {
                clampedHeight = lineHeight
            }
            return TextMeasurement(width: estimatedWidth, height: clampedHeight)
        }

        // Multiline: estimate how many lines the text wraps to
        let charsPerLine = max(1, Int(maxW / charWidth))
        let totalLines = (text.count + charsPerLine - 1) / charsPerLine

        let effectiveLines: Int
        if let limit = lineLimit, limit > 0 {
            effectiveLines = min(totalLines, limit)
        } else {
            effectiveLines = totalLines
        }

        let width = min(estimatedWidth, maxW)
        let height = lineHeight * Float(effectiveLines)
        return TextMeasurement(width: width, height: height)
    }
}
