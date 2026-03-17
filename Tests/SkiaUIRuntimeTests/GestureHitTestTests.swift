// GestureHitTestTests.swift – SkiaUIRuntime test suite
// Tests for gesture handler invocation and hit testing via RootHost.

import Testing
@testable import SkiaUIRuntime
@testable import SkiaUIState
@testable import SkiaUIDSL
import SkiaUIElement

extension AllRuntimeTests {
    @Suite(.serialized) struct GestureHitTestTests {
        @Test func handleLongPressInvokesHandler() {
            let ctx = RenderContext()
            var invoked = false
            let id = ctx.registerLongPressHandler { invoked = true }
            let host = RootHost(context: ctx)
            host.handleLongPress(id: id)
            #expect(invoked)
        }

        @Test func handleDragInvokesOnChanged() {
            let ctx = RenderContext()
            nonisolated(unsafe) var changedValue: DragValue?
            let handler = DragHandler(
                onChanged: { v in changedValue = v },
                onEnded: { _ in }
            )
            let id = ctx.registerDragHandler(handler)
            let host = RootHost(context: ctx)
            let val = DragValue(startX: 0, startY: 0, currentX: 50, currentY: 30)
            host.handleDrag(id: id, value: val)
            #expect(changedValue != nil)
            #expect(abs(changedValue!.translationX - 50) < 0.01)
        }

        @Test func handleDragEndInvokesOnEnded() {
            let ctx = RenderContext()
            nonisolated(unsafe) var endedValue: DragValue?
            let handler = DragHandler(
                onChanged: { _ in },
                onEnded: { v in endedValue = v }
            )
            let id = ctx.registerDragHandler(handler)
            let host = RootHost(context: ctx)
            let val = DragValue(startX: 10, startY: 10, currentX: 60, currentY: 40)
            host.handleDragEnd(id: id, value: val)
            #expect(endedValue != nil)
            #expect(abs(endedValue!.translationX - 50) < 0.01)
        }

        @Test func hitTestLongPressReturnsId() {
            let ctx = RenderContext()
            ctx.resetLongPressState()
            let host = RootHost(context: ctx)
            host.setViewport(width: 400, height: 300)

            // Render a view with onLongPressGesture
            struct LongPressView: View {
                var body: some View {
                    Text("Hold").onLongPressGesture { }
                }
            }
            host.render(LongPressView())

            // Hit test inside the text bounds — should find the long press ID
            let result = host.hitTestLongPress(x: 200, y: 150)
            #expect(result != nil)
        }

        @Test func hitTestLongPressOutsideReturnsNil() {
            let ctx = RenderContext()
            ctx.resetLongPressState()
            let host = RootHost(context: ctx)
            host.setViewport(width: 400, height: 300)

            struct LongPressView: View {
                var body: some View {
                    Text("Hold").onLongPressGesture { }
                }
            }
            host.render(LongPressView())

            // Hit test far outside the text bounds
            let result = host.hitTestLongPress(x: 0, y: 0)
            #expect(result == nil)
        }

        @Test func hitTestDragReturnsId() {
            let ctx = RenderContext()
            ctx.resetDragState()
            let host = RootHost(context: ctx)
            host.setViewport(width: 400, height: 300)

            struct DragView: View {
                var body: some View {
                    Rectangle()
                        .onDrag(onChanged: { _ in }, onEnded: { _ in })
                }
            }
            host.render(DragView())

            // Hit test inside the rectangle bounds (centered in viewport)
            let result = host.hitTestDrag(x: 200, y: 150)
            #expect(result != nil)
        }
    }
}
