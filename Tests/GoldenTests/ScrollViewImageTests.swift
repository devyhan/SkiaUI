// ScrollViewImageTests.swift – GoldenTests
// Display list golden tests for ScrollView clipping behavior.
// Run: swift test --filter GoldenTests/ScrollViewImageTests

import Testing
import SkiaUIDSL

extension AllGoldenTests {
@Suite(.serialized) struct ScrollViewImageTests {

    @Test func scrollViewClipsContent() {
        // Vertical scroll with content exceeding viewport height
        assertImageSnapshot(
            ScrollView {
                Text("Line 1")
                Text("Line 2")
                Text("Line 3")
                Text("Line 4")
                Text("Line 5")
            },
            named: "scrollViewClipsContent",
            width: 60,
            height: 200
        )
    }

    @Test func scrollViewHorizontal() {
        // Horizontal scroll with content exceeding viewport width
        assertImageSnapshot(
            ScrollView(.horizontal) {
                Text("AAAA")
                Text("BBBB")
                Text("CCCC")
                Text("DDDD")
            },
            named: "scrollViewHorizontal",
            width: 200,
            height: 60
        )
    }
}
}
