// RootHost.swift – SkiaUIRuntime module
// Central host that orchestrates rendering a view tree into a display list.

import SkiaUIDSL
import SkiaUIState
import SkiaUIElement
import SkiaUILayout
import SkiaUIRenderTree
import SkiaUIDisplayList
import SkiaUIRenderer

public final class RootHost: @unchecked Sendable {
    private var currentElement: Element?
    private var currentLayout: LayoutNode?
    private let layoutEngine = LayoutEngine()
    private var viewportWidth: Float = 800
    private var viewportHeight: Float = 600
    private var onDisplayList: (([UInt8]) -> Void)?

    public init() {}

    public func setViewport(width: Float, height: Float) {
        viewportWidth = width
        viewportHeight = height
    }

    public func setOnDisplayList(_ handler: @escaping ([UInt8]) -> Void) {
        onDisplayList = handler
    }

    public func render<V: View>(_ view: V) {
        let element = ViewToElementConverter.convert(view)
        var layout = layoutEngine.layout(element, proposal: ProposedSize(width: viewportWidth, height: viewportHeight))

        // Center content within viewport (matches SwiftUI root view behavior)
        layout.x = (viewportWidth - layout.width) / 2
        layout.y = (viewportHeight - layout.height) / 2

        let renderTreeBuilder = RenderTreeBuilder()
        let renderNode = renderTreeBuilder.build(element: element, layout: layout)

        let displayListBuilder = DisplayListBuilder()
        let displayList = displayListBuilder.build(from: renderNode)

        currentElement = element
        currentLayout = layout

        let encoder = CommandEncoder()
        let bytes = encoder.encode(displayList)
        onDisplayList?(bytes)
    }

    public func hitTest(x: Float, y: Float) -> Int? {
        guard let element = currentElement, let layout = currentLayout else { return nil }
        return hitTestElement(element, layout: layout, x: x, y: y, offsetX: 0, offsetY: 0)
    }

    private func hitTestElement(_ element: Element, layout: LayoutNode, x: Float, y: Float, offsetX: Float, offsetY: Float) -> Int? {
        let absX = offsetX + layout.x
        let absY = offsetY + layout.y

        // Check if point is within this node's bounds
        guard x >= absX && x <= absX + layout.width && y >= absY && y <= absY + layout.height else {
            return nil
        }

        // Check children in reverse order (top-most first) before checking self
        switch element {
        case .container(_, let children):
            for (i, child) in children.enumerated().reversed() {
                if i < layout.children.count {
                    if let id = hitTestElement(child, layout: layout.children[i], x: x, y: y, offsetX: absX, offsetY: absY) {
                        return id
                    }
                }
            }
        case .modified(let inner, let modifier):
            // Modifiers that add a layout wrapper (.padding, .frame) store
            // the inner element's layout as their first child.
            // Transparent modifiers (background, foregroundColor, onTap, font,
            // accessibility) return the inner layout directly — no wrapper.
            let innerLayout: LayoutNode
            switch modifier {
            case .padding, .frame:
                innerLayout = layout.children.first ?? layout
            default:
                innerLayout = layout
            }
            if let id = hitTestElement(inner, layout: innerLayout, x: x, y: y, offsetX: absX, offsetY: absY) {
                return id
            }
            // Then check if this modifier is an onTap
            if case .onTap(let id) = modifier {
                return id
            }
        default:
            break
        }

        // Check modifiers for onTap at this level
        if case .modified(_, .onTap(let id)) = element {
            return id
        }

        return nil
    }
}
