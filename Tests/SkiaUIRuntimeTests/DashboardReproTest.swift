// DashboardReproTest.swift – Reproduce DashboardView counter update issue

import Testing
@testable import SkiaUIRuntime
@testable import SkiaUIDSL
import SkiaUIElement
import SkiaUIState
import SkiaUIDisplayList

private struct CounterView: View {
    @State private var count = 0
    var body: some View {
        VStack(spacing: 16) {
            Text("Counter Demo")
            Text("Count: \(count)")
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
            Text("Reset")
                .padding(12)
                .background(.gray)
                .foregroundColor(.white)
                .onTapGesture { count = 0 }
        }
        .padding(32)
    }
}

private struct View1: View { var body: some View { Text("View1") } }
private struct View2: View { var body: some View { Text("View2") } }
private struct View3: View { var body: some View { Text("View3") } }
private struct View4: View { var body: some View { Text("View4") } }
private struct View5: View { var body: some View { Text("View5") } }
private struct View6: View { var body: some View { Text("View6") } }
private struct View7: View { var body: some View { Text("View7") } }
private struct View8: View { var body: some View { Text("View8") } }
private struct View9: View { var body: some View { Text("View9") } }
private struct View10: View { var body: some View { Text("View10") } }
private struct View11: View { var body: some View { Text("View11") } }
private struct View12: View { var body: some View { Text("View12") } }

// Exact replica of DashboardView with full sidebar + 13 if/else branches
private struct DashboardView: View {
    @State private var selectedExample = 0
    let counterView = CounterView()
    let v1 = View1(); let v2 = View2(); let v3 = View3()
    let v4 = View4(); let v5 = View5(); let v6 = View6()
    let v7 = View7(); let v8 = View8(); let v9 = View9()
    let v10 = View10(); let v11 = View11(); let v12 = View12()

    var body: some View {
        HStack(spacing: 0) {
            // Full sidebar with 13 menu items (matches real DashboardView)
            VStack(alignment: .leading, spacing: 0) {
                Text("SkiaUI").font(size: 20, weight: .bold).padding(16)

                Text("Basics").font(size: 11, weight: .bold).foregroundColor(.gray)
                    .padding(top: 12, leading: 16, bottom: 4, trailing: 16)

                Text("Counter")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 0 ? .blue : .clear)
                    .foregroundColor(selectedExample == 0 ? .white : .black)
                    .onTapGesture { selectedExample = 0 }
                Text("V1")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 1 ? .blue : .clear)
                    .foregroundColor(selectedExample == 1 ? .white : .black)
                    .onTapGesture { selectedExample = 1 }
                Text("V2")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 2 ? .blue : .clear)
                    .foregroundColor(selectedExample == 2 ? .white : .black)
                    .onTapGesture { selectedExample = 2 }
                Text("V3")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 3 ? .blue : .clear)
                    .foregroundColor(selectedExample == 3 ? .white : .black)
                    .onTapGesture { selectedExample = 3 }
                Text("V4")
                    .padding(top: 8, leading: 16, bottom: 8, trailing: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedExample == 4 ? .blue : .clear)
                    .foregroundColor(selectedExample == 4 ? .white : .black)
                    .onTapGesture { selectedExample = 4 }
                Text("V5").onTapGesture { selectedExample = 5 }
                Text("V6").onTapGesture { selectedExample = 6 }
                Text("V7").onTapGesture { selectedExample = 7 }
                Text("V8").onTapGesture { selectedExample = 8 }
                Text("V9").onTapGesture { selectedExample = 9 }
                Text("V10").onTapGesture { selectedExample = 10 }
                Text("V11").onTapGesture { selectedExample = 11 }

                Spacer()
            }
            .frame(width: 200)
            .background(Color(white: 0.94))

            Spacer()

            // 13 if/else branches (matches real DashboardView)
            if selectedExample == 0 {
                counterView
            } else if selectedExample == 1 {
                v1
            } else if selectedExample == 2 {
                v2
            } else if selectedExample == 3 {
                v3
            } else if selectedExample == 4 {
                v4
            } else if selectedExample == 5 {
                v5
            } else if selectedExample == 6 {
                v6
            } else if selectedExample == 7 {
                v7
            } else if selectedExample == 8 {
                v8
            } else if selectedExample == 9 {
                v9
            } else if selectedExample == 11 {
                v11
            } else if selectedExample == 12 {
                v12
            } else {
                v10
            }

            Spacer()
        }
    }
}

extension AllRuntimeTests {
@Suite(.serialized) struct DashboardReproTest {

    private func resetAll() {
        StateStorage.shared.reset()
        DependencyRecorder.shared.clearCallbacks()
        resetTapState()
    }

    private func extractTexts(from bytes: [UInt8]) -> [String] {
        let encoder = CommandEncoder()
        guard let dl = encoder.decode(bytes) else { return [] }
        return dl.commands.compactMap { cmd -> String? in
            if case .drawText(let t, _, _, _, _, _, _, _, _, _) = cmd { return t }
            return nil
        }
    }

    @Test func counterIncrementImmediatelyVisible() {
        resetAll()

        let view = DashboardView()
        let host = RootHost()
        host.setViewport(width: 800, height: 600)

        var captures: [[UInt8]] = []
        host.setOnDisplayList { captures.append($0) }

        // Render 1: initial
        host.render(view)
        let texts1 = extractTexts(from: captures[0])
        let countTexts1 = texts1.filter { $0.contains("Count") }
        print("[R1] Count texts: \(countTexts1)")
        print("[R1] Total tapHandlers: \(tapHandlers.count), keys: \(tapHandlers.keys.sorted())")
        #expect(texts1.contains("Count: 0"))

        // Find the Increase handler (second-to-last: sidebar 13 + counter Decrease, *Increase*, Reset)
        let sortedKeys = tapHandlers.keys.sorted()
        // Sidebar has 13 onTapGesture handlers. Counter has 3: Decrease, Increase, Reset.
        // So keys 0..12 = sidebar, 13 = Decrease, 14 = Increase, 15 = Reset
        let increaseKey = sortedKeys[sortedKeys.count - 2]
        print("[R1] Calling tapHandler[\(increaseKey)] (Increase)")
        tapHandlers[increaseKey]!()

        let countVal: Int? = StateStorage.shared.get(id: 1)
        print("[AFTER TAP] count state (slot 1) = \(String(describing: countVal))")

        // Render 2
        host.render(view)
        #expect(captures.count == 2, "Should have 2 captures")
        let texts2 = extractTexts(from: captures[1])
        let countTexts2 = texts2.filter { $0.contains("Count") }
        print("[R2] Count texts: \(countTexts2)")
        print("[R2] bytes equal: \(captures[0] == captures[1])")

        #expect(texts2.contains("Count: 1"),
                "Should show Count: 1 but got: \(countTexts2)")
    }
}
}
