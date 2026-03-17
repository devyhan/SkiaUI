# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SkiaUI is a declarative UI engine written in Swift that renders to Skia (CanvasKit) on the web. SwiftUI-style DSL, canvas-based rendering, renderer-agnostic core. Experimental stage — APIs are unstable.

## Build & Test

```bash
swift build                              # Build all modules
swift test                               # Run all 21 test suites (161 tests)
swift test --filter SkiaUILayoutTests    # Run a single test suite
swift test --filter "LayoutTests/testTextLayout"  # Run a single test
cd WebClient && pnpm install             # Install WebClient JS dependencies
```

Requirements: Swift 6.2+, macOS 14.0+, Node.js/pnpm (for WebClient).

## Architecture — Rendering Pipeline

The pipeline flows through distinct Swift modules, each a separate SPM target:

```
Swift DSL (@ViewBuilder) → Element Tree → Reconciler → Layout Engine → Render Tree → Display List → CommandEncoder → [binary bytes] → Web Host (CanvasKit)
```

**The binary display list is the only thing that crosses the Swift–JS boundary** — zero JSON, zero object marshalling.

### Module Roles

| Module | Purpose | Key Types |
|--------|---------|-----------|
| **SkiaUIElement** | Core value-type tree | `Element` (indirect enum), `Modifier` (enum), `ElementColor`, `ElementID` |
| **SkiaUIText** | Font/text types | `Font`, `TextStyle`, `ParagraphSpec` |
| **SkiaUIDSL** | SwiftUI-style API surface | `View`, `PrimitiveView`, `ViewBuilder`, `ViewToElementConverter`, primitives (Text, Rectangle, Spacer), containers (VStack, HStack, ZStack), modifiers |
| **SkiaUIState** | Reactive state | `@State`, `Binding`, `StateStorage` (singleton with NSLock), `EnvironmentValues` |
| **SkiaUIReconciler** | Tree diffing | `Reconciler.diff()` → `[Patch]`, `DirtyTracker` |
| **SkiaUILayout** | ProposedSize negotiation | `LayoutEngine`, `ProposedSize`, `LayoutNode`, `LayoutStrategy` protocol, `VStackLayout`/`HStackLayout`/`ZStackLayout` |
| **SkiaUIRenderTree** | Paintable scene graph | `RenderNode`, `RenderTreeBuilder`, `DisplayListBuilder` |
| **SkiaUIDisplayList** | Serialized draw commands | `DisplayList`, `DrawCommand` (enum), `CommandEncoder` (binary encode/decode) |
| **SkiaUIRenderer** | Backend abstraction | `RendererBackend` protocol |
| **SkiaUISemantics** | Accessibility tree | `SemanticsNode`, `SemanticsTreeBuilder`, `SemanticsRole` |
| **SkiaUIRuntime** | Orchestrator | `App` protocol, `RootHost` (runs full pipeline), `FrameLoop` (polls dirty state) |
| **SkiaUIWebBridge** | WASM/JS interop | `WebBridge`, `DisplayListExport` — active only when `canImport(JavaScriptKit)` |
| **SkiaUIDevTools** | Debug tools | `TreeInspector`, `DebugOverlay`, `SemanticsInspector` |
| **SkiaUI** | Umbrella | Re-exports DSL + State + Runtime — `import SkiaUI` for all public APIs |

### State Change Flow

`@State` setter → `StateStorage.markDirty()` → `FrameLoop` polls `consumeDirty()` → `RootHost.render()` re-executes full pipeline.

### Key Dependency Chain (Package.swift)

```
SkiaUI (umbrella) → SkiaUIDSL, SkiaUIState, SkiaUIRuntime
SkiaUIRuntime → SkiaUIDSL, SkiaUIState, SkiaUIElement, SkiaUIReconciler, SkiaUILayout, SkiaUIRenderTree, SkiaUIDisplayList, SkiaUIRenderer, SkiaUISemantics
SkiaUIRenderTree → SkiaUIElement, SkiaUILayout, SkiaUIDisplayList
SkiaUIDSL → SkiaUIElement, SkiaUIText
```

Core modules (Element, Text, DisplayList, State) have zero dependencies.

## Code Conventions

- Swift 6.2+ with strict concurrency — all core types are `Equatable` and `Sendable`
- Element tree is a **value-type indirect enum** — immutable, serializable, diffable
- ViewBuilder uses SE-0348 `buildPartialBlock` for unlimited children (accumulates via `TupleView2`)
- Layout uses **ProposedSize-based negotiation** (SwiftUI-compatible): `nil` = use intrinsic size
- Stack layout distributes space by `layoutPriority` groups, then by flexibility within groups
- Text sizing is estimated: `fontSize × 0.6 × charCount` width, `fontSize × 1.2` height
- No external dependencies for core modules (JavaScriptKit only for WASM builds, commented out by default)
- Tests use Swift Testing framework (`@Suite`, `@Test`)

## Documentation Sync Rules

`README.md` (root) is the **source of truth**. All translated READMEs must have identical structure.

| File | Language |
|------|----------|
| `README.md` | English (source of truth) |
| `Docs/README_ko.md` | Korean |
| `Docs/README_ja.md` | Japanese |
| `Docs/README_zh.md` | Chinese |

Docsify site (`Docs/`) mirrors the same content with Docsify-compatible links (`/ko/`, `/ja/`, `/zh/`). Feature Status table must reflect actual implementation in `Sources/`. GitHub Pages deploys from `Docs/` via GitHub Actions.

## Git Conventions

- Commit messages: imperative mood, concise
- No Co-Authored-By lines in commits
- Main branch: `main`
