// State.swift – SkiaUIState module
// Property wrapper for reactive state management.

import Foundation

@propertyWrapper
public struct State<Value: Sendable>: Sendable where Value: Equatable {
    private let id: Int
    private let initialValue: Value

    public init(wrappedValue: Value) {
        self.id = RenderContext.active.stateStorage.allocate(initialValue: wrappedValue)
        self.initialValue = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            let ctx = RenderContext.active
            ctx.dependencyRecorder.notifyRead(stateID: id)
            return ctx.stateStorage.get(id: id) ?? initialValue
        }
        nonmutating set {
            let ctx = RenderContext.active
            let oldValue: Value? = ctx.stateStorage.get(id: id)
            if oldValue != newValue {
                ctx.stateStorage.set(id: id, value: newValue)
                ctx.dependencyRecorder.notifyWrite(stateID: id)
                ctx.stateStorage.markDirty()
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
