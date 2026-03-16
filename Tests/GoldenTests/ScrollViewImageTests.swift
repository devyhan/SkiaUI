// ScrollViewImageTests.swift – GoldenTests
// Display list golden tests for ScrollView clipping behavior.
// Run: swift test --filter GoldenTests/ScrollViewImageTests

import Testing
import SkiaUIDSL
import SkiaUIElement
import SkiaUILayout
import SkiaUIRenderTree
import SkiaUIDisplayList
import SkiaUIState
import SkiaUI

@Suite(.serialized) struct ScrollViewImageTests {

    /// End-to-end test: RootHost.handleScroll applies offset → re-render produces translate command.
    @Test func scrollPipelineEndToEnd() {
        // Reset global state
        resetScrollIDCounter()
        ScrollOffsetStorage.shared.reset()

        let host = RootHost()
        host.setViewport(width: 300, height: 200)

        struct TestScrollView: View {
            var body: some View {
                ScrollView {
                    VStack(spacing: 8) {
                        Text("A")
                        Text("B")
                        Text("C")
                        Text("D")
                        Text("E")
                        Text("F")
                        Text("G")
                        Text("H")
                    }
                }
                .frame(width: 200, height: 80)
            }
        }

        var displayList1 = [UInt8]()
        var displayList2 = [UInt8]()

        host.setOnDisplayList { bytes in displayList1 = bytes }
        let view = TestScrollView()
        host.render(view)
        #expect(!displayList1.isEmpty, "Initial render should produce display list")

        // Scroll at center of viewport (should hit the scroll container)
        host.handleScroll(x: 150, y: 100, deltaX: 0, deltaY: 40)

        host.setOnDisplayList { bytes in displayList2 = bytes }
        host.render(view)
        #expect(!displayList2.isEmpty, "Re-render should produce display list")
        #expect(displayList1 != displayList2, "Display list should change after scroll")

        // Verify at least one offset was stored (scroll ID may vary due to global counter)
        let offsets = ScrollOffsetStorage.shared.allOffsets()
        let hasPositiveOffset = offsets.values.contains { $0 > 0 }
        #expect(hasPositiveOffset, "Scroll offset should be > 0, got: \(offsets)")
    }
    /// Test scroll in a nested layout (simulates ScrollView inside a VStack with frame/background).
    @Test func scrollNestedInModifiers() {
        resetScrollIDCounter()
        ScrollOffsetStorage.shared.reset()

        let host = RootHost()
        host.setViewport(width: 400, height: 400)

        struct NestedScrollView: View {
            var body: some View {
                VStack(spacing: 16) {
                    Text("Title").font(size: 20, weight: .bold)
                    ScrollView {
                        VStack(spacing: 8) {
                            Text("A")
                            Text("B")
                            Text("C")
                            Text("D")
                            Text("E")
                            Text("F")
                        }
                    }
                    .frame(width: 200, height: 80)
                    .background(.gray)
                    Text("Footer")
                }
                .padding(32)
            }
        }

        var dl1 = [UInt8]()
        var dl2 = [UInt8]()

        host.setOnDisplayList { dl1 = $0 }
        let view = NestedScrollView()
        host.render(view)

        // Scroll at center — should hit the scroll container
        host.handleScroll(x: 200, y: 200, deltaX: 0, deltaY: 30)

        host.setOnDisplayList { dl2 = $0 }
        host.render(view)

        let offsets = ScrollOffsetStorage.shared.allOffsets()
        let hasPositiveOffset = offsets.values.contains { $0 > 0 }
        #expect(hasPositiveOffset, "Scroll offset should be > 0, got: \(offsets)")
        #expect(dl1 != dl2, "Display list should change after scroll")
    }

    @Test func scrollViewClipsContent() {
        // Vertical scroll with content exceeding viewport height
        assertImageSnapshot(
            ScrollView {
                Text("Line 1")
                Text("Line 2")
                Text("Line 3")
                Text("Line 4")
                Text("Line 5")
            },
            named: "scrollViewClipsContent",
            width: 60,
            height: 200
        )
    }

    @Test func scrollViewHorizontal() {
        // Horizontal scroll with content exceeding viewport width
        assertImageSnapshot(
            ScrollView(.horizontal) {
                Text("AAAA")
                Text("BBBB")
                Text("CCCC")
                Text("DDDD")
            },
            named: "scrollViewHorizontal",
            width: 200,
            height: 60
        )
    }
}
