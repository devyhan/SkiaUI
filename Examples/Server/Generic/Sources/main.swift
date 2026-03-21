import Foundation
import SkiaUI

// A minimal example showing how to use SkiaUI on the server
// to generate a binary display list without any web framework.

let host = RootHost()
host.setViewport(width: 500, height: 500)

print("Rendering SkiaUI view to binary display list...")

host.setOnDisplayList { bytes in
    print("Success! Generated \(bytes.count) bytes.")
    
    // In a real server, you would send these bytes over a socket
    // or write them to a file for a client to fetch.
    let desktopPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop/sample.skialist")
    
    try? Data(bytes).write(to: desktopPath)
    print("Saved to: \(desktopPath.path)")
}

host.render(
    ZStack {
        Color(hex: 0xEEEEEE)
        VStack {
            Text("Generic Server")
                .fontSize(40)
            Text("No Framework Required")
                .foregroundColor(.blue)
        }
    }
)
