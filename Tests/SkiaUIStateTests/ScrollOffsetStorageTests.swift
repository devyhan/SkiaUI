// ScrollOffsetStorageTests.swift – SkiaUIState test suite
// Tests for scroll offset storage and clamping behavior.

import Testing
@testable import SkiaUIState

@Suite(.serialized) struct ScrollOffsetStorageTests {
    // Use high unique IDs per test to avoid cross-target interference
    // (other targets may call ScrollOffsetStorage.shared.reset() concurrently).

    @Test func initialOffsetIsZero() {
        let storage = ScrollOffsetStorage.shared
        // Unregistered ID always returns 0
        #expect(storage.getOffset(id: 80001) == 0)
    }

    @Test func applyDeltaAccumulates() {
        let storage = ScrollOffsetStorage.shared
        let id = 80002
        storage.setContentSize(id: id, size: 500)
        storage.setViewportSize(id: id, size: 200)
        storage.applyDelta(id: id, delta: -999999) // Reset to 0
        storage.applyDelta(id: id, delta: 50)
        #expect(storage.getOffset(id: id) == 50)
        storage.setContentSize(id: id, size: 500)
        storage.setViewportSize(id: id, size: 200)
        storage.applyDelta(id: id, delta: 30)
        #expect(storage.getOffset(id: id) == 80)
    }

    @Test func offsetClampedToZero() {
        let storage = ScrollOffsetStorage.shared
        let id = 80003
        storage.setContentSize(id: id, size: 500)
        storage.setViewportSize(id: id, size: 200)
        // Try to scroll past top
        storage.applyDelta(id: id, delta: -100)
        #expect(storage.getOffset(id: id) == 0)
    }

    @Test func offsetClampedToMaxScroll() {
        let storage = ScrollOffsetStorage.shared
        let id = 80004
        storage.setContentSize(id: id, size: 500)
        storage.setViewportSize(id: id, size: 200)
        // maxScroll = 500 - 200 = 300
        storage.applyDelta(id: id, delta: 999)
        #expect(storage.getOffset(id: id) == 300)
    }

    @Test func maxScrollCalculation() {
        let storage = ScrollOffsetStorage.shared
        let id = 80005
        storage.setContentSize(id: id, size: 1000)
        storage.setViewportSize(id: id, size: 400)
        #expect(storage.maxScroll(id: id) == 600)
    }

    @Test func maxScrollNeverNegative() {
        let storage = ScrollOffsetStorage.shared
        let id = 80006
        storage.setContentSize(id: id, size: 100)
        storage.setViewportSize(id: id, size: 400)
        // Content smaller than viewport → maxScroll = 0
        #expect(storage.maxScroll(id: id) == 0)
    }

    @Test func allOffsetsReturnsDictionary() {
        let storage = ScrollOffsetStorage.shared
        let id = 80007
        storage.setContentSize(id: id, size: 500)
        storage.setViewportSize(id: id, size: 200)
        storage.applyDelta(id: id, delta: 42)
        let offsets = storage.allOffsets()
        #expect(offsets[id] == 42)
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
