// LayoutDemo.swift – SkiaUIDocsSite module
// Demonstrates layout capabilities with stacks.

import SkiaUI

struct LayoutDemo: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Layout Demo").fontSize(20).bold()
            HStack(spacing: 12) {
                Rectangle()
                    .fill(.red)
                    .cornerRadius(8)
                    .frame(width: 60, height: 60)
                Rectangle()
                    .fill(.green)
                    .cornerRadius(8)
                    .frame(width: 60, height: 60)
                Rectangle()
                    .fill(.blue)
                    .cornerRadius(8)
                    .frame(width: 60, height: 60)
            }
            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    Text("\(i)")
                        .fontSize(12)
                        .padding(8)
                        .background(.init(red: 0.9, green: 0.9, blue: 1.0))
                }
            }
        }
    }
}
