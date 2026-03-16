import type { CanvasKit, Canvas, Paint } from 'canvaskit-wasm';
import type { FontManager } from './fontManager';

const OP_SAVE = 1;
const OP_RESTORE = 2;
const OP_TRANSLATE = 3;
const OP_CLIP_RECT = 4;
const OP_DRAW_RECT = 5;
const OP_DRAW_RRECT = 6;
const OP_DRAW_TEXT = 7;
const OP_RETAINED_BEGIN = 8;
const OP_RETAINED_END = 9;

export class DisplayListPlayer {
  private ck: CanvasKit;
  private paint: Paint;
  private fontManager: FontManager;

  constructor(ck: CanvasKit, fontManager: FontManager) {
    this.ck = ck;
    this.paint = new ck.Paint();
    this.paint.setAntiAlias(true);
    this.fontManager = fontManager;
  }

  play(buffer: ArrayBuffer, canvas: Canvas): void {
    const view = new DataView(buffer);
    let offset = 0;

    const readInt32 = (): number => { const v = view.getInt32(offset, true); offset += 4; return v; };
    const readFloat = (): number => { const v = view.getFloat32(offset, true); offset += 4; return v; };
    const readUint32 = (): number => { const v = view.getUint32(offset, true); offset += 4; return v; };

    // Read header
    const _version = readInt32();
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
          canvas.clipRect(this.ck.XYWHRect(x, y, w, h), this.ck.ClipOp.Intersect, true);
          break;
        }
        case OP_DRAW_RECT: {
          const x = readFloat();
          const y = readFloat();
          const w = readFloat();
          const h = readFloat();
          const color = readUint32();
          this.setColor(color);
          this.paint.setStyle(this.ck.PaintStyle.Fill);
          canvas.drawRect(this.ck.XYWHRect(x, y, w, h), this.paint);
          break;
        }
        case OP_DRAW_RRECT: {
          const x = readFloat();
          const y = readFloat();
          const w = readFloat();
          const h = readFloat();
          const radius = readFloat();
          const color = readUint32();
          this.setColor(color);
          this.paint.setStyle(this.ck.PaintStyle.Fill);
          canvas.drawRRect(this.ck.RRectXY(this.ck.XYWHRect(x, y, w, h), radius, radius), this.paint);
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
          const _fontWeight = readInt32();
          const color = readUint32();
          const boundsWidth = readFloat();
          // Decode fontFamily (4-byte length + UTF-8 bytes, length 0 = nil)
          const familyLen = readInt32();
          let fontFamily: string | null = null;
          if (familyLen > 0) {
            const familyBytes = new Uint8Array(buffer, offset, familyLen);
            offset += familyLen;
            fontFamily = new TextDecoder().decode(familyBytes);
          }
          this.setColor(color);

          const typeface = this.fontManager.getTypeface(fontFamily);
          const font = new this.ck.Font(typeface, fontSize);
          let drawX = x;
          if (boundsWidth > 0) {
            const ids = font.getGlyphIDs(text);
            const widths = font.getGlyphWidths(ids);
            const actualWidth = widths.reduce((sum: number, w: number) => sum + w, 0);
            drawX = (boundsWidth - actualWidth) / 2;
          }
          canvas.drawText(text, drawX, y, this.paint, font);
          font.delete();
          break;
        }
        case OP_RETAINED_BEGIN: {
          readInt32(); // id
          readInt32(); // version
          break;
        }
        case OP_RETAINED_END:
          break;
      }
    }
  }

  private setColor(argb: number): void {
    const a = ((argb >>> 24) & 0xFF) / 255;
    const r = ((argb >> 16) & 0xFF) / 255;
    const g = ((argb >> 8) & 0xFF) / 255;
    const b = (argb & 0xFF) / 255;
    this.paint.setColor(this.ck.Color4f(r, g, b, a));
  }

  dispose(): void {
    this.paint.delete();
  }
}
