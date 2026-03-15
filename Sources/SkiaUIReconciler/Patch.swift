// Patch.swift – SkiaUIReconciler module
// Types representing incremental changes between element trees.

import SkiaUIElement

public struct ElementPath: Equatable, Sendable {
    public var indices: [Int]
    public init(_ indices: [Int] = []) { self.indices = indices }
    public func appending(_ index: Int) -> ElementPath {
        ElementPath(indices + [index])
    }
}

public enum Patch: Equatable, Sendable {
    case insert(path: ElementPath, element: Element)
    case delete(path: ElementPath)
    case update(path: ElementPath, from: Element, to: Element)
    case replace(path: ElementPath, from: Element, to: Element)
}
