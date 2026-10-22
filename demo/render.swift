// render.swift: renders a demo scene to PNG frames (macOS 14+).
//
//   swiftc -parse-as-library -target arm64-apple-macos14 \
//     templates/swiftui/Motion.swift templates/swiftui/LiveFace.swift demo/*.swift -o /tmp/render-demo
//   /tmp/render-demo room /tmp/frames      # or: orbit
//   ffmpeg -framerate 30 -i /tmp/frames/%04d.png -c:v libx264 -pix_fmt yuv420p -crf 20 demo/demo.mp4
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@main
struct RenderDemo {
    @MainActor
    static func main() throws {
        let args = CommandLine.arguments
        let scene = args.count > 1 ? args[1] : "room"
        let out = URL(fileURLWithPath: args.count > 2 ? args[2] : "frames")
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        let fps = 30.0
        let loopMs = scene == "orbit" ? OrbitScene.loopMs : DemoScene.loopMs
        let frames = Int(loopMs / 1000 * fps)
        for f in 0..<frames {
            let t = Double(f) / fps * 1000
            let content: AnyView = scene == "orbit" ? AnyView(OrbitScene(t: t)) : AnyView(DemoScene(t: t))
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
            let url = out.appendingPathComponent(String(format: "%04d.png", f))
            guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            CGImageDestinationAddImage(dest, image, nil)
            CGImageDestinationFinalize(dest)
        }
        print("rendered \(frames) frames of \(scene) to \(out.path)")
    }
}
