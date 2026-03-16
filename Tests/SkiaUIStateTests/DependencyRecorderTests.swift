// DependencyRecorderTests.swift – SkiaUIState test suite
// Tests for DependencyRecorder callback bridge and StateStorage slot counter.
// Uses local instances (not shared singletons) to avoid cross-target interference.

import Testing
@testable import SkiaUIState

@Suite struct DependencyRecorderTests {
    @Test func readCallbackFires() {
        let recorder = DependencyRecorder()

        var readIDs: [Int] = []
        recorder.setCallbacks(
            onRead: { readIDs.append($0) },
            onWrite: { _ in }
        )
        recorder.notifyRead(stateID: 42)
        recorder.notifyRead(stateID: 7)

        #expect(readIDs == [42, 7])
    }

    @Test func writeCallbackFires() {
        let recorder = DependencyRecorder()

        var writeIDs: [Int] = []
        recorder.setCallbacks(
            onRead: { _ in },
            onWrite: { writeIDs.append($0) }
        )
        recorder.notifyWrite(stateID: 99)

        #expect(writeIDs == [99])
    }

    @Test func noCallbackWhenCleared() {
        let recorder = DependencyRecorder()
        var called = false
        recorder.setCallbacks(
            onRead: { _ in called = true },
            onWrite: { _ in called = true }
        )
        recorder.clearCallbacks()
        recorder.notifyRead(stateID: 0)
        recorder.notifyWrite(stateID: 0)

        #expect(!called)
    }

    @Test func slotCounterReset() {
        let storage = StateStorage()

        let id1 = storage.allocate(initialValue: 10)
        let id2 = storage.allocate(initialValue: 20)
        #expect(id1 == 0)
        #expect(id2 == 1)

        storage.resetSlotCounter()
        let id3 = storage.allocate(initialValue: 999)
        #expect(id3 == 0) // counter reset, same slot
    }

    @Test func allocatePreservesExistingValue() {
        let storage = StateStorage()

        let id = storage.allocate(initialValue: 42)
        storage.set(id: id, value: 100)

        storage.resetSlotCounter()
        let id2 = storage.allocate(initialValue: 42) // should not overwrite 100
        #expect(id2 == id)
        let value: Int? = storage.get(id: id2)
        #expect(value == 100) // preserved, not reset to 42
    }
}
