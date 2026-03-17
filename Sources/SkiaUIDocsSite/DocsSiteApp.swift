// DocsSiteApp.swift – SkiaUIDocsSite module
// Entry point for the WASM documentation site demo app.
// Routes to different demo views based on the demo ID.

import SkiaUI

@main
struct DocsSiteApp: App {
    var body: some View {
        VStack(spacing: 16) {
            Text("SkiaUI Demos").fontSize(28).bold()
            TextDemo()
            LayoutDemo()
            InteractiveDemo()
        }
    }
}
