// DisplayListExport.swift – SkiaUIWebBridge module
// Exports a DisplayList to the JavaScript host via binary encoding.

#if canImport(JavaScriptKit)
import JavaScriptKit
import SkiaUIDisplayList

public struct DisplayListExport {
    public static func exportToJS(_ displayList: DisplayList) {
        let encoder = CommandEncoder()
        let bytes = encoder.encode(displayList)
        // Bulk transfer via JSTypedArray (O(1) copy instead of O(n) element-by-element)
        bytes.withUnsafeBufferPointer { buffer in
            let jsArray = JSTypedArray<UInt8>(buffer)
            JSObject.global.skiaUI.submitDisplayList.function!(jsArray.jsValue)
        }
    }
}
#else
import SkiaUIDisplayList

public struct DisplayListExport: Sendable {
    public static func exportToJS(_ displayList: DisplayList) {
        // No-op on non-Wasm platforms
    }
}
#endif
