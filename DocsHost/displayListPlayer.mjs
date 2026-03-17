// displayListPlayer.mjs – Browser-compatible DisplayList binary decoder + CanvasKit renderer.
// Extracted from WebClient/scripts/render.mjs for use in DocsHost.

// DisplayList opcodes (must match CommandEncoder.swift)
const OP_SAVE = 1;
const OP_RESTORE = 2;
const OP_TRANSLATE = 3;
const OP_CLIP_RECT = 4;
const OP_DRAW_RECT = 5;
const OP_DRAW_RRECT = 6;
const OP_DRAW_TEXT = 7;
const OP_RETAINED_BEGIN = 8;
const OP_RETAINED_END = 9;

export function play(ck, buffer, canvas, typeface) {
  const view = new DataView(buffer);
  let offset = 0;

  const readInt32 = () => { const v = view.getInt32(offset, true); offset += 4; return v; };
  const readFloat = () => { const v = view.getFloat32(offset, true); offset += 4; return v; };
  const readUint32 = () => { const v = view.getUint32(offset, true); offset += 4; return v; };

  const paint = new ck.Paint();
  paint.setAntiAlias(true);

  const setColor = (argb) => {
    const a = ((argb >>> 24) & 0xFF) / 255;
    const r = ((argb >> 16) & 0xFF) / 255;
    const g = ((argb >> 8) & 0xFF) / 255;
    const b = (argb & 0xFF) / 255;
    paint.setColor(ck.Color4f(r, g, b, a));
  };

  // Header
  readInt32(); // version
  const commandCount = readInt32();

  for (let i = 0; i < commandCount; i++) {
    const op = view.getUint8(offset); offset += 1;

    switch (op) {
      case OP_SAVE:
        canvas.save();
        break;
      case OP_RESTORE:
        canvas.restore();
        break;
      case OP_TRANSLATE: {
        const x = readFloat();
        const y = readFloat();
        canvas.translate(x, y);
        break;
      }
      case OP_CLIP_RECT: {
        const x = readFloat();
        const y = readFloat();
        const w = readFloat();
        const h = readFloat();
        canvas.clipRect(ck.XYWHRect(x, y, w, h), ck.ClipOp.Intersect, true);
        break;
      }
      case OP_DRAW_RECT: {
        const x = readFloat();
        const y = readFloat();
        const w = readFloat();
        const h = readFloat();
        const color = readUint32();
        setColor(color);
        paint.setStyle(ck.PaintStyle.Fill);
        canvas.drawRect(ck.XYWHRect(x, y, w, h), paint);
        break;
      }
      case OP_DRAW_RRECT: {
        const x = readFloat();
        const y = readFloat();
        const w = readFloat();
        const h = readFloat();
        const radius = readFloat();
        const color = readUint32();
        setColor(color);
        paint.setStyle(ck.PaintStyle.Fill);
        canvas.drawRRect(ck.RRectXY(ck.XYWHRect(x, y, w, h), radius, radius), paint);
        break;
      }
      case OP_DRAW_TEXT: {
        const textLen = readInt32();
        const textBytes = new Uint8Array(buffer, offset, textLen);
        offset += textLen;
        const text = new TextDecoder().decode(textBytes);
        const x = readFloat();
        const y = readFloat();
        const fontSize = readFloat();
        readInt32(); // fontWeight (unused)
        const color = readUint32();
        const boundsWidth = readFloat();
        // fontFamily (4-byte length + UTF-8 bytes, length 0 = nil)
        const familyLen = readInt32();
        if (familyLen > 0) {
          offset += familyLen;
        }
        readInt32(); // lineLimit
        readInt32(); // lineBreakMode
        setColor(color);

        const font = new ck.Font(typeface, fontSize);
        let drawX = x;
        if (boundsWidth > 0) {
          const ids = font.getGlyphIDs(text);
          const widths = font.getGlyphWidths(ids);
          const actualWidth = widths.reduce((sum, w) => sum + w, 0);
          drawX = (boundsWidth - actualWidth) / 2;
        }
        canvas.drawText(text, drawX, y, paint, font);
        font.delete();
        break;
      }
      case OP_RETAINED_BEGIN:
        readInt32(); // id
        readInt32(); // version
        break;
      case OP_RETAINED_END:
        break;
    }
  }

  paint.delete();
}
