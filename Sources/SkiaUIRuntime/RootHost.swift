// RootHost.swift – SkiaUIRuntime module
// Central host that orchestrates rendering a view tree into a display list.

import SkiaUIDSL
import SkiaUIState
import SkiaUIElement
import SkiaUIReconciler
import SkiaUILayout
import SkiaUIRenderTree
import SkiaUIDisplayList
import SkiaUIRenderer

public final class RootHost: @unchecked Sendable {
    private var currentElement: Element?
    private var currentLayout: LayoutNode?
    private let layoutEngine = LayoutEngine()
    private let reconciler = Reconciler()
    private var previousElement: Element?
    private var previousDisplayListBytes: [UInt8]?
    private var previousScrollOffsets: [Int: Float] = [:]
    private var previousViewportWidth: Float = 0
    private var previousViewportHeight: Float = 0
    private var dirtyTracker = DirtyTracker()
    private var retainedCache = RetainedSubtreeCache()
    private let renderCache = RenderCache()
    private var viewportWidth: Float = 800
    private var viewportHeight: Float = 600
    private var onDisplayList: (([UInt8]) -> Void)?
    private let attributeGraph = AttributeGraph()

    public init() {}

    public func setViewport(width: Float, height: Float) {
        viewportWidth = width
        viewportHeight = height
    }

    public func setOnDisplayList(_ handler: @escaping ([UInt8]) -> Void) {
        onDisplayList = handler
    }

    public func render<V: View>(_ view: V) {
        // Reset scroll ID counter so the same tree structure yields the same IDs,
        // allowing scroll offsets to persist across re-renders.
        resetScrollIDCounter()
        StateStorage.shared.resetSlotCounter()

        // Register dependency recording callbacks
        let graph = self.attributeGraph
        var liveNodeIDs = Set<AttributeNodeID>()

        DependencyRecorder.shared.setCallbacks(
            onRead: { stateID in
                graph.recordSourceRead(AttributeNodeID(sourcePath: [stateID]))
            },
            onWrite: { stateID in
                graph.markSourceChanged(AttributeNodeID(sourcePath: [stateID]))
            }
        )

        // Use interceptor for per-subtree caching
        let element = ViewToElementConverter.withInterceptor({ path, evaluator in
            let nodeID = AttributeNodeID(viewPath: path)
            liveNodeIDs.insert(nodeID)
            graph.recordComputedRead(nodeID)

            let result = graph.evaluate(nodeID) {
                AnyHashableSendable(evaluator())
            }
            return result.unwrap()!
        }, convert: view)

        // NOTE: Do NOT clear DependencyRecorder callbacks here.
        // The onWrite callback must remain active between frames so that
        // @State mutations (user interactions) call markSourceChanged()
        // on the AttributeGraph, marking dependent nodes as out-of-date
        // before the next render cycle.
        graph.pruneDeadNodes(liveIDs: liveNodeIDs)

        // Phase 1: Reconciler early-return — skip entire pipeline if element tree unchanged
        let scrollOffsets = ScrollOffsetStorage.shared.allOffsets()
        let viewportChanged = viewportWidth != previousViewportWidth || viewportHeight != previousViewportHeight
        if let prev = previousElement {
            let patches = reconciler.diff(old: prev, new: element)
            if patches.isEmpty && scrollOffsets == previousScrollOffsets && !viewportChanged,
               let cachedBytes = previousDisplayListBytes {
                onDisplayList?(cachedBytes)
                return
            }

            // Phase 2: Populate DirtyTracker from patches
            dirtyTracker.clear()
            for patch in patches {
                let path: ElementPath = switch patch {
                case .insert(let p, _): p
                case .delete(let p): p
                case .update(let p, _, _): p
                case .replace(let p, _, _): p
                }
                dirtyTracker.markDirty(path)
            }
        }

        // Phase 3: Clear per-frame caches before computing layout.
        // The retained subtree cache must be cleared when the element tree changed,
        // because subtreeVersion is always 0 and would falsely cache-hit otherwise.
        layoutEngine.clearCache()
        retainedCache.clear()
        var layout = layoutEngine.layout(element, proposal: ProposedSize(width: viewportWidth, height: viewportHeight))

        // Center content within viewport (matches SwiftUI root view behavior)
        layout.x = (viewportWidth - layout.width) / 2
        layout.y = (viewportHeight - layout.height) / 2

        // Sync scroll metrics (content/viewport sizes) for all scroll containers
        syncScrollMetrics(element: element, layout: layout)

        let renderTreeBuilder = RenderTreeBuilder(renderCache: renderCache)
        let renderNode = renderTreeBuilder.build(element: element, layout: layout, scrollOffsets: scrollOffsets)

        var displayListBuilder = DisplayListBuilder(retainedCache: retainedCache)
        let displayList = displayListBuilder.build(from: renderNode)
        retainedCache = displayListBuilder.retainedCache

        currentElement = element
        currentLayout = layout
        previousElement = element
        previousScrollOffsets = scrollOffsets
        previousViewportWidth = viewportWidth
        previousViewportHeight = viewportHeight

        let encoder = CommandEncoder()
        let bytes = encoder.encode(displayList)
        previousDisplayListBytes = bytes
        onDisplayList?(bytes)
    }

