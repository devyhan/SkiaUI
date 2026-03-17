// TextDemo.swift – SkiaUIDocsSite module
// Demonstrates text rendering capabilities.

import SkiaUI

struct TextDemo: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Text Demo").fontSize(20).bold()
            Text("Regular text at default size")
            Text("Large bold text").fontSize(24).bold()
            Text("Colored text").foregroundColor(.red)
            Text("Multiline text with line limit")
                .lineLimit(2)
                .fontSize(14)
        }
    }
}
