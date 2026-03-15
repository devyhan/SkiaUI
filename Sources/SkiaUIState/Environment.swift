// Environment.swift – SkiaUIState module
// Key-value store for passing values through the view hierarchy.

public struct EnvironmentValues: Sendable {
    private var storage: [String: AnySendable] = [:]

    public init() {}

    public subscript<T: Sendable>(key: String) -> T? {
        get { (storage[key] as? TypedSendable<T>)?.value }
        set {
            if let v = newValue {
                storage[key] = TypedSendable(v)
            } else {
                storage.removeValue(forKey: key)
            }
        }
    }
}

protocol AnySendable: Sendable {}

struct TypedSendable<T: Sendable>: AnySendable {
    let value: T
    init(_ value: T) { self.value = value }
}
