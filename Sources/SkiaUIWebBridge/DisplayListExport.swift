// DisplayListExport.swift – SkiaUIWebBridge module
// Exports a DisplayList to the JavaScript host via binary encoding.

#if canImport(JavaScriptKit)
import JavaScriptKit
import SkiaUIDisplayList

public struct DisplayListExport {
    public static func exportToJS(_ displayList: DisplayList) {
        let encoder = CommandEncoder()
        let bytes = encoder.encode(displayList)
        // Convert to JS Uint8Array and call submitDisplayList
        let jsArray = JSObject.global.Uint8Array.function!.new(bytes.count)
        for (i, byte) in bytes.enumerated() {
            jsArray[i] = .number(Double(byte))
        }
        let buffer = jsArray.buffer
        JSObject.global.skiaUI.submitDisplayList.function!(buffer)
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
