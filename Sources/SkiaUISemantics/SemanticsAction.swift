// SemanticsAction.swift – SkiaUISemantics module
// Accessibility actions that can be performed on semantics nodes.

public enum SemanticsAction: String, Sendable, Codable {
    case tap
    case longPress
    case scrollUp
    case scrollDown
    case increment
    case decrement
}
