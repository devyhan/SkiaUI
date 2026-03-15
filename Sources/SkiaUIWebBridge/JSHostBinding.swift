// JSHostBinding.swift – SkiaUIWebBridge module
// Bindings for querying viewport size and scheduling frames from JS host.

#if canImport(JavaScriptKit)
import JavaScriptKit

public struct JSHostBinding {
    public static func getViewportWidth() -> Float {
        Float(JSObject.global.skiaUI.viewportWidth.number ?? 800)
    }

    public static func getViewportHeight() -> Float {
        Float(JSObject.global.skiaUI.viewportHeight.number ?? 600)
    }

    public static func requestAnimationFrame(_ callback: @escaping () -> Void) {
        _ = JSObject.global.requestAnimationFrame.function!(
            JSClosure { _ in callback(); return .undefined }
        )
    }
}
#else
public struct JSHostBinding: Sendable {
    public static func getViewportWidth() -> Float { 800 }
    public static func getViewportHeight() -> Float { 600 }
    public static func requestAnimationFrame(_ callback: @escaping () -> Void) {}
}
#endif
