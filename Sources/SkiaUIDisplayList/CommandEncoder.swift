// CommandEncoder.swift – SkiaUIDisplayList module
// Binary encoding/decoding for Swift<->JS boundary.

public struct CommandEncoder: Sendable {
    // Command opcodes
    private static let OP_SAVE: UInt8 = 1
    private static let OP_RESTORE: UInt8 = 2
    private static let OP_TRANSLATE: UInt8 = 3
    private static let OP_CLIP_RECT: UInt8 = 4
    private static let OP_DRAW_RECT: UInt8 = 5
    private static let OP_DRAW_RRECT: UInt8 = 6
    private static let OP_DRAW_TEXT: UInt8 = 7
    private static let OP_RETAINED_BEGIN: UInt8 = 8
    private static let OP_RETAINED_END: UInt8 = 9
    private static let OP_DRAW_IMAGE: UInt8 = 10

    public init() {}

    public func encode(_ displayList: DisplayList) -> [UInt8] {
        var buffer: [UInt8] = []
        // Header: version (4 bytes) + command count (4 bytes)
        appendInt32(&buffer, Int32(displayList.version))
        appendInt32(&buffer, Int32(displayList.commands.count))
        for cmd in displayList.commands {
            encodeCommand(&buffer, cmd)
        }
        return buffer
    }

    public func decode(_ data: [UInt8]) -> DisplayList? {
        var offset = 0
        guard data.count >= 8 else { return nil }
        let version = readInt32(data, &offset)
        let count = readInt32(data, &offset)
        var commands: [DrawCommand] = []
        commands.reserveCapacity(Int(count))
        for _ in 0..<count {
            guard let cmd = decodeCommand(data, &offset) else { return nil }
            commands.append(cmd)
        }
        return DisplayList(commands: commands, version: Int(version))
    }

    // MARK: - Encoding helpers

    private func encodeCommand(_ buffer: inout [UInt8], _ cmd: DrawCommand) {
        switch cmd {
        case .save:
            buffer.append(Self.OP_SAVE)
        case .restore:
            buffer.append(Self.OP_RESTORE)
        case .translate(let x, let y):
            buffer.append(Self.OP_TRANSLATE)
            appendFloat(&buffer, x)
            appendFloat(&buffer, y)
        case .clipRect(let x, let y, let w, let h):
            buffer.append(Self.OP_CLIP_RECT)
            appendFloat(&buffer, x)
            appendFloat(&buffer, y)
            appendFloat(&buffer, w)
            appendFloat(&buffer, h)
        case .drawRect(let x, let y, let w, let h, let color):
            buffer.append(Self.OP_DRAW_RECT)
            appendFloat(&buffer, x)
            appendFloat(&buffer, y)
            appendFloat(&buffer, w)
            appendFloat(&buffer, h)
            appendUInt32(&buffer, color)
        case .drawRRect(let x, let y, let w, let h, let radius, let color):
            buffer.append(Self.OP_DRAW_RRECT)
            appendFloat(&buffer, x)
            appendFloat(&buffer, y)
            appendFloat(&buffer, w)
            appendFloat(&buffer, h)
            appendFloat(&buffer, radius)
            appendUInt32(&buffer, color)
        case .drawText(let text, let x, let y, let fontSize, let fontWeight, let color, let boundsWidth, let fontFamily, let lineLimit, let lineBreakMode):
            buffer.append(Self.OP_DRAW_TEXT)
            let textBytes = Array(text.utf8)
            appendInt32(&buffer, Int32(textBytes.count))
            buffer.append(contentsOf: textBytes)
            appendFloat(&buffer, x)
            appendFloat(&buffer, y)
            appendFloat(&buffer, fontSize)
            appendInt32(&buffer, Int32(fontWeight))
            appendUInt32(&buffer, color)
            appendFloat(&buffer, boundsWidth)
            if let family = fontFamily {
                let familyBytes = Array(family.utf8)
                appendInt32(&buffer, Int32(familyBytes.count))
                buffer.append(contentsOf: familyBytes)
            } else {
                appendInt32(&buffer, 0)
            }
            appendInt32(&buffer, Int32(lineLimit ?? 0))
            appendInt32(&buffer, Int32(lineBreakMode))
        case .drawImage(let source, let x, let y, let w, let h, let contentMode):
            buffer.append(Self.OP_DRAW_IMAGE)
            let sourceBytes = Array(source.utf8)
            appendInt32(&buffer, Int32(sourceBytes.count))
            buffer.append(contentsOf: sourceBytes)
            appendFloat(&buffer, x)
            appendFloat(&buffer, y)
            appendFloat(&buffer, w)
            appendFloat(&buffer, h)
            appendInt32(&buffer, Int32(contentMode))
        case .retainedSubtreeBegin(let id, let version):
            buffer.append(Self.OP_RETAINED_BEGIN)
            appendInt32(&buffer, Int32(truncatingIfNeeded: id))
            appendInt32(&buffer, Int32(truncatingIfNeeded: version))
        case .retainedSubtreeEnd:
            buffer.append(Self.OP_RETAINED_END)
        }
    }

