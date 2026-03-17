// Reconciler.swift – SkiaUIReconciler module
// Diffing engine that reconciles old and new element trees.

import SkiaUIElement

public struct Reconciler: Sendable {
    public init() {}

    public func diff(old: Element, new: Element) -> [Patch] {
        var patches: [Patch] = []
        diffElement(old: old, new: new, path: ElementPath(), patches: &patches)
        return patches
    }

    private func diffElement(old: Element, new: Element, path: ElementPath, patches: inout [Patch]) {
        if old == new { return }

        switch (old, new) {
        case (.empty, .empty):
            return

        case (.text(let oldText, let oldProps), .text(let newText, let newProps)):
            if oldText != newText || oldProps != newProps {
                patches.append(.update(path: path, from: old, to: new))
            }

        case (.rectangle(let oldProps), .rectangle(let newProps)):
            if oldProps != newProps {
                patches.append(.update(path: path, from: old, to: new))
            }

        case (.spacer(let oldMin), .spacer(let newMin)):
            if oldMin != newMin {
                patches.append(.update(path: path, from: old, to: new))
            }

        case (.image(let oldProps), .image(let newProps)):
            if oldProps != newProps {
                patches.append(.update(path: path, from: old, to: new))
            }

        case (.container(let oldProps, let oldChildren), .container(let newProps, let newChildren)):
            if oldProps != newProps {
                patches.append(.update(path: path, from: old, to: new))
            }
            diffChildren(old: oldChildren, new: newChildren, path: path, patches: &patches)

        case (.modified(let oldInner, let oldMod), .modified(let newInner, let newMod)):
            if oldMod != newMod {
                patches.append(.update(path: path, from: old, to: new))
            }
            diffElement(old: oldInner, new: newInner, path: path.appending(0), patches: &patches)

        default:
            // Different types - full replace
            patches.append(.replace(path: path, from: old, to: new))
        }
    }

    private func diffChildren(old: [Element], new: [Element], path: ElementPath, patches: inout [Patch]) {
        let minCount = min(old.count, new.count)
        for i in 0..<minCount {
            diffElement(old: old[i], new: new[i], path: path.appending(i), patches: &patches)
        }
        // New children added
        for i in minCount..<new.count {
            patches.append(.insert(path: path.appending(i), element: new[i]))
        }
        // Old children removed
        for i in minCount..<old.count {
            patches.append(.delete(path: path.appending(i)))
        }
    }
}
