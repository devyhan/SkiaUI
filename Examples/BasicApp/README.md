# SkiaUI BasicApp Example

A minimal SkiaUI app that renders to a browser canvas via WebAssembly.

## Prerequisites

- Swift 6.2+
- Swift WASM SDK

Install the WASM SDK:

```bash
swift sdk install https://download.swift.org/swift-6.2.4-release/wasm-sdk/swift-6.2.4-RELEASE/swift-6.2.4-RELEASE_wasm.artifactbundle.tar.gz
```

## Quick Start

1. **Copy this directory** to start your own project:

   ```bash
   cp -r Examples/BasicApp ~/MySkiaUIApp
   cd ~/MySkiaUIApp
   ```

2. **Edit `Sources/App.swift`** to build your UI:

   ```swift
   import SkiaUI
   import SkiaUIWebBridge

   @main
   struct BasicApp: SkiaUI.App {
       var body: some View {
           VStack(spacing: 16) {
               Text("Hello, SkiaUI!")
                   .fontSize(28)
                   .bold()
           }
       }

       static func main() {
           WebBridge.start(BasicApp.self)
       }
   }
   ```

3. **Build and run (with Vapor):**

   ```bash
   # Build directly into Vapor's public directory
   swift run skia build --output Public
   
   # Start the Vapor server
   swift run App
   ```

4. Open `http://localhost:8080` (or your Vapor port) in your browser.

## Project Structure

```
BasicApp/
├── Package.swift              # SPM manifest with SkiaUI dependency
├── Sources/
│   └── App.swift              # Entry point and UI definition
├── WebHost/
│   ├── index.html             # Browser entry point (CanvasKit loader)
│   └── displayListPlayer.mjs  # DisplayList binary decoder + renderer
└── README.md                  # This file
```

## How It Works

1. `swift run skia build` compiles Swift to WASM, generates JS glue code, and bundles everything into `dist/`
2. `index.html` loads CanvasKit, initializes the canvas, and starts the WASM app
3. Swift renders UI via the SkiaUI pipeline and sends binary display list commands to `displayListPlayer.mjs`
4. The player decodes the binary commands and draws them using CanvasKit
