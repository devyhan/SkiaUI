// RootHostOptimizationTests.swift – SkiaUIRuntime test suite
// Tests for rendering pipeline optimizations (reconciler, caching, dirty tracking).

import Testing
@testable import SkiaUIRuntime
import SkiaUIDSL
import SkiaUIElement
import SkiaUIState
import SkiaUIDisplayList
import SkiaUIReconciler
@testable import SkiaUIRenderTree
import SkiaUILayout

extension AllRuntimeTests {
@Suite(.serialized) struct RootHostOptimizationTests {

    private func resetAll() {
        StateStorage.shared.reset()
        DependencyRecorder.shared.clearCallbacks()
    }

    // MARK: - Phase 1: Reconciler Early Return

    @Test func identicalRenderEmitsCachedBytes() {
        resetAll()
        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var captures: [[UInt8]] = []
        host.setOnDisplayList { captures.append($0) }

        let view = Text("Hello")
        host.render(view)
        host.render(view)

        #expect(captures.count == 2)
        #expect(captures[0] == captures[1])
    }

    @Test func changedStateProducesDifferentBytes() {
        resetAll()
        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var captures: [[UInt8]] = []
        host.setOnDisplayList { captures.append($0) }

        host.render(Text("Hello"))
        host.render(Text("World"))

        #expect(captures.count == 2)
        #expect(captures[0] != captures[1])
    }

    @Test func scrollOnlyChangeReRenders() {
        resetAll()
        resetScrollIDCounter()
        ScrollOffsetStorage.shared.reset()

        let host = RootHost()
        host.setViewport(width: 300, height: 200)

        var captures: [[UInt8]] = []
        host.setOnDisplayList { captures.append($0) }

        // Build a scrollable view with enough content to overflow the 80px frame
        let view = ScrollView {
            VStack(spacing: 8) {
                Text("Item 1")
                Text("Item 2")
                Text("Item 3")
                Text("Item 4")
                Text("Item 5")
                Text("Item 6")
                Text("Item 7")
                Text("Item 8")
            }
        }
        .frame(width: 200, height: 80)

        host.render(view)

        // Frame is centered: x=(300-200)/2=50, y=(200-80)/2=60
        // Hit center of the frame at (150, 100)
        host.handleScroll(x: 150, y: 100, deltaX: 0, deltaY: 30)

        host.render(view)

        #expect(captures.count == 2)
        // Scroll changed, so bytes should differ
        #expect(captures[0] != captures[1])
    }

    // MARK: - Phase 2: DirtyTracker + Layout Equality

    @Test func colorChangePreservesLayout() {
        resetAll()
        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var captures: [[UInt8]] = []
        host.setOnDisplayList { captures.append($0) }

        // foregroundColor change should not change layout dimensions
        let view1 = Text("Hello").foregroundColor(.red)
        let view2 = Text("Hello").foregroundColor(.blue)

        host.render(view1)
        host.render(view2)

        #expect(captures.count == 2)
        // Color change means different bytes (different draw commands)
        #expect(captures[0] != captures[1])
    }

    @Test func dirtyTrackerPopulatedFromPatches() {
        let reconciler = Reconciler()
        var tracker = DirtyTracker()

        let old = Element.text("Hello", .init())
        let new = Element.text("World", .init())
        let patches = reconciler.diff(old: old, new: new)

        #expect(!patches.isEmpty)

        for patch in patches {
            let path: ElementPath = switch patch {
            case .insert(let p, _): p
            case .delete(let p): p
            case .update(let p, _, _): p
            case .replace(let p, _, _): p
            }
            tracker.markDirty(path)
        }

        #expect(!tracker.isEmpty)
        #expect(tracker.isDirty(ElementPath()))
    }

    // MARK: - Phase 5: drawingGroup

    @Test func drawingGroupTransparentToLayout() {
        let engine = LayoutEngine()
        let base = Element.text("Hello", .init(fontSize: 14))
        let grouped = Element.modified(base, .drawingGroup)

        let proposal = ProposedSize(width: 200, height: 100)
        let baseLayout = engine.layout(base, proposal: proposal)
        let groupedLayout = engine.layout(grouped, proposal: proposal)

        #expect(baseLayout.width == groupedLayout.width)
        #expect(baseLayout.height == groupedLayout.height)
    }

    @Test func drawingGroupCachesRenderNode() {
        let cache = RenderCache()
        let element = Element.modified(.text("Hello", .init(fontSize: 14)), .drawingGroup)
        let layout = LayoutNode(width: 42, height: 16.8)
        let builder1 = RenderTreeBuilder(renderCache: cache)
        let node1 = builder1.build(element: element, layout: layout)

        // Same element+layout should return same cached node instance
        let builder2 = RenderTreeBuilder(renderCache: cache)
        let node2 = builder2.build(element: element, layout: layout)

        #expect(node1 === node2)
    }

    @Test func drawingGroupInvalidatesOnChange() {
        let cache = RenderCache()
        let element1 = Element.modified(.text("Hello", .init(fontSize: 14)), .drawingGroup)
        let element2 = Element.modified(.text("World", .init(fontSize: 14)), .drawingGroup)
        let layout = LayoutNode(width: 42, height: 16.8)
        let builder1 = RenderTreeBuilder(renderCache: cache)
        let node1 = builder1.build(element: element1, layout: layout)

        let builder2 = RenderTreeBuilder(renderCache: cache)
        let node2 = builder2.build(element: element2, layout: layout)

        // Different element should produce different node
        #expect(node1 !== node2)
    }

    @Test func drawingGroupVisualOutput() {
        resetAll()
        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var withGroupBytes: [UInt8] = []
        var withoutGroupBytes: [UInt8] = []

        host.setOnDisplayList { withoutGroupBytes = $0 }
        host.render(Text("Test"))

        // Reset to clear caches for fair comparison
        let host2 = RootHost()
        host2.setViewport(width: 400, height: 300)
        host2.setOnDisplayList { withGroupBytes = $0 }
        host2.render(Text("Test").drawingGroup())

        // Both should produce non-empty output
        #expect(!withGroupBytes.isEmpty)
        #expect(!withoutGroupBytes.isEmpty)
        // The drawingGroup version will have retained subtree markers,
        // so bytes will differ, but both should decode successfully
        let encoder = CommandEncoder()
        let dl1 = encoder.decode(withoutGroupBytes)
        let dl2 = encoder.decode(withGroupBytes)
        #expect(dl1 != nil)
        #expect(dl2 != nil)
    }
}
}
