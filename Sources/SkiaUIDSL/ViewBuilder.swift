// ViewBuilder.swift – SkiaUIDSL module
// Result builder for composing View hierarchies declaratively.
// Uses buildPartialBlock (SE-0348) for unlimited children support.

import SkiaUIElement

@resultBuilder
public struct ViewBuilder {
    // MARK: - Empty block

    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    // MARK: - Partial block (SE-0348)

    /// Single expression – first element in a block.
    public static func buildPartialBlock<V: View>(first: V) -> V {
        first
    }

    /// Accumulate pairs – called for each subsequent element in the block.
    public static func buildPartialBlock<A: View, V: View>(accumulated: A, next: V) -> TupleView2<A, V> {
        TupleView2(first: accumulated, second: next)
    }

    // MARK: - Conditionals

    /// Optional (if without else)
    public static func buildOptional<V: View>(_ component: V?) -> ConditionalView<V, EmptyView> {
        if let component {
            return ConditionalView(first: component)
        } else {
            return ConditionalView(second: EmptyView())
        }
    }

    /// if-else: true branch
    public static func buildEither<TrueContent: View, FalseContent: View>(first component: TrueContent) -> ConditionalView<TrueContent, FalseContent> {
        ConditionalView(first: component)
    }

    /// if-else: false branch
    public static func buildEither<TrueContent: View, FalseContent: View>(second component: FalseContent) -> ConditionalView<TrueContent, FalseContent> {
        ConditionalView(second: component)
    }

    // MARK: - Expression passthrough

    public static func buildExpression<V: View>(_ expression: V) -> V {
        expression
    }
}

// MARK: - TupleView2

/// A view that groups two child views. Used by ViewBuilder to accumulate children.
public struct TupleView2<First: View, Second: View>: View {
    public typealias Body = Never
    public var body: Never { fatalError() }

    public let first: First
    public let second: Second

    public init(first: First, second: Second) {
        self.first = first
        self.second = second
    }
}

extension TupleView2: PrimitiveView {
    public func asElement() -> Element {
        let elements = collectElements()
        if elements.count == 1 { return elements[0] }
        // When used standalone (not inside a container), wrap in a vstack
        return .container(
            .init(layout: .vstack(spacing: 0, alignment: 1)),
            children: elements
        )
    }

    func collectElements() -> [Element] {
        var result: [Element] = []
        collectFrom(first, into: &result)
        collectFrom(second, into: &result)
        return result
    }

    private func collectFrom<V: View>(_ view: V, into result: inout [Element]) {
        if let tuple = view as? any TupleViewProtocol {
            result.append(contentsOf: tuple.flattenedElements())
        } else {
            result.append(ViewToElementConverter.convert(view))
        }
    }
}

// MARK: - TupleViewProtocol (internal)

/// Internal protocol for flattening nested TupleView2 structures into flat element arrays.
protocol TupleViewProtocol {
    func flattenedElements() -> [Element]
}

extension TupleView2: TupleViewProtocol {
    func flattenedElements() -> [Element] {
        collectElements()
    }
}

// MARK: - ConditionalView

/// A view that represents the result of an if/else conditional in a ViewBuilder.
public struct ConditionalView<TrueContent: View, FalseContent: View>: View {
    public typealias Body = Never
    public var body: Never { fatalError() }

    enum Storage {
        case first(TrueContent)
        case second(FalseContent)
    }

    let storage: Storage

    init(first: TrueContent) { storage = .first(first) }
    init(second: FalseContent) { storage = .second(second) }
}

extension ConditionalView: PrimitiveView {
    public func asElement() -> Element {
        switch storage {
        case .first(let view): return ViewToElementConverter.convert(view)
        case .second(let view): return ViewToElementConverter.convert(view)
        }
    }
}
