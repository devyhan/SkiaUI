// LayoutTests.swift – SkiaUILayout test suite
// Tests for layout engine constraint solving.

import Testing
@testable import SkiaUILayout
import SkiaUIElement

@Suite struct LayoutTests {
    let engine = LayoutEngine()

    @Test func emptyLayout() {
        let node = engine.layout(.empty, constraints: .unconstrained)
        #expect(node.width == 0)
        #expect(node.height == 0)
    }

    @Test func textLayout() {
        let el = Element.text("Hello", .init(fontSize: 20))
        let node = engine.layout(el, constraints: .unconstrained)
        #expect(node.width > 0)
        #expect(node.height > 0)
    }

    @Test func vstackLayout() {
        let el = Element.container(
            .init(layout: .vstack(spacing: 10, alignment: 1)),
            children: [
                .text("A", .init(fontSize: 14)),
                .text("B", .init(fontSize: 14)),
                .text("C", .init(fontSize: 14)),
            ]
        )
        let node = engine.layout(el, constraints: Constraints(maxWidth: 200, maxHeight: 400))
        #expect(node.children.count == 3)
        // Y offsets should be cumulative
        #expect(node.children[0].y == 0)
        #expect(node.children[1].y > node.children[0].y)
        #expect(node.children[2].y > node.children[1].y)
        // Spacing of 10 between items
        let gap1 = node.children[1].y - (node.children[0].y + node.children[0].height)
        let gap2 = node.children[2].y - (node.children[1].y + node.children[1].height)
        #expect(abs(gap1 - 10) < 0.01)
        #expect(abs(gap2 - 10) < 0.01)
    }

    @Test func hstackLayout() {
        let el = Element.container(
            .init(layout: .hstack(spacing: 8, alignment: 1)),
            children: [
                .text("Left", .init(fontSize: 14)),
                .text("Right", .init(fontSize: 14)),
            ]
        )
        let node = engine.layout(el, constraints: Constraints(maxWidth: 400, maxHeight: 200))
        #expect(node.children.count == 2)
        #expect(node.children[0].x == 0)
        #expect(node.children[1].x > node.children[0].x)
    }

    @Test func spacerInVStack() {
        let el = Element.container(
            .init(layout: .vstack(spacing: 0, alignment: 1)),
            children: [
                .text("Top", .init(fontSize: 14)),
                .spacer(minLength: nil),
                .text("Bottom", .init(fontSize: 14)),
            ]
        )
        let node = engine.layout(el, constraints: Constraints(maxWidth: 200, maxHeight: 400))
        #expect(node.children.count == 3)
        // Spacer should take up remaining space
        let spacerHeight = node.children[1].height
        let textHeight = node.children[0].height + node.children[2].height
        #expect(spacerHeight > 0)
        #expect(abs(spacerHeight + textHeight - 400) < 0.01)
    }

    @Test func paddingLayout() {
        let el = Element.modified(
            .text("Hello", .init(fontSize: 14)),
            .padding(top: 10, leading: 20, bottom: 10, trailing: 20)
        )
        let node = engine.layout(el, constraints: Constraints(maxWidth: 200, maxHeight: 200))
        #expect(node.children.count == 1)
        let inner = node.children[0]
        #expect(inner.x == 20) // leading padding
        #expect(inner.y == 10) // top padding
        // Total size includes padding
        #expect(node.width == inner.width + 40)
        #expect(node.height == inner.height + 20)
    }

    @Test func frameLayout() {
        let el = Element.modified(
            .text("Hello", .init(fontSize: 14)),
            .frame(.init(minWidth: 100, idealWidth: 100, maxWidth: 100, minHeight: 50, idealHeight: 50, maxHeight: 50, alignment: 0))
        )
        let node = engine.layout(el, constraints: .unconstrained)
        #expect(node.width == 100)
        #expect(node.height == 50)
    }

    // MARK: - Phase 2: Priority + Flexibility

    @Test func layoutPriorityInHStack() {
        // Child with higher priority gets space first
        let el = Element.container(
            .init(layout: .hstack(spacing: 0, alignment: 1)),
            children: [
                .text("AAAA", .init(fontSize: 14)),  // priority 0
                .modified(.text("BB", .init(fontSize: 14)), .layoutPriority(1)),  // priority 1
            ]
        )
        let node = engine.layout(el, proposal: ProposedSize(width: 100, height: 50))
        #expect(node.children.count == 2)
        // Priority 1 child should get its full size before priority 0
        let child1 = node.children[1]  // BB with priority 1
        let expectedBBWidth = Float(2) * 14 * 0.6  // 16.8
        #expect(abs(child1.width - expectedBBWidth) < 0.01)
    }

