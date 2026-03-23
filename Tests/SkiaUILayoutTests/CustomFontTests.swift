// CustomFontTests.swift – SkiaUILayout test suite
// Tests for custom font measurement and LayoutEngine integration.

import Testing
import SkiaUIElement
@testable import SkiaUILayout

/// A mock measurer that returns predictable values and records parameters for verification.
struct MockCustomFontMeasurer: TextMeasurer {
    let fixedWidth: Float
    let fixedHeight: Float
    
    // We use a reference type box to record the last call parameters in a Sendable-safe way for testing.
    class CallRecord: @unchecked Sendable {
        var lastText: String?
        var lastFontSize: Float?
        var lastFontWeight: Int?
        var lastFontFamily: String?
        var lastMaxWidth: Float?
    }
    let record = CallRecord()

    func measure(text: String, fontSize: Float, fontWeight: Int, fontFamily: String?, maxWidth: Float?, lineLimit: Int?) -> TextMeasurement {
        record.lastText = text
        record.lastFontSize = fontSize
        record.lastFontWeight = fontWeight
        record.lastFontFamily = fontFamily
        record.lastMaxWidth = maxWidth
        
        return TextMeasurement(width: fixedWidth, height: fixedHeight)
    }
}

@Suite struct CustomFontTests {
    @Test func layoutEngineUsesCustomMeasurer() {
        let mock = MockCustomFontMeasurer(fixedWidth: 123, fixedHeight: 45)
        let engine = LayoutEngine(textMeasurer: mock)
        
        // Create a text element with custom font properties
        let textElement = Element.text("Hello World", .init(
            fontSize: 24,
            fontWeight: 700,
            fontFamily: "MyCustomFont"
        ))
        
        let layout = engine.layout(textElement, proposal: ProposedSize(width: 500, height: nil))
        
        // Verify the layout engine used the mock's returned values
        #expect(layout.width == 123)
        #expect(layout.height == 45)
        
        // Verify parameters were passed correctly to the measurer
        #expect(mock.record.lastText == "Hello World")
        #expect(mock.record.lastFontSize == 24)
        #expect(mock.record.lastFontWeight == 700)
        #expect(mock.record.lastFontFamily == "MyCustomFont")
        #expect(mock.record.lastMaxWidth == 500)
    }

    @Test func layoutEnginePassesNilFontFamily() {
        let mock = MockCustomFontMeasurer(fixedWidth: 100, fixedHeight: 20)
        let engine = LayoutEngine(textMeasurer: mock)
        
        let textElement = Element.text("No Family", .init(fontSize: 16))
        _ = engine.layout(textElement, proposal: .unspecified)
        
        #expect(mock.record.lastFontFamily == nil)
    }

    @Test func nestedTextInContainers() {
        let mock = MockCustomFontMeasurer(fixedWidth: 50, fixedHeight: 20)
        let engine = LayoutEngine(textMeasurer: mock)
        
        // Text inside a padding modifier
        let text = Element.text("Inside", .init(fontSize: 12))
        let element = Element.modified(text, .padding(top: 10, leading: 10, bottom: 10, trailing: 10))
        
        let layout = engine.layout(element, proposal: .unspecified)
        
        // 50 (text) + 10 (leading) + 10 (trailing) = 70
        #expect(layout.width == 70)
        // 20 (text) + 10 (top) + 10 (bottom) = 40
        #expect(layout.height == 40)
    }
}
