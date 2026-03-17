// DocsSiteApp.swift – SkiaUIDocsSite module
// Entry point for the WASM documentation site demo app.
// Routes to different demo views based on the ?demo= URL parameter.

import SkiaUI
import SkiaUIWebBridge
#if canImport(JavaScriptKit)
import JavaScriptKit
#endif

@main
struct DocsSiteApp: App {
    var body: some View {
        switch Self.currentDemoID() {
        case "text-demo":
            TextDemo()
        case "layout-demo":
            LayoutDemo()
        case "interactive-demo":
            InteractiveDemo()
        default:
            VStack(spacing: 16) {
                Text("SkiaUI Demos").fontSize(28).bold()
                TextDemo()
                LayoutDemo()
                InteractiveDemo()
            }
        }
    }

    static func main() {
        WebBridge.start(DocsSiteApp.self)
    }

    private static func currentDemoID() -> String? {
        #if canImport(JavaScriptKit)
        let search = JSObject.global.location.search.string ?? ""
        guard search.contains("demo=") else { return nil }
        let query = search.dropFirst() // drop leading "?"
        for param in query.split(separator: "&") {
            let parts = param.split(separator: "=", maxSplits: 1)
            if parts.count == 2 && parts[0] == "demo" {
                return String(parts[1]).removingPercentEncoding
            }
        }
        return nil
        #else
        return nil
        #endif
    }
}
