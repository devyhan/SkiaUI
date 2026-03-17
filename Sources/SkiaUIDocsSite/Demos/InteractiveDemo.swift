// InteractiveDemo.swift – SkiaUIDocsSite module
// Demonstrates interactive elements with tap gestures.

import SkiaUI

struct InteractiveDemo: View {
    @State var count = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("Interactive Demo").fontSize(20).bold()
            Text("Count: \(count)").fontSize(18)
            HStack(spacing: 12) {
                Text("Tap +1")
                    .padding(12)
                    .background(.init(red: 0.2, green: 0.6, blue: 1.0))
                    .foregroundColor(.white)
                    .onTapGesture { count += 1 }
                Text("Reset")
                    .padding(12)
                    .background(.init(red: 0.8, green: 0.2, blue: 0.2))
                    .foregroundColor(.white)
                    .onTapGesture { count = 0 }
            }
        }
    }
}
