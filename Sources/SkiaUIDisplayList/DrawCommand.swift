// DrawCommand.swift – SkiaUIDisplayList module
// Individual drawing operations recorded in a display list.

public enum DrawCommand: Equatable, Sendable {
    case save
    case restore
    case translate(x: Float, y: Float)
    case clipRect(x: Float, y: Float, width: Float, height: Float)
    case drawRect(x: Float, y: Float, width: Float, height: Float, color: UInt32)
    case drawRRect(x: Float, y: Float, width: Float, height: Float, radius: Float, color: UInt32)
    case drawText(text: String, x: Float, y: Float, fontSize: Float, fontWeight: Int, color: UInt32, boundsWidth: Float = 0, fontFamily: String? = nil, lineLimit: Int? = nil, lineBreakMode: Int = 0)
    case drawImage(source: String, x: Float, y: Float, width: Float, height: Float, contentMode: Int)
    case retainedSubtreeBegin(id: Int, version: Int)
    case retainedSubtreeEnd
}
