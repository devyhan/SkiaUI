// CoreTextMeasurer.swift – SkiaUILayout module
// CoreText-based text measurement for accurate native text sizing.

#if canImport(CoreText)
import CoreText
import Foundation

public struct CoreTextMeasurer: TextMeasurer {
    public init() {}

    public func measure(text: String, fontSize: Float, fontWeight: Int, fontFamily: String?, maxWidth: Float?, lineLimit: Int? = nil) -> TextMeasurement {
        let ctFont = makeFont(size: CGFloat(fontSize), weight: fontWeight, family: fontFamily)
        let attrString = CFAttributedStringCreate(nil, text as CFString, [kCTFontAttributeName: ctFont] as CFDictionary)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString!)

        let constraintSize: CGSize
        if let maxW = maxWidth {
            constraintSize = CGSize(width: CGFloat(maxW), height: CGFloat.greatestFiniteMagnitude)
        } else {
            constraintSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }

        let fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, constraintSize, nil)
        var measuredHeight = Float(ceil(fitSize.height))

        // Apply lineLimit if specified
        if let limit = lineLimit, limit > 0 {
            let lineHeight = Float(ceil(CGFloat(fontSize) * 1.2))
            let maxHeight = lineHeight * Float(limit)
            measuredHeight = min(measuredHeight, maxHeight)
        }

        return TextMeasurement(
            width: Float(ceil(fitSize.width)),
            height: measuredHeight
        )
    }

    private func makeFont(size: CGFloat, weight: Int, family: String?) -> CTFont {
        let ctWeight = mapWeight(weight)
        if let family = family {
            let descriptor = CTFontDescriptorCreateWithAttributes([
                kCTFontFamilyNameAttribute: family,
                kCTFontWeightTrait: ctWeight,
            ] as CFDictionary)
            return CTFontCreateWithFontDescriptor(descriptor, size, nil)
        }
        return CTFontCreateWithName("Helvetica" as CFString, size, nil)
    }

    private func mapWeight(_ weight: Int) -> CGFloat {
        switch weight {
        case ...100: return -0.8   // Thin
        case ...200: return -0.6   // ExtraLight
        case ...300: return -0.4   // Light
        case ...400: return  0.0   // Regular
        case ...500: return  0.23  // Medium
        case ...600: return  0.3   // SemiBold
        case ...700: return  0.4   // Bold
        case ...800: return  0.56  // ExtraBold
        default:     return  0.62  // Black
        }
    }
}
#endif
