// TextMeasurerTests.swift – SkiaUILayout test suite
// Tests for EstimatedTextMeasurer multiline and lineLimit support.

import Testing
@testable import SkiaUILayout

@Suite struct TextMeasurerTests {
    let measurer = EstimatedTextMeasurer()

    @Test func singleLineMeasurement() {
        // "Hello" = 5 chars, fontSize=10 → width=5*10*0.6=30, height=10*1.2=12
        let result = measurer.measure(text: "Hello", fontSize: 10, fontWeight: 400, fontFamily: nil, maxWidth: nil, lineLimit: nil)
        #expect(abs(result.width - 30) < 0.01)
        #expect(abs(result.height - 12) < 0.01)
    }

    @Test func singleLineNoMaxWidth() {
        // Without maxWidth, width = estimatedWidth
        let result = measurer.measure(text: "Test", fontSize: 14, fontWeight: 400, fontFamily: nil, maxWidth: nil, lineLimit: nil)
        let expected = Float(4) * 14 * 0.6  // 33.6
        #expect(abs(result.width - expected) < 0.01)
    }

    @Test func multilineWrapping() {
        // 20 chars, maxWidth=60, fontSize=10 → charWidth=6, charsPerLine=10, 2 lines → height=24
        let text = String(repeating: "a", count: 20)
        let result = measurer.measure(text: text, fontSize: 10, fontWeight: 400, fontFamily: nil, maxWidth: 60, lineLimit: nil)
        #expect(abs(result.width - 60) < 0.01)
        #expect(abs(result.height - 24) < 0.01)
    }

    @Test func lineLimitCapping() {
        // 40 chars, maxWidth=60, fontSize=10 → charWidth=6, charsPerLine=10, 4 lines
        // lineLimit=2 → capped to 2 lines → height=24
        let text = String(repeating: "b", count: 40)
        let result = measurer.measure(text: text, fontSize: 10, fontWeight: 400, fontFamily: nil, maxWidth: 60, lineLimit: 2)
        #expect(abs(result.height - 24) < 0.01)
    }

    @Test func lineLimitNilNoRestriction() {
        // 30 chars, maxWidth=60, fontSize=10 → 3 lines, no lineLimit → all 3 lines
        let text = String(repeating: "c", count: 30)
        let result = measurer.measure(text: text, fontSize: 10, fontWeight: 400, fontFamily: nil, maxWidth: 60, lineLimit: nil)
        #expect(abs(result.height - 36) < 0.01)  // 3 * 12
    }

    @Test func lineLimitOneAlwaysSingleLine() {
        // Long text with lineLimit=1 → height = single line height
        let text = String(repeating: "d", count: 100)
        let result = measurer.measure(text: text, fontSize: 10, fontWeight: 400, fontFamily: nil, maxWidth: 60, lineLimit: 1)
        let lineHeight: Float = 10 * 1.2
        #expect(abs(result.height - lineHeight) < 0.01)
    }

    @Test func emptyText() {
        // "" → width=0, height=lineHeight
        let result = measurer.measure(text: "", fontSize: 10, fontWeight: 400, fontFamily: nil, maxWidth: nil, lineLimit: nil)
        #expect(abs(result.width - 0) < 0.01)
        #expect(abs(result.height - 12) < 0.01)
    }

    @Test func widthClampedToMaxWidth() {
        // estimatedWidth > maxWidth → width clamped to maxWidth
        let text = String(repeating: "e", count: 20)
        let result = measurer.measure(text: text, fontSize: 10, fontWeight: 400, fontFamily: nil, maxWidth: 60, lineLimit: nil)
        #expect(result.width <= 60)
    }
}