    private func decodeCommand(_ data: [UInt8], _ offset: inout Int) -> DrawCommand? {
        guard offset < data.count else { return nil }
        let op = data[offset]; offset += 1
        switch op {
        case Self.OP_SAVE: return .save
        case Self.OP_RESTORE: return .restore
        case Self.OP_TRANSLATE:
            let x = readFloat(data, &offset)
            let y = readFloat(data, &offset)
            return .translate(x: x, y: y)
        case Self.OP_CLIP_RECT:
            let x = readFloat(data, &offset)
            let y = readFloat(data, &offset)
            let w = readFloat(data, &offset)
            let h = readFloat(data, &offset)
            return .clipRect(x: x, y: y, width: w, height: h)
        case Self.OP_DRAW_RECT:
            let x = readFloat(data, &offset)
            let y = readFloat(data, &offset)
            let w = readFloat(data, &offset)
            let h = readFloat(data, &offset)
            let c = readUInt32(data, &offset)
            return .drawRect(x: x, y: y, width: w, height: h, color: c)
        case Self.OP_DRAW_RRECT:
            let x = readFloat(data, &offset)
            let y = readFloat(data, &offset)
            let w = readFloat(data, &offset)
            let h = readFloat(data, &offset)
            let r = readFloat(data, &offset)
            let c = readUInt32(data, &offset)
            return .drawRRect(x: x, y: y, width: w, height: h, radius: r, color: c)
        case Self.OP_DRAW_TEXT:
            let len = Int(readInt32(data, &offset))
            guard offset + len <= data.count else { return nil }
            let textBytes = Array(data[offset..<offset+len])
            offset += len
            let text = String(decoding: textBytes, as: UTF8.self)
            let x = readFloat(data, &offset)
            let y = readFloat(data, &offset)
            let fontSize = readFloat(data, &offset)
            let fontWeight = readInt32(data, &offset)
            let color = readUInt32(data, &offset)
            let boundsWidth = readFloat(data, &offset)
            let familyLen = Int(readInt32(data, &offset))
            let fontFamily: String?
            if familyLen > 0 {
                guard offset + familyLen <= data.count else { return nil }
                let familyBytes = Array(data[offset..<offset+familyLen])
                offset += familyLen
                fontFamily = String(decoding: familyBytes, as: UTF8.self)
            } else {
                fontFamily = nil
            }
            let lineLimitRaw = Int(readInt32(data, &offset))
            let lineLimit: Int? = lineLimitRaw > 0 ? lineLimitRaw : nil
            let lineBreakMode = Int(readInt32(data, &offset))
            return .drawText(text: text, x: x, y: y, fontSize: fontSize, fontWeight: Int(fontWeight), color: color, boundsWidth: boundsWidth, fontFamily: fontFamily, lineLimit: lineLimit, lineBreakMode: lineBreakMode)
        case Self.OP_DRAW_IMAGE:
            let srcLen = Int(readInt32(data, &offset))
            guard offset + srcLen <= data.count else { return nil }
            let srcBytes = Array(data[offset..<offset+srcLen])
            offset += srcLen
            let source = String(decoding: srcBytes, as: UTF8.self)
            let x = readFloat(data, &offset)
            let y = readFloat(data, &offset)
            let w = readFloat(data, &offset)
            let h = readFloat(data, &offset)
            let contentMode = Int(readInt32(data, &offset))
            return .drawImage(source: source, x: x, y: y, width: w, height: h, contentMode: contentMode)
        case Self.OP_RETAINED_BEGIN:
            let id = readInt32(data, &offset)
            let ver = readInt32(data, &offset)
            return .retainedSubtreeBegin(id: Int(id), version: Int(ver))
        case Self.OP_RETAINED_END: return .retainedSubtreeEnd
        default: return nil
        }
    }

    // MARK: - Binary helpers

    private func appendFloat(_ buffer: inout [UInt8], _ value: Float) {
        var v = value
        withUnsafeBytes(of: &v) { buffer.append(contentsOf: $0) }
    }

    private func appendInt32(_ buffer: inout [UInt8], _ value: Int32) {
        var v = value
        withUnsafeBytes(of: &v) { buffer.append(contentsOf: $0) }
    }

    private func appendUInt32(_ buffer: inout [UInt8], _ value: UInt32) {
        var v = value
        withUnsafeBytes(of: &v) { buffer.append(contentsOf: $0) }
    }

    private func readFloat(_ data: [UInt8], _ offset: inout Int) -> Float {
        let bytes = Array(data[offset..<offset+4])
        offset += 4
        return bytes.withUnsafeBytes { $0.load(as: Float.self) }
    }

    private func readInt32(_ data: [UInt8], _ offset: inout Int) -> Int32 {
        let bytes = Array(data[offset..<offset+4])
        offset += 4
        return bytes.withUnsafeBytes { $0.load(as: Int32.self) }
    }

    private func readUInt32(_ data: [UInt8], _ offset: inout Int) -> UInt32 {
        let bytes = Array(data[offset..<offset+4])
        offset += 4
        return bytes.withUnsafeBytes { $0.load(as: UInt32.self) }
    }
}
