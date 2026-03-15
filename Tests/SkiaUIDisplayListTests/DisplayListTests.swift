// DisplayListTests.swift – SkiaUIDisplayList test suite
// Tests for display list recording and command serialization.

import Testing
@testable import SkiaUIDisplayList

@Suite struct DisplayListTests {
    @Test func emptyDisplayList() {
        let dl = DisplayList()
        #expect(dl.commands.isEmpty)
        #expect(dl.version == 0)
    }

    @Test func appendCommands() {
        var dl = DisplayList()
        dl.append(.save)
        dl.append(.drawRect(x: 0, y: 0, width: 100, height: 50, color: 0xFF0000FF))
        dl.append(.restore)
        #expect(dl.count == 3)
    }

    @Test func encodingRoundTrip() {
        let original = DisplayList(commands: [
            .save,
            .translate(x: 10, y: 20),
            .drawRect(x: 0, y: 0, width: 100, height: 50, color: 0xFF0000FF),
            .drawText(text: "Hello", x: 10, y: 30, fontSize: 14, fontWeight: 400, color: 0xFF000000),
            .restore,
        ], version: 42)

        let encoder = CommandEncoder()
        let encoded = encoder.encode(original)
        let decoded = encoder.decode(encoded)

        #expect(decoded != nil)
        #expect(decoded?.version == 42)
        #expect(decoded?.commands.count == original.commands.count)
        #expect(decoded?.commands == original.commands)
    }

    @Test func encodingRoundTripRRect() {
        let original = DisplayList(commands: [
            .drawRRect(x: 0, y: 0, width: 50, height: 50, radius: 8, color: 0xFFFF0000),
        ], version: 1)

        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
    }

    @Test func retainedSubtreeEncoding() {
        let original = DisplayList(commands: [
            .retainedSubtreeBegin(id: 1, version: 3),
            .drawRect(x: 0, y: 0, width: 10, height: 10, color: 0xFF000000),
            .retainedSubtreeEnd,
        ], version: 1)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
    }
}
