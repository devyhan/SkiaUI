import SkiaUI
import SkiaUIWebBridge

@main
struct BasicApp: SkiaUI.App {
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
        WebBridge.start(BasicApp.self)
    }
}
