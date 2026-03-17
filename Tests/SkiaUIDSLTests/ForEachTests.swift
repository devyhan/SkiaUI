// ForEachTests.swift – SkiaUIDSL test suite
// Tests for ForEach view composition and element generation.

import Testing
@testable import SkiaUIDSL
import SkiaUIElement

@Suite struct ForEachTests {
    @Test func rangeBasedForEach() {
        let view = ForEach(0..<3) { i in
            Text("Item \(i)")
        }
        let elements = view.flattenedElements()
        #expect(elements.count == 3)
        if case .text(let s, _) = elements[0] {
            #expect(s == "Item 0")
        } else {
            Issue.record("Expected text element at index 0")
        }
        if case .text(let s, _) = elements[2] {
            #expect(s == "Item 2")
        } else {
            Issue.record("Expected text element at index 2")
        }
    }

    @Test func identifiableForEach() {
        struct Item: Identifiable {
            let id: Int
            let name: String
        }
        let items = [Item(id: 1, name: "A"), Item(id: 2, name: "B")]
        let view = ForEach(items) { item in
            Text(item.name)
        }
        let elements = view.flattenedElements()
        #expect(elements.count == 2)
        if case .text(let s, _) = elements[0] {
            #expect(s == "A")
        } else {
            Issue.record("Expected text element")
        }
        if case .text(let s, _) = elements[1] {
            #expect(s == "B")
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func idKeyPathForEach() {
        struct Item {
            let key: String
            let value: Int
        }
        let items = [Item(key: "x", value: 10), Item(key: "y", value: 20)]
        let view = ForEach(items, id: \.key) { item in
            Text("\(item.value)")
        }
        let elements = view.flattenedElements()
        #expect(elements.count == 2)
        if case .text(let s, _) = elements[0] {
            #expect(s == "10")
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test func emptyDataForEach() {
        let view = ForEach(0..<0) { i in
            Text("Item \(i)")
        }
        let elements = view.flattenedElements()
        #expect(elements.isEmpty)
    }

    @Test func emptyDataAsElement() {
        let view = ForEach(0..<0) { i in
            Text("Item \(i)")
        }
        let element = view.asElement()
        #expect(element == .empty)
    }

    @Test func forEachInVStack() {
        let view = VStack {
            Text("Header")
            ForEach(0..<3) { i in
                Text("Row \(i)")
            }
            Text("Footer")
        }
        let element = view.asElement()
        if case .container(_, let children) = element {
            // Header + 3 ForEach items + Footer = 5
            #expect(children.count == 5)
            if case .text(let s, _) = children[0] {
                #expect(s == "Header")
            } else {
                Issue.record("Expected Header text")
            }
            if case .text(let s, _) = children[1] {
                #expect(s == "Row 0")
            } else {
                Issue.record("Expected Row 0 text")
            }
            if case .text(let s, _) = children[4] {
                #expect(s == "Footer")
            } else {
                Issue.record("Expected Footer text")
            }
        } else {
            Issue.record("Expected container element")
        }
    }

    @Test func forEachInHStack() {
        let view = HStack {
            ForEach(0..<2) { i in
                Text("Col \(i)")
            }
        }
        let element = view.asElement()
        if case .container(let props, let children) = element {
            if case .hstack = props.layout {
                // pass
            } else {
                Issue.record("Expected hstack layout")
            }
            #expect(children.count == 2)
        } else {
            Issue.record("Expected container element")
        }
    }

    @Test func singleItemForEach() {
        let view = ForEach(0..<1) { _ in
            Text("Only")
        }
        let element = view.asElement()
        // Single item should return the element directly
        if case .text(let s, _) = element {
            #expect(s == "Only")
        } else {
            Issue.record("Expected single text element, got: \(element)")
        }
    }
}
