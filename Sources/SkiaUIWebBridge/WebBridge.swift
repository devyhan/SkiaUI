// WebBridge.swift – SkiaUIWebBridge module
// Bridge layer for Wasm/JavaScript interop via JavaScriptKit.

#if canImport(JavaScriptKit)
import JavaScriptKit
import SkiaUIRuntime
import SkiaUIDSL
import SkiaUIState
import SkiaUIDisplayList

public struct WebBridge {
    public static func start<A: App>(_ appType: A.Type) {
        let app = A()
        let host = RootHost()

        host.setOnDisplayList { bytes in
            // Convert bytes to JS Uint8Array and submit
            let jsArray = JSObject.global.Uint8Array.function!.new(bytes.count)
            for (i, byte) in bytes.enumerated() {
                jsArray[i] = .number(Double(byte))
            }
            let buffer = jsArray.buffer
            JSObject.global.skiaUI.submitDisplayList.function!(buffer)
        }

        let viewport = JSObject.global.skiaUI.viewport
        let width = Float(viewport.width.number ?? 800)
        let height = Float(viewport.height.number ?? 600)
        host.setViewport(width: width, height: height)

        host.render(app.body)

        StateStorage.shared.setOnDirty {
            host.render(app.body)
        }
    }
}
#else
import SkiaUIRuntime
import SkiaUIDSL
import SkiaUIState

public struct WebBridge: Sendable {
    public init() {}

    public static func start<A: App>(_ appType: A.Type) {
        // No-op on non-Wasm platforms
    }
}
#endif
