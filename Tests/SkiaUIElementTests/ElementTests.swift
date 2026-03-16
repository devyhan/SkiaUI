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

    @Test func textPropertiesWithFontFamily() {
        let props = Element.TextProperties(fontSize: 18, fontWeight: 700, fontFamily: "Courier")
        #expect(props.fontFamily == "Courier")
        #expect(props.fontSize == 18)
        #expect(props.fontWeight == 700)
    }

    @Test func textPropertiesFontFamilyNilByDefault() {
        let props = Element.TextProperties()
        #expect(props.fontFamily == nil)
    }

    @Test func fontModifierWithFamily() {
        let mod = Element.Modifier.font(size: 20, weight: 400, family: "Helvetica")
        if case .font(let size, let weight, let family) = mod {
            #expect(size == 20)
            #expect(weight == 400)
            #expect(family == "Helvetica")
        } else {
            Issue.record("Expected font modifier")
        }
    }

    @Test func fontModifierFamilyDefaultNil() {
        let mod = Element.Modifier.font(size: 14, weight: 400)
        if case .font(_, _, let family) = mod {
            #expect(family == nil)
        } else {
            Issue.record("Expected font modifier")
        }
    }

    @Test func textElementWithFontFamilyEquatable() {
        let a = Element.text("Hi", .init(fontFamily: "Courier"))
        let b = Element.text("Hi", .init(fontFamily: "Courier"))
        let c = Element.text("Hi", .init(fontFamily: "Arial"))
        #expect(a == b)
        #expect(a != c)
    }

    @Test func elementHashable() {
        let a = Element.text("Hello", .init(fontSize: 14))
        let b = Element.text("Hello", .init(fontSize: 14))
        let c = Element.text("World", .init(fontSize: 14))
        #expect(a.hashValue == b.hashValue)
        #expect(a.hashValue != c.hashValue)
        // Set membership works
        let set: Set<Element> = [a, b, c]
        #expect(set.count == 2)
    }
}
