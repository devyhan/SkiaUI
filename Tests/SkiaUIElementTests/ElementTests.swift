// ElementTests.swift – SkiaUIElement test suite
// Tests for core element types and identity.

import Testing
@testable import SkiaUIElement

@Suite struct ElementTests {
    @Test func emptyElement() {
        let element = Element.empty
        #expect(element == .empty)
    }

    @Test func textElement() {
        let el = Element.text("Hello", .init())
        if case .text(let s, _) = el {
            #expect(s == "Hello")
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func containerElement() {
        let el = Element.container(
            .init(layout: .vstack(spacing: 8, alignment: 1)),
            children: [.text("A", .init()), .text("B", .init())]
        )
        #expect(ElementTree.childCount(el) == 2)
    }

    @Test func elementIDGeneration() {
        let id1 = ElementID.generate()
        let id2 = ElementID.generate()
        #expect(id1 != id2)
    }

    @Test func scrollContainerElement() {
        let el = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 7)),
            children: [.text("Scroll content", .init())]
        )
        if case .container(let props, let children) = el {
            if case .scroll(let axis, let scrollID) = props.layout {
                #expect(axis == .vertical)
                #expect(scrollID == 7)
            } else {
                Issue.record("Expected scroll layout")
            }
            #expect(children.count == 1)
        } else {
            Issue.record("Expected container element")
        }
    }

    @Test func scrollContainerEquatable() {
        let a = Element.container(
            .init(layout: .scroll(axis: .horizontal, scrollID: 3)),
            children: [.text("A", .init())]
        )
        let b = Element.container(
            .init(layout: .scroll(axis: .horizontal, scrollID: 3)),
            children: [.text("A", .init())]
        )
        let c = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 3)),
            children: [.text("A", .init())]
        )
        #expect(a == b)
        #expect(a != c)
    }

    @Test func modifiedElement() {
        let base = Element.text("Hello", .init())
        let modified = Element.modified(base, .padding(top: 10, leading: 10, bottom: 10, trailing: 10))
        if case .modified(let inner, .padding) = modified {
            #expect(inner == base)
        } else {
            Issue.record("Expected modified element")
        }
    }
}
