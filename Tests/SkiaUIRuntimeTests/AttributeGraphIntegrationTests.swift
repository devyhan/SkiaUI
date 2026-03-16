// AttributeGraphIntegrationTests.swift – SkiaUIRuntime test suite
// Integration tests for Eval/vite attribute graph incremental rendering.

import Testing
@testable import SkiaUIRuntime
import SkiaUIDSL
import SkiaUIElement
import SkiaUIState
import SkiaUIDisplayList

extension AllRuntimeTests {
@Suite(.serialized) struct AttributeGraphIntegrationTests {

    // Helper to reset all shared state before each test
    private func resetAll() {
        StateStorage.shared.reset()
        DependencyRecorder.shared.clearCallbacks()
    }

    @Test func firstFrameEvaluatesAll() {
        resetAll()
        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var bytes: [UInt8] = []
        host.setOnDisplayList { bytes = $0 }

        host.render(Text("Hello"))
        #expect(!bytes.isEmpty)
    }

    @Test func unchangedViewProducesSameOutput() {
        resetAll()

        struct StaticView: View {
            var body: some View {
                Text("Static")
            }
        }

        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var captures: [[UInt8]] = []
        host.setOnDisplayList { captures.append($0) }

        host.render(StaticView())
        host.render(StaticView())

        #expect(captures.count == 2)
        #expect(captures[0] == captures[1])
    }

    @Test func primitiveViewChangeProducesDifferentOutput() {
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

    @Test func identicalOutputPreservesCache() {
        resetAll()

        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var captures: [[UInt8]] = []
        host.setOnDisplayList { captures.append($0) }

        let view = VStack {
            Text("Title")
            Text("Body")
        }
        host.render(view)
        host.render(view)

        #expect(captures.count == 2)
        #expect(captures[0] == captures[1])
    }

    @Test func multipleRendersCycleConsistently() {
        resetAll()

        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var lastBytes: [UInt8] = []
        host.setOnDisplayList { lastBytes = $0 }

        for _ in 0..<5 {
            host.render(Text("Stable"))
        }

        #expect(!lastBytes.isEmpty)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(lastBytes)
        #expect(decoded != nil)
    }

    @Test func scrollOffsetChangeStillWorks() {
        resetAll()
        resetScrollIDCounter()
        ScrollOffsetStorage.shared.reset()

        let host = RootHost()
        host.setViewport(width: 300, height: 200)

        var captures: [[UInt8]] = []
        host.setOnDisplayList { captures.append($0) }

        let view = ScrollView {
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

        host.render(view)

        ScrollOffsetStorage.shared.setContentSize(id: 0, size: 1000)
        ScrollOffsetStorage.shared.setViewportSize(id: 0, size: 200)
        ScrollOffsetStorage.shared.applyDelta(id: 0, delta: 50)

        host.render(view)

        #expect(captures.count == 2)
        #expect(captures[0] != captures[1])
    }

    @Test func nestedCompositeViewsWork() {
        resetAll()

        struct Inner: View {
            var body: some View { Text("Inner") }
        }
        struct Outer: View {
            var body: some View {
                VStack {
                    Inner()
                    Text("Outer")
                }
            }
        }

        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var bytes: [UInt8] = []
        host.setOnDisplayList { bytes = $0 }

        host.render(Outer())
        #expect(!bytes.isEmpty)

        var bytes2: [UInt8] = []
        host.setOnDisplayList { bytes2 = $0 }
        host.render(Outer())
        #expect(bytes == bytes2)
    }

    @Test func goldenOutputDecodable() {
        resetAll()

        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var bytes: [UInt8] = []
        host.setOnDisplayList { bytes = $0 }

        let view = VStack(spacing: 8) {
            Text("Hello").fontSize(20).bold()
            Text("World").foregroundColor(.red)
        }
        host.render(view)

        #expect(!bytes.isEmpty)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(bytes)
        #expect(decoded != nil)
    }

    @Test func graphCacheSurvivesMultipleFrames() {
        resetAll()

        struct DeepView: View {
            var body: some View {
                VStack {
                    HStack {
                        Text("A")
                        Text("B")
                    }
                    Text("C")
                }
            }
        }

        let host = RootHost()
        host.setViewport(width: 400, height: 300)

        var allCaptures: [[UInt8]] = []
        host.setOnDisplayList { allCaptures.append($0) }

        // Render 3 identical frames
        host.render(DeepView())
        host.render(DeepView())
        host.render(DeepView())

        #expect(allCaptures.count == 3)
        #expect(allCaptures[0] == allCaptures[1])
        #expect(allCaptures[1] == allCaptures[2])
    }
}
}
