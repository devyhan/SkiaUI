// render.mjs – Offline CanvasKit renderer for image snapshot testing.
// Reads binary DisplayList from stdin, renders to PNG, writes to stdout.
//
// Environment variables:
//   RENDER_WIDTH  – canvas width  (default 200)
//   RENDER_HEIGHT – canvas height (default 100)

import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const WIDTH = parseInt(process.env.RENDER_WIDTH || '200', 10);
const HEIGHT = parseInt(process.env.RENDER_HEIGHT || '100', 10);

// ── DisplayList opcodes (must match CommandEncoder.swift) ──

const OP_SAVE = 1;
const OP_RESTORE = 2;
const OP_TRANSLATE = 3;
const OP_CLIP_RECT = 4;
const OP_DRAW_RECT = 5;
const OP_DRAW_RRECT = 6;
const OP_DRAW_TEXT = 7;
const OP_RETAINED_BEGIN = 8;
const OP_RETAINED_END = 9;

function play(ck, buffer, canvas, primaryFontData, fallbackFonts) {
  const view = new DataView(buffer);
  let offset = 0;

  const readInt32 = () => { const v = view.getInt32(offset, true); offset += 4; return v; };
  const readFloat = () => { const v = view.getFloat32(offset, true); offset += 4; return v; };
  const readUint32 = () => { const v = view.getUint32(offset, true); offset += 4; return v; };

  // header and commands loop ...
  readInt32(); // version
  const commandCount = readInt32();

  for (let i = 0; i < commandCount; i++) {
    const op = view.getUint8(offset); offset += 1;

    switch (op) {
      case OP_SAVE: canvas.save(); break;
      case OP_RESTORE: canvas.restore(); break;
      case OP_TRANSLATE: canvas.translate(readFloat(), readFloat()); break;
      case OP_CLIP_RECT: canvas.clipRect(ck.XYWHRect(readFloat(), readFloat(), readFloat(), readFloat()), ck.ClipOp.Intersect, true); break;
      case OP_DRAW_RECT: {
        const x = readFloat(), y = readFloat(), w = readFloat(), h = readFloat(), color = readUint32();
        const paint = new ck.Paint();
        const a = ((color >>> 24) & 0xFF) / 255, r = ((color >> 16) & 0xFF) / 255, g = ((color >> 8) & 0xFF) / 255, b = (color & 0xFF) / 255;
        paint.setColor(ck.Color4f(r, g, b, a));
        paint.setStyle(ck.PaintStyle.Fill);
        canvas.drawRect(ck.XYWHRect(x, y, w, h), paint);
        paint.delete();
        break;
      }
      case OP_DRAW_RRECT: {
        const x = readFloat(), y = readFloat(), w = readFloat(), h = readFloat(), radius = readFloat(), color = readUint32();
        const paint = new ck.Paint();
        const a = ((color >>> 24) & 0xFF) / 255, r = ((color >> 16) & 0xFF) / 255, g = ((color >> 8) & 0xFF) / 255, b = (color & 0xFF) / 255;
        paint.setColor(ck.Color4f(r, g, b, a));
        paint.setStyle(ck.PaintStyle.Fill);
        canvas.drawRRect(ck.RRectXY(ck.XYWHRect(x, y, w, h), radius, radius), paint);
        paint.delete();
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
        readInt32(); // weight
        const color = readUint32();
        const boundsWidth = readFloat();
        const familyLen = readInt32();
        let fontFamily = null;
        if (familyLen > 0) {
          const familyBytes = new Uint8Array(buffer, offset, familyLen);
          offset += familyLen;
          fontFamily = new TextDecoder().decode(familyBytes);
        }
        const lineLimit = readInt32();
        readInt32(); // lineBreakMode

        const fontProvider = ck.TypefaceFontProvider.Make();
        if (primaryFontData) fontProvider.registerFont(primaryFontData, "Roboto");
        for (const font of fallbackFonts) {
          if (font.data) fontProvider.registerFont(font.data, font.family);
        }

        const style = new ck.ParagraphStyle({
          textStyle: {
            color: ck.Color4f(((color >> 16) & 0xFF) / 255, ((color >> 8) & 0xFF) / 255, (color & 0xFF) / 255, ((color >>> 24) & 0xFF) / 255),
            fontSize: fontSize,
            fontFamilies: ["Roboto", "Apple SD Gothic Neo", "Hiragino Sans GB", "PingFang SC", "STHeiti", "Thonburi", "Devanagari Sangam MN", "Geeza Pro", "Apple Color Emoji", "sans-serif"],
          },
          maxLines: lineLimit > 0 ? lineLimit : undefined,
          ellipsis: lineLimit > 0 ? '...' : undefined,
        });

        const builder = ck.ParagraphBuilder.MakeFromFontProvider(style, fontProvider);
        builder.addText(text);
        const paragraph = builder.build();
        
        // Use a more lenient width for layout to prevent accidental wrapping 
        // that causes vertical overlap in VStacks.
        // If lineLimit is 1, we effectively want to disable wrapping.
        const layoutWidth = (lineLimit === 1) ? 10000 : (boundsWidth > 0 ? boundsWidth + (fontSize * 0.5) : 2000);
        paragraph.layout(layoutWidth);
        
        let drawX = x;
        if (boundsWidth > 0) {
          // Center the paragraph within the original boundsWidth
          drawX = (boundsWidth - paragraph.getMaxIntrinsicWidth()) / 2;
        }
        canvas.drawParagraph(paragraph, drawX, y);

        paragraph.delete();
        builder.delete();
        fontProvider.delete();
        break;
      }
      case OP_RETAINED_BEGIN: readInt32(); readInt32(); break;
      case OP_RETAINED_END: break;
    }
  }
}

