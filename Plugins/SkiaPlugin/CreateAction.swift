import Foundation
import PackagePlugin

enum CreateAction {
    static func run(context: PluginContext, arguments: [String]) throws {
        let extractor = ArgumentExtractor(arguments)
        let positional = extractor.remainingArguments

        guard let name = positional.first else {
            throw PluginError.missingProjectName
        }

        let fm = FileManager.default
        let projectDir = context.package.directoryURL.path + "/\(name)"

        guard !fm.fileExists(atPath: projectDir) else {
            throw PluginError.directoryExists(name)
        }

        // Create directory structure
        try fm.createDirectory(atPath: projectDir + "/Sources", withIntermediateDirectories: true)
        try fm.createDirectory(atPath: projectDir + "/WebHost", withIntermediateDirectories: true)

        // Write Package.swift
        try packageSwiftTemplate(name: name).write(
            toFile: projectDir + "/Package.swift", atomically: true, encoding: .utf8
        )

        // Write App.swift
        try appSwiftTemplate(name: name).write(
            toFile: projectDir + "/Sources/App.swift", atomically: true, encoding: .utf8
        )

        // Write WebHost files
        try indexHTMLTemplate.write(
            toFile: projectDir + "/WebHost/index.html", atomically: true, encoding: .utf8
        )
        try displayListPlayerTemplate.write(
            toFile: projectDir + "/WebHost/displayListPlayer.mjs", atomically: true, encoding: .utf8
        )

        print("Created '\(name)/' with the following structure:")
        print("  \(name)/")
        print("  \u{251c}\u{2500}\u{2500} Package.swift")
        print("  \u{251c}\u{2500}\u{2500} Sources/")
        print("  \u{2502}   \u{2514}\u{2500}\u{2500} App.swift")
        print("  \u{2514}\u{2500}\u{2500} WebHost/")
        print("      \u{251c}\u{2500}\u{2500} index.html")
        print("      \u{2514}\u{2500}\u{2500} displayListPlayer.mjs")
        print("")
        print("Next steps:")
        print("  cd \(name)")
        print("  swift package --allow-writing-to-package-directory skia build")
    }

    // MARK: - Templates

    private static func packageSwiftTemplate(name: String) -> String {
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

    private static func appSwiftTemplate(name: String) -> String {
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

    private static let indexHTMLTemplate = """
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

        const fontResp = await fetch("https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Me5Q.ttf");
        const fontData = await fontResp.arrayBuffer();
        const typeface = CanvasKit.Typeface.MakeFreeTypeFaceFromData(fontData);

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

        canvas.addEventListener("click", (e) => {
          if (typeof window.skiaUI.handleTap === "function") {
            try { window.skiaUI.handleTap(e.offsetX, e.offsetY); }
            catch (err) { console.error("[SkiaUI] handleTap error:", err); }
          }
        });

        canvas.addEventListener("wheel", (e) => {
          e.preventDefault();
          if (typeof window.skiaUI.handleScroll === "function") {
            window.skiaUI.handleScroll(e.offsetX, e.offsetY, e.deltaX, e.deltaY);
          }
        }, { passive: false });

        await init();
      </script>
    </body>
    </html>
    """

    private static let displayListPlayerTemplate = ##"""
    // displayListPlayer.mjs – Browser-compatible DisplayList binary decoder + CanvasKit renderer.

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

      readInt32(); // version
      const commandCount = readInt32();

      for (let i = 0; i < commandCount; i++) {
        const op = view.getUint8(offset); offset += 1;

        switch (op) {
          case OP_SAVE: canvas.save(); break;
          case OP_RESTORE: canvas.restore(); break;
          case OP_TRANSLATE: {
            const x = readFloat(); const y = readFloat();
            canvas.translate(x, y); break;
          }
          case OP_CLIP_RECT: {
            const x = readFloat(); const y = readFloat();
            const w = readFloat(); const h = readFloat();
            canvas.clipRect(ck.XYWHRect(x, y, w, h), ck.ClipOp.Intersect, true); break;
          }
          case OP_DRAW_RECT: {
            const x = readFloat(); const y = readFloat();
            const w = readFloat(); const h = readFloat();
            const color = readUint32(); setColor(color);
            paint.setStyle(ck.PaintStyle.Fill);
            canvas.drawRect(ck.XYWHRect(x, y, w, h), paint); break;
          }
          case OP_DRAW_RRECT: {
            const x = readFloat(); const y = readFloat();
            const w = readFloat(); const h = readFloat();
            const radius = readFloat(); const color = readUint32();
            setColor(color); paint.setStyle(ck.PaintStyle.Fill);
            canvas.drawRRect(ck.RRectXY(ck.XYWHRect(x, y, w, h), radius, radius), paint); break;
          }
          case OP_DRAW_TEXT: {
            const textLen = readInt32();
            const textBytes = new Uint8Array(buffer, offset, textLen);
            offset += textLen;
            const text = new TextDecoder().decode(textBytes);
            const x = readFloat(); const y = readFloat();
            const fontSize = readFloat();
            readInt32(); const color = readUint32();
            const boundsWidth = readFloat();
            const familyLen = readInt32();
            if (familyLen > 0) { offset += familyLen; }
            readInt32(); readInt32();
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
            font.delete(); break;
          }
          case OP_RETAINED_BEGIN: readInt32(); readInt32(); break;
          case OP_RETAINED_END: break;
        }
      }
      paint.delete();
    }
    """##
}
