// TypographyImageTests.swift – GoldenTests
// DSL-based image snapshot tests for typography rendering.
// Run: swift test --filter GoldenTests/TypographyImageTests

import Testing
import SkiaUIDSL

@Suite struct TypographyImageTests {
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
}
