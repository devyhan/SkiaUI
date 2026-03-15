// Binding.swift – SkiaUIState module
// Two-way reference to a mutable value.

public struct Binding<Value>: Sendable where Value: Sendable {
    private let getter: @Sendable () -> Value
    private let setter: @Sendable (Value) -> Void

    public init(get: @escaping @Sendable () -> Value, set: @escaping @Sendable (Value) -> Void) {
        self.getter = get
        self.setter = set
    }

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }
}
