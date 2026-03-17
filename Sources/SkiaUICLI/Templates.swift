enum Templates {
    static func packageSwift(name: String) -> String {
        """
        // swift-tools-version: 6.2

        import PackageDescription

        let package = Package(
            name: "\(name)",
            platforms: [.macOS(.v14)],
            dependencies: [
                .package(url: "https://github.com/devyhan/SkiaUI.git", branch: "main"),
                .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", exact: "0.47.1"),
            ],
            targets: [
                .executableTarget(
                    name: "App",
                    dependencies: [
                        .product(name: "SkiaUI", package: "SkiaUI"),
                        .product(name: "SkiaUIWebBridge", package: "SkiaUI"),
                    ]
                ),
            ]
        )
        """
    }

    static func appSwift(name: String) -> String {
        """
        import SkiaUI
        import SkiaUIWebBridge

        @main
        struct \(name)App: SkiaUI.App {
            var body: some View {
                VStack(spacing: 16) {
                    Text("Hello, SkiaUI!")
                        .fontSize(28)
                        .bold()
                    Text("Canvas-based UI powered by Swift + Skia")
                        .fontSize(16)
                        .foregroundColor(.gray)
                }
            }

            static func main() {
                WebBridge.start(\(name)App.self)
            }
        }
        """
    }

    static let indexHTML = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>SkiaUI Demo</title>
      <script type="importmap">
        {
          "imports": {
            "@bjorn3/browser_wasi_shim": "https://esm.sh/@bjorn3/browser_wasi_shim@0.3.0"
          }
        }
      </script>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: #f2f2f2; overflow: hidden; }
        canvas { display: block; }
      </style>
    </head>
    <body>
      <canvas id="skia-canvas"></canvas>
      <script type="module">
        import CanvasKitInit from "https://esm.sh/canvaskit-wasm@0.39.1";
        import { play } from "./displayListPlayer.mjs";
        import { init } from "./package/index.js";

        const CanvasKit = await CanvasKitInit({
          locateFile: (file) => `https://unpkg.com/canvaskit-wasm@0.39.1/bin/${file}`,
        });

        const canvas = document.getElementById("skia-canvas");
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;

        const surface = CanvasKit.MakeWebGLCanvasSurface(canvas);
        const skCanvas = surface.getCanvas();

        // Load default font for text rendering
        const fontResp = await fetch("https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Me5Q.ttf");
        const fontData = await fontResp.arrayBuffer();
        const typeface = CanvasKit.Typeface.MakeFreeTypeFaceFromData(fontData);

        // Set up the bridge that Swift's WebBridge.start() expects
        window.skiaUI = {
          viewport: { width: canvas.width, height: canvas.height },
          submitDisplayList(bytes) {
            try {
              const buf = bytes.buffer ?? bytes;
              skCanvas.clear(CanvasKit.Color4f(0.95, 0.95, 0.95, 1.0));
              play(CanvasKit, buf, skCanvas, typeface);
              surface.flush();
            } catch (err) {
              console.error("[SkiaUI] submitDisplayList error:", err);
            }
          },
        };

        // Forward click events to Swift tap handler
        canvas.addEventListener("click", (e) => {
          if (typeof window.skiaUI.handleTap === "function") {
            try {
              window.skiaUI.handleTap(e.offsetX, e.offsetY);
            } catch (err) {
              console.error("[SkiaUI] handleTap error:", err);
            }
          }
        });

        // Forward wheel events to Swift scroll handler
        canvas.addEventListener("wheel", (e) => {
          e.preventDefault();
          if (typeof window.skiaUI.handleScroll === "function") {
            window.skiaUI.handleScroll(e.offsetX, e.offsetY, e.deltaX, e.deltaY);
          }
        }, { passive: false });

        // Start the Swift WASM app
        await init();
      </script>
    </body>
    </html>
    """

    static let displayListPlayerMJS = ##"""
    // displayListPlayer.mjs – Browser-compatible DisplayList binary decoder + CanvasKit renderer.

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
    """##

    static let buildSH = """
    #!/bin/bash
    set -euo pipefail

    # Build the WASM binary
    swift package --swift-sdk swift-6.2.4-RELEASE_wasm js --product App -c release

    # Create the distribution directory
    rm -rf dist
    mkdir -p dist

    # Copy PackageToJS output and web host files
    cp -r .build/plugins/PackageToJS/outputs/Package dist/package
    cp WebHost/index.html dist/
    cp WebHost/displayListPlayer.mjs dist/

    echo "Build complete! Serve the dist/ directory with a local server:"
    echo "  npx serve dist"
    echo "  python3 -m http.server -d dist"
    """
}
