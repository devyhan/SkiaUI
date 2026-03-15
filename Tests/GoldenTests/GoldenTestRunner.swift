// GoldenTestRunner.swift – GoldenTests
// Captures and serializes display lists for golden test comparison.

import Foundation
import SkiaUIDSL
import SkiaUIElement
import SkiaUILayout
import SkiaUIRenderTree
import SkiaUIDisplayList

public struct GoldenTestRunner {
    private let goldensDir: String

    public init(goldensDir: String) {
        self.goldensDir = goldensDir
    }

    public func captureDisplayList<V: View>(_ view: V, width: Float = 400, height: Float = 300) -> DisplayList {
        let element = ViewToElementConverter.convert(view)
        let constraints = Constraints(maxWidth: width, maxHeight: height)
        let engine = LayoutEngine()
        let layout = engine.layout(element, constraints: constraints)
        let builder = RenderTreeBuilder()
        let renderNode = builder.build(element: element, layout: layout)
        let dlBuilder = DisplayListBuilder()
        return dlBuilder.build(from: renderNode)
    }

    public func serialize(_ displayList: DisplayList) -> String {
        var lines: [String] = []
        lines.append("version: \(displayList.version)")
        lines.append("commands: \(displayList.commands.count)")
        for (i, cmd) in displayList.commands.enumerated() {
            lines.append("  [\(i)] \(describeCommand(cmd))")
        }
        return lines.joined(separator: "\n")
    }

    private func describeCommand(_ cmd: DrawCommand) -> String {
        switch cmd {
        case .save: return "save"
        case .restore: return "restore"
        case .translate(let x, let y): return "translate(\(x), \(y))"
        case .clipRect(let x, let y, let w, let h): return "clipRect(\(x), \(y), \(w), \(h))"
        case .drawRect(let x, let y, let w, let h, let c): return "drawRect(\(x), \(y), \(w), \(h), 0x\(String(c, radix: 16, uppercase: true)))"
        case .drawRRect(let x, let y, let w, let h, let r, let c): return "drawRRect(\(x), \(y), \(w), \(h), r=\(r), 0x\(String(c, radix: 16, uppercase: true)))"
        case .drawText(let text, let x, let y, let fs, let fw, let c, let bw): return "drawText(\"\(text)\", \(x), \(y), fs=\(fs), fw=\(fw), 0x\(String(c, radix: 16, uppercase: true)), bw=\(bw))"
        case .retainedSubtreeBegin(let id, let v): return "retainedBegin(id=\(id), v=\(v))"
        case .retainedSubtreeEnd: return "retainedEnd"
        }
    }

    public func compareGolden(name: String, actual: String) -> Bool {
        let path = "\(goldensDir)/\(name).golden"
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            guard let data = fileManager.contents(atPath: path),
                  let expected = String(data: data, encoding: .utf8) else { return false }
            return actual == expected
        } else {
            // Create golden file
            try? fileManager.createDirectory(atPath: goldensDir, withIntermediateDirectories: true)
            try? actual.write(toFile: path, atomically: true, encoding: .utf8)
            return true
        }
    }
}
