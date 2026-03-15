// BasicGoldenTests.swift – GoldenTests suite
// Golden tests for display list output verification.

import Testing
import Foundation
import SkiaUIDSL
import SkiaUIElement
import SkiaUILayout
import SkiaUIRenderTree
import SkiaUIDisplayList

@Suite struct BasicGoldenTests {
    func makeRunner() -> GoldenTestRunner {
        // Use a temp directory for test goldens
        let dir = NSTemporaryDirectory() + "SkiaUIGoldens"
        return GoldenTestRunner(goldensDir: dir)
    }

    @Test func singleTextGolden() {
        let runner = makeRunner()
        let dl = runner.captureDisplayList(Text("Hello World"))
        let serialized = runner.serialize(dl)
        #expect(serialized.contains("drawText"))
        #expect(serialized.contains("Hello World"))
    }

    @Test func rectangleGolden() {
        let runner = makeRunner()
        let dl = runner.captureDisplayList(Rectangle().fill(.blue))
        let serialized = runner.serialize(dl)
        #expect(serialized.contains("drawRect"))
    }

    @Test func vstackGolden() {
        let runner = makeRunner()
        let view = VStack {
            Text("A")
            Text("B")
        }
        let dl = runner.captureDisplayList(view)
        let serialized = runner.serialize(dl)
        // Should have at least 2 drawText commands
        let textCount = serialized.components(separatedBy: "drawText").count - 1
        #expect(textCount >= 2)
    }

    @Test func displayListCommandCount() {
        let runner = makeRunner()
        let view = VStack {
            Text("One")
            Text("Two")
            Text("Three")
        }
        let dl = runner.captureDisplayList(view)
        // Each node gets save+restore, text nodes get drawText
        #expect(dl.commands.count > 0)
    }
}
