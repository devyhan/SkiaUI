// CounterApp.swift – Example
// Interactive counter demonstrating State management and tap gestures.
// NOTE: This is a reference example – not compiled as a module target.

import SkiaUIDSL
import SkiaUIState

public struct CounterView: View {
    @State private var count = 0

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Text("Counter Demo")
                .font(size: 24, weight: .bold)
            Text("Count: \(count)")
                .font(size: 32)
                .foregroundColor(.blue)
            HStack(spacing: 16) {
                Text("- Decrease")
                    .padding(12)
                    .background(.red)
                    .foregroundColor(.white)
                    .onTapGesture { count -= 1 }
                Text("+ Increase")
                    .padding(12)
                    .background(.blue)
                    .foregroundColor(.white)
                    .onTapGesture { count += 1 }
            }
        }
        .padding(32)
    }
}
