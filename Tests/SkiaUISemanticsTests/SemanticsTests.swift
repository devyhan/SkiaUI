// SemanticsTests.swift – SkiaUISemantics test suite
// Tests for semantics tree construction and accessibility.

import Testing
import Foundation
@testable import SkiaUISemantics
import SkiaUIElement
import SkiaUILayout

@Suite struct SemanticsTests {
    @Test func semanticsNodeInit() {
        let node = SemanticsNode(id: 1, role: .button, label: "Click me")
        #expect(node.id == 1)
        #expect(node.role == .button)
        #expect(node.label == "Click me")
    }

    @Test func semanticsTreeJSON() {
        let tree = SemanticsTree(
            root: SemanticsNode(
                id: 0,
                role: .container,
                children: [
                    SemanticsNode(id: 1, role: .text, label: "Hello"),
                    SemanticsNode(id: 2, role: .button, label: "Tap", actions: [.tap]),
                ]
            ),
            version: 1
        )
        let json = tree.toJSON()
        #expect(json != nil)

        if let data = json {
            let restored = SemanticsTree.fromJSON(data)
            #expect(restored != nil)
            #expect(restored?.root.children.count == 2)
            #expect(restored?.root.children[0].label == "Hello")
            #expect(restored?.root.children[1].actions == [.tap])
        }
    }

    @Test func semanticsTreeBuilderText() {
        var builder = SemanticsTreeBuilder()
        let element = Element.text("Hello World", .init())
        let layout = LayoutNode(width: 100, height: 20)
        let tree = builder.build(element: element, layout: layout)
        #expect(tree.root.role == .text)
        #expect(tree.root.label == "Hello World")
    }

    @Test func semanticsTreeBuilderOnTap() {
        var builder = SemanticsTreeBuilder()
        let element = Element.modified(
            .text("Click me", .init()),
            .onTap(id: 42)
        )
        let layout = LayoutNode(width: 100, height: 30)
        let tree = builder.build(element: element, layout: layout)
        #expect(tree.root.role == .button)
        #expect(tree.root.actions.contains(.tap))
    }

    @Test func semanticsTreeBuilderAccessibilityLabel() {
        var builder = SemanticsTreeBuilder()
        let element = Element.modified(
            .text("X", .init()),
            .accessibilityLabel("Close button")
        )
        let layout = LayoutNode(width: 30, height: 30)
        let tree = builder.build(element: element, layout: layout)
        #expect(tree.root.label == "Close button")
    }

    @Test func semanticsTreeBuilderContainer() {
        var builder = SemanticsTreeBuilder()
        let element = Element.container(
            .init(layout: .vstack(spacing: 8, alignment: 1)),
            children: [
                .text("A", .init()),
                .text("B", .init()),
            ]
        )
        let layout = LayoutNode(width: 100, height: 50, children: [
            LayoutNode(y: 0, width: 100, height: 20),
            LayoutNode(y: 28, width: 100, height: 20),
        ])
        let tree = builder.build(element: element, layout: layout)
        #expect(tree.root.role == .container)
        #expect(tree.root.children.count == 2)
        #expect(tree.root.children[0].label == "A")
        #expect(tree.root.children[1].label == "B")
    }
}
