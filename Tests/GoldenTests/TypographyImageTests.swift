// TypographyImageTests.swift – GoldenTests
// DSL-based image snapshot tests for typography rendering.
// Run: swift test --filter GoldenTests/TypographyImageTests

import Testing
import SkiaUIDSL

extension AllGoldenTests {
@Suite(.serialized) struct TypographyImageTests {
    @Test func plainText() {
        assertImageSnapshot(Text("Hello"), named: "plainText")
    }

    @Test func textWithFontSize() {
        assertImageSnapshot(Text("Big").fontSize(32), named: "textWithFontSize")
    }

    @Test func textWithBoldWeight() {
        assertImageSnapshot(Text("Bold").fontWeight(700), named: "textWithBoldWeight")
    }

    @Test func textWithForegroundColor() {
        assertImageSnapshot(
            Text("Blue").foregroundColor(.blue),
            named: "textWithForegroundColor"
        )
    }

    @Test func textWithAllTypography() {
        assertImageSnapshot(
            Text("Styled").fontSize(24).fontWeight(700).foregroundColor(.red),
            named: "textWithAllTypography"
        )
    }

    @Test func multipleTextsInVStack() {
        assertImageSnapshot(
            VStack {
                Text("A")
                Text("B")
            },
            named: "multipleTextsInVStack"
        )
    }

    @Test func multilingualText() {
        assertImageSnapshot(
            VStack(spacing: 8) {
                Text("Hello World (English)")
                Text("안녕하세요 (Korean)")
                Text("こんにちは (Japanese)")
                Text("你好 (Chinese)")
                Text("नमस्ते (Hindi)")
                Text("สวัสดี (Thai)")
                Text("مرحبا (Arabic - RTL)")
                Text("Emojis: 🚀 🌍 🌈 🍎")
                Text("Mixed: 한글, 中文, 日本語, 123").fontSize(14)
            },
            named: "multilingualText",
            width: 400,
            height: 350
        )
    }
}
}
