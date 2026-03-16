// ScrollPipelineTests.swift – SkiaUIRuntime test suite
// Tests for scroll handling through the full rendering pipeline.
// These tests use RootHost and must be serialized with other runtime tests.

import Testing
@testable import SkiaUIRuntime
import SkiaUIDSL
import SkiaUIElement
import SkiaUIState
import SkiaUIDisplayList

extension AllRuntimeTests {
@Suite(.serialized) struct ScrollPipelineTests {

    private func resetAll() {
        StateStorage.shared.reset()
        ScrollOffsetStorage.shared.reset()
        resetScrollIDCounter()
        DependencyRecorder.shared.clearCallbacks()
    }

    /// End-to-end test: RootHost.handleScroll applies offset → re-render produces translate command.
    @Test func scrollPipelineEndToEnd() {
        resetAll()

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

        // Verify at least one offset was stored
        let offsets = ScrollOffsetStorage.shared.allOffsets()
        let hasPositiveOffset = offsets.values.contains { $0 > 0 }
        #expect(hasPositiveOffset, "Scroll offset should be > 0, got: \(offsets)")
    }

    /// Test scroll in a nested layout (simulates ScrollView inside a VStack with frame/background).
    @Test func scrollNestedInModifiers() {
        resetAll()

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
}
}