    public func handleScroll(x: Float, y: Float, deltaX: Float, deltaY: Float) {
        guard let element = currentElement, let layout = currentLayout else { return }
        if let hit = scrollHitTest(element: element, layout: layout, x: x, y: y, offsetX: 0, offsetY: 0) {
            let delta: Float = switch hit.axis {
            case .vertical:   deltaY
            case .horizontal: deltaX
            }
            ScrollOffsetStorage.shared.applyDelta(id: hit.scrollID, delta: delta)
            StateStorage.shared.markDirty()
        }
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
        case .container(let props, let children):
            // Adjust coordinates for scroll offset
            var childOffsetX = absX
            var childOffsetY = absY
            if case .scroll(let axis, let scrollID) = props.layout {
                let offset = ScrollOffsetStorage.shared.getOffset(id: scrollID)
                switch axis {
                case .vertical:   childOffsetY -= offset
                case .horizontal: childOffsetX -= offset
                }
            }
            for (i, child) in children.enumerated().reversed() {
                if i < layout.children.count {
                    if let id = hitTestElement(child, layout: layout.children[i], x: x, y: y, offsetX: childOffsetX, offsetY: childOffsetY) {
                        return id
                    }
                }
            }
        case .modified(let inner, let modifier):
            // Modifiers that add a layout wrapper (.padding, .frame) store
            // the inner element's layout as their first child.
            // Transparent modifiers (background, foregroundColor, onTap, font,
            // accessibility) share the same layout node — pass original offset
            // to avoid double-counting layout.x/y.
            let innerLayout: LayoutNode
            let nextOffsetX: Float
            let nextOffsetY: Float
            switch modifier {
            case .padding, .frame:
                innerLayout = layout.children.first ?? layout
                nextOffsetX = absX
                nextOffsetY = absY
            default:
                innerLayout = layout
                nextOffsetX = offsetX
                nextOffsetY = offsetY
            }
            if let id = hitTestElement(inner, layout: innerLayout, x: x, y: y, offsetX: nextOffsetX, offsetY: nextOffsetY) {
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

    private func syncScrollMetrics(element: Element, layout: LayoutNode) {
        if case .container(let props, _) = element,
           case .scroll(let axis, let scrollID) = props.layout,
           let childLayout = layout.children.first {
            let storage = ScrollOffsetStorage.shared
            switch axis {
            case .vertical:
                storage.setContentSize(id: scrollID, size: childLayout.height)
                storage.setViewportSize(id: scrollID, size: layout.height)
            case .horizontal:
                storage.setContentSize(id: scrollID, size: childLayout.width)
                storage.setViewportSize(id: scrollID, size: layout.width)
            }
        }
        // Recurse into children
        if case .container(_, let children) = element {
            for (i, child) in children.enumerated() where i < layout.children.count {
                syncScrollMetrics(element: child, layout: layout.children[i])
            }
        } else if case .modified(let inner, let modifier) = element {
            // Only .padding and .frame wrap the inner layout as a child node.
            // Transparent modifiers share the same layout directly.
            let innerLayout: LayoutNode
            switch modifier {
            case .padding, .frame:
                innerLayout = layout.children.first ?? layout
            default:
                innerLayout = layout
            }
            syncScrollMetrics(element: inner, layout: innerLayout)
        }
    }

    private func scrollHitTest(element: Element, layout: LayoutNode, x: Float, y: Float, offsetX: Float, offsetY: Float) -> (scrollID: Int, axis: Element.ScrollAxis)? {
        let absX = offsetX + layout.x
        let absY = offsetY + layout.y

        guard x >= absX && x <= absX + layout.width && y >= absY && y <= absY + layout.height else {
            return nil
        }

        switch element {
        case .container(let props, let children):
            var childOffsetX = absX
            var childOffsetY = absY
            if case .scroll(let axis, let scrollID) = props.layout {
                let offset = ScrollOffsetStorage.shared.getOffset(id: scrollID)
                switch axis {
                case .vertical:   childOffsetY -= offset
                case .horizontal: childOffsetX -= offset
                }
            }
            // Check children first (innermost scroll container wins)
            for (i, child) in children.enumerated().reversed() {
                if i < layout.children.count {
                    if let hit = scrollHitTest(element: child, layout: layout.children[i], x: x, y: y, offsetX: childOffsetX, offsetY: childOffsetY) {
                        return hit
                    }
                }
            }
            // If no nested scroll container, return this one if it is a scroll
            if case .scroll(let axis, let scrollID) = props.layout {
                return (scrollID: scrollID, axis: axis)
            }
        case .modified(let inner, let modifier):
            let innerLayout: LayoutNode
            let nextOffsetX: Float
            let nextOffsetY: Float
            switch modifier {
            case .padding, .frame:
                // Wrapping modifiers store inner layout as a child
                innerLayout = layout.children.first ?? layout
                nextOffsetX = absX
                nextOffsetY = absY
            default:
                // Transparent modifiers share the same layout node.
                // Pass original offsets to avoid double-counting layout.x/y.
                innerLayout = layout
                nextOffsetX = offsetX
                nextOffsetY = offsetY
            }
            return scrollHitTest(element: inner, layout: innerLayout, x: x, y: y, offsetX: nextOffsetX, offsetY: nextOffsetY)
        default:
            break
        }
        return nil
    }
}
