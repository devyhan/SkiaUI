// DisplayListTests.swift – SkiaUIDisplayList test suite
// Tests for display list recording and command serialization.

import Testing
@testable import SkiaUIDisplayList
@testable import SkiaUIRenderTree

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

    @Test func encodingRoundTripWithFontFamily() {
        let original = DisplayList(commands: [
            .drawText(text: "Custom", x: 0, y: 14, fontSize: 18, fontWeight: 700, color: 0xFF000000, boundsWidth: 100, fontFamily: "Courier"),
        ], version: 1)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
    }

    @Test func encodingRoundTripWithNilFontFamily() {
        let original = DisplayList(commands: [
            .drawText(text: "Default", x: 0, y: 14, fontSize: 14, fontWeight: 400, color: 0xFF000000, boundsWidth: 80),
        ], version: 1)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
        if case .drawText(_, _, _, _, _, _, _, let family, _, _) = decoded!.commands[0] {
            #expect(family == nil)
        }
    }

    // MARK: - Phase 4: Retained Subtree

    @Test func retainedSubtreeMarkerEmitted() {
        let node = RenderNode(
            frame: (10, 20, 100, 50),
            paintStyle: PaintStyle(fillColor: 0xFF0000FF),
            subtreeID: 42,
            subtreeVersion: 1
        )
        var builder = DisplayListBuilder()
        let list = builder.build(from: node)
        // First build: cache miss, should emit begin/content/end markers
        let hasBegin = list.commands.contains { cmd in
            if case .retainedSubtreeBegin(let id, let v) = cmd { return id == 42 && v == 1 }
            return false
        }
        let hasEnd = list.commands.contains { $0 == .retainedSubtreeEnd }
        #expect(hasBegin)
        #expect(hasEnd)
    }

    @Test func retainedCacheHitSkipsCommands() {
        let node = RenderNode(
            frame: (10, 20, 100, 50),
            paintStyle: PaintStyle(fillColor: 0xFF0000FF),
            subtreeID: 42,
            subtreeVersion: 1
        )
        // First build: populates cache
        var builder = DisplayListBuilder()
        let firstList = builder.build(from: node)

        // Second build with same cache: should hit cache and skip inner commands
        let secondList = builder.build(from: node)

        // Second list should be shorter (only begin + end markers)
        #expect(secondList.commands.count < firstList.commands.count)
        #expect(secondList.commands.count == 2) // retainedBegin + retainedEnd
    }

    @Test func retainedCacheInvalidation() {
        let node = RenderNode(
            frame: (10, 20, 100, 50),
            paintStyle: PaintStyle(fillColor: 0xFF0000FF),
            subtreeID: 42,
            subtreeVersion: 1
        )
        var builder = DisplayListBuilder()
        let firstList = builder.build(from: node)

        // Invalidate the cache entry
        builder.retainedCache.invalidate(id: 42)

        // Third build: should regenerate full commands
        let thirdList = builder.build(from: node)
        #expect(thirdList.commands.count == firstList.commands.count)
    }

    // MARK: - Phase 5: drawImage + drawText lineLimit Encoding

    @Test func drawImageEncodingRoundTrip() {
        let original = DisplayList(commands: [
            .drawImage(source: "img.png", x: 10, y: 20, width: 100, height: 80, contentMode: 0),
        ], version: 1)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
    }

    @Test func drawImageContentModeFill() {
        let original = DisplayList(commands: [
            .drawImage(source: "photo.jpg", x: 0, y: 0, width: 200, height: 150, contentMode: 1),
        ], version: 1)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
    }

    @Test func drawImageUnicodeSource() {
        let original = DisplayList(commands: [
            .drawImage(source: "이미지.png", x: 0, y: 0, width: 50, height: 50, contentMode: 0),
        ], version: 1)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
    }

    @Test func drawTextWithLineLimitRoundTrip() {
        let original = DisplayList(commands: [
            .drawText(text: "Hello World", x: 10, y: 20, fontSize: 14, fontWeight: 400, color: 0xFF000000, boundsWidth: 100, lineLimit: 3, lineBreakMode: 1),
        ], version: 1)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
    }

    @Test func drawTextLineLimitNilRoundTrip() {
        let original = DisplayList(commands: [
            .drawText(text: "No limit", x: 0, y: 14, fontSize: 14, fontWeight: 400, color: 0xFF000000, boundsWidth: 80, lineLimit: nil, lineBreakMode: 0),
        ], version: 1)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
        if case .drawText(_, _, _, _, _, _, _, _, let lineLimit, _) = decoded!.commands[0] {
            #expect(lineLimit == nil)
        }
    }

    @Test func drawTextLineBreakModeDefault() {
        let original = DisplayList(commands: [
            .drawText(text: "Default", x: 0, y: 14, fontSize: 14, fontWeight: 400, color: 0xFF000000, boundsWidth: 60, lineLimit: nil, lineBreakMode: 0),
        ], version: 1)
        let encoder = CommandEncoder()
        let decoded = encoder.decode(encoder.encode(original))
        #expect(decoded == original)
    }
}
