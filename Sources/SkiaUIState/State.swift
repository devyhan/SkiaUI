// State.swift – SkiaUIState module
// Property wrapper for reactive state management.

import Foundation

@propertyWrapper
public struct State<Value: Sendable>: Sendable where Value: Equatable {
    private let id: Int
    private let initialValue: Value

    public init(wrappedValue: Value) {
        self.id = StateStorage.shared.allocate(initialValue: wrappedValue)
        self.initialValue = wrappedValue
    }

    public var wrappedValue: Value {
        get { StateStorage.shared.get(id: id) ?? initialValue }
        nonmutating set {
            let oldValue: Value? = StateStorage.shared.get(id: id)
            if oldValue != newValue {
                StateStorage.shared.set(id: id, value: newValue)
                StateStorage.shared.markDirty()
            }
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}
