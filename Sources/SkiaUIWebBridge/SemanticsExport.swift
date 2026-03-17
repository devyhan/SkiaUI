// SemanticsExport.swift – SkiaUIWebBridge module
// Exports semantics tree to JS host for DOM overlay accessibility.

#if canImport(JavaScriptKit)
import JavaScriptKit
import SkiaUISemantics
import Foundation

public struct SemanticsExport {
    public static func exportToJS(_ tree: SemanticsTree) {
        guard let json = tree.toJSON() else { return }
        let jsonString = String(data: json, encoding: .utf8) ?? "{}"
        let skiaUI = JSObject.global.skiaUI.object!
        _ = skiaUI.updateSemantics.function?(jsonString)
    }
}
#else
import SkiaUISemantics

public struct SemanticsExport: Sendable {
    public static func exportToJS(_ tree: SemanticsTree) {
        // No-op on macOS
    }
}
#endif
