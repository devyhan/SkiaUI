import type { CanvasKit, Canvas, Paint } from 'canvaskit-wasm';
import type { FontManager } from './fontManager';
import type { ImageCache } from './imageCache';

const OP_SAVE = 1;
const OP_RESTORE = 2;
const OP_TRANSLATE = 3;
const OP_CLIP_RECT = 4;
const OP_DRAW_RECT = 5;
const OP_DRAW_RRECT = 6;
const OP_DRAW_TEXT = 7;
const OP_RETAINED_BEGIN = 8;
const OP_RETAINED_END = 9;
const OP_DRAW_IMAGE = 10;

export class DisplayListPlayer {
  private ck: CanvasKit;
  private paint: Paint;
  private fontManager: FontManager;
  private imageCache: ImageCache;

  constructor(ck: CanvasKit, fontManager: FontManager, imageCache: ImageCache) {
    this.ck = ck;
    this.paint = new ck.Paint();
    this.paint.setAntiAlias(true);
    this.fontManager = fontManager;
    this.imageCache = imageCache;
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
          // Decode lineLimit and lineBreakMode (Int32 each, 0 = unlimited/wordWrap)
          const lineLimit = readInt32();
          const _lineBreakMode = readInt32();
          this.setColor(color);

          const fontMgr = this.fontManager.getFontMgr();
          const style = new this.ck.ParagraphStyle({
            textStyle: {
              color: this.ck.Color4f(
                ((color >> 16) & 0xFF) / 255,
                ((color >> 8) & 0xFF) / 255,
                (color & 0xFF) / 255,
                ((color >>> 24) & 0xFF) / 255
              ),
              fontSize: fontSize,
              fontFamilies: fontFamily ? [fontFamily, 'sans-serif'] : ['sans-serif'],
            },
            maxLines: lineLimit > 0 ? lineLimit : undefined,
            ellipsis: '...',
          });

          const builder = this.ck.ParagraphBuilder.Make(style, fontMgr);
          builder.addText(text);
          const paragraph = builder.build();
          paragraph.layout(boundsWidth > 0 ? boundsWidth : 10000);

          let drawX = x;
          if (boundsWidth > 0) {
            drawX = (boundsWidth - paragraph.getMaxIntrinsicWidth()) / 2;
          }
          canvas.drawParagraph(paragraph, drawX, y);
          
          paragraph.delete();
          builder.delete();
          fontMgr.delete();
          break;
        }
        case OP_DRAW_IMAGE: {
          const srcLen = readInt32();
          const srcBytes = new Uint8Array(buffer, offset, srcLen);
          offset += srcLen;
          const source = new TextDecoder().decode(srcBytes);
          const ix = readFloat();
          const iy = readFloat();
          const iw = readFloat();
          const ih = readFloat();
          const _contentMode = readInt32();
          const img = this.imageCache.get(source);
          if (img) {
            const srcRect = this.ck.XYWHRect(0, 0, img.width(), img.height());
            const dstRect = this.ck.XYWHRect(ix, iy, iw, ih);
            canvas.drawImageRect(img, srcRect, dstRect, this.paint);
          } else {
            // Draw grey placeholder while image loads
            this.paint.setColor(this.ck.Color4f(0.85, 0.85, 0.85, 1));
            this.paint.setStyle(this.ck.PaintStyle.Fill);
            canvas.drawRect(this.ck.XYWHRect(ix, iy, iw, ih), this.paint);
            // Trigger async load
            this.imageCache.load(source);
          }
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

  private wrapText(text: string, font: any, maxWidth: number): string[] {
    const words = text.split(' ');
    const lines: string[] = [];
    let currentLine = '';

    for (const word of words) {
      const testLine = currentLine ? `${currentLine} ${word}` : word;
      const ids = font.getGlyphIDs(testLine);
      const widths = font.getGlyphWidths(ids);
      const testWidth = widths.reduce((sum: number, w: number) => sum + w, 0);

      if (testWidth > maxWidth && currentLine) {
        lines.push(currentLine);
        currentLine = word;
      } else {
        currentLine = testLine;
      }
    }
    if (currentLine) {
      lines.push(currentLine);
    }
    return lines.length > 0 ? lines : [text];
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
