// ScrollOffsetStorageTests.swift – SkiaUIState test suite
// Tests for scroll offset storage and clamping behavior.

import Testing
@testable import SkiaUIState

@Suite struct ScrollOffsetStorageTests {
    @Test func initialOffsetIsZero() {
        let storage = ScrollOffsetStorage.shared
        storage.reset()
        #expect(storage.getOffset(id: 999) == 0)
    }

    @Test func applyDeltaAccumulates() {
        let storage = ScrollOffsetStorage.shared
        storage.reset()
        storage.setContentSize(id: 0, size: 500)
        storage.setViewportSize(id: 0, size: 200)
        storage.applyDelta(id: 0, delta: 50)
        #expect(storage.getOffset(id: 0) == 50)
        storage.applyDelta(id: 0, delta: 30)
        #expect(storage.getOffset(id: 0) == 80)
    }

    @Test func offsetClampedToZero() {
        let storage = ScrollOffsetStorage.shared
        storage.reset()
        storage.setContentSize(id: 0, size: 500)
        storage.setViewportSize(id: 0, size: 200)
        // Try to scroll past top
        storage.applyDelta(id: 0, delta: -100)
        #expect(storage.getOffset(id: 0) == 0)
    }

    @Test func offsetClampedToMaxScroll() {
        let storage = ScrollOffsetStorage.shared
        storage.reset()
        storage.setContentSize(id: 0, size: 500)
        storage.setViewportSize(id: 0, size: 200)
        // maxScroll = 500 - 200 = 300
        storage.applyDelta(id: 0, delta: 999)
        #expect(storage.getOffset(id: 0) == 300)
    }

    @Test func maxScrollCalculation() {
        let storage = ScrollOffsetStorage.shared
        storage.reset()
        storage.setContentSize(id: 0, size: 1000)
        storage.setViewportSize(id: 0, size: 400)
        #expect(storage.maxScroll(id: 0) == 600)
    }

    @Test func maxScrollNeverNegative() {
        let storage = ScrollOffsetStorage.shared
        storage.reset()
        storage.setContentSize(id: 0, size: 100)
        storage.setViewportSize(id: 0, size: 400)
        // Content smaller than viewport → maxScroll = 0
        #expect(storage.maxScroll(id: 0) == 0)
    }

    @Test func allOffsetsReturnsDictionary() {
        let storage = ScrollOffsetStorage.shared
        storage.reset()
        storage.setContentSize(id: 1, size: 500)
        storage.setViewportSize(id: 1, size: 200)
        storage.applyDelta(id: 1, delta: 42)
        let offsets = storage.allOffsets()
        #expect(offsets[1] == 42)
    }

    @Test func resetClearsEverything() {
        let storage = ScrollOffsetStorage.shared
        let testID = 99999  // Unique ID to avoid parallel test interference
        storage.setContentSize(id: testID, size: 500)
        storage.setViewportSize(id: testID, size: 200)
        storage.applyDelta(id: testID, delta: 100)
        #expect(storage.getOffset(id: testID) == 100)
        storage.reset()
        #expect(storage.getOffset(id: testID) == 0)
        #expect(storage.maxScroll(id: testID) == 0)
        #expect(storage.allOffsets()[testID] == nil)
    }
}
