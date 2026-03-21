import Vapor
import SkiaUI

@main
struct VaporServerExample {
    static func main() async throws {
        let app = try await Application.make()
        
        // Configure static files (where your WASM app lives)
        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
        
        // Example: Stream a dynamic display list
        app.get("display-list") { req -> Response in
            let host = RootHost()
            host.setViewport(width: 800, height: 600)
            
            var bytes: [UInt8] = []
            host.setOnDisplayList { bytes = $0 }
            
            // Render a simple view
            host.render(
                VStack(spacing: 20) {
                    Text("Generated on Server")
                        .fontSize(32)
                        .bold()
                    Text("Time: \(Date())")
                        .foregroundColor(.gray)
                }
                .padding(40)
            )
            
            return Response(
                status: .ok,
                headers: ["Content-Type": "application/octet-stream"],
                body: .init(data: Data(bytes))
            )
        }
        
        try await app.execute()
    }
}
