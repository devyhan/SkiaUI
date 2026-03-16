// AnyHashableSendable.swift – SkiaUIState module
// Type-erased container for Hashable & Sendable values.

public struct AnyHashableSendable: @unchecked Sendable, Equatable {
    private let _value: AnyHashable

    public init<T: Hashable & Sendable>(_ value: T) {
        self._value = AnyHashable(value)
    }

    public func unwrap<T>() -> T? {
        _value.base as? T
    }

    public static func == (lhs: AnyHashableSendable, rhs: AnyHashableSendable) -> Bool {
        lhs._value == rhs._value
    }
}
