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
        let context = RenderContext()
        let app = A()
        let host = RootHost(context: context)

        host.setOnDisplayList { bytes in
            // Bulk transfer: create JSTypedArray directly from Swift [UInt8]
            bytes.withUnsafeBufferPointer { buffer in
                let jsArray = JSTypedArray<UInt8>(buffer)
                JSObject.global.skiaUI.submitDisplayList.function!(jsArray.jsValue)
            }
        }

        let viewport = JSObject.global.skiaUI.viewport
        let width = Float(viewport.width.number ?? 800)
        let height = Float(viewport.height.number ?? 600)
        host.setViewport(width: width, height: height)

        // Register tap handler bridge
        JSObject.global.skiaUI.handleTap = .object(JSClosure { args in
            if let tapID = args.first?.number.map({ Int($0) }) {
                host.handleTap(id: tapID)
            }
            return .undefined
        })

        // Register scroll handler bridge
        JSObject.global.skiaUI.handleScroll = .object(JSClosure { args in
            guard args.count >= 4,
                  let x = args[0].number.map({ Float($0) }),
                  let y = args[1].number.map({ Float($0) }),
                  let dx = args[2].number.map({ Float($0) }),
                  let dy = args[3].number.map({ Float($0) }) else {
                return .undefined
            }
            host.handleScroll(x: x, y: y, deltaX: dx, deltaY: dy)
            return .undefined
        })

        host.render(app.body)

        context.stateStorage.setOnDirty {
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
