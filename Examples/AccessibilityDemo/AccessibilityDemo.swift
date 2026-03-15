// AccessibilityDemo.swift – Examples
// Demonstrates accessibility modifiers and semantics annotations.

import SkiaUIDSL
import SkiaUIState

public struct AccessibilityDemoView: View {
    @State private var count = 0

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Text("Accessible Counter")
                .font(size: 24, weight: .bold)
                .accessibilityRole("header")
            Text("Count: \(count)")
                .font(size: 32)
                .foregroundColor(.blue)
                .accessibilityLabel("Current count is \(count)")
            HStack(spacing: 16) {
                Text("Decrease")
                    .padding(12)
                    .background(.red)
                    .foregroundColor(.white)
                    .onTapGesture { count -= 1 }
                    .accessibilityLabel("Decrease counter by one")
                    .accessibilityHint("Double tap to decrease")
                Text("Increase")
                    .padding(12)
                    .background(.blue)
                    .foregroundColor(.white)
                    .onTapGesture { count += 1 }
                    .accessibilityLabel("Increase counter by one")
                    .accessibilityHint("Double tap to increase")
            }
        }
        .padding(32)
        .accessibilityRole("container")
    }
}
