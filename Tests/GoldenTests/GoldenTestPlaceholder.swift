// BasicGoldenTests.swift – GoldenTests suite
// Golden tests for display list output verification.

import Testing
import Foundation
import SkiaUIDSL
import SkiaUIElement
import SkiaUILayout
import SkiaUIRenderTree
import SkiaUIDisplayList

@Suite(.serialized) struct BasicGoldenTests {
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

    @Test func scrollViewGoldenClipsContent() {
        let runner = makeRunner()
        let view = ScrollView {
            Text("A")
            Text("B")
            Text("C")
        }
        let dl = runner.captureDisplayList(view, width: 200, height: 40)
        let serialized = runner.serialize(dl)
        // Scroll container should emit clipRect
        #expect(serialized.contains("clipRect"))
        // Should still render text content
        let textCount = serialized.components(separatedBy: "drawText").count - 1
        #expect(textCount >= 3)
    }

    @Test func scrollViewHorizontalGolden() {
        let runner = makeRunner()
        let view = ScrollView(.horizontal) {
            Text("AAAA")
            Text("BBBB")
        }
        let dl = runner.captureDisplayList(view, width: 50, height: 100)
        let serialized = runner.serialize(dl)
        #expect(serialized.contains("clipRect"))
        let textCount = serialized.components(separatedBy: "drawText").count - 1
        #expect(textCount >= 2)
    }

    @Test func scrollOffsetAppliedInDisplayList() {
        // Reset scroll ID counter so IDs are deterministic
        resetScrollIDCounter()

        let view = ScrollView {
            VStack(spacing: 8) {
                Text("A")
                Text("B")
                Text("C")
                Text("D")
                Text("E")
                Text("F")
            }
        }

        let element = ViewToElementConverter.convert(view)
        let engine = LayoutEngine()
        let layout = engine.layout(element, proposal: ProposedSize(width: 200, height: 60))

        // Verify the scroll container's layout: viewport=60, content > 60
        #expect(layout.height == 60, "Viewport height should be 60")
        if let childLayout = layout.children.first {
            #expect(childLayout.height > 60, "Content height \(childLayout.height) should exceed viewport 60")
        }

        // Build render tree with scroll offset applied
        let scrollOffsets: [Int: Float] = [0: 30]
        let renderBuilder = RenderTreeBuilder()
        let renderNode = renderBuilder.build(element: element, layout: layout, scrollOffsets: scrollOffsets)

        // Verify render node has scroll offset
        #expect(renderNode.clipToBounds == true, "Scroll container should clip")
        #expect(renderNode.scrollOffset != nil, "Scroll container should have scroll offset")
        if let scroll = renderNode.scrollOffset {
            #expect(scroll.y == -30, "Scroll offset y should be -30, got \(scroll.y)")
        }

        // Build display list and check for translate after clipRect
        let dlBuilder = DisplayListBuilder()
        let dl = dlBuilder.build(from: renderNode)
        let runner = makeRunner()
        let serialized = runner.serialize(dl)

        #expect(serialized.contains("clipRect"), "Should have clipRect command")
        #expect(serialized.contains("translate(0.0, -30.0)"), "Should have scroll translate, got:\n\(serialized)")
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

    @Test func customFontFamilyInDisplayList() {
        let runner = makeRunner()
        let view = Text("Custom").font(.custom("Monaspace Neon", size: 18))
        let dl = runner.captureDisplayList(view)
        let serialized = runner.serialize(dl)
        #expect(serialized.contains("drawText"))
        #expect(serialized.contains("ff=Monaspace Neon"))
        #expect(serialized.contains("fs=18.0"))
    }

    @Test func systemFontNoFamilyInDisplayList() {
        let runner = makeRunner()
        let view = Text("System").font(.system(size: 20))
        let dl = runner.captureDisplayList(view)
        let serialized = runner.serialize(dl)
        #expect(serialized.contains("drawText"))
        // system-ui should not appear as a family in the display list
        #expect(!serialized.contains("ff=system-ui"))
        #expect(serialized.contains("fs=20.0"))
    }
}
