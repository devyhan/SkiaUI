# SkiaUI

用Swift编写的声明式UI引擎。在Web上通过[Skia (CanvasKit)](https://skia.org/docs/user/modules/canvaskit/)进行渲染。编写SwiftUI风格的代码，在HTML Canvas上绘制像素级精确的UI。

**[English](/)** | **[한국어](/ko/)** | **[日本語](/ja/)**

```swift
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

## 为什么选择SkiaUI

Swift开发者要构建Web UI，要么转向JavaScript技术栈，要么接受以DOM为中心的渲染限制。

SkiaUI选择了不同的道路：

- **Swift作为唯一的UI语言** -- 声明式ResultBuilder DSL、`@State`、modifier
- **基于Canvas的渲染** -- 不是DOM元素，而是通过Skia绘图命令直接在`<canvas>`上绘制
- **渲染器无关的核心** -- DSL和布局引擎完全不知道CanvasKit的存在

## 架构

核心设计原则是**声明、计算、绘制的严格分离**。

```mermaid
graph TD
    A["Swift DSL<br/>(@ViewBuilder)"] --> B["Element Tree<br/><i>不可变、Equatable、Sendable值类型树</i>"]
    B --> C["Reconciler<br/><i>比较新旧树，生成最小Patch集</i>"]
    C --> D["Layout Engine<br/><i>基于约束的尺寸计算</i>"]
    D --> E["Render Tree<br/><i>已定位的RenderNode</i>"]
    E --> F["Display List<br/><i>扁平的DrawCommand缓冲区</i>"]
    F --> G["CommandEncoder<br/><i>二进制格式</i>"]
    G --> H["Web Host<br/><i>CanvasKit &lt;canvas&gt;</i>"]

    style A fill:#f5a623,color:#000
    style B fill:#4a90d9,color:#fff
    style C fill:#4a90d9,color:#fff
    style D fill:#4a90d9,color:#fff
    style E fill:#4a90d9,color:#fff
    style F fill:#7b68ee,color:#fff
    style G fill:#7b68ee,color:#fff
    style H fill:#50c878,color:#000
```

每一层都是独立的Swift模块，在`Package.swift`中定义了明确的依赖边界。

### 状态变更时的数据流

```mermaid
sequenceDiagram
    participant U as 用户点击
    participant S as @State
    participant SS as StateStorage
    participant RH as RootHost
    participant VE as ViewToElementConverter
    participant LE as LayoutEngine
    participant RT as RenderTreeBuilder
    participant DL as DisplayListBuilder
    participant CE as CommandEncoder
    participant WH as Web Host

    U->>S: 修改值
    S->>SS: set(id, value)
    SS->>SS: markDirty()
    SS->>RH: onDirty回调
    RH->>VE: convert(view)
    VE-->>RH: Element树
    RH->>LE: layout(element, constraints)
    LE-->>RH: LayoutNode树
    RH->>RT: build(element, layout)
    RT-->>RH: RenderNode树
    RH->>DL: build(renderNode)
    DL-->>RH: DisplayList
    RH->>CE: encode(displayList)
    CE-->>RH: [UInt8]
    RH->>WH: onDisplayList(bytes)
    WH->>WH: 通过CanvasKit回放
```

### 模块依赖图

```mermaid
graph BT
    Element["SkiaUIElement"]
    Text["SkiaUIText"]
    DSL["SkiaUIDSL"]
    State["SkiaUIState"]
    Reconciler["SkiaUIReconciler"]
    Layout["SkiaUILayout"]
    DL["SkiaUIDisplayList"]
    Renderer["SkiaUIRenderer"]
    RenderTree["SkiaUIRenderTree"]
    Semantics["SkiaUISemantics"]
    Runtime["SkiaUIRuntime"]
    WebBridge["SkiaUIWebBridge"]
    DevTools["SkiaUIDevTools"]
    Umbrella["SkiaUI<br/>(umbrella)"]
    DSL --> Element
    DSL --> Text
    Reconciler --> Element
    Layout --> Element
    RenderTree --> Element
    RenderTree --> Layout
    RenderTree --> DL
    Renderer --> DL
    Semantics --> Element
    Semantics --> Layout
    Runtime --> DSL
    Runtime --> State
    Runtime --> Element
    Runtime --> Reconciler
    Runtime --> Layout
    Runtime --> RenderTree
    Runtime --> DL
    Runtime --> Renderer
    Runtime --> Semantics
    WebBridge --> Runtime
    WebBridge --> DL
    WebBridge --> Semantics
    DevTools --> Element
    DevTools --> Layout
    DevTools --> Semantics
    DevTools --> RenderTree
    DevTools --> DL
    Umbrella --> DSL
    Umbrella --> State
    Umbrella --> Runtime

    style Umbrella fill:#f5a623,color:#000
    style Runtime fill:#4a90d9,color:#fff
    style DSL fill:#4a90d9,color:#fff
    style WebBridge fill:#50c878,color:#000
```

## 模块映射

```text
SkiaUI (umbrella)
  @_exported import SkiaUIDSL
  @_exported import SkiaUIState
  @_exported import SkiaUIRuntime

SkiaUIDSL           -> [SkiaUIElement, SkiaUIText]
  View协议、@ViewBuilder、PrimitiveView协议
  Primitives:   Text, Rectangle, Spacer, EmptyView
  Containers:   VStack, HStack, ZStack, ScrollView
  Modifiers:    padding, frame, background, foregroundColor, font,
                onTapGesture, accessibilityLabel/Role/Hint/Hidden,
                layoutPriority, fixedSize, drawingGroup
```

核心模块无外部依赖。`JavaScriptKit`仅在WebAssembly构建时由`SkiaUIWebBridge`使用。

## 核心设计决策

### Element：设计为indirect enum

```swift
public indirect enum Element: Hashable, Sendable {
    case empty
    case text(String, TextProperties)
    case rectangle(RectangleProperties)
    case spacer(minLength: Float?)
    case container(ContainerProperties, children: [Element])
    case modified(Element, Modifier)
}
```

整个UI树是一个单一的值类型`Equatable`结构。

### 基于约束的布局

```swift
public protocol LayoutStrategy: Sendable {
    func layout(children: [Element], constraints: Constraints,
                measure: (Element, Constraints) -> LayoutNode) -> LayoutNode
}
```

每种栈类型实现`LayoutStrategy`。

### 显示列表：渲染边界

显示列表是**跨越Swift-JavaScript边界的唯一数据**。

### 渲染树

`RenderTreeBuilder`同时遍历`Element`树和`LayoutNode`树，生成已定位的`RenderNode`。

### Reconciler

`ElementPath`以`[Int]`索引编码树位置。`DirtyTracker`标记路径及其祖先以执行目标re-layout。

### 响应式状态

`@State`由全局`StateStorage`（基于`NSLock`的线程安全）支撑。`AttributeGraph`（Eval/vite算法）跟踪每个composite View的`@State`依赖，缓存Element子树，在输入未变时跳过View的body重新执行。

### ViewBuilder (SE-0348)

使用`buildPartialBlock`（SE-0348）支持无限子元素。

## DSL接口

### 基本视图

| 视图 | 描述 |
| ---- | ---- |
| `Text("Hello")` | 带样式的文本节点 |
| `Rectangle()` | 纯色或圆角矩形 |
| `Spacer()` | 栈内弹性空间 |
| `EmptyView()` | 零尺寸占位符 |

### 容器

| 视图 | 描述 |
| ---- | ---- |
| `VStack(alignment:spacing:)` | 垂直布局 |
| `HStack(alignment:spacing:)` | 水平布局 |
| `ZStack(alignment:)` | 叠加/层叠布局 |
| `ScrollView(_:)` | 可滚动容器（`.vertical`或`.horizontal`） |

### View modifier

| Modifier | 示例 |
| -------- | ---- |
| `.padding(_:)` | `.padding(16)` |
| `.frame(width:height:)` | `.frame(width: 200, height: 100)` |
| `.background(_:)` | `.background(.blue)` |
| `.foregroundColor(_:)` | `.foregroundColor(.white)` |
| `.font(size:weight:)` | `.font(size: 24, weight: .bold)` |
| `.font(_:)` | `.font(.custom("Monaspace Neon", size: 16))` |
| `.fontFamily(_:)` | `.fontFamily("Courier")` (Text专用) |
| `.onTapGesture { }` | `.onTapGesture { count += 1 }` |
| `.accessibilityLabel(_:)` | `.accessibilityLabel("关闭按钮")` |
| `.drawingGroup()` | `.drawingGroup()` |

### Rectangle专用modifier

| Modifier | 示例 |
| -------- | ---- |
| `.fill(_:)` | `Rectangle().fill(.red)` |
| `.cornerRadius(_:)` | `Rectangle().fill(.orange).cornerRadius(12)` |

### 类型

| 类型 | 值 |
| ---- | -- |
| `Color` | `.red`, `.blue`, `.green`, `.orange`, `.purple`, `.yellow`, `.gray`, `.black`, `.white`, `.clear` |
| `FontWeight` | `.ultraLight`, `.thin`, `.light`, `.regular`, `.medium`, `.semibold`, `.bold`, `.heavy`, `.black` |
| `Font` | `.largeTitle`, `.title`, `.headline`, `.body`, `.caption`, `.custom("Name", size:)`, `.system(size:weight:design:)` |
| `Font.Design` | `.default`, `.monospaced`, `.rounded`, `.serif` |

## Web Client

`WebClient/`包含通过CanvasKit回放二进制显示列表的TypeScript客户端库。它不了解UI树、布局或状态。

## 快速开始

### 前提条件

- Swift 6.2+
- macOS 14.0+
- Node.js / pnpm（用于WebClient）

### 构建与运行

```bash
swift build
swift test
```

## 服务器集成

SkiaUI可以在服务器（如[Vapor](https://vapor.codes)）中作为包依赖使用。服务器执行完整的渲染管线，并通过HTTP发送结果`[UInt8]`二进制数据。浏览器客户端fetch该二进制数据，并通过`DisplayListPlayer`在`<canvas>`上回放。

### 1. 添加依赖

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

### 2. 渲染View

```swift
import SkiaUI

let host = RootHost()
host.setViewport(width: 800, height: 600)

var bytes: [UInt8] = []
host.setOnDisplayList { bytes = $0 }
host.render(CounterView())
// `bytes` 现在包含二进制显示列表
```

### 3. 通过HTTP提供

```swift
// Vapor示例
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

### 4. 浏览器客户端

将`WebClient/`静态文件复制到服务器的public目录，然后fetch并回放：

```js
const resp = await fetch('/display-list');
const buffer = await resp.arrayBuffer();
player.play(buffer, canvas);
```

## 项目状态

SkiaUI处于早期开发阶段。

- [x] 基于`@ViewBuilder`的ResultBuilder DSL
- [x] 4个基本视图
- [x] 4个容器视图（`VStack`、`HStack`、`ZStack`、`ScrollView`）
- [x] 15个view modifier + 2个Rectangle专用modifier
- [x] `@State`响应性与自动重新渲染
- [x] 基于约束的布局引擎
- [x] 基于最小diff的树协调
- [x] 二进制显示列表编码/解码
- [x] CanvasKit Web渲染
- [x] Z-order正确命中测试
- [x] 无障碍语义树

### 路线图

- [ ] List
- [ ] 动画系统
- [ ] 图片支持
- [ ] 键盘 / 焦点管理
- [ ] 无障碍DOM覆盖层
- [ ] 原生Skia后端（Metal / Vulkan）
- [ ] Hot reload

## 许可证

MIT — 详细信息请参阅 [LICENSE](https://github.com/devyhan/SkiaUI/blob/main/LICENSE)。

第三方许可证列于 [THIRD_PARTY_NOTICES](https://github.com/devyhan/SkiaUI/blob/main/THIRD_PARTY_NOTICES)。
