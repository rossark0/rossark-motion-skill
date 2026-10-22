// render.swift: renders the demo scene to PNG frames (macOS 14+).
//
//   swiftc -parse-as-library -target arm64-apple-macos14 \
//     templates/swiftui/Motion.swift templates/swiftui/LiveFace.swift \
//     demo/DemoScene.swift demo/render.swift -o /tmp/render-demo
//   /tmp/render-demo /tmp/frames
//   ffmpeg -framerate 30 -i /tmp/frames/%04d.png -c:v libx264 -pix_fmt yuv420p -crf 18 demo/demo.mp4
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@main
struct RenderDemo {
    @MainActor
    static func main() throws {
        let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "frames")
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        let fps = 30.0
        let frames = Int(DemoScene.loopMs / 1000 * fps)
        for f in 0..<frames {
            let t = Double(f) / fps * 1000
            let renderer = ImageRenderer(content: DemoScene(t: t))
            renderer.scale = 2
            guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
            let url = out.appendingPathComponent(String(format: "%04d.png", f))
            guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            CGImageDestinationAddImage(dest, image, nil)
            CGImageDestinationFinalize(dest)
        }
        print("rendered \(frames) frames to \(out.path)")
    }
}
