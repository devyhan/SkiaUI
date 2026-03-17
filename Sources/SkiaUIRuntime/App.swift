// App.swift – SkiaUIRuntime module
// Entry-point protocol for SkiaUI applications.

import SkiaUIDSL

public protocol App {
    associatedtype RootBody: View
    @ViewBuilder var body: RootBody { get }
    init()
}

extension App {
    public static func main() {
        let app = Self()
        let host = RootHost()
        host.render(app.body)
    }
}