// ── Main ──

async function main() {
  // Read all of stdin as binary
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks);

  if (input.length === 0) {
    process.stderr.write('render.mjs: empty stdin\n');
    process.exit(1);
  }

  // Initialize CanvasKit
  const require = createRequire(import.meta.url);
  const ckDir = dirname(require.resolve('canvaskit-wasm/package.json'));

  const CanvasKitInit = (await import('canvaskit-wasm')).default;
  const ck = await CanvasKitInit({
    locateFile: (file) => join(ckDir, 'bin', file),
  });

  // Load fonts
  const fontPath = join(__dirname, '..', 'public', 'Roboto-Regular.ttf');
  const fontData = readFileSync(fontPath);
  const fontBuffer = fontData.buffer.slice(fontData.byteOffset, fontData.byteOffset + fontData.byteLength);

  const fallbackPaths = [
    { path: '/System/Library/Fonts/AppleSDGothicNeo.ttc', family: 'Apple SD Gothic Neo' },
    { path: '/System/Library/Fonts/Hiragino Sans GB.ttc', family: 'Hiragino Sans GB' },
    { path: '/System/Library/Fonts/STHeiti Light.ttc', family: 'STHeiti' },
    { path: '/System/Library/Fonts/Supplemental/Thonburi.ttc', family: 'Thonburi' },
    { path: '/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc', family: 'Devanagari Sangam MN' },
    { path: '/System/Library/Fonts/GeezaPro.ttc', family: 'Geeza Pro' },
    { path: '/System/Library/Fonts/Apple Color Emoji.ttc', family: 'Apple Color Emoji' }
  ];
  
  const fallbackFonts = [];
  for (const item of fallbackPaths) {
    try {
      const rawData = readFileSync(item.path);
      fallbackFonts.push({
        data: rawData.buffer.slice(rawData.byteOffset, rawData.byteOffset + rawData.byteLength),
        family: item.family
      });
    } catch (e) {
      // Font not found, ignore
    }
  }

  // Create offscreen surface
  const surface = ck.MakeSurface(WIDTH, HEIGHT);
  if (!surface) {
    process.stderr.write('render.mjs: failed to create surface\n');
    process.exit(1);
  }

  const canvas = surface.getCanvas();
  canvas.clear(ck.WHITE);

  // Render
  const arrayBuffer = input.buffer.slice(input.byteOffset, input.byteOffset + input.byteLength);
  play(ck, arrayBuffer, canvas, fontBuffer, fallbackFonts);

  surface.flush();

  // Encode to PNG and write to stdout
  const image = surface.makeImageSnapshot();
  const pngBytes = image.encodeToBytes();

  if (!pngBytes) {
    process.stderr.write('render.mjs: failed to encode PNG\n');
    process.exit(1);
  }

  process.stdout.write(Buffer.from(pngBytes));

  // Cleanup
  image.delete();
  surface.delete();
}

main().catch((err) => {
  process.stderr.write(`render.mjs: ${err.message}\n`);
  process.exit(1);
});
