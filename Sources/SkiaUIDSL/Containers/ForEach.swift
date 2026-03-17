// ForEach.swift – SkiaUIDSL module
// A view that generates elements from a collection of data.

import SkiaUIElement

/// A structure that computes views on demand from an underlying collection of identified data.
public struct ForEach<Data: RandomAccessCollection, ID: Hashable, Content: View>: PrimitiveView {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let content: (Data.Element) -> Content

    /// Creates an instance that uniquely identifies and creates views from a collection using the given key path.
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = id
        self.content = content
    }

    public func asElement() -> Element {
        // Should not be called directly; flattenedElements() is used by containers
        let elements = flattenedElements()
        if elements.isEmpty { return .empty }
        if elements.count == 1 { return elements[0] }
        return .container(.init(layout: .vstack(spacing: 0, alignment: 1)), children: elements)
    }
}

// MARK: - Identifiable convenience

extension ForEach where Data.Element: Identifiable, ID == Data.Element.ID {
    /// Creates an instance that uniquely identifies and creates views from a collection of `Identifiable` data.
    public init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = \Data.Element.id
        self.content = content
    }
}

// MARK: - Range<Int> convenience

extension ForEach where Data == Range<Int>, ID == Int {
    /// Creates an instance that computes views for each value in a range of integers.
    public init(_ data: Range<Int>, @ViewBuilder content: @escaping (Int) -> Content) {
        self.data = data
        self.id = \.self
        self.content = content
    }
}

// MARK: - TupleViewProtocol

extension ForEach: TupleViewProtocol {
    func flattenedElements() -> [Element] {
        data.map { item in
            ViewToElementConverter.convert(content(item))
        }
    }
}
