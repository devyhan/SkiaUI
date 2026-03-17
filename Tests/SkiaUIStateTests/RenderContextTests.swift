// RenderContextTests.swift – SkiaUIState test suite
// Tests for RenderContext gesture handler registration and activation.

import Testing
@testable import SkiaUIState

@Suite struct RenderContextTests {
    @Test func longPressHandlerRegistration() {
        let ctx = RenderContext()
        var called = [Int]()
        let id0 = ctx.registerLongPressHandler { called.append(0) }
        let id1 = ctx.registerLongPressHandler { called.append(1) }
        let id2 = ctx.registerLongPressHandler { called.append(2) }
        #expect(id0 == 0)
        #expect(id1 == 1)
        #expect(id2 == 2)
        ctx.longPressHandlers[id1]?()
        #expect(called == [1])
    }

    @Test func longPressHandlerReset() {
        let ctx = RenderContext()
        _ = ctx.registerLongPressHandler {}
        _ = ctx.registerLongPressHandler {}
        ctx.resetLongPressState()
        #expect(ctx.longPressHandlers.isEmpty)
        // After reset, IDs should restart from 0
        let newID = ctx.registerLongPressHandler {}
        #expect(newID == 0)
    }

    @Test func dragHandlerRegistration() {
        let ctx = RenderContext()
        nonisolated(unsafe) var changedValues = [Float]()
        let handler = DragHandler(
            onChanged: { v in changedValues.append(v.translationX) },
            onEnded: { _ in }
        )
        let id0 = ctx.registerDragHandler(handler)
        let id1 = ctx.registerDragHandler(handler)
        #expect(id0 == 0)
        #expect(id1 == 1)
        let val = DragValue(startX: 10, startY: 0, currentX: 30, currentY: 0)
        ctx.dragHandlers[id0]?.onChanged(val)
        #expect(changedValues == [20])
    }

    @Test func dragHandlerReset() {
        let ctx = RenderContext()
        let handler = DragHandler(onChanged: { _ in }, onEnded: { _ in })
        _ = ctx.registerDragHandler(handler)
        ctx.resetDragState()
        #expect(ctx.dragHandlers.isEmpty)
    }

    @Test func dragValueTranslation() {
        let val = DragValue(startX: 10, startY: 20, currentX: 30, currentY: 50)
        #expect(abs(val.translationX - 20) < 0.01)
        #expect(abs(val.translationY - 30) < 0.01)
    }

    @Test func contextActivation() {
        let ctx = RenderContext()
        ctx.activate {
            #expect(RenderContext.active === ctx)
        }
    }

    @Test func contextActivationNested() {
        let outer = RenderContext()
        let inner = RenderContext()
        outer.activate {
            #expect(RenderContext.active === outer)
            inner.activate {
                #expect(RenderContext.active === inner)
            }
            // After inner exits, outer should be restored
            #expect(RenderContext.active === outer)
        }
    }
}
