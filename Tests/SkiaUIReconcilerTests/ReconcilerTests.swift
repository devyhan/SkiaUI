// ReconcilerTests.swift – SkiaUIReconciler test suite
// Tests for element tree diffing and reconciliation.

import Testing
@testable import SkiaUIReconciler
import SkiaUIElement

@Suite struct ReconcilerTests {
    let reconciler = Reconciler()

    @Test func identicalTreesNoPatch() {
        let tree = Element.text("Hello", .init())
        let patches = reconciler.diff(old: tree, new: tree)
        #expect(patches.isEmpty)
    }

    @Test func textChangeProducesUpdate() {
        let old = Element.text("Hello", .init())
        let new = Element.text("World", .init())
        let patches = reconciler.diff(old: old, new: new)
        #expect(patches.count == 1)
        if case .update(_, let from, let to) = patches.first {
            #expect(from == old)
            #expect(to == new)
        } else {
            Issue.record("Expected update patch")
        }
    }

    @Test func childInsert() {
        let old = Element.container(.init(layout: .vstack(spacing: 0, alignment: 1)), children: [
            .text("A", .init()),
        ])
        let new = Element.container(.init(layout: .vstack(spacing: 0, alignment: 1)), children: [
            .text("A", .init()),
            .text("B", .init()),
        ])
        let patches = reconciler.diff(old: old, new: new)
        #expect(patches.count == 1)
        if case .insert(let path, _) = patches.first {
            #expect(path.indices == [1])
        }
    }

    @Test func childDelete() {
        let old = Element.container(.init(layout: .vstack(spacing: 0, alignment: 1)), children: [
            .text("A", .init()),
            .text("B", .init()),
        ])
        let new = Element.container(.init(layout: .vstack(spacing: 0, alignment: 1)), children: [
            .text("A", .init()),
        ])
        let patches = reconciler.diff(old: old, new: new)
        #expect(patches.count == 1)
        if case .delete(let path) = patches.first {
            #expect(path.indices == [1])
        }
    }

    @Test func typeChangeProducesReplace() {
        let old = Element.text("Hello", .init())
        let new = Element.rectangle(.init())
        let patches = reconciler.diff(old: old, new: new)
        #expect(patches.count == 1)
        if case .replace = patches.first {
            // pass
        } else {
            Issue.record("Expected replace patch")
        }
    }

    @Test func deepNestedChange() {
        let old = Element.container(.init(layout: .vstack(spacing: 0, alignment: 1)), children: [
            .container(.init(layout: .hstack(spacing: 0, alignment: 1)), children: [
                .text("A", .init()),
                .text("B", .init()),
            ]),
        ])
        let new = Element.container(.init(layout: .vstack(spacing: 0, alignment: 1)), children: [
            .container(.init(layout: .hstack(spacing: 0, alignment: 1)), children: [
                .text("A", .init()),
                .text("C", .init()),
            ]),
        ])
        let patches = reconciler.diff(old: old, new: new)
        #expect(patches.count == 1)
        if case .update(let path, _, _) = patches.first {
            #expect(path.indices == [0, 1])
        }
    }

    @Test func identicalScrollContainersNoPatch() {
        let tree = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 0)),
            children: [.text("A", .init())]
        )
        let patches = reconciler.diff(old: tree, new: tree)
        #expect(patches.isEmpty)
    }

    @Test func scrollContainerChildChange() {
        let old = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 0)),
            children: [.text("A", .init())]
        )
        let new = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 0)),
            children: [.text("B", .init())]
        )
        let patches = reconciler.diff(old: old, new: new)
        #expect(patches.count == 1)
        if case .update(let path, _, _) = patches.first {
            #expect(path.indices == [0])
        } else {
            Issue.record("Expected update patch for scroll container child")
        }
    }

    @Test func scrollAxisChangePatch() {
        let old = Element.container(
            .init(layout: .scroll(axis: .vertical, scrollID: 0)),
            children: [.text("A", .init())]
        )
        let new = Element.container(
            .init(layout: .scroll(axis: .horizontal, scrollID: 0)),
            children: [.text("A", .init())]
        )
        let patches = reconciler.diff(old: old, new: new)
        // ContainerProperties changed → should produce a patch
        #expect(!patches.isEmpty)
    }

    @Test func dirtyTracker() {
        var tracker = DirtyTracker()
        let path = ElementPath([1, 2])
        tracker.markDirty(path)
        #expect(tracker.isDirty(ElementPath([1, 2])))
        #expect(tracker.isDirty(ElementPath([1])))
        #expect(tracker.isDirty(ElementPath([])))
        #expect(!tracker.isDirty(ElementPath([0])))
        tracker.clear()
        #expect(tracker.isEmpty)
    }
}