    @Test func multipleSpacersEqualDistribution() {
        // Two spacers should split remaining space equally
        let el = Element.container(
            .init(layout: .vstack(spacing: 0, alignment: 1)),
            children: [
                .spacer(minLength: nil),
                .text("Mid", .init(fontSize: 14)),
                .spacer(minLength: nil),
            ]
        )
        let node = engine.layout(el, proposal: ProposedSize(width: 200, height: 300))
        let textH = node.children[1].height
        let spacer1H = node.children[0].height
        let spacer2H = node.children[2].height
        #expect(abs(spacer1H - spacer2H) < 0.01)
        #expect(abs(spacer1H + spacer2H + textH - 300) < 0.01)
    }

    @Test func spacerHasLowestPriority() {
        // Spacer (priority -inf) should get space last, after all regular children
        let el = Element.container(
            .init(layout: .hstack(spacing: 0, alignment: 1)),
            children: [
                .text("Hello", .init(fontSize: 14)),
                .spacer(minLength: nil),
                .text("World", .init(fontSize: 14)),
            ]
        )
        let node = engine.layout(el, proposal: ProposedSize(width: 200, height: 50))
        // Both texts should get their full intrinsic width
        let text1W = Float(5) * 14 * 0.6
        let text2W = Float(5) * 14 * 0.6
        #expect(abs(node.children[0].width - text1W) < 0.01)
        #expect(abs(node.children[2].width - text2W) < 0.01)
        // Spacer takes the rest
        let spacerW = node.children[1].width
        #expect(abs(spacerW + text1W + text2W - 200) < 0.01)
    }

    // MARK: - Phase 3: Flexible Frame

    @Test func flexibleFrameClamping() {
        // .frame(minWidth: 50, maxWidth: 200) should clamp child
        let el = Element.modified(
            .text("Hi", .init(fontSize: 14)),  // intrinsic width ~16.8
            .frame(.init(minWidth: 50, maxWidth: 200))
        )
        let node = engine.layout(el, proposal: ProposedSize(width: 300, height: 50))
        #expect(node.width >= 50)
        #expect(node.width <= 200)
    }

    @Test func flexibleFrameIdealWithNilProposal() {
        // When proposal is nil, ideal size should be used
        let el = Element.modified(
            .rectangle(.init()),
            .frame(.init(idealWidth: 100, idealHeight: 80))
        )
        let node = engine.layout(el, proposal: .unspecified)
        #expect(node.width == 100)
        #expect(node.height == 80)
    }

    @Test func fixedSizeIgnoresProposal() {
        // .fixedSize() should use ideal (intrinsic) size
        let el = Element.modified(
            .text("Hello World", .init(fontSize: 14)),
            .fixedSize(horizontal: true, vertical: true)
        )
        // Propose a very small width
        let constrained = engine.layout(el, proposal: ProposedSize(width: 10, height: 50))
        let intrinsic = engine.layout(el, proposal: .unspecified)
        // fixedSize should give intrinsic width regardless of small proposal
        #expect(constrained.width == intrinsic.width)
    }

    @Test func fontModifierWithFamilyPropagation() {
        // .font modifier with family should propagate to text element for layout
        let el = Element.modified(
            .text("Hello", .init(fontSize: 14)),
            .font(size: 24, weight: 700, family: "Courier")
        )
        let node = engine.layout(el, proposal: ProposedSize(width: 200, height: 100))
        // Layout should use fontSize 24 (from modifier), not 14 (from text)
        let expectedWidth = Float(5) * 24 * 0.6  // 72
        let expectedHeight = 24 * Float(1.2)     // 28.8
        #expect(abs(node.width - expectedWidth) < 0.01)
        #expect(abs(node.height - expectedHeight) < 0.01)
    }

    // MARK: - Phase 3: Layout Cache

    @Test func layoutCacheHit() {
        let eng = LayoutEngine()
        let el = Element.text("Cache", .init(fontSize: 14))
        let proposal = ProposedSize(width: 200, height: 100)
        let first = eng.layout(el, proposal: proposal)
        let second = eng.layout(el, proposal: proposal)
        #expect(first == second)
    }

    @Test func layoutCacheClearWorks() {
        let eng = LayoutEngine()
        let el = Element.text("Cache", .init(fontSize: 14))
        let proposal = ProposedSize(width: 200, height: 100)
        let first = eng.layout(el, proposal: proposal)
        eng.clearCache()
        let second = eng.layout(el, proposal: proposal)
        #expect(first == second)
    }
}
