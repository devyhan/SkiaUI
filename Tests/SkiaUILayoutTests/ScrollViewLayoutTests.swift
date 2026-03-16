// ScrollViewLayoutTests.swift – SkiaUILayout test suite
// Tests for ScrollView layout behavior.

import Testing
@testable import SkiaUILayout
import SkiaUIElement

@Suite struct ScrollViewLayoutTests {
    let engine = LayoutEngine()

    @Test func scrollViewVerticalLayout() {
        // Content taller than viewport → viewport-sized node with taller child
        let tallContent = Element.container(
            .init(layout: .vstack(spacing: 8, alignment: 1)),
            children: [
                .text("A", .init(fontSize: 14)),
                .text("B", .init(fontSize: 14)),
                .text("C", .init(fontSize: 14)),
                .text("D", .init(fontSize: 14)),
                .text("E", .init(fontSize: 14)),
            ]
        )
        let scroll = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 0)),
            children: [tallContent]
        )
        let node = engine.layout(scroll, proposal: ProposedSize(width: 200, height: 50))
        // Viewport should be proposal size
        #expect(node.width == 200)
        #expect(node.height == 50)
        // Child (inner vstack) should be taller than viewport
        #expect(node.children.count == 1)
        #expect(node.children[0].height > 50)
    }

    @Test func scrollViewHorizontalLayout() {
        // Content wider than viewport → viewport-sized node with wider child
        let wideContent = Element.container(
            .init(layout: .hstack(spacing: 8, alignment: 1)),
            children: [
                .text("AAAA", .init(fontSize: 14)),
                .text("BBBB", .init(fontSize: 14)),
                .text("CCCC", .init(fontSize: 14)),
                .text("DDDD", .init(fontSize: 14)),
            ]
        )
        let scroll = Element.container(
            .init(layout: .scroll(axis: .horizontal, scrollID: 0)),
            children: [wideContent]
        )
        let node = engine.layout(scroll, proposal: ProposedSize(width: 50, height: 200))
        // Viewport should be proposal size
        #expect(node.width == 50)
        #expect(node.height == 200)
        // Child (inner hstack) should be wider than viewport
        #expect(node.children.count == 1)
        #expect(node.children[0].width > 50)
    }

    @Test func scrollViewCrossAxisConstrained() {
        // Cross-axis should match proposal
        let content = Element.container(
            .init(layout: .vstack(spacing: 0, alignment: 1)),
            children: [.text("Hello", .init(fontSize: 14))]
        )
        let scroll = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 0)),
            children: [content]
        )
        let node = engine.layout(scroll, proposal: ProposedSize(width: 300, height: 100))
        #expect(node.width == 300)
        // Child's width should be constrained to 300
        #expect(node.children[0].width <= 300)
    }

    @Test func scrollViewContentSmallerThanViewport() {
        // Content smaller than viewport → viewport still = proposal
        let content = Element.container(
            .init(layout: .vstack(spacing: 0, alignment: 1)),
            children: [.text("Hi", .init(fontSize: 14))]
        )
        let scroll = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 0)),
            children: [content]
        )
        let node = engine.layout(scroll, proposal: ProposedSize(width: 200, height: 400))
        #expect(node.width == 200)
        #expect(node.height == 400)
        #expect(node.children[0].height < 400)
    }

    @Test func scrollViewEmptyContent() {
        let scroll = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 0)),
            children: []
        )
        let node = engine.layout(scroll, proposal: ProposedSize(width: 200, height: 300))
        #expect(node.width == 0)
        #expect(node.height == 0)
    }
}
