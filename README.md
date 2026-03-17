<p align="center">
  <img src="Resources/SkiaUI.png" alt="SkiaUI Logo" width="400">
</p>

# SkiaUI

A declarative UI engine written in Swift that renders to [Skia (CanvasKit)](https://skia.org/docs/user/modules/canvaskit/) on the web.

Write SwiftUI-style code, render pixel-perfect UI on an HTML `<canvas>`.

**[한국어](Docs/README_ko.md)** | **[日本語](Docs/README_ja.md)** | **[中文](Docs/README_zh.md)** | **[Documentation](https://devyhan.github.io/SkiaUI/)**

> [!IMPORTANT]
> SkiaUI is currently in an **experimental stage**. APIs are unstable and may change without notice. Not recommended for production use.

```swift
import SkiaUI

struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Count: \(count)")
                .font(size: 32)
                .foregroundColor(.blue)

            HStack(spacing: 16) {
                Text("- Decrease")
                    .padding(12)
                    .background(.red)
                    .foregroundColor(.white)
                    .onTapGesture { count -= 1 }

                Text("+ Increase")
                    .padding(12)
                    .background(.blue)
                    .foregroundColor(.white)
                    .onTapGesture { count += 1 }
            }
        }
        .padding(32)
    }
}
```

## Goals

- **Swift as the single UI language** -- declarative ResultBuilder DSL, `@State`, modifiers
- **Canvas-based rendering** -- Skia drawing commands on `<canvas>`, not DOM elements
- **Renderer-agnostic core** -- a native Skia or Metal backend can be added without changing user code

## Architecture

```mermaid
graph TD
    A["Swift DSL<br/>(@ViewBuilder)"] --> B["Element Tree"]
    B --> C["Reconciler"]
    C --> D["Layout Engine"]
    D --> E["Render Tree"]
    E --> F["Display List"]
    F --> G["CommandEncoder"]
    G --> H["Web Host<br/>(CanvasKit)"]

    style A fill:#f5a623,color:#000
    style B fill:#4a90d9,color:#fff
    style C fill:#4a90d9,color:#fff
    style D fill:#4a90d9,color:#fff
    style E fill:#4a90d9,color:#fff
    style F fill:#7b68ee,color:#fff
    style G fill:#7b68ee,color:#fff
    style H fill:#50c878,color:#000
```

Each layer is a separate Swift module. The binary display list is the **only thing that crosses the Swift–JavaScript boundary** — zero JSON, zero object marshalling.

## Feature Status

| Category | Feature | Status |
| -------- | ------- | ------ |
| **Views** | Text, Rectangle, Spacer, EmptyView | Done |
| **Containers** | VStack, HStack, ZStack, ScrollView | Done |
| **Modifiers** | padding, frame, background, foregroundColor, font, fontFamily, onTapGesture, drawingGroup | Done |
| **Typography** | Font struct (.custom, .system, semantic styles), fontFamily pipeline, FontManager | Done |
| **Layout** | ProposedSize negotiation, layoutPriority, fixedSize, flexible frame (min/ideal/max) | Done |
| **State** | @State, Binding, automatic re-rendering, incremental evaluation (AttributeGraph) | Done |
| **Accessibility** | accessibilityLabel, accessibilityRole, accessibilityHint, accessibilityHidden | Done |
| **Rendering** | Binary display list, CanvasKit replay, retained subtrees, pipeline optimizations | Done |
| **Reconciler** | Tree diff, Patch, DirtyTracker, RootHost integration | Done |
| **Testing** | 21 test suites, 161 tests | Done |
| **Rendering** | List | Planned |
| **Rendering** | Animation system | Planned |
| **Rendering** | Image support | Planned |
| **Platform** | Native Skia backend (Metal / Vulkan) | Planned |

## Products

| Product | Description |
| ------- | ----------- |
| **SkiaUI** | Umbrella module — `import SkiaUI` to access all DSL, state, and runtime APIs |
| **SkiaUIWebBridge** | JavaScriptKit interop layer for WebAssembly builds (isolated dependency) |
| **SkiaUIDevTools** | TreeInspector, DebugOverlay, SemanticsInspector for development |

## Getting Started

### Requirements

- Swift 6.2+
- macOS 14.0+
- Node.js / pnpm (for WebClient)

### Build & Test

```bash
# Build all modules
swift build

# Run tests
swift test
```

### Quick Start (WASM)

Deploy a SkiaUI app directly to the browser via WebAssembly in 5 steps:

**1. Install the Swift WASM SDK**

```bash
swift sdk install https://download.swift.org/swift-6.2.4-release/wasm-sdk/swift-6.2.4-RELEASE/swift-6.2.4-RELEASE_wasm.artifactbundle.tar.gz
```

**2. Copy the example project**

```bash
cp -r Examples/BasicApp ~/MySkiaUIApp
cd ~/MySkiaUIApp
```

**3. Edit `Sources/App.swift`**

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

**4. Build**

```bash
./build.sh
```

**5. Serve and open**

```bash
npx serve dist    # or: python3 -m http.server -d dist
```

Open `http://localhost:3000` in your browser.

> See [`Examples/BasicApp/`](Examples/BasicApp/) for the complete example project.

## Server Integration

SkiaUI can run on a server (e.g. Vapor) and stream binary display lists to a browser client over HTTP.

**1. Add Dependency**

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/devyhan/SkiaUI.git", branch: "main")
],
targets: [
    .executableTarget(name: "MyApp", dependencies: [
        .product(name: "SkiaUI", package: "SkiaUI")
    ])
]
```

**2. Render a View**

```swift
import SkiaUI

let host = RootHost()
host.setViewport(width: 800, height: 600)

var bytes: [UInt8] = []
host.setOnDisplayList { bytes = $0 }
host.render(CounterView())
// `bytes` now contains the binary display list
```

**3. Serve via HTTP**

```swift
// Vapor example
app.get("display-list") { req -> Response in
    var bytes: [UInt8] = []
    host.setOnDisplayList { bytes = $0 }
    host.render(MyView())
    return Response(
        status: .ok,
        headers: ["Content-Type": "application/octet-stream"],
        body: .init(data: Data(bytes))
    )
}
```

**4. Browser Client**

Copy `WebClient/` static files to your server's public directory, then fetch and replay:

```js
const resp = await fetch('/display-list');
const buffer = await resp.arrayBuffer();
player.play(buffer, canvas);
```

## Known Limitations

- Text rendering relies on estimated glyph widths (`fontSize × 0.6 × charCount`), not real font metrics
- No text wrapping or line breaking — single-line text only
- No gesture recognizers beyond `onTapGesture`
- No keyboard input or focus management
- No image loading or rendering
- No animation or transition support

## License

MIT — see [LICENSE](LICENSE) for details.

Third-party licenses are listed in [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES).

## Disclaimer

SwiftUI is a trademark owned by Apple Inc. This project is not affiliated with, endorsed by, or connected to Apple Inc. in any way.
