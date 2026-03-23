// WebTextMeasurer.swift – SkiaUIWebBridge module
// JavaScript-based text measurement for accurate sizing in Wasm/Browser.

import SkiaUILayout

#if canImport(JavaScriptKit)
import JavaScriptKit

public struct WebTextMeasurer: TextMeasurer, @unchecked Sendable {
    private let skiaUI: JSObject

    public init() {
        self.skiaUI = JSObject.global.skiaUI.object!
    }

    public func measure(text: String, fontSize: Float, fontWeight: Int, fontFamily: String?, maxWidth: Float?, lineLimit: Int?) -> TextMeasurement {
        guard let measureFunc = skiaUI.measureText.function else {
            // Fallback if JS side didn't provide measureText
            return EstimatedTextMeasurer().measure(text: text, fontSize: fontSize, fontWeight: fontWeight, fontFamily: fontFamily, maxWidth: maxWidth, lineLimit: lineLimit)
        }

        let result = measureFunc(
            text.jsValue,
            fontSize.jsValue,
            fontWeight.jsValue,
            (fontFamily ?? "").jsValue,
            (maxWidth ?? -1).jsValue,
            (lineLimit ?? 0).jsValue
        )

        return TextMeasurement(
            width: Float(result.width.number ?? 0),
            height: Float(result.height.number ?? 0)
        )
    }
}
#endif
